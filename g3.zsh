# Google-specific shell configuration

# Fixes completion lag in google3.
zstyle ':completion:*' users root $USER

# Source g4 and hg completions if they exist.
if [[ -f /etc/bash_completion.d/g4d ]]; then
  . /etc/bash_completion.d/p4
  . /etc/bash_completion.d/g4d
fi

if [[ -f /etc/bash_completion.d/hgd ]]; then
  source /etc/bash_completion.d/hgd
fi

export SEEKH_STAGING="https://staging-seekh-pa.sandbox.googleapis.com"
export SEEKH_PROD="https://seekh-pa.clients6.google.com"

# Exclude google3 commands from pingme notifications.
ZSH_PINGME_EXCLUDED_COMMANDS+=(
    "span"
    "boq"
    "dart-dev-runner"
)

# Logs dir
mkdir -p "/usr/local/google/home/$USER/mylogs"
export MYLOGS="/usr/local/google/home/$USER/mylogs"
