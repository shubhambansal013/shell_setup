# PingMe Zsh Plugin

**PingMe** is a Zsh plugin that provides notifications for long-running commands. When a command's execution time exceeds a configurable duration, PingMe can ring the terminal bell and send a Telegram message.

This is particularly useful for developers, system administrators, and anyone who runs time-consuming tasks in the terminal and wants to be notified upon completion without constantly monitoring the window.

## Features

-   **Execution Time Threshold**: Triggers notifications only for commands that exceed a specified duration.
-   **Terminal Bell**: Rings the terminal bell for native, immediate feedback.
-   **Telegram Integration**: Sends a push notification to your phone or desktop via Telegram.
-   **Command Exclusion**: Allows you to specify commands (e.g., editors, pagers) that should not trigger notifications.
-   **Verbose Mode**: Provides detailed logging for easy debugging and troubleshooting.

## Installation

The plugin is designed to be used with a Zsh plugin manager or sourced directly. The recommended installation is through the `setup.sh` script in the parent directory, which handles the symlinking automatically.

### Automated Installation (Recommended)

If you are using the broader shell setup from the parent directory, the `setup.sh` script will automatically symlink this plugin to the correct Oh My Zsh custom plugins directory. No manual steps are needed.

### Manual Installation

If you wish to install this plugin manually:

1.  **Clone or Download the Plugin**:
    Place the `pingme` directory (containing `pingme.plugin.zsh`) into your Zsh plugins directory. For Oh My Zsh, this is typically `~/.oh-my-zsh/custom/plugins/`.

2.  **Activate the Plugin**:
    Add `pingme` to the `plugins` array in your `.zshrc` file:
    ```zsh
    plugins=(
        # other plugins...
        pingme
    )
    ```

3.  **Restart Your Shell**:
    Open a new terminal or source your `.zshrc` to apply the changes:
    ```zsh
    source ~/.zshrc
    ```

## Configuration

All configuration is done via environment variables. For best results, define these in your `.zshrc` **before** the line that sources your plugins.

### General Configuration

-   `ZSH_PINGME_DURATION`: The minimum execution time (in seconds) for a command to trigger a notification.
    -   **Default**: `20`
    -   **Example**: `export ZSH_PINGME_DURATION=30`

-   `ZSH_PINGME_EXCLUDED_COMMANDS`: An array of command names to ignore. The check is performed on the base command (e.g., `vim` in `sudo vim`).
    -   **Default**: `(vi vim nano emacs tmux less more man)`
    -   **Example**: `export ZSH_PINGME_EXCLUDED_COMMANDS=("vi" "nano" "git commit")`

### Telegram Notifications

To receive notifications via Telegram, you must provide your bot token and chat ID.

**Security Note**: To avoid committing secrets to version control, it is strongly recommended to export these variables from a file that is not tracked by Git, such as `~/.zshenv`.

-   `TELEGRAM_BOT_TOKEN`: Your Telegram bot's API token.
-   `TELEGRAM_CHAT_ID`: The chat ID where the bot should send messages.

**Example (in `~/.zshenv`)**:
```zsh
export TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
export TELEGRAM_CHAT_ID="YOUR_TELEGRAM_CHAT_ID"
```

### Debugging

-   `ZSH_PINGME_VERBOSE`: Set to `1` to enable detailed logging. This is useful for troubleshooting.
    -   **Default**: Disabled
    -   **Example**: `export ZSH_PINGME_VERBOSE=1`

## How It Works

The plugin leverages Zsh's built-in `preexec` and `precmd` hooks:

1.  **`preexec` Hook**: Before a command is executed, this hook records the start time (`EPOCHSECONDS`) and the command string.
2.  **`precmd` Hook**: After the command finishes (but before the next prompt is drawn), this hook calculates the total execution time.
3.  **Evaluation**: It checks if the duration exceeds `ZSH_PINGME_DURATION` and if the command is not in the `ZSH_PINGME_EXCLUDED_COMMANDS` list.
4.  **Notification**: If the conditions are met, it rings the terminal bell and, if configured, sends a formatted message to your Telegram chat.

This ensures that the monitoring has minimal overhead and integrates seamlessly into the shell's lifecycle.
