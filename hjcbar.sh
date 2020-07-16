#!/bin/sh

# Run this script with:
# killall -9 lemonbar hjcbar.sh; hjcbar.sh | lemonbar -a 50 -p -f "ibm plex mono:size=14" -f "DejaVu Sans Mono:size=14" -f "Noto Sans CJK TC:size=14" -f "IPAGothic:size=14"  -f  "Font Awesome:size=14" -B "#282828" -F "#ebdbb2" -n "hjcbar" | sh &

nl='
'
delim='┋'

TMP="/tmp/hjcbar-tmp"
[ -d "$TMP" ] || mkdir "$TMP"

calc () { awk "BEGIN { print int($*) }"; }

time () { time="%{A3:$TERMINAL -e calcurse &:}$(date '+%b-%d %H:%M')%{A3}"; }

volume () { volume="%{A1:pulsemixer --toggle-mute; kill -35 $(pidof -x hjcbar.sh);:}%{A3:$TERMINAL -e pulsemixer &:}%{A5:pulsemixer --change-volume +1; kill -35 $(pidof -x hjcbar.sh);:}%{A4:pulsemixer --change-volume -1; kill -35 $(pidof -x hjcbar.sh):}$(amixer get Master | grep -o "[0-9]*%\|\[on\]\|\[off\]" | sed "s/\[on\]//;s/\[off\]//")%{A4}%{A5}%{A3}%{A1}"; }

network () { network="%{A3:$TERMINAL -e nmtui &:}$(printf '%s ' "$(grep "^\s*w" /proc/net/wireless | awk '{ print "", int($3 * 100 / 70) "%" }')" "$(sed "s/down/❌/;s/up//;s/unknown//" /sys/class/net/e*/operstate)")%{A3}"; }

system () {
    read -r name user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    total=$((user+nice+system+idle+iowait+irq+softirq+steal+guest+guest_nice))
    idle=$((idle+iowait+irq))
    [ -z $pretotal ] && pretotal=$((total-1))
    [ -z $preidle ] && preidle=$((idle-1))
    cpu=" $(calc "(($total-$pretotal)-($idle-$preidle))/($total-$pretotal)*100")%"
    pretotal=$total
    preidle=$idle
    memory=" $(free -h | sed -n '2{p;q}' | cut -d ' ' -f 19)"
    system="%{A3:$TERMINAL -e htop &:}$memory $cpu%{A3}"
}

weather () {
    [ "$(stat -c %y "$HOME/.local/share/weatherreport" 2>/dev/null | cut -d' ' -f1)" = "$(date '+%Y-%m-%d')" ] ||
	(ping -q -c 1 1.1.1.1 >/dev/null && curl -s "wttr.in/$location" > "$HOME/.local/share/weatherreport") &&
	weather="%{A3:$TERMINAL -e less $HOME/.local/share/weatherreport &:}$(sed '16q;d' "$HOME/.local/share/weatherreport" | grep -wo "[0-9]*%" | sort -n | sed -e '$!d' | sed -e "s/^/ /g" | tr -d '\n' &&
	sed '13q;d' "$HOME/.local/share/weatherreport" | grep -o "m\\(-\\)*[0-9]\\+" | sort -n -t 'm' -k 2n | sed -e 1b -e '$!d' | tr '\n|m' ' ' | awk '{print " ",$1 "°","",$2 "°"}')%{A3}"
}

battery () {
    for x in /sys/class/power_supply/BAT?; do
	num="${x##*BAT}"
	AC="$(cat -u $x/status)"
	CAP="$(cat -u $x/capacity)"
	case $AC in
	    "Charging") battery="$(printf '%s' "$battery" " $num: $CAP%")" ;;
	    *)
		case "$CAP" in
		    100|9[0-9])	battery="$(printf '%s' "$battery" " $num: $CAP%")" ;;
		    8[0-9]|7[0-9]) battery="$(printf '%s' "$battery" " $num: $CAP%")" ;;
		    6[0-9]|5[0-9]) battery="$(printf '%s' "$battery" " $num: $CAP%")" ;;
		    4[0-9]|3[0-9]) battery="$(printf '%s' "$battery" " $num: $CAP%")" ;;
		    *) battery="$(printf '%s' "$battery" " $num: $CAP%")" ;;
		esac
	esac
    done
}

