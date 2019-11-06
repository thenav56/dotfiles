Add to /etc/default/grub

```grub
GRUB_CMDLINE_LINUX_DEFAULT="quiet video=DP-2:1920x1080"
```
Update Grub and reboot
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg ; reboot
```
