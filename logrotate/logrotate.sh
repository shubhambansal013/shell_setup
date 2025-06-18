#!/bin/bash

# Set -euo pipefail for robust error handling.
set -euo pipefail

# Script to run a command and manage its log file rotation using a logrotate.conf template.

# --- Configuration ---
# LOGROTATE_VERBOSE: If set to "true", the script will output verbose messages.
LOGROTATE_VERBOSE="${LOGROTATE_VERBOSE:-false}"
# LOGROTATE_CHECK_INTERVAL: Interval in seconds to check for log rotation.
LOGROTATE_CHECK_INTERVAL="${LOGROTATE_CHECK_INTERVAL:-60}"
# ---------------------

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <log_file_path> <command> [command_args]"
    echo "Example: $0 /tmp/ping_google.log ping -c 300 google.com"
    exit 1
fi

LOG_FILE_PATH="$1"
shift
COMMAND_TO_RUN="$1"
shift
COMMAND_ARGS=("$@")

# Determine the directory of this script to find the template logrotate.conf
CMD_PID=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_CONFIG_FILE="${SCRIPT_DIR}/logrotate.conf"

# Check if logrotate is installed
if ! command -v logrotate &> /dev/null; then
    echo "ERROR: logrotate is not installed. Please install it before running this script."
    exit 1
fi

# Function to log a message only if verbose mode is enabled.
log_verbose() {
    if [ "$LOGROTATE_VERBOSE" == "true" ]; then
        echo "$@"
    fi
}

log_verbose "Rotation interval configured via LOGROTATE_CHECK_INTERVAL: ${LOGROTATE_CHECK_INTERVAL} seconds."

# Create secure temporary files for the dynamic config and status
DYNAMIC_CONFIG_FILE=$(mktemp /tmp/dyn_logrotate_XXXXXX.conf)
STATUS_FILE=$(mktemp /tmp/logrotate_status_XXXXXX)

if [ -z "$DYNAMIC_CONFIG_FILE" ] || [ -z "$STATUS_FILE" ]; then
    echo "ERROR: Failed to create temporary files."
    exit 1
fi

# Cleanup function for the temporary dynamic config file
cleanup() {
    log_verbose "Cleaning up temporary files..."
    if [ -n "$CMD_PID" ] && kill -0 "$CMD_PID" 2>/dev/null; then
        log_verbose "Terminating background command with PID: ${CMD_PID}"
        kill "$CMD_PID"
    fi
    rm -f "$DYNAMIC_CONFIG_FILE" "$STATUS_FILE"
}

# Set up trap to call cleanup function on script exit, interrupt, or termination
trap cleanup EXIT INT TERM

echo "--- Log Rotation Wrapper Script ---"
echo "Command to execute: ${COMMAND_TO_RUN} ${COMMAND_ARGS[*]}"
echo "Log file for output: ${LOG_FILE_PATH}"
echo "Logrotate template configuration: ${TEMPLATE_CONFIG_FILE}"
log_verbose "Dynamic logrotate configuration will be generated at: ${DYNAMIC_CONFIG_FILE}"
log_verbose "Logrotate status file: ${STATUS_FILE}"
log_verbose ""
log_verbose "IMPORTANT PRE-REQUISITES:"
log_verbose "1. Ensure the logrotate utility is installed on your system."
log_verbose "2. The logrotate template file ('${TEMPLATE_CONFIG_FILE}') will be used to generate a dynamic config."
log_verbose "   It should contain '__LOG_FILE_PATH_PLACEHOLDER__' where the log file path should be inserted."
log_verbose "3. The rotation interval is controlled by the LOGROTATE_CHECK_INTERVAL environment variable (default: 60 seconds)."
log_verbose "4. For applications that don't reopen logs on signal, ensure 'copytruncate' is used in '${TEMPLATE_CONFIG_FILE}' (Highly Recommended)."
log_verbose "   Example section in '${TEMPLATE_CONFIG_FILE}' (before path substitution):"
log_verbose "   __LOG_FILE_PATH_PLACEHOLDER__ {"
log_verbose "       size 1M # Or your desired rotation trigger"
log_verbose "       copytruncate"
log_verbose "       rotate 4"
log_verbose "       # ... other options"
log_verbose "   }"
log_verbose "-----------------------------------"
log_verbose ""

