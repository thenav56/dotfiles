#!/bin/bash -x

# Turn off the main display
ddcutil --sn HDTW023 setvcp D6 05

# Suspend to remote display
systemctl suspend
