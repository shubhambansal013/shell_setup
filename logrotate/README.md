# Log Rotation Wrapper Script

This directory contains a shell script (`logrotate.sh`) and a template logrotate configuration file (`logrotate.conf`) designed to help manage log files for long-running commands.

## Problem Solved

When running a command that produces a lot of output piped to a file, the log file can grow indefinitely, potentially filling up disk space or hitting file size limits, causing the command to stop prematurely.
This script automates the process of running your command while periodically using the `logrotate` utility to manage its log file based on criteria like size or time.

## Files

*   `logrotate.sh`: The main wrapper script. You run this script, providing your command and the desired log file path.
*   `logrotate.conf`: A **template** configuration file for `logrotate`. **You MUST edit this file** for each specific log file you want to manage.

## Prerequisites

1.  **`logrotate` utility**: Ensure `logrotate` is installed on your system. Most Linux distributions have it by default.
    *   You can usually check by running `logrotate --version`.
2.  **Permissions**: The script needs execute permissions (`chmod +x logrotate.sh`).

## How to Use

1.  **Configure `logrotate.conf` (Crucial!):**
    *   Open `logrotate.conf` in a text editor.
    *   **The most important step**: Find the line that specifies the log file path (e.g., `/path/to/your/logfile.log {`). Change this path to the **exact, absolute path** of the log file that `logrotate.sh` will be managing for your command.
    *   Adjust other parameters within the curly braces `{ ... }` according to your needs:
        *   `daily`, `weekly`, `monthly`: Rotate logs based on time.
        *   `size <size>`: Rotate when the log file reaches a specific size (e.g., `size 1M` for 1 Megabyte, `size 100k` for 100 Kilobytes, `size 1G` for 1 Gigabyte).
        *   `rotate <count>`: Number of old log files to keep.
        *   `compress`: Compress rotated logs (usually with gzip).
        *   `delaycompress`: Don't compress the most recent rotated log immediately.
        *   `copytruncate`: **Highly Recommended for most use cases with this script.** This option copies the log file and then truncates the original. This allows the running command to continue logging to the original file descriptor without interruption. Without it, your command might stop logging or you might lose logs if the command doesn't support reopening its log file after rotation.
        *   `missingok`: Don't issue an error if the log file is missing.
        *   `notifempty`: Don't rotate the log if it's empty.
        *   `create <mode> <owner> <group>`: Create a new log file with specified permissions and ownership after rotation.

    **Example `logrotate.conf` section for a log file `/tmp/my_app.log`:**
    ```
    /tmp/my_app.log {
        size 1M
        copytruncate
        rotate 5
        compress
        delaycompress
        missingok
        notifempty
        create 0640 myuser mygroup
    }
    ```
    *Note: The `logrotate.conf` provided is a template. For this script, it expects one primary configuration block where the log file path matches the second argument given to `logrotate.sh`.*

2.  **Make `logrotate.sh` Executable (if not already):**
    ```bash
    chmod +x logrotate.sh
    ```

3.  **Run `logrotate.sh`:**
    Execute the script with two arguments:
    *   Argument 1: The command you want to run (enclose in double quotes if it contains spaces or special characters).
    *   Argument 2: The absolute path to the log file where the command's output should be stored.

    ```bash
    ./logrotate.sh "your_long_running_command --with --options" /path/to/your/actual_logfile.log
    ```
    **Example:**
    ```bash
    ./logrotate.sh "ping -c 600 google.com" /tmp/google_ping.log
    ```
    *Remember, `/tmp/google_ping.log` in this example must be the path configured inside your `logrotate.conf`.*

4.  **Monitor Logs (Optional):**
    While the script is running, it will print the log file path and a `tail` command. You can monitor the live output of your command in a separate terminal:
    ```bash
    tail -f /path/to/your/actual_logfile.log
    ```
    (Replace `/path/to/your/actual_logfile.log` with the actual path you used when running `logrotate.sh`).

## How `logrotate.sh` Works

1.  It takes your command and the target log file path as arguments.
2.  It creates the log file and its directory if they don't exist.
3.  It runs your command in the background (`&`), redirecting both its standard output (stdout) and standard error (stderr) to the specified log file.
4.  While your command is running, the script periodically (default: every 60 seconds, configurable via `ROTATE_INTERVAL` in the script) calls the `logrotate` utility.
5.  `logrotate` uses the `logrotate.conf` file (expected to be in the same directory as `logrotate.sh`) and a status file (stored in `/tmp/`) to decide if logs need rotation based on the rules you defined.
6.  After your command finishes, the script runs `logrotate` one last time.
7.  The script provides informational output about its actions and the status of your command.

## Important Considerations

*   **`logrotate.conf` is Key:** The behavior of log rotation is entirely dependent on how you configure `logrotate.conf`. Ensure the log file path in this config **exactly matches** the path you provide to `logrotate.sh`.
*   **`copytruncate`:** For commands that don't support being signaled to reopen their log files (most simple commands and scripts), `copytruncate` is essential for seamless logging across rotations and for `tail -f` to work reliably.
*   **Status File:** `logrotate` uses a status file (e.g., `/tmp/logrotate_script_your_actual_logfile.status`) to keep track of when logs were last rotated. This script creates a unique status file based on the log file name.
*   **Error Handling:** The script includes basic error checks. `logrotate` itself can output errors if its configuration is problematic; these will be visible in the script's output.
*   **Resource Usage:** The periodic checking and `logrotate` execution consume some system resources. The default 60-second interval is usually fine, but you can adjust `ROTATE_INTERVAL` in `logrotate.sh` if needed.

