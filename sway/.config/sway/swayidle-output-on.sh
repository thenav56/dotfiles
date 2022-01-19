#!/bin/bash


OFF_OUTPUTS=$(swaymsg -t get_outputs | jq -r '.[] | select(.dpms != true) | .name')

for output in $OFF_OUTPUTS
do
    swaymsg "output $output dpms on"
done
