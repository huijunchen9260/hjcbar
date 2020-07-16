#!/bin/sh

killall -9 lemonbar hjcbar.sh watchbar
hjcbar.sh | lemonbar -a 50 -p -f "ibm plex mono:size=14" -f "DejaVu Sans Mono:size=14" -f "Noto Sans CJK TC:size=14" -f "IPAGothic:size=14"  -f  "Font Awesome:size=14" -B "#282828" -F "#ebdbb2" -n "hjcbar" | sh &
watchbar &
