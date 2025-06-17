#!/bin/bash

# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Oh My Zsh not found. Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  # The installer might change the shell, so we need to ensure subsequent commands run in a zsh context if possible,
  # or at least inform the user that a new shell is required.
  # For simplicity, we'll assume the user will restart the shell as per the final script message.
else
  echo "Oh My Zsh is already installed."
fi

# Create necessary directories
mkdir -p ~/.oh-my-zsh/custom/plugins

# Copy configuration files
cp tmux.conf ~/.tmux.conf
cp zshrc ~/.zshrc
cp -r plugins/* ~/.oh-my-zsh/custom/plugins/

# Install Powerlevel10k theme if not already installed
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
  echo "Powerlevel10k theme not found. Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
  echo "Powerlevel10k theme already installed."
fi

# Install zsh plugins
ZSH_CUSTOM="~/.oh-my-zsh/custom"

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
else
  echo "zsh-autosuggestions already installed."
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
else
  echo "zsh-syntax-highlighting already installed."
fi

echo "Setup complete. Please restart your shell or source your .zshrc file."
