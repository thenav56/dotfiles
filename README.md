## Automatic

```bash
./install

./sudo-install
```

## Manual

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

https://wiki.archlinux.org/title/Wake-on-LAN#systemd.link

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

## Replace
Search for `REPLACE` and replace the values accordingly
