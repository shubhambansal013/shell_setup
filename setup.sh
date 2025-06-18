#!/bin/bash

# This script sets up the shell environment.

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
    ~/.fzf/install --all --no-zsh # Installs fzf and key bindings/completions
  else
    print_message "fzf directory already exists. Running install script..."
    ~/.fzf/install --all --no-zsh
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

# 7. Install custom Pingme plugin
# -------------------------------
PINGME_PLUGIN_SOURCE_DIR="$SCRIPT_DIR/zsh-plugins/pingme"
PINGME_PLUGIN_TARGET_DIR="$ZSH_CUSTOM_PLUGINS_DIR/pingme"

print_message "Installing custom Pingme plugin..."
mkdir -p "$PINGME_PLUGIN_TARGET_DIR"

# Symlink the main plugin file
PINGME_PLUGIN_SOURCE_FILE="$PINGME_PLUGIN_SOURCE_DIR/pingme.plugin.zsh"
PINGME_PLUGIN_TARGET_FILE="$PINGME_PLUGIN_TARGET_DIR/pingme.plugin.zsh"
if [ -f "$PINGME_PLUGIN_SOURCE_FILE" ]; then
  if [ -L "$PINGME_PLUGIN_TARGET_FILE" ] && [ "$(readlink "$PINGME_PLUGIN_TARGET_FILE")" = "$PINGME_PLUGIN_SOURCE_FILE" ]; then
    echo "Pingme plugin is already correctly symlinked."
  else
    rm -f "$PINGME_PLUGIN_TARGET_FILE"
    ln -s "$PINGME_PLUGIN_SOURCE_FILE" "$PINGME_PLUGIN_TARGET_FILE"
    echo "Pingme plugin symlinked to $PINGME_PLUGIN_TARGET_FILE"
  fi
else
  echo "ERROR: Pingme plugin source not found at $PINGME_PLUGIN_SOURCE_FILE. Skipping."
fi

# Symlink the interactive configuration script
PINGME_CONFIGURE_SOURCE_FILE="$PINGME_PLUGIN_SOURCE_DIR/pingme_configure.zsh"
PINGME_CONFIGURE_TARGET_FILE="$PINGME_PLUGIN_TARGET_DIR/pingme_configure.zsh"
if [ -f "$PINGME_CONFIGURE_SOURCE_FILE" ]; then
  if [ -L "$PINGME_CONFIGURE_TARGET_FILE" ] && [ "$(readlink "$PINGME_CONFIGURE_TARGET_FILE")" = "$PINGME_CONFIGURE_SOURCE_FILE" ]; then
    echo "Pingme configure script is already correctly symlinked."
  else
    rm -f "$PINGME_CONFIGURE_TARGET_FILE"
    ln -s "$PINGME_CONFIGURE_SOURCE_FILE" "$PINGME_CONFIGURE_TARGET_FILE"
    echo "Pingme configure script symlinked to $PINGME_CONFIGURE_TARGET_FILE"
  fi
else
  # This is not a fatal error, just a missing feature.
  echo "WARN: Pingme configure script not found at $PINGME_CONFIGURE_SOURCE_FILE. Skipping."
fi

# 8. Source .zshrc
# ----------------
print_message "Setup complete!"
echo "Please source your .zshrc file to apply changes, or open a new terminal:"
echo "source ~/.zshrc"
echo "Shell setup script finished."

