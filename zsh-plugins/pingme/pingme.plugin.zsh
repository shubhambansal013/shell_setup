# Zsh plugin to ring a terminal bell and send a Telegram notification for
# long-running commands.
#
# To set up Telegram notifications, source the interactive configuration script:
#   source /path/to/pingme_configure.zsh
#
# This will guide you through creating a ~/.pingme.env file with your
# Telegram credentials. The plugin will automatically source this file if it exists.

# Source environment variables from ~/.pingme.env if it exists.
if [[ -f "${ZDOTDIR:-$HOME}/.pingme.env" ]]; then
  source "${ZDOTDIR:-$HOME}/.pingme.env"
fi

# --- Configuration ---
# Default to 1 second. Users can override this in their .zshrc by setting
# ZSH_PINGME_DURATION before sourcing this plugin. For example:
# export ZSH_PINGME_DURATION=30
: "${ZSH_PINGME_DURATION:=20}"

# Set to enable verbose mode.
# export ZSH_PINGME_VERBOSE=1
: "${ZSH_PINGME_VERBOSE:=}"

# --- Excluded Commands ---
# Define a list of commands that should not trigger notifications.
# Users can override this in their .zshrc. For example:
# ZSH_PINGME_EXCLUDED_COMMANDS=("vi" "nano" "my_custom_tool")
# Initialize with defaults only if not already set by the user.
if (( ! ${+ZSH_PINGME_EXCLUDED_COMMANDS} )); then
    ZSH_PINGME_EXCLUDED_COMMANDS=(
    vi
    vim
    nano
    emacs
    tmux
    less
    more
    man
    cat
    tail
    ssh
    git
    fzf
  )
fi

# For Telegram notifications, you need to set the following environment variables:
# export TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
# export TELEGRAM_CHAT_ID="YOUR_TELEGRAM_CHAT_ID"

# --- Helper Functions ---
_zsh_pingme_verbose_print() {
    if [[ -n "$ZSH_PINGME_VERBOSE" ]]; then
        print -r -- "[PingMe Verbose] $1" >&2
    fi
}

