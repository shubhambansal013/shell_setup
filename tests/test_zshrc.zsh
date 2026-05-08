#!/bin/zsh

# Test script for zshrc

# Setup a mock environment
export HOME=$(mktemp -d)
cp zshrc $HOME/.zshrc
cp g3.zsh $HOME/g3.zsh

# Mock SHELL_SETUP_DIR to point to $HOME for testing
# In the real zshrc it's determined via $(dirname "$(readlink -f "${(%):-%x}")")
# which might not work exactly same when sourced from a script depending on how it's called.

echo "Testing zshrc sourcing..."

# Source zshrc and capture output/errors
# We use a subshell to avoid polluting current shell
zsh -c "source $HOME/.zshrc" 2>test_errors.log

if [[ -s test_errors.log ]]; then
  echo "FAILED: Errors found during sourcing:"
  cat test_errors.log
  exit 1
else
  echo "PASSED: zshrc sourced without errors."
fi

# Check if tm function uses tmux
zsh -c "source $HOME/.zshrc; which tm" > tm_output.log
if grep -q "tmux" tm_output.log; then
  echo "PASSED: 'tm' function uses 'tmux'."
else
  echo "FAILED: 'tm' function does not seem to use 'tmux'."
  cat tm_output.log
  exit 1
fi

# Check if d alias uses tmux
zsh -c "source $HOME/.zshrc; alias d" > alias_output.log
if grep -q "tmux detach" alias_output.log; then
  echo "PASSED: 'd' alias uses 'tmux detach'."
else
  echo "FAILED: 'd' alias does not seem to use 'tmux detach'."
  cat alias_output.log
  exit 1
fi

echo "All tests passed!"
rm test_errors.log tm_output.log alias_output.log
rm -rf $HOME
