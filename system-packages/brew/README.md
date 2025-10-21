## System settings

### Keyboard settings

- Open System Preferences and click on 'Keyboard'
    - Click on 'Modifier Keys...'
        - For 'Caps Lock (⇪) key', choose '⎋ Escape'
        - For 'Globe (🌐) key', choose '⌃ Control'
        - For '⌃ Control', choose 'Globe (🌐) key'
        - Click 'Done'
    - Click on 'Spotlight'
        - [x] Show Spotlight search '⇪⌘Space'
            - To use spotlight along with Raycast
        - Click 'Done'

### Trackpad settings

- Open `unnaturalscrollwheels`
- Open System Preferences and click on 'Keyboard'
    - Enable `Tap to click`

## Lock Screen
- Require password after screen saver begins or ... " Use "Immediately"

## Date/Time
- General
    - Date & Time
        - 24-hour time - Disable

### Menu Bar
- Open System Preferences and click on 'Menu Bar'
- Show
    - [x] Wi-Fi
    - [x] Bluetooth
    - [x] Focus - Show When Active
    - [x] Screen Mirroring - Show When Active
    - [x] Display - Always Show
    - [x] Sound - Always Show
- Apps in Menu bar
    - 1password
    - AlDente
    - Caffeine
    - MonitorControl
    - Stats
    - WireGuard

### Battery
- Open System Preferences and click on 'Battery'
- Battery Health
    - Disable "Optimized Battery Charging"
- Open AlDente

## GPG
```bash
mkdir ~/.gnupg
echo "pinentry-program $(which pinentry-mac)" >> ~/.gnupg/gpg-agent.conf
```

## zsh

Hide "last login" message in shell
```
touch ~/.hushlogin
```

## Manually install these

- teleport
    - Using package from teleport to add support for `TOUCHID`
    - https://goteleport.com/docs/installation/macos/#installing-teleport (Teleport Community Edition)

## Commands

```bash
brew bundle upgrade --cleanup
```
