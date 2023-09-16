## Arch package


### Tool
- pacman: Arch official package manager <https://wiki.archlinux.org/title/pacman>
- yay: An AUR Helper Written in Go <https://github.com/Jguer/yay>


### Basic commands
```bash
# Update local package list
yay -Sy

# Update local package list and upgrade all packages
yay -Syu
yay  # Same as yay -Syu

# Search for package
yay -s <package-name>

# Install package
yay -S <package-name>

# List non AUR, non dependencies packages
yay -Qne

# List non ARU, non dependencies packages
yay -Qme
```
> NOTE: You can replace `yay` with `sudo pacman`, but it will not install AUR packages


## Vim

Learn vim
```bash
vimtutor
```


## Custom Scripts
TODO
