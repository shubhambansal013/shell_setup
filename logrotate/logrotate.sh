#!/bin/bash

# Script to run a command and manage its log file rotation using a logrotate.conf template.

# --- Configuration ---
# ROTATE_INTERVAL: How often to check for log rotation (in seconds) while the command is running.
ROTATE_INTERVAL=60
# ---------------------

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 \"<command_to_run>\" <log_file_path>"
    echo "Example: $0 \"ping -c 300 google.com\" /tmp/ping_google.log"
    exit 1
fi

COMMAND_TO_RUN="$1"
LOG_FILE_PATH="$2" # This will be substituted into the logrotate config

# Determine the directory of this script to find the template logrotate.conf
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_CONFIG_FILE="${SCRIPT_DIR}/logrotate.conf"

# Define a unique path for the dynamically generated logrotate config
# Using $$ for PID to ensure uniqueness if multiple instances run for different logs
DYNAMIC_CONFIG_FILE="/tmp/dyn_logrotate_$(basename "${LOG_FILE_PATH}" .log)_$$.conf"
STATUS_FILE="/tmp/logrotate_script_$(basename "${LOG_FILE_PATH}" .log)_$$.status" # Also make status file unique per run

# Cleanup function for the temporary dynamic config file
cleanup() {
    echo "Cleaning up temporary files..."
    rm -f "$DYNAMIC_CONFIG_FILE"
    # Consider if status file should also be cleaned or if logrotate needs it for continuity across script reruns.
    # For now, let's leave status file for logrotate's own state management across its own invocations.
    # If truly ephemeral runs are desired, add: rm -f "$STATUS_FILE"
}

# Set up trap to call cleanup function on script exit, interrupt, or termination
trap cleanup EXIT INT TERM

echo "--- Log Rotation Wrapper Script ---"
echo "Command to execute: ${COMMAND_TO_RUN}"
echo "Log file for output: ${LOG_FILE_PATH}"
echo "Logrotate template configuration: ${TEMPLATE_CONFIG_FILE}"
echo "Dynamic logrotate configuration will be generated at: ${DYNAMIC_CONFIG_FILE}"
echo "Logrotate status file: ${STATUS_FILE}"
echo "Rotation check interval: ${ROTATE_INTERVAL} seconds"
echo ""
echo "IMPORTANT PRE-REQUISITES:"
echo "1. Ensure the logrotate utility is installed on your system."
echo "2. The logrotate template file ('${TEMPLATE_CONFIG_FILE}') will be used to generate a dynamic config."
echo "   It should contain '__LOG_FILE_PATH_PLACEHOLDER__' where the log file path should be inserted."
echo "3. For applications that don't reopen logs on signal, ensure 'copytruncate' is used in '${TEMPLATE_CONFIG_FILE}' (Highly Recommended)."
echo "   Example section in '${TEMPLATE_CONFIG_FILE}' (before path substitution):"
echo "   __LOG_FILE_PATH_PLACEHOLDER__ {"
echo "       size 1M # Or your desired rotation trigger"
echo "       copytruncate"
echo "       rotate 4"
echo "       # ... other options"
echo "   }"
echo "-----------------------------------"
echo ""

# Create the log file and its directory if they don't exist.
if ! mkdir -p "$(dirname "$LOG_FILE_PATH")"; then
    echo "ERROR: Failed to create directory for log file: $(dirname "$LOG_FILE_PATH")"
    exit 1
fi
if ! touch "$LOG_FILE_PATH"; then
    echo "ERROR: Failed to create log file: $LOG_FILE_PATH"
    exit 1
fi

# Function to generate dynamic logrotate config
generate_dynamic_config() {
    # Replace the placeholder with the actual log file path. Using | as sed delimiter to avoid issues with / in paths.
    if ! sed "s|__LOG_FILE_PATH_PLACEHOLDER__|${LOG_FILE_PATH}|g" "${TEMPLATE_CONFIG_FILE}" > "${DYNAMIC_CONFIG_FILE}"; then
        echo "ERROR: Failed to generate dynamic logrotate configuration file at ${DYNAMIC_CONFIG_FILE}."
        exit 1
    fi
    echo "Dynamic logrotate configuration generated at ${DYNAMIC_CONFIG_FILE}"
}

echo "Starting command at $(date)..."
# Execute the command in the background, redirecting stdout and stderr.
eval "${COMMAND_TO_RUN}" >> "${LOG_FILE_PATH}" 2>&1 &
CMD_PID=$!

echo "Command started with PID ${CMD_PID}. Output is being logged to ${LOG_FILE_PATH}."
echo "To view live logs, run in another terminal: tail -f \"${LOG_FILE_PATH}\""

# Monitor the command and run logrotate periodically.
while kill -0 "${CMD_PID}" >/dev/null 2>&1; do
    sleep "${ROTATE_INTERVAL}"
    echo "$(date): Performing scheduled log rotation check for '${LOG_FILE_PATH}'..."
    generate_dynamic_config
    if [ -f "$DYNAMIC_CONFIG_FILE" ]; then
        logrotate -s "${STATUS_FILE}" "${DYNAMIC_CONFIG_FILE}"
        echo "$(date): logrotate command finished (check its output above for details on rotation)."
    else
        echo "$(date): ERROR - Dynamic logrotate config not found, skipping rotation."
    fi
done

# Wait for the command to actually finish and capture its exit code
wait "${CMD_PID}"
CMD_EXIT_CODE=$?
echo ""
echo "Command with PID ${CMD_PID} finished at $(date) with exit code ${CMD_EXIT_CODE}."

echo "Performing final log rotation for '${LOG_FILE_PATH}'..."
generate_dynamic_config
if [ -f "$DYNAMIC_CONFIG_FILE" ]; then
    logrotate -s "${STATUS_FILE}" "${DYNAMIC_CONFIG_FILE}"
    echo "Final logrotate command finished."
else
    echo "ERROR - Dynamic logrotate config not found for final rotation."
fi

echo "--- Log rotation process complete ---"
# Trap will handle cleanup
exit "${CMD_EXIT_CODE}"
