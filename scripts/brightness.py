#!/usr/bin/env python

import subprocess
import sys

def get_brightness():
    output = subprocess.run(['brightnessctl', 'i', '--machine-readable', '--exponent=2'], stdout=subprocess.PIPE).stdout.decode('utf-8')
    percent = output.split(',')[3][:-1]
    return int(percent)

def set_brightness(value: int):
    subprocess.run(['brightnessctl', 'set', str(value) + '%', '--exponent=2', '--min-value=5'])

def increase_brightness():
    cur = get_brightness()
    new = min(100, (cur + 5) * 5 // 5)
    set_brightness(new)

def decrease_brightness():
    cur = get_brightness()
    new = min(100, (cur + 5) * 5 // 5)
    set_brightness(new)

match sys.argv[1]:
    case 'increase':
        increase_brightness()
    case 'decrease':
        decrease_brightness()
