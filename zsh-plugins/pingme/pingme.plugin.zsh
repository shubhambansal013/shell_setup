# Zsh plugin to ring a terminal bell and send a Telegram notification for
# long-running commands.

# --- Configuration ---
# Default to 1 second. Users can override this in their .zshrc by setting
# ZSH_PINGME_DURATION before sourcing this plugin. For example:
# export ZSH_PINGME_DURATION=30
: "${ZSH_PINGME_DURATION:=10}"

# Set to enable verbose mode.
# export ZSH_PINGME_VERBOSE=1
: "${ZSH_PINGME_VERBOSE:=}"

# For Telegram notifications, you need to set the following environment variables:
# export TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
# export TELEGRAM_CHAT_ID="YOUR_TELEGRAM_CHAT_ID"

# --- Helper Functions ---
_zsh_pingme_verbose_print() {
    if [[ -n "$ZSH_PINGME_VERBOSE" ]]; then
        print -r -- "%F{cyan}[PingMe Verbose]%f $1" >&2
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
    if ! curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" --data-urlencode "text=${message_text}" --data "parse_mode=Markdown" > /dev/null; then
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
    if [[ -n "$_zsh_pingme_start_time" && -n "$_zsh_pingme_command_string" ]]; then
        local cmd_end_time=$EPOCHSECONDS
        local cmd_duration=$((cmd_end_time - _zsh_pingme_start_time))
        _zsh_pingme_verbose_print "precmd: Processing command: '${_zsh_pingme_command_string}'. Duration: ${cmd_duration}s. Threshold: ${ZSH_PINGME_DURATION}s."

        # Send a notification if the command duration exceeds the threshold.
        if (( cmd_duration >= ZSH_PINGME_DURATION )); then
            _zsh_pingme_verbose_print "precmd: Command met threshold. Sending Telegram notification."
            local telegram_message="Cmd finished \[${cmd_duration}s]: ${_zsh_pingme_command_string}"
            _zsh_pingme_send_telegram_notification "${telegram_message}"
        fi
        _zsh_pingme_verbose_print "precmd: Ringing bell."
        print -n '\a' # Ring the terminal bell.

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
