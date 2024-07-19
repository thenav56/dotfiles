#!/bin/bash -x

pacman -S ansible python-passlib

# Install additional ansible plugins
ansible-galaxy collection install -r requirements.yml
