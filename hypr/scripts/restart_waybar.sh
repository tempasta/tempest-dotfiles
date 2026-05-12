#!/bin/bash

# kill waybar cleanly (not just pkill)
killall -q waybar

# wait until it's actually dead
while pgrep -x waybar >/dev/null; do
    sleep 0.1
done

# start fresh with proper logging
nohup waybar >/tmp/waybar.log 2>&1 & disown
