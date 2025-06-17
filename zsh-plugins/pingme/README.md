# PingMe Zsh Plugin

Zsh plugin to enhance your terminal experience by providing auditory and Telegram notifications for command completion.

## Features

*   **Terminal Bell:** Rings the terminal bell after every command finishes.
*   **Telegram Notifications for Long Commands:** Sends a Telegram message when a command's execution time meets or exceeds a configurable duration.

## Installation

1.  Place the `pingme` directory (containing `pingme.plugin.zsh`) into your Oh My Zsh custom plugins directory (e.g., `$ZSH_CUSTOM/plugins/pingme`).
    If you are storing it at a different custom path, ensure `ZSH_CUSTOM` is set appropriately in your `.zshrc` before Oh My Zsh is sourced. For example, if your plugin is at `$HOME/experimental/users/your_user/plugins/pingme/pingme.plugin.zsh`, set:
    ```zsh
    export ZSH_CUSTOM=$HOME/experimental/users/your_user
    ```
2.  Add `pingme` to the `plugins=(...)` list in your `.zshrc` file.

    ```zsh
    plugins=(
        # other plugins
        pingme
    )
    ```

## Configuration

### Notification Duration (Required for Telegram)

*   `ZSH_PINGME_DURATION`: Minimum duration (in seconds) for a command to be considered "long-running" to trigger a Telegram notification. Defaults to `1` second.
    Set this **before** sourcing Oh My Zsh / loading the plugin in your `.zshrc`:
    ```zsh
    export ZSH_PINGME_DURATION=30 # Notify for commands running 30s or longer
    ```

### Telegram Setup (Required for Telegram)

To receive Telegram notifications, you **must** set the following environment variables in your `.zshrc` (or similar shell configuration file):

*   `TELEGRAM_BOT_TOKEN`: Your Telegram Bot Token.
*   `TELEGRAM_CHAT_ID`: The Chat ID where the bot should send messages.

    ```zsh
    export TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
    export TELEGRAM_CHAT_ID="YOUR_TELEGRAM_CHAT_ID"
    ```

## Usage

*   **Automatic:** The plugin works automatically after installation and configuration. A bell will sound after each command. If a command runs longer than `ZSH_PINGME_DURATION`, a Telegram message will be sent.

## How it Works

The plugin uses Zsh's `preexec` and `precmd` hooks:

*   `preexec`: Records the start time and the command string just before a command is executed.
*   `precmd`: Executed after a command finishes. It calculates the duration. 
    *   It always rings the terminal bell.
    *   If the duration is greater than or equal to `ZSH_PINGME_DURATION`, it sends a Telegram notification.
