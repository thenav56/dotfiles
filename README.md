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
