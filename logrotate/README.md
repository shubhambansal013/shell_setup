# Log Rotation Wrapper Script

This directory contains a shell script (`logrotate.sh`) and a template
`logrotate.conf` file to manage log files for long-running commands.

## Log Rotation Wrapper Script

This script automates running a command and managing its log file using
`logrotate`. It prevents log files from growing indefinitely, avoiding disk space
issues and file size limits.

## Prerequisites

*   **`logrotate`**: Ensure `logrotate` is installed (`logrotate --version`).
*   **Permissions**: The script needs execute permissions (`chmod +x
    logrotate.sh`).

## Usage

```bash
./logrotate.sh <log_file_path> <command> [args]
```

*   `<log_file_path>`: The absolute path to the log file.
*   `<command>`: The command to run (enclose in quotes if it has spaces).
*   `[args]`: Optional arguments for the command.

The script generates the `logrotate` configuration dynamically based on the
provided log file path.

## Configuration

*   **`logrotate.conf`**: This file is a template for rotation settings (e.g.,
    size, number of rotations). The log file path placeholder is handled
    automatically by the script.
*   **`LOGROTATE_CHECK_INTERVAL`**: Set the interval (in seconds) for checking
    and rotating logs. Default is 60 seconds.
    ```bash
    export LOGROTATE_CHECK_INTERVAL=30
    ```
*   **`LOGROTATE_VERBOSE`**: Set to `true` to enable verbose output. Default is
    `false`.
    ```bash
    export LOGROTATE_VERBOSE=true
    ```

## Example

```bash
./logrotate.sh /tmp/my_app.log "my_long_running_command --option1 --option2"
```
This will run `my_long_running_command --option1 --option2`, redirecting its
output to `/tmp/my_app.log`, and periodically rotate the log file based on the
settings in `logrotate.conf`.
