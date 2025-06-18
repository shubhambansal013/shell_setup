#!/bin/bash

# This script sets up the shell environment.
# It assumes it is run from the google3/experimental/users/bansalshubham/shell_setup/ directory.

# Define the custom plugins directory for Oh My Zsh
ZSH_CUSTOM_PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

# Helper function to print messages
print_message() {
  echo "--------------------------------------------------"
  echo "$1"
  echo "--------------------------------------------------"
}

# 1. Install Oh My Zsh
# --------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  print_message "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  print_message "Oh My Zsh is already installed."
fi

# 2. Install Powerlevel10k theme
# ------------------------------
POWERLEVEL10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$POWERLEVEL10K_DIR" ]; then
  print_message "Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$POWERLEVEL10K_DIR"
else
  print_message "Powerlevel10k theme is already installed."
fi

# 3. Install fzf (fuzzy finder)
# -----------------------------
if ! command -v fzf &> /dev/null; then
  print_message "Installing fzf..."
  if [ ! -d "$HOME/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all # Installs fzf and key bindings/completions
  else
    print_message "fzf directory already exists. Running install script..."
    ~/.fzf/install --all
  fi
else
  print_message "fzf is already installed."
fi

# 4. Install zsh-autosuggestions plugin
# -------------------------------------
ZSH_AUTOSUGGESTIONS_DIR="$ZSH_CUSTOM_PLUGINS_DIR/zsh-autosuggestions"
if [ ! -d "$ZSH_AUTOSUGGESTIONS_DIR" ]; then
  print_message "Installing zsh-autosuggestions plugin..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_DIR"
else
  print_message "zsh-autosuggestions plugin is already installed."
fi

# 5. Install zsh-syntax-highlighting plugin
# -----------------------------------------
ZSH_SYNTAX_HIGHLIGHTING_DIR="$ZSH_CUSTOM_PLUGINS_DIR/zsh-syntax-highlighting"
if [ ! -d "$ZSH_SYNTAX_HIGHLIGHTING_DIR" ]; then
  print_message "Installing zsh-syntax-highlighting plugin..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_SYNTAX_HIGHLIGHTING_DIR"
else
  print_message "zsh-syntax-highlighting plugin is already installed."
fi

# 6. Symlink configuration files
# ------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Symlink .zshrc
ZSHRC_SOURCE="$SCRIPT_DIR/zshrc"
ZSHRC_TARGET="$HOME/.zshrc"
if [ -f "$ZSHRC_SOURCE" ]; then
  print_message "Symlinking .zshrc..."
  if [ -L "$ZSHRC_TARGET" ] && [ "$(readlink "$ZSHRC_TARGET")" = "$ZSHRC_SOURCE" ]; then
    echo ".zshrc is already correctly symlinked."
  else
    rm -f "$ZSHRC_TARGET" # Remove existing file/symlink
    ln -s "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
    echo ".zshrc symlinked to $ZSHRC_TARGET"
  fi
else
  echo "ERROR: $ZSHRC_SOURCE not found."
fi

# Symlink .tmux.conf
TMUX_CONF_SOURCE="$SCRIPT_DIR/tmux.conf"
TMUX_CONF_TARGET="$HOME/.tmux.conf"
if [ -f "$TMUX_CONF_SOURCE" ]; then
  print_message "Symlinking .tmux.conf..."
  if [ -L "$TMUX_CONF_TARGET" ] && [ "$(readlink "$TMUX_CONF_TARGET")" = "$TMUX_CONF_SOURCE" ]; then
    echo ".tmux.conf is already correctly symlinked."
  else
    rm -f "$TMUX_CONF_TARGET" # Remove existing file/symlink
    ln -s "$TMUX_CONF_SOURCE" "$TMUX_CONF_TARGET"
    echo ".tmux.conf symlinked to $TMUX_CONF_TARGET"
  fi
else
  echo "ERROR: $TMUX_CONF_SOURCE not found. Skipping."
fi

# 7. Pingme plugin
# ----------------
# The 'pingme' plugin seems to be custom.
# Ensure it is correctly placed in $ZSH_CUSTOM_PLUGINS_DIR/pingme
# or one of the standard Oh My Zsh plugin directories.
# If it's a script, ensure it's executable and in your $PATH or sourced correctly.
print_message "Regarding 'pingme' plugin:"
echo "Ensure the 'pingme' plugin is correctly installed/configured."
echo "If it's a custom plugin, place it in: $ZSH_CUSTOM_PLUGINS_DIR/pingme"

# 8. Source .zshrc
# ----------------
print_message "Setup complete!"
echo "Please source your .zshrc file to apply changes, or open a new terminal:"
echo "source ~/.zshrc"

echo "Shell setup script finished."

