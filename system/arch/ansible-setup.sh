#!/usr/bin/env bash
set -euo pipefail

# Bootstrap Ansible itself plus the python-passlib library needed by
# init.yml's `vars_prompt encrypt: sha512_crypt`. Run as root from
# system/arch/.

pacman -S ansible python-passlib

ansible-galaxy collection install -r requirements.yml
