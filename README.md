## Automatic

```bash
./install
```

## Manual

### SSH
TODO

### Network
#### DNS configuration
<https://wiki.archlinux.org/title/systemd-resolved>

```bash
# Enable systemd-resolved
sudo systemctl enable --now systemd-resolved

# Link systemd-resolved config to system resolv conf
ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Create config directory for custom configs
mkdir -p /etc/systemd/resolved.conf.d/
```

Copy this to `/etc/systemd/resolved.conf.d/dns_over_tls.conf`
```config
[Resolve]
DNS=1.1.1.1 1.0.0.1
DNSOverTLS=yes
```

Reload systemd-resolved to use new configuration
```bash
sudo systemctl restart systemd-resolved
```

#### Connection configuration
<https://wiki.archlinux.org/title/systemd-networkd>

**Wired network**

Create `/etc/systemd/network/20-wired.network`
```config
[Match]
Name=enp1s0

[Network]
DHCP=yes

[DHCPv4]
RouteMetric=10

[IPv6AcceptRA]
RouteMetric=10
```

**Wireless network**

Create `/etc/systemd/network/25-wireless.network`
```config
[Match]
Name=wlan0

[Network]
DHCP=yes
IgnoreCarrierLoss=3s

[DHCPv4]
RouteMetric=20

[IPv6AcceptRA]
RouteMetric=20
```
> NOTE: wlan0 and enp1s0 can be different in your system. Please use `ip config`

### Git configuration
Create a new file ~/.git-additional.config and add sensitive configurations there
Sample:
```gitconfig
[user]
    email = example@gmail.com
    name = your-username
    signingkey = your-gpg-public-key
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


### Auto-lock
After suspend https://github.com/betterlockscreen/betterlockscreen#systemd
```bash
systemctl enable --now betterlockscreen@$USER
```

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
sudo mount --mkdir /dev/mapper/root /mnt/encrypted/

# Now check if all is okay
# -- Create a sample file
echo 'hi-there' | sudo tee /mnt/encrypted/test-file.txt
# -- Unmount
sudo umount /mnt/encrypted/
# -- Close encyption virtual partition
sudo cryptsetup close root
# -- Open again
sudo cryptsetup open /dev/sda3 root
# -- Mount again
sudo mount /dev/mapper/root /mnt/encrypted/
# -- Check the file content
sudo cat /mnt/encrypted/test-file.txt
```

Auto mount partition
> NOTE: Not using fstab as it is needed before starting linux
> We will encrypt during login instead using PAM
TODO
MAYBE NOT THIS ONE? Follow this
- https://wiki.archlinux.org/title/pam_mount [I am using this one]
    - Maybe use configuration in dot file https://wiki.archlinux.org/title/pam_mount#Local_(per-user)_configuration
- https://wiki.archlinux.org/title/Dm-crypt/Mounting_at_login

### Full Disk
Nothing here

## Backup
TODO
To read:
- https://borgbackup.readthedocs.io/en/stable/deployment/central-backup-server.html
- https://borgbackup.readthedocs.io/en/stable/deployment/hosting-repositories.html

## Replace
Search for `REPLACE` and replace the values accordingly
