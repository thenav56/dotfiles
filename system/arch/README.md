```bash
# Install ansible (As root)
./ansible-setup.sh

# Arch system setup (As root)
ansible-playbook --diff playbooks/init.yml --extra-vars "username=your_username new_hostname=your_hostname"

# This can be used in future to sync configs as well (As your_username)
ansible-playbook --ask-become-pass --diff playbooks/system-sync.yml --extra-vars "username=your_username"
```
> NOTE: Replace --extra-vars value with required ones


# Comman issues
## Local Packages are newer then core/extra
```bash
sudo pacman -Syuu
```
