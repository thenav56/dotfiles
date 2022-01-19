### systemd-networkd-wait-online.service

sudo systemctl edit systemd-networkd-wait-online.service

```
[Unit]
Description=Wait for Network to be Configured
Documentation=man:systemd-networkd-wait-online.service(8)
DefaultDependencies=no
Conflicts=shutdown.target
Requires=systemd-networkd.service
After=systemd-networkd.service
Before=network-online.target shutdown.target

[Service]
Type=oneshot
## CUSTOM CHANGE
ExecStart=
ExecStart=/usr/lib/systemd/systemd-networkd-wait-online --any
## CUSTOM CHANGE
RemainAfterExit=yes

[Install]
WantedBy=network-online.target
```

### Zram config
/etc/systemd/zram-generator.conf
```
[zram0]
zram-fraction = 0.5
```
