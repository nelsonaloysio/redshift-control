#!/usr/bin/env bash
#
# Simple bash script to interact with redshift
# and adjust screen colors and brightness.
#
# Requires setting the "LAT_LONG" var in file.
#
# usage: redshift-control {option} [--nocolor]
# options:
#   start   set automatic settings
#   pause   interrupt or activate redshift
#   stop    reset brightness and colors
#   up      brighten monitor screens
#   down    dim monitor screens
#   force   instant night colors

# set required var #

LAT_LONG=''        # location 'lat:long' (eg '-10:-30')

# set user options #

BRIGHTNESS='10'    # brightness (10 equals to 100%)
DAYTEMP='6500'     # temperature (6500 day - 4500 night)
FORCETEMP='3600'   # force temperature value (optional)

# main argument to execute
ARG="$(echo "$1" | sed s:-::g)"

# optional; sets brightness without touching colors
[[ "$2" = '--nocolor' ]] && NOCOLOR=true || NOCOLOR=false

# cache path to store var
CONF="/home/$USER/.cache/redshift_control"

# check running processes
RUNNING="$(ps aux | grep -w redshift | grep -v redshift-control | wc -l)"
[[ $(( "$RUNNING" > "1" )) = 1 ]] && RUNNING=true || RUNNING=false

# set functions #

function help {
    head -n 15 "$0" | tail -n 8 | sed 's/# //'; }

function brightness_up {
    b="$BRIGHTNESS"
    # read brightness value from cache
    [ -f "$CONF" ] && b="$(cat $CONF)"
    [[ $b = 10 ]] && exit 0
    # set min/max brightness value
    [[ $(( "$b" > "10" )) = 1 ]] && b='10'
    [[ $(( "$b" < "1" )) = 1 ]] && b='1'
    # level brightness up and save to cache
    b=$(( $b + 1 )); echo "$b" > "$CONF"
    # check value and convert to input format
    [[ $(( "$b" > "9" )) = 1 ]] && b="1.0" || b="0.${b:0:1}"
    # execute redshift and adjust brightness
    [[ "$NOCOLOR" = "true" ]] &&
    redshift -l $LAT_LONG -b $b -o -O $DAYTEMP -P
    [[ "$NOCOLOR" = "false" ]] &&
    redshift -l $LAT_LONG -b $b -o -P; }

function brightness_down {
    b="$BRIGHTNESS"
    # read brightness value from cache
    [ -f "$CONF" ] && b="$(cat $CONF)"
    [[ $b = 1 ]] && exit 0
    # set min/max brightness value
    [[ $(( "$b" > "10" )) = 1 ]] && b='10'
    [[ $(( "$b" < "1" )) = 1 ]] && b='1'
    # level brightness up and save to cache
    b=$(( $b - 1 )); echo "$b" > "$CONF"
    # check value and convert to input format
    [[ $(( "$b" > "9" )) = 1 ]] && b="1.0" || b="0.${b:0:1}"
    # execute redshift and adjust brightness
    [[ "$NOCOLOR" = "true" ]] &&
    redshift -l $LAT_LONG -b $b -o -O $DAYTEMP -P
    [[ "$NOCOLOR" = "false" ]] &&
    redshift -l $LAT_LONG -b $b -o -P; }

function redshift_start {
    echo 10 > "$CONF"
    redshift -l $LAT_LONG &
    disown; }

function redshift_force {
    b="$BRIGHTNESS"
    # read brightness value from cache
    [ -f "$CONF" ] && b="$(cat $CONF)"
    # set min/max brightness value
    [[ $(( "$b" > "10" )) = 1 ]] && b='10'
    [[ $(( "$b" < "1" )) = 1 ]] && b='1'
    # check value and convert to input format
    [[ $(( "$b" > "9" )) = 1 ]] && b="1.0" || b="0.${b:0:1}"
    # execute redshift and adjust color & brightness
    redshift -l $LAT_LONG -b $b -o -O $FORCETEMP -P; }

function redshift_pause {
    pkill -USR1 '^redshift$'; }

function redshift_reset {
    redshift -l $LAT_LONG -o -x -P
    echo 10 > "$CONF"; }

function redshift_kill {
    pnames="$(ps aux | grep redshift | grep -v grep | grep -v redshift-control | awk '{print $13}')"
    pids="$(ps aux | grep redshift | grep -v grep | grep -v redshift-control | awk '{print $2}')"
    [[ "$pids" != "" ]] && kill -9 $pids; }

function send_notify () {
    notify-send -i notification-audio-volume-high\
                --hint=string:x-canonical-private-synchronous:\
                "Redshift" "${1}" -t 1700 ;}

# execute #

case "$ARG" in

    start)
        [[ $RUNNING = false ]] &&
        redshift_start
        ;;

    force)
        [[ $RUNNING = true ]] &&
        redshift_kill
        redshift_force
        ;;

    pause)
        [[ $RUNNING = false ]] &&
        redshift_reset &&
        redshift_start ||
        redshift_pause
        ;;

    stop|reset)
        redshift_kill
        redshift_reset
        ;;

    up|brightnessup)
        redshift_kill
        brightness_up
        ;;

    down|brightnessdown)
        redshift_kill
        brightness_down
        ;;

    *) # default
        help
        ;;

esac # finishes