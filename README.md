# Shell Setup

This directory contains configuration files for the shell environment.

## Zsh (.zshrc)

The `.zshrc` file configures the Zsh shell. It includes:
- Oh My Zsh setup
- Theme configuration (powerlevel10k)
- Plugin management (e.g., `fzf`, `zsh-autosuggestions`, `zsh-syntax-highlighting`)
- Aliases and custom functions

### fzf Integration

`fzf` (fuzzy finder) is integrated as an Oh My Zsh plugin. 

To ensure `fzf` works correctly:
1.  **Install `fzf`**: Follow the official `fzf` installation instructions. You can typically install it by cloning the repository and running its install script:
    ```bash
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
    ```
2.  **Enable the plugin**: Add `fzf` to the `plugins` array in your `.zshrc` file:
    ```zsh
    plugins=(
        fzf
        # other plugins...
        zsh-autosuggestions
        zsh-syntax-highlighting
        pingme
    )
    ```

## Setup Script (setup.sh)

The `setup.sh` script provides commands and instructions for setting up the shell environment, including `fzf` installation.

## Other configurations
- `tmux.conf`: Configuration for tmux.
- `zsh-plugins/`: Directory for custom zsh plugins (if any).
