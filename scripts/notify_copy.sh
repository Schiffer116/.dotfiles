#!/usr/bin/env bash

content=$(cat)
notify-send -- "Copied:" "$content"
