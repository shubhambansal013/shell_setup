# Shell Setup

This repository contains the configuration files and an automated setup script for a feature-rich Zsh shell environment.

## Quick Start

To set up your shell environment, simply run the setup script:

```bash
./setup.sh
```

The script will handle the installation of all necessary tools and the symlinking of configuration files.

## What's Included?

The `setup.sh` script automates the installation and configuration of the following components:

-   **[Oh My Zsh](https://ohmyz.sh/)**: An open-source, community-driven framework for managing your Zsh configuration.
-   **[Powerlevel10k](https://github.com/romkatv/powerlevel10k)**: A fast and flexible theme for Zsh.
-   **[fzf](https://github.com/junegunn/fzf)**: A command-line fuzzy finder for quick file and command history search.
-   **Zsh Plugins**:
    -   **[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)**: Suggests commands as you type based on history and completions.
    -   **[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)**: Provides syntax highlighting for the command line.
    -   **Custom `pingme` plugin**: A local plugin for notifications.

## Configuration Files

The setup script will automatically symlink the following configuration files to your home directory:

-   `.zshrc`: The main configuration file for the Zsh shell. It loads Oh My Zsh, the Powerlevel10k theme, all plugins, and custom aliases.
-   `.tmux.conf`: The configuration file for `tmux`.

The script also manages custom Zsh plugins located in the `zsh-plugins/` directory.