_zsh_pingme_extract_base_command() {
    local full_command_string="$1"
    local base_command
    local parts
    # zsh array splitting from string by spaces.
    parts=(${(s: :)full_command_string})

    if [[ ${#parts[@]} -eq 0 ]]; then
        _zsh_pingme_verbose_print "extract_base_command: Command string was empty or all spaces."
        base_command=""
    else
        local cmd_idx=1
        while [[ $cmd_idx -lt ${#parts[@]} && "${parts[$cmd_idx]}" == *=* ]]; do
            ((cmd_idx++))
        done

        local first_word="${parts[$cmd_idx]}"

        if [[ "$first_word" == "sudo" && ${#parts[@]} -gt $cmd_idx ]]; then
            base_command="${parts[$((cmd_idx+1))]}"
        elif [[ "$first_word" == "env" && ${#parts[@]} -gt $cmd_idx ]]; then
            local env_cmd_idx=$((cmd_idx+1))
            while [[ $env_cmd_idx -le ${#parts[@]} && ( "${parts[$env_cmd_idx]}" == *=* || "${parts[$env_cmd_idx]}" == -* ) ]]; do
                ((env_cmd_idx++))
            done
            if [[ $env_cmd_idx -le ${#parts[@]} ]]; then
                base_command="${parts[$env_cmd_idx]}"
            else
                base_command="env"
            fi
        else
            base_command="$first_word"
        fi
    fi

    if [[ -n "$base_command" ]]; then
        base_command="${base_command##*/}"
    fi
    
    _zsh_pingme_verbose_print "extract_base_command: Extracted base command: \'${base_command}\' from \'${full_command_string}\'"
    echo "$base_command"
}

# Formats seconds into a string like: 1h 23m 45s or 45m 0s or 30s
_zsh_pingme_format_duration() {
    local -i total_seconds=$1
    if (( total_seconds < 0 )); then total_seconds=0; fi
    local -i hours=$((total_seconds / 3600))
    local -i minutes=$(( (total_seconds % 3600) / 60 ))
    local -i seconds=$((total_seconds % 60))

    if (( hours > 0 )); then
        echo "${hours}h ${minutes}m ${seconds}s"
    elif (( minutes > 0 )); then
        echo "${minutes}m ${seconds}s"
    else
        echo "${seconds}s"
    fi
}

# --- Globals ---
# Start time (in EPOCHSECONDS) of the command being executed.
_zsh_pingme_start_time=
# Command string being executed.
_zsh_pingme_command_string=

# --- Plugin Loaded Message ---
_zsh_pingme_verbose_print "Plugin loaded. Duration: ${ZSH_PINGME_DURATION}s, Verbose: ${ZSH_PINGME_VERBOSE:-disabled}"

# --- Hook Functions ---

_zsh_pingme_send_telegram_notification() {
    local message_text="$1"
    _zsh_pingme_verbose_print "telegram: Attempting to send: '$message_text'"
    if [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]]; then
        _zsh_pingme_verbose_print "telegram: Token or Chat ID not set. Notification disabled."
        return 1
    fi
    if ! curl -s --connect-timeout 5 --max-time 10 -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" --data-urlencode "text=${message_text}" --data "parse_mode=Markdown" > /dev/null; then
        _zsh_pingme_verbose_print "telegram: curl command failed to send notification."
        return 1
    fi
    _zsh_pingme_verbose_print "telegram: Notification sent successfully via curl."
    return 0
}

# Executed before a command line is executed.
zsh_pingme_preexec() {
    _zsh_pingme_start_time=$EPOCHSECONDS
    _zsh_pingme_command_string="$1"
    _zsh_pingme_verbose_print "preexec: Recording command: '$1', start_time: $EPOCHSECONDS"
}

# Executed before each prompt is displayed (after a command has finished).
zsh_pingme_precmd() {
    _zsh_pingme_verbose_print "precmd: Entered. Monitored command: '${_zsh_pingme_command_string}', start_time: ${_zsh_pingme_start_time}"

    local base_command
    base_command=$(_zsh_pingme_extract_base_command "$_zsh_pingme_command_string")
    _zsh_pingme_verbose_print "precmd: Base command: '${base_command}'"

    # Check if the base command is in the excluded list.
    if (( ${#ZSH_PINGME_EXCLUDED_COMMANDS[@]} > 0 )); then
        for excluded_command in "${ZSH_PINGME_EXCLUDED_COMMANDS[@]}"; do
            if [[ "$base_command" == "$excluded_command" ]]; then
                _zsh_pingme_verbose_print "precmd: Command '${base_command}' is in the excluded list. Skipping."
                # Reset variables and exit.
                _zsh_pingme_start_time=
                _zsh_pingme_command_string=
                return
            fi
        done
    fi

    if [[ -n "$_zsh_pingme_start_time" && -n "$_zsh_pingme_command_string" ]]; then
        local cmd_end_time=$EPOCHSECONDS
        local cmd_duration=$((cmd_end_time - _zsh_pingme_start_time))
        _zsh_pingme_verbose_print "precmd: Processing command: '${_zsh_pingme_command_string}'. Duration: ${cmd_duration}s. Threshold: ${ZSH_PINGME_DURATION}s."

        # Send a notification if the command duration exceeds the threshold.
        if (( cmd_duration >= ZSH_PINGME_DURATION )); then
            _zsh_pingme_verbose_print "precmd: Command met threshold. Sending Telegram notification."
            
            local formatted_duration=$(_zsh_pingme_format_duration "$cmd_duration")
            local telegram_message="Cmd finished \[${formatted_duration}]: ${_zsh_pingme_command_string}"
            _zsh_pingme_send_telegram_notification "${telegram_message}"
            _zsh_pingme_verbose_print "precmd: Ringing bell."
            print -n '\a' # Ring the terminal bell.
        fi

        # Reset variables to avoid re-running for an empty command/prompt.
        _zsh_pingme_verbose_print "precmd: Resetting PingMe variables."
        _zsh_pingme_start_time=
        _zsh_pingme_command_string=
    fi
}

# --- Setup ---

# Ensure the add-zsh-hook function is available.
autoload -Uz add-zsh-hook

# Add the functions to Zsh's pre-execution and pre-command hooks.
add-zsh-hook preexec zsh_pingme_preexec
add-zsh-hook precmd zsh_pingme_precmd

# Ensure the start time variable is initially unset.
unset _zsh_pingme_start_time _zsh_pingme_command_string
