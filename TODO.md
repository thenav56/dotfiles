- CAPS->ESC Not working properly
- nvim
    - clipboard not working properly
        - install xclip fixed - Check again? - WORKING FINE
    - LATER lsp
    - ...
- Xserver
    - TO CONNECT
        - Start the vitual session (Remote)
            - sudo systemctl start vncserver@:1.service
        - Port forward to connect (Local)
            - ssh -N -L 5901:localhost:5901 tc-rup
        - Stop the vitual session (Remote)
            - sudo systemctl stop vncserver@:1.service
- Dotbot
    - Add script to auto install packages
- Fonts:
    - Emoji
    - vim icon
    - FIXED
        - yay -S noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra
        - yay -S ttf-hack-nerd
        - Used Hack in kitty config
- zsh
    - completions not working - WORKING NOW
    - Maybe not use zinit?
- rofi
    - Config? - ADDED
- notifications
    - dunst
        - Added keybinds - Check i3-config
        - config  - ADDED - NEED UPDATES
- yay
    - File based packages setup? or just keep track?
- polybar
- gitconfig
- atuin
    - Remove from history?

- i3
    - Lock
    - TODO Auto lock
    - TODO Auto suspend

- Wake on lan
    - Added a section in README.md
- ENCRYPTION
    - TODO PARTIAL
