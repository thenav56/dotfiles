## Automatic

```bash
./install

./sudo-install
```

## Manual

### DNS configuration
> NOTE: After Automatic command

```bash
sudo cp ~/.dotfiles/system/resolved/dns_over_tls.conf /etc/systemd/resolved.conf.d
```

### Git configuration
Create a new file ~/.git-additional.config and add sensitive configurations there
Sample:
```gitconfig
[user]
    email = example@gmail.com
    name = your-username
    signingkey = your-gpg-public-key
```
