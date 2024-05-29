```
# Install ansible
./ansible-setup.sh


# Arch system setup (As root)
ansible-playbook -i localhost playbooks/init.yml


```

# /etc/crypttab
```
# <name>  <device>     <password>     <options>
swap      /dev/sdX#    /dev/urandom   swap,cipher=aes-xts-plain64,size=512
```
