#!/bin/bash -x

pacman -S ansible python-passlib
ansible-galaxy collection install -r requirements.yml

# Run this as root user
# ansible-playbook -i localhost init.yml
# As user with sudo access
# ansible-playbook -i localhost system-config.yml --ask-become-pass --diff
