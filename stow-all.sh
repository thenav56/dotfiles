#!/bin/zsh

for d in `ls *`;
do
    ( stow $d )
done
