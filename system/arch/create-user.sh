#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


read -p 'Type your new username' newuser

useradd -m $newuser
passwd $newuser

# Create some groups we might need in future
groupadd docker || true
groupadd i2c || true

# Add user to groups
usermod --append --groups docker,wheel,i2c $newuser
