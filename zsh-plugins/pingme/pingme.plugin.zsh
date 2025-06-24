# Zsh plugin to ring a terminal bell and send a Telegram notification for
# long-running commands.
#
# To set up Telegram notifications, you need to run the interactive configuration
# script:
#   source /path/to/pingme_configure.zsh
#
# This script will guide you through creating a ~/.pingme.env file with your
# Telegram credentials. The plugin will automatically source this file if it
# exists.
#
# The Telegram notification includes:
#   - A status icon: ✅ for success, ❌ for failure.
#   - The command's exit code.
#   - The command string (truncated to 1024 characters to avoid excessively
#     long messages).

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

# The pingme_configure.zsh script is for interactive configuration and is not
# the plugin itself.

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

# Extracts the base command from a full command string, ignoring sudo, env,
# variable assignments, and options.
# Examples:
#   "git clone ..." -> "git"
#   "sudo apt-get update" -> "apt-get"
#   "env FOO=bar /path/to/binary --flag" -> "binary"
#   "/usr/bin/python3 my_script.py" -> "python3"
_zsh_pingme_extract_base_command() {
    local full_command_string="$1"
    local base_command
    local part
    # Split the command string into parts by spaces.
    for part in ${(s: :)full_command_string}; do
        case "$part" in
            sudo|env|*=*|-*)
                continue
                ;;
            *)
                base_command="$part"
                break
                ;;
        esac
    done

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
# Exit status of the last command.
_zsh_pingme_exit_status=

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

    local response
    response=$(curl -s --connect-timeout 5 --max-time 10 -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" --data-urlencode "text=${message_text}" --data "parse_mode=Markdown")
    local curl_exit_code=$?

    if [[ $curl_exit_code -ne 0 ]]; then
        _zsh_pingme_verbose_print "telegram: curl command failed with exit code ${curl_exit_code}."
        if [[ -n "$response" ]]; then
            _zsh_pingme_verbose_print "telegram: curl response: '$response'"
        fi
        return 1
    fi

    # Telegram API returns a JSON with "ok":true on success.
    # A simple string check is sufficient and avoids a dependency on a JSON parser.
    if [[ "$response" == *"\"ok\":true"* ]]; then
        _zsh_pingme_verbose_print "telegram: Notification sent successfully via curl."
    else
        _zsh_pingme_verbose_print "telegram: API call successful, but notification failed. Response: $response"
        return 1
    fi

    return 0
}

# Executed before a command line is executed, to record the start time and the
# command string.
zsh_pingme_preexec() {
    _zsh_pingme_start_time=$EPOCHSECONDS
    _zsh_pingme_command_string="$1"
    _zsh_pingme_verbose_print "preexec: Recording command: '$1', start_time: $EPOCHSECONDS"
}

# Executed before each prompt is displayed (after a command has finished), to
# check if the command took long enough and send a notification if needed.
zsh_pingme_precmd() {
    # Capture the exit status of the command.
    _zsh_pingme_exit_status=$?
    _zsh_pingme_verbose_print "precmd: Entered. Monitored command: '${_zsh_pingme_command_string}', start_time: ${_zsh_pingme_start_time}"

    # Exit early if there is no command to process.
    if [[ -z "$_zsh_pingme_command_string" || -z "$_zsh_pingme_start_time" ]] ; then
        _zsh_pingme_verbose_print "precmd: No command to process. Skipping."
        # Reset variables and exit.
        unset _zsh_pingme_start_time
        unset _zsh_pingme_command_string
        unset _zsh_pingme_exit_status
        return
    fi

    local base_command
    base_command=$(_zsh_pingme_extract_base_command "$_zsh_pingme_command_string")
    _zsh_pingme_verbose_print "precmd: Base command: '${base_command}'"

    # Check if the base command is in the excluded list.
    if (( ${#ZSH_PINGME_EXCLUDED_COMMANDS[@]} > 0 )) ; then
        for excluded_command in "${ZSH_PINGME_EXCLUDED_COMMANDS[@]}"; do
            if [[ "$base_command" == "$excluded_command" ]]; then
                _zsh_pingme_verbose_print "precmd: Command '${base_command}' is in the excluded list. Skipping."
                # Reset variables and exit.
                unset _zsh_pingme_start_time
                unset _zsh_pingme_command_string
                unset _zsh_pingme_exit_status
                return
            fi
        done
    fi

    local cmd_end_time=$EPOCHSECONDS
    local cmd_duration=$((cmd_end_time - _zsh_pingme_start_time))
    _zsh_pingme_verbose_print "precmd: Processing command: '${_zsh_pingme_command_string}'. Duration: ${cmd_duration}s. Threshold: ${ZSH_PINGME_DURATION}s."

    # Send a notification if the command duration exceeds the threshold.
    if (( cmd_duration >= ZSH_PINGME_DURATION )) ; then
        _zsh_pingme_verbose_print "precmd: Command met threshold. Sending Telegram notification."

        local formatted_duration=$(_zsh_pingme_format_duration "$cmd_duration")
        local status_icon="✅"
        if [[ $_zsh_pingme_exit_status -ne 0 ]] ; then
            status_icon="❌"
        fi
        local command_string_for_telegram="${_zsh_pingme_command_string}"
        if [[ ${#command_string_for_telegram} -gt 1024 ]]; then
            command_string_for_telegram="${command_string_for_telegram:0:1021}..."
        fi
        local telegram_message; printf -v telegram_message '%s Command finished in `%s` (exit code: `%s`):\n```\n%s\n```' "${status_icon}" "${formatted_duration}" "$_zsh_pingme_exit_status" "${command_string_for_telegram}"
        _zsh_pingme_send_telegram_notification "${telegram_message}"
        _zsh_pingme_verbose_print "precmd: Ringing bell."
        print -n '\a' # Ring the terminal bell.
    fi

    # Reset variables to avoid re-running for an empty command/prompt.
    _zsh_pingme_verbose_print "precmd: Resetting PingMe variables."
    unset _zsh_pingme_start_time
    unset _zsh_pingme_command_string
    unset _zsh_pingme_exit_status
}

# --- Setup: Add hooks to Zsh ---

# Ensure the add-zsh-hook function is available.
autoload -Uz add-zsh-hook

# Add the functions to Zsh's pre-execution and pre-command hooks.
add-zsh-hook preexec zsh_pingme_preexec
add-zsh-hook precmd zsh_pingme_precmd

# Ensure the global variables are initially reset.
unset _zsh_pingme_start_time
unset _zsh_pingme_command_string
unset _zsh_pingme_exit_status
