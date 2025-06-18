# Log Rotation Wrapper Script

This directory contains a shell script (`logrotate.sh`) that automatically runs a command and manages its log file rotation.

## Features

*   **Automatic Log Rotation**: Prevents log files from growing indefinitely.
*   **Unique Log Files**: Creates a unique, timestamped log file for each run to avoid conflicts.
*   **Easy to Use**: Simply provide a base log path and the command to execute.

## Prerequisites

*   **`logrotate`**: Ensure `logrotate` is installed on your system.
*   **Permissions**: The script requires execute permissions (`chmod +x logrotate.sh`).

## Usage

```bash
./logrotate.sh <base_log_path> <command> [args]
```

*   `<base_log_path>`: The base path for the log file. The script will append a timestamp to this path to create a unique log file for each run.
*   `<command>`: The command to execute.
*   `[args]`: Optional arguments for the command.

## How It Works

The script creates a unique log file by appending a timestamp to the `<base_log_path>`. For example, if you provide `/tmp/my_app.log`, the actual log file might be `/tmp/my_app_20231027_120000.log`.

It then runs the specified command in the background, redirecting its output to the unique log file. A `logrotate` process is run periodically to rotate the logs based on the settings in `logrotate.conf`.

## Configuration

*   **`logrotate.conf`**: A template file for log rotation settings (e.g., size, number of rotations). The script automatically replaces the log file path placeholder.
*   **`LOGROTATE_CHECK_INTERVAL`**: The interval (in seconds) for checking and rotating logs. The default is 60 seconds.
*   **`LOGROTATE_VERBOSE`**: Set to `true` to enable verbose output from the script and `logrotate`.

## Example

```bash
./logrotate.sh /tmp/my_app.log "my_long_running_command --option1 --option2"
```

This command will:
1.  Create a unique log file, such as `/tmp/my_app_20231027_120000.log`.
2.  Run `my_long_running_command --option1 --option2`.
3.  Redirect all output to the unique log file.
4.  Periodically rotate the log file according to the rules in `logrotate.conf`.
