## Automatic

```bash
./install
```

**Arch** - [README](./system/arch/README.md)

## Manual

### Git configuration
Create a new file ~/.git-additional.config and add sensitive configurations there
Sample:
```gitconfig
[user]
    email = example@gmail.com
    name = your-username
    signingkey = your-gpg-public-key
```

### ZSH overwrite configuration
Create a new file ~/.zsh-additional-rc add sensitive and overwrite configurations there
Sample:
```bash
export VimGPGDefaultRecipients="myemail@gmail.com"
export VIM_DAY_THEME="base16-catppuccin-latte"
export VIM_NIGHT_THEME="base16-summerfruit-dark"
```

### Wake on LAN

> NOTE: If enabling WOL is available through BIOS then use that instead

<https://wiki.archlinux.org/title/Wake-on-LAN#systemd.link>

Create new file `/etc/systemd/network/50-wired.link`
```
[Match]
MACAddress=aa:bb:cc:dd:ee:ff

[Link]
NamePolicy=kernel database onboard slot path
MACAddressPolicy=persistent
WakeOnLan=magic
```
> NOTE: Replace "aa:bb:cc:dd:ee:ff" with your ethernet card MACAddress. Use `ip addr`


### Remote access using VNC
#### Virtual
This host
```bash
# Add your users in `/etc/tigervnc/vncserver.users`
echo ":1=$USER" | sudo tee /etc/tigervnc/vncserver.users

# Enable virtual session (boot as well)
sudo systemctl enable --now vncserver@:1.service
```
> NOTE: For more info [vnc-server-virtual-doc](https://wiki.archlinux.org/title/TigerVNC#Running_vncserver_for_virtual_(headless)_sessions>)

Host to access from
```bash
# Run this to forward your remote port to your local port 5901
ssh -N -L 5901:localhost:5901 -t your-server-host
```
> Now connect using any vnc client. Recommended [Remmina](https://remmina.org/)

#### Physical
```bash
ssh -L 5901:localhost:5900 -t your-server-host 'DISPLAY=:0 x0vncserver -localhost -SecurityTypes none'
```
> Now connect using any vnc client. Recommended [Remmina](https://remmina.org/)


## Encryption
[LUKS](https://access.redhat.com/solutions/100463)

### On partitions
<https://wiki.archlinux.org/title/dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition>

Why?
> With seperate partition, we can decrypt and mount this after boot which is helpfull
> when we can't physically turn on the system. For eg: Using WOL or a friend turns on the system.

Create a separate partitions
- 10-100GB should be sufficient for most of the cases
- Check current uses by using [dua](https://github.com/Byron/dua-cli) or [gdu](https://github.com/dundee/gdu) or [ncdu](https://linux.die.net/man/1/ncdu) on your home directory.


Use for what?
- Sensitive applications
    - Browsers (Heavy)
    - Credentials (Light)
        - AWS
        - docker
        - github
        - gpg
    - Project's secrets (Light)
    - Database dumps (Heavy)

Assuming the new partition is /dev/sdb3
> NOTE: Make sure update your current user password to better one

> NOTE: Use you current password for the partition encyption to avoid forgeting or avoiding
> entering password twice faster login
TODO: More notes

Create encrypted partition
```bash
# Enable encyption on the parition using cryptsetup
sudo cryptsetup -y -v luksFormat /dev/sda3
# Then map the parition as virtual parition using cryptsetup
sudo cryptsetup open /dev/sda3 root
# Format the mapped parition using mkfs.ext4
sudo mkfs.ext4 /dev/mapper/root
# Mount the new mapped partition
sudo mount --mkdir /dev/mapper/root /mnt/encrypted_data/

# Now check if all is okay
# -- Create a sample file
echo 'hi-there' | sudo tee /mnt/encrypted_data/test-file.txt
# -- Unmount
sudo umount /mnt/encrypted_data/
# -- Close encyption virtual partition
sudo cryptsetup close root
# -- Open again
sudo cryptsetup open /dev/sda3 root
# -- Mount again
sudo mount /dev/mapper/root /mnt/encrypted_data/
# -- Check the file content
sudo cat /mnt/encrypted_data/test-file.txt
```

Auto mount partition
> NOTE: Not using fstab as it is needed before starting linux
> We will encrypt during login instead using PAM
MAYBE NOT THIS ONE? Follow this
- Global [I am using this one]
    - https://wiki.archlinux.org/title/pam_mount
        - Install the `pam_mount` package: https://wiki.archlinux.org/title/Pam_mount#Configuration
        - Update `/etc/security/pam_mount.conf.xml`: https://wiki.archlinux.org/title/Pam_mount#Global_(system)_configuration
        - Update `/etc/pam.d/system-login`: https://wiki.archlinux.org/title/Pam_mount#Login_manager_configuration
- Per-user
    - Maybe use configuration in dot file https://wiki.archlinux.org/title/pam_mount#Local_(per-user)_configuration
    - https://wiki.archlinux.org/title/Dm-crypt/Mounting_at_login

### Full Disk
Nothing here

## Backup
TODO
To read:
- https://borgbackup.readthedocs.io/en/stable/deployment/central-backup-server.html
- https://borgbackup.readthedocs.io/en/stable/deployment/hosting-repositories.html

## Power button
> https://wiki.archlinux.org/title/Power_management#ACPI_events

To make power button have sleep action.
Add `HandlePowerKey=suspend` to **/etc/systemd/logind.conf**
then
```bash
sudo systemctl kill -s HUP systemd-logind
```
> NOTE: This will kill all your sessions

## Font
<https://www.nerdfonts.com/cheat-sheet>

- MacOS
    - [./system-packages/brew/README.md](./system-packages/brew/README.md)
    - GPG
        - Setup: <https://gist.github.com/phortuin/cf24b1cca3258720c71ad42977e1ba57>
        - Permission: https://superuser.com/questions/954509/what-are-the-correct-permissions-for-the-gnupg-enclosing-folder-gpg-warning
    - Ctrl+Space not working: <https://github.com/zsh-users/zsh-autosuggestions/issues/132#issuecomment-491248596>
    - Encrypted DNS: https://github.com/paulmillr/encrypted-dns
    - Alacritty unsigned error: https://github.com/alacritty/alacritty/issues/4673#issuecomment-771291615
