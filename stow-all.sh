#!/bin/zsh

for d in `ls -d */`;
do
    ( stow $d )
done
