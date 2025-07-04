#!/bin/zsh

# Interactive configuration script for the PingMe Zsh plugin.
#
# To run the configuration, simply source this file from your shell:
#   source /path/to/this/script/pingme_configure.zsh
#
# This script will guide you through setting up Telegram notifications
# and will create a ~/.pingme.env file with your credentials.

_pingme_do_configure() {
  print "Welcome to PingMe's interactive configuration."
  print "This will guide you through setting up Telegram notifications."
  print "Your credentials will be stored in a dedicated file at ~/.pingme.env"
  print -- "--------------------------------------------------------"

  local token
  local chat_id

  # Prompt for Bot Token
  print "First, I need your Telegram Bot Token."
  print "You can get one from BotFather on Telegram."
  print -n "Please enter your Telegram Bot Token and press [Enter]: "
  read -r token
  if [[ -z "$token" ]]; then
    print "\nError: Bot Token cannot be empty. Aborting."
    return 1
  fi

  # Prompt for Chat ID
  print "\nNext, I need your Telegram Chat ID."
  print "This is your personal chat ID with the bot."
  print "You can get it by messaging your bot and visiting:"
  print "https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates"
  print -n "Please enter your Telegram Chat ID and press [Enter]: "
  read -r chat_id
  if [[ -z "$chat_id" ]]; then
    print "\nError: Chat ID cannot be empty. Aborting."
    return 1
  fi
  
  print -- "--------------------------------------------------------"

  local pingme_env_file="${ZDOTDIR:-$HOME}/.pingme.env"

  # Create or overwrite the .pingme.env file with the new credentials.
  {
    print "# PingMe Environment Variables - Managed by pingme_configure"
    print "# Do not edit this file manually."
    print "export TELEGRAM_BOT_TOKEN=\"$token\""
    print "export TELEGRAM_CHAT_ID=\"$chat_id\""
  } > "$pingme_env_file"

  print "\nConfiguration has been saved to your ~/.pingme.env file."
  print "The PingMe plugin will automatically load this file when your shell starts."
  print "\nFor the changes to take effect in all new shells, you may need to restart your terminal."
  print "To apply changes to your current shell, please run:"
  print "  source ~/.pingme.env"

  # Export for current session for immediate use.
  export TELEGRAM_BOT_TOKEN="$token"
  export TELEGRAM_CHAT_ID="$chat_id"
  print "\nI've also exported the variables for your current shell session."
  print "You can test your setup now with a long-running command, like 'sleep 21'."
  print "Configuration complete. Enjoy using PingMe!"
}

# Run the configuration and then clean up the function to keep the shell environment clean.
_pingme_do_configure
unset -f _pingme_do_configure
