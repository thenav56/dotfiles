#!/bin/bash

export SSH_AUTH_SOCK=
eval `ssh-agent`

find "$HOME/.ssh/keys/private/" -type f -not -path "**/unused/**" | while read -r file; do
    ssh-add $file
done