groups() {
    cur=$(xprop -root _NET_CURRENT_DESKTOP)
    cur=${cur##* }
    tot=$(xprop -root _NET_NUMBER_OF_DESKTOPS)
    tot=${tot##* }
    wincount="$(xdotool search --all --onlyvisible --desktop $cur "" 2>/dev/null | wc -l)"
    # Only work for 2 monitors
    monitoroutput=$(xrandr --listactivemonitors)
    monitoroutput=${monitoroutput#*$nl}
    count1=${monitoroutput#*$nl}
    count2=${monitoroutput%$nl*}
    [ ${#count1} -eq ${#count2} ] && monitorcount=1 || monitorcount=2
    # monitorcount=$(xrandr --listactivemonitors | tail -n +2 | wc -l)
    idle='-'
    active='†'
    occupy='o'
    case "$monitorcount" in
        '1')
	    line=$(printf '%*s ' "$((tot-1))" | tr ' ' "$idle")
	    for w in $(wmctrl -l | cut -d ' ' -f3 | uniq); do
		line=$(printf '%s' "$line" | sed "s/^\(.\{$w\}\)./\1$occupy/")
	    done
	    ws=$(echo $line | sed "s/^\(.\{$cur\}\)./\1$active/")
	    ;;
	'2') sep=$(calc "$tot/$monitorcount")
	    if [ $cur -lt $sep ]; then
		line=$(printf '%*s ' "$tot" | tr ' ' "$idle")
		for w in $(wmctrl -l | cut -d ' ' -f3 | uniq); do
		    w=$((w+1))
		    line=$(printf '%s' "$line" | sed "s/^\(.\{$w\}\)./\1$occupy/")
		done
		ws=$(echo $line | sed "s/^\(.\{$cur\}\)./\1$active/; s/\(.\{$sep\}\)./\1 /")
	    else
		cur=$(calc "$cur+1")
		line=$(printf '%*s ' "$tot" | tr ' ' "$idle")
		for w in $(wmctrl -l | cut -d ' ' -f3 | uniq); do
		    w=$((w+1))
		    line=$(printf '%s' "$line" | sed "s/^\(.\{$w\}\)./\1$occupy/")
		done
		ws=$(echo $line | sed "s/^\(.\{$cur\}\)./\1$active/; s/\(.\{$sep\}\)./\1 /")
	    fi
	    ;;
    esac
}

music () {
    playicon=""
    pauseicon=""
    format=$(mpc -f "[%title%]|[%file%]" 2>/dev/null)
    name=${format%%$nl*}
    name="${name##*/}"
    status="$(printf '%s' "$format" | grep -o "\[playing\]\|\[paused\]" | sed "s/\[playing\]/$playicon/; s/\[paused\]/$pauseicon/; s/\n//")"
    echo "$status" > "$TMP/status"

    music="%{A1:mpc toggle > /dev/null; kill -37 $(pidof -x hjcbar.sh);:}%{A3:$TERMINAL -e ncmpcpp &:}$([ ${#name} -ge 40 ] && printf '%s' "$(printf '%s' "$name" | cut -b 1-40)... $status" || printf '%s' "$name $status")%{A3}%{A1}"
}

musictime () { musictime=$(mpc status 2>/dev/null | grep -o "[0-9]*:[0-9]*/[0-9]*:[0-9]*"); }

# This loop will fill a buffer with our infos, and output it to stdout.
update () {
    left="${ws} ${wincount} $delim ${system}"
    right="${musictime} ${music} ${volume} $delim ${weather} $delim ${network} $delim ${battery} $delim ${time}"
    monitorlist=$(xrandr --listactivemonitors)
    tmp=0
    IFS=$nl
    for m in ${monitorlist#*$nl}; do
	unset IFS
	m=${m##* }
	BAR="$BAR%{S${tmp}} %{l}%{A3:arandr &:}$m%{A3} $delim ${left}%{r}${right}"
	tmp=$((tmp+1))
    done
    # printf '%s\n' "$(echo "$BAR" | tr '\n' ' ')"
    echo "$BAR" | tr '\n' ' '
    unset tmp BAR

    # Hide bar in full screen
    wid=$(xdo id -a "hjcbar")
    for w in $(echo $wid); do
	xdo above -t "$(xdo id -N Bspwm -n root | sort | head -n 1)" "$w"
    done
}

refresh () {
    case "$sig" in
	# manual update
	35) volume ;;
	36) groups ;;
	37) music ;;
	# auto update
        38) musictime ;;
	39) network ;;
	40) time ;;
	41) system ;;
	42) unset battery; battery ;;
	43) weather ;;
	'') unset battery; network; time; system; battery ;;
    esac
    unset sig
}

# Use user-defined "Real-time" signal, from 35-49.
# See the output of `kill -l`, and add 34 to the `num` in `RTMIN+num`.
trap 'sig=35;' 35
trap 'sig=36;' 36
trap 'sig=37;' 37
trap 'sig=38;' 38
trap 'sig=39;' 39
trap 'sig=40;' 40
trap 'sig=41;' 41
trap 'sig=42;' 42
trap 'sig=43;' 43

time; volume; system; weather; battery; network; groups; music; musictime
while :; do
    refresh; update &
    sleep 1m &
    wait
done
