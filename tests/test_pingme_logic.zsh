#!/bin/zsh

# Source the plugin to get the function
source zsh-plugins/pingme/pingme.plugin.zsh

test_extract() {
    local input="$1"
    local expected="$2"
    local actual=$(_zsh_pingme_extract_base_command "$input")
    if [[ "$actual" == "$expected" ]]; then
        echo "PASSED: '$input' -> '$actual'"
    else
        echo "FAILED: '$input' -> expected '$expected', got '$actual'"
        return 1
    fi
}

echo "Testing _zsh_pingme_extract_base_command..."

test_extract "ls -l" "ls"
test_extract "sudo ls -l" "ls"
test_extract "sudo -u user ls -l" "ls"
test_extract "env FOO=bar ls" "ls"
test_extract "FOO=bar ls" "ls"
test_extract "sudo -u user -g group /usr/bin/python3 script.py" "python3"
test_extract "git clone repo" "git"
test_extract "./myprog --arg" "myprog"

if [[ $? -eq 0 ]]; then
    echo "All logic tests passed!"
else
    echo "Some logic tests failed!"
    exit 1
fi
