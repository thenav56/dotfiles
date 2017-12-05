#!/bin/zsh

for d in `ls *`;
do
    ( stow -D $d )
done