# Check if the template config file exists and is readable.
if [ ! -r "$TEMPLATE_CONFIG_FILE" ]; then
    echo "ERROR: Template configuration file '${TEMPLATE_CONFIG_FILE}' does not exist or is not readable."
    exit 1
fi

# Create the log file and its directory if they don't exist.
if ! mkdir -p "$(dirname "$LOG_FILE_PATH")"; then
    echo "ERROR: Failed to create directory for log file: $(dirname "$LOG_FILE_PATH")"
    exit 1
fi
if ! touch "$LOG_FILE_PATH"; then
    echo "ERROR: Failed to create log file: $LOG_FILE_PATH"
    exit 1
fi

# Escape the LOG_FILE_PATH for sed to handle special characters
ESCAPED_LOG_FILE_PATH=$(printf '%s\n' "$LOG_FILE_PATH" | sed -e 's/\\/\\\\/g' -e 's/[&|]/\\&/g')

# Function to run logrotate
run_logrotate() {
    echo "$(date): Performing log rotation for '${LOG_FILE_PATH}'..."
    if [ "$LOGROTATE_VERBOSE" != "true" ]; then
        if logrotate -v -s "${STATUS_FILE}" "${DYNAMIC_CONFIG_FILE}" > /dev/null 2>&1; then
            echo "$(date): logrotate command finished (verbose output suppressed)."
        else
            echo "$(date): ERROR - logrotate command failed (verbose output suppressed)."
        fi
    else
        if logrotate -v -s "${STATUS_FILE}" "${DYNAMIC_CONFIG_FILE}"; then
            echo "$(date): logrotate command finished (check its output above for details on rotation)."
        else
            echo "$(date): ERROR - logrotate command failed."
        fi
    fi
}

# Generate the dynamic logrotate config once at the beginning
if ! sed "s|__LOG_FILE_PATH_PLACEHOLDER__|${ESCAPED_LOG_FILE_PATH}|g" "${TEMPLATE_CONFIG_FILE}" > "${DYNAMIC_CONFIG_FILE}"; then
    echo "ERROR: Failed to generate dynamic logrotate configuration file at ${DYNAMIC_CONFIG_FILE}."
    exit 1
fi
log_verbose "Dynamic logrotate configuration generated at: ${DYNAMIC_CONFIG_FILE}"

echo "Starting command at $(date)..."
# Execute the command in the background, redirecting stdout and stderr.

"${COMMAND_TO_RUN}" "${COMMAND_ARGS[@]}" >> "${LOG_FILE_PATH}" 2>&1 &
CMD_PID=$!

echo "Command started with PID ${CMD_PID}. Output is being logged to ${LOG_FILE_PATH}."
echo "To view live logs, run in another terminal: tail -f \"${LOG_FILE_PATH}\""

# Monitor the command and run logrotate periodically.
while kill -0 "${CMD_PID}" >/dev/null 2>&1; do
    sleep "${LOGROTATE_CHECK_INTERVAL}"
    run_logrotate
done

# Wait for the command to actually finish and capture its exit code
wait "${CMD_PID}"
CMD_EXIT_CODE=$?
echo ""
echo "Command with PID ${CMD_PID} finished at $(date) with exit code ${CMD_EXIT_CODE}."

echo "Performing final log rotation for '${LOG_FILE_PATH}'..."
run_logrotate

echo "--- Log rotation process complete ---"
# Trap will handle cleanup
exit "${CMD_EXIT_CODE}"
