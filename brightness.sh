#!/bin/sh
BL=/sys/class/backlight/intel_backlight
actual=$(cat $BL/actual_brightness)
if [ -z $1 ]; then
   echo $actual
   exit
fi
XBR=$(xrandr --verbose | '
if [ "$1" = "+" ]; then
    new=$(( $actual + 1000 ))
    if [ $new -gt $(cat BL/max_brightness) ]; then
        echo xrandr + $XBR
    else
        echo $new | sudo tee $BL/brightness
    fi
elif [ "$1" = "-" ]; then
    new=$(( $actual - 1000 ))
    if [ $new -lt 1 ]; then return; fi
fi