This setup provides a flexible way to prevent runaway log files from disrupting your commands.

## Manual Test for Rapid Log Rotation

To observe the log rotation in action quickly, you can configure the script and `logrotate.conf` for rapid rotation. This is a manual test designed to help you verify the script's behavior under fast logging conditions.

**1. Configure `logrotate.conf` for Testing:**
   Make the following temporary changes to your `google3/experimental/users/bansalshubham/logrotate/logrotate.conf` file:

   *   **Log File Path**: Change the log file path at the top of the configuration to a temporary test path. For example:
       ```
       /tmp/test_logrotate.log {
       ```
   *   **Rotation Size**: Set a very small rotation size to trigger rotation quickly:
       ```
       size 1k # Test: rotate frequently
       ```
   *   **Number of Rotations**: Reduce the number of old logs kept to simplify observation:
       ```
       rotate 3 # Test: keep fewer backups
       ```
   *   **Disable Time-Based Rotation**: Ensure any time-based rotation (like `daily`, `weekly`, `monthly`) is commented out, so size is the primary trigger:
       ```
       # daily
       ```
   *   **Enable `copytruncate`**: It's highly recommended to have this active for the test, as the sample logging command won't reopen log files on its own:
       ```
       copytruncate
       ```
   *   **Disable Compression**: Ensure `compress` and `delaycompress` are commented out for simpler observation of rotated files.

   After these changes, the relevant part of your `logrotate.conf` for the test might look like this:
   ```
   /tmp/test_logrotate.log {
       # daily
       size 1k # Test: rotate frequently
       rotate 3 # Test: keep fewer backups
       create 0644 youruser yourgroup # Adjust user/group if needed for /tmp, or remove if problematic
       # compress
       # delaycompress
       copytruncate # Recommended for commands that don't reopen logs
       missingok
       notifempty
   }
   ```

**2. Configure `logrotate.sh` for Faster Checks:**
   Edit `google3/experimental/users/bansalshubham/logrotate/logrotate.sh` and temporarily change the `ROTATE_INTERVAL` variable for more frequent checks by `logrotate.sh`:
   ```bash
   ROTATE_INTERVAL=2 # Original default is 60. This will make the script check every 2 seconds.
   ```

**3. Prepare the Test Command:**
   You'll need a command that writes data frequently. This shell command writes 200 lines with a ~100ms delay between each line. Each line includes a timestamp and some padding text to help reach the `1k` rotation size quickly.
   ```bash
   TEST_CMD='for i in $(seq 1 200); do echo "$(date +%Y-%m-%dT%H:%M:%S.%N): Test log line $i - $(head -c 50 /dev/urandom | base64)"; sleep 0.1; done'
   ```
   You can define this `TEST_CMD` variable in your shell before running `logrotate.sh`.

**4. Run the Test:**
   First, ensure `logrotate.sh` is executable:
   ```bash
   chmod +x google3/experimental/users/bansalshubham/logrotate/logrotate.sh
   ```
   Then, execute the script from the directory containing it (e.g., `google3/experimental/users/bansalshubham/logrotate/`):
   ```bash
   ./logrotate.sh "$TEST_CMD" /tmp/test_logrotate.log
   ```
   *(Make sure the log path `/tmp/test_logrotate.log` used here matches exactly what you set in `logrotate.conf` for the test.)*

**5. Observe the Behavior:**
   The test command will run for approximately 20 seconds.
   *   **Terminal Output**: Watch the output from `logrotate.sh`. You will see messages indicating the command has started, where it's logging, and periodic checks for log rotation (every 2 seconds).
   *   **Log File Directory**: While the test is running, or immediately after it finishes, inspect the `/tmp/` directory. You can list the files:
       ```bash
       ls -lha /tmp/test_logrotate.log*
       ```
       You should observe:
       *   The active log file: `/tmp/test_logrotate.log`
       *   Rotated log files: `/tmp/test_logrotate.log.1`, `/tmp/test_logrotate.log.2`, `/tmp/test_logrotate.log.3`. (Since `rotate 3` is set, `logrotate` will keep up to 3 older files. Compression is off, so they won't have a `.gz` extension.)
       *   The rotated files should be small (around 1-2KB) due to the `size 1k` setting.
   *   **Log Content**: Examine the content of these files:
       ```bash
       cat /tmp/test_logrotate.log.1 # View the first rotated file
       tail -f /tmp/test_logrotate.log # In a separate terminal, view live logs during the test
       ```
       You should see the "Test log line..." entries distributed across these files, indicating that rotation occurred.

**6. Revert Changes After Testing:**
   **This is a crucial step.** After you are done with testing, remember to revert all the temporary changes you made:
   *   **In `logrotate.conf`**: 
       *   Change `size 1k` back to your desired operational size (e.g., `size 1M`).
       *   Change `rotate 3` back to your standard number of backups (e.g., `rotate 7`).
       *   Uncomment `daily` (or your preferred time-based rotation) if you use it.
       *   Change the log file path from `/tmp/test_logrotate.log` back to your template path (e.g., `/path/to/your/logfile.log`).
       *   Decide if `copytruncate` should remain or be commented out for your normal use cases.
       *   Re-enable `compress` and `delaycompress` if you normally use them.
   *   **In `logrotate.sh`**: 
       *   Change `ROTATE_INTERVAL=2` back to a more reasonable value like `ROTATE_INTERVAL=60`.

This manual testing procedure will help you confirm that the log rotation mechanism is working as expected with your script.