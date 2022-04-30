#!/bin/bash

ip route | grep -q 'wg' \
    && echo '{"text":"Connected","class":"connected","percentage":100}' \
    || echo '{"text":"Disconnected","class":"disconnected","percentage":0}'
