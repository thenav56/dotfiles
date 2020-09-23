# .dotfiles

Uses **stow** to install and uninstall configurations.

To install a certain config:
```bash
stow <name>
```

To uninstall a certain config:
```bash
stow -D <name>
```

To install all configs:
```bash
./stow-all.sh
```

To uninstall all configs:
```bash
./unstow-all.sh
```

# For Alacritty and base16 themes
```bash
# ZSH auto complete and switcher
# Make sure to remove `echo ". ~/.base16_theme"` from base16-shell/profile_helper.sh
git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell

# Theme collection for alacritty
git clone https://github.com/aaron-williamson/base16-alacritty ~/.alacritty-theme

# Theme switcher for alacritty
git clone https://github.com/toggle-corp/alacritty-colorscheme ~/alacritty-colorscheme
```

## Sway troubleshoot
```bash
yay -S xorg-server-xwayland  # Application are not starting(freezing on startup)

yay -S libappindicator-gtk3  # Tray icons not showing
```

## Brightness Issues

Add this to /etc/udev/rules.d/backlight.rules
```text
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="acpi_video0", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="acpi_video0", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
```

Add current user to video group
```bash
sudo usermod -a -G video $LOGNAME
```
