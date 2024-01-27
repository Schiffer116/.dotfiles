#!/bin/sh

if [ $(pgrep gammastep) ]; then
    pkill gammastep
else
    gammastep -O 4500K
fi
