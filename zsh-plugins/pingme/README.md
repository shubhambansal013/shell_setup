# PingMe Zsh Plugin

Zsh plugin to ring a terminal bell and send a Telegram notification for long-running commands.

## Installation

1.  Clone this repository or download the `pingme.plugin.zsh` file.
2.  Source the `pingme.plugin.zsh` file in your `.zshrc` file:

    ```zsh
    source /path/to/pingme.plugin.zsh
    ```

## Configuration

You can configure the plugin by setting the following environment variables in your `.zshrc` **before** sourcing the plugin:

*   `ZSH_PINGME_DURATION`: The minimum duration (in seconds) for a command to be considered long-running.
    Default: `10`
    Example:
    ```zsh
    export ZSH_PINGME_DURATION=30
    ```

*   `ZSH_PINGME_VERBOSE`: Set to `1` to enable verbose logging for debugging.
    Default: Disabled
    Example:
    ```zsh
    export ZSH_PINGME_VERBOSE=1
    ```

*   `ZSH_PINGME_EXCLUDED_COMMANDS`: An array of commands that should not trigger notifications. The comparison is done against the base command (e.g., `vim` for `sudo vim`).
    Default: `(vi vim nano emacs tmux less more man)`
    Example:
    ```zsh
    export ZSH_PINGME_EXCLUDED_COMMANDS=("vi" "nano" "my_custom_tool")
    ```

### Telegram Notifications

To enable Telegram notifications, you also need to set the following environment variables:

*   `TELEGRAM_BOT_TOKEN`: Your Telegram Bot Token.
*   `TELEGRAM_CHAT_ID`: Your Telegram Chat ID.

Example:
```zsh
export TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
export TELEGRAM_CHAT_ID="YOUR_TELEGRAM_CHAT_ID"
```

## How it Works

The plugin uses Zsh's `preexec` and `precmd` hook functions:

*   `preexec`: Executed before a command line is executed. It records the start time and the command string.
*   `precmd`: Executed before each prompt is displayed (after a command has finished). It calculates the command's duration. If the duration exceeds `ZSH_PINGME_DURATION` and the command is not in `ZSH_PINGME_EXCLUDED_COMMANDS`:
    *   A Telegram notification is sent (if configured).
    *   The terminal bell is rung.

## Troubleshooting

If you encounter issues, enable verbose mode (`export ZSH_PINGME_VERBOSE=1`) and check the output in your terminal. This can help identify problems with configuration or script execution.
