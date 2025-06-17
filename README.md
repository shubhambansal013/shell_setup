# Shell Configuration Setup

This script sets up the shell environment by copying configuration files and installing necessary Zsh plugins.

## Prerequisites

- Git must be installed.
- Zsh must be installed and set as the default shell.
- The script will attempt to install Oh My Zsh if it's not found.

## Setup

## Setup

1.  **Clone the repository or download the files.**
2.  **Navigate to the `shell_config` directory.**
3.  **Make the `setup.sh` script executable:**
    ```bash
    chmod +x setup.sh
    ```
4.  **Run the setup script:**
    ```bash
    ./setup.sh
    ```
5.  **Restart your shell or source your `.zshrc` file:**
    ```bash
    source ~/.zshrc
    ```

## Included Configurations

-   **tmux:** Configuration file `tmux.conf` is copied to `~/.tmux.conf`.
-   **zsh:** Configuration file `zshrc` is copied to `~/.zshrc`.
-   **zsh plugins:** Plugins in the `plugins` directory are copied to `~/.oh-my-zsh/custom/plugins/`.

## Installed Zsh Plugins and Theme

-   **zsh-autosuggestions:** Cloned from [https://github.com/zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions).
-   **zsh-syntax-highlighting:** Cloned from [https://github.com/zsh-users/zsh-syntax-highlighting.git](https://github.com/zsh-users/zsh-syntax-highlighting.git).
-   **Powerlevel10k Theme:** Cloned from [https://github.com/romkatv/powerlevel10k.git](https://github.com/romkatv/powerlevel10k.git). To enable this theme, ensure your `.zshrc` file contains `ZSH_THEME="powerlevel10k/powerlevel10k"`.
