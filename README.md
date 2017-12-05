# .dotfiles

Configuration files for termite, vim, i3wm, i3blocks, compton, redshift, rofi, dunst & twmn.
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
