#!/bin/bash
# Auto rotate screen based on device orientation

# Screen orientation and launcher location is set based upon accelerometer position
# This script should be added to startup applications for the user

### configuration
# find your Touchscreen and Touchpad device with `xinput`
TouchscreenDevice='ELAN Touchscreen'
TouchpadDevice='SynPS/2 Synaptics TouchPad'
KeyboardDevice='AT Translated Set 2 keyboard'

### arguments
if [ "$1" == '-nosd' ]; then NOSD=1; fi

### functions
rotatescreen() {
  # Contributors: Ruben Barkow: https://gist.github.com/rubo77/daa262e0229f6e398766

  touchpadEnabled=$(xinput --list-props "$TouchpadDevice" | awk '/Device Enabled/{print $NF}')
  screenMatrix=$(xinput --list-props "$TouchscreenDevice" | awk '/Coordinate Transformation Matrix/{print $5$6$7$8$9$10$11$12$NF}')

  # Matrix for rotation
  # ⎡ 1 0 0 ⎤
  # ⎜ 0 1 0 ⎥
  # ⎣ 0 0 1 ⎦
  normal='1 0 0 0 1 0 0 0 1'
  normal_float='1.000000,0.000000,0.000000,0.000000,1.000000,0.000000,0.000000,0.000000,1.000000'

  #⎡ -1  0 1 ⎤
  #⎜  0 -1 1 ⎥
  #⎣  0  0 1 ⎦
  inverted='-1 0 1 0 -1 1 0 0 1'
  inverted_float='-1.000000,0.000000,1.000000,0.000000,-1.000000,1.000000,0.000000,0.000000,1.000000'

  # 90° to the left 
  # ⎡ 0 -1 1 ⎤
  # ⎜ 1  0 0 ⎥
  # ⎣ 0  0 1 ⎦
  left='0 -1 1 1 0 0 0 0 1'
  left_float='0.000000,-1.000000,1.000000,1.000000,0.000000,0.000000,0.000000,0.000000,1.000000'

  # 90° to the right
  #⎡  0 1 0 ⎤
  #⎜ -1 0 1 ⎥
  #⎣  0 0 1 ⎦
  right='0 1 0 -1 0 1 0 0 1'

  if [ "$1" == "-u" ]; then
    echo "Upside down"
    xrandr -o inverted
    xinput set-prop "$TouchscreenDevice" 'Coordinate Transformation Matrix' $inverted
    xinput disable "$TouchpadDevice"
    xinput disable "$KeyboardDevice"
    # if onboard isn't running, start it
    [[  `pgrep onboard` ]] || onboard 2>/dev/null &
  elif [ "$1" == "-l" ]; then
    echo "90° to the left"
    xrandr -o left
    xinput set-prop "$TouchscreenDevice" 'Coordinate Transformation Matrix' $left
    xinput disable "$TouchpadDevice"
    xinput disable "$KeyboardDevice"
    [[  `pgrep onboard` ]] || onboard 2>/dev/null &
  elif [ "$1" == "-r" ]; then
    echo "90° right up"
    xrandr -o right
    xinput set-prop "$TouchscreenDevice" 'Coordinate Transformation Matrix' $right
    xinput disable "$TouchpadDevice"
    xinput disable "$KeyboardDevice"
    [[  `pgrep onboard` ]] || onboard 2>/dev/null &
  elif [ "$1" == "-n" ]; then
    echo "Back to normal"
    xrandr -o normal
    xinput set-prop "$TouchscreenDevice" 'Coordinate Transformation Matrix' $normal
    xinput enable "$TouchpadDevice"
    xinput enable "$KeyboardDevice"
    killall -q onboard
  fi
}

### dependencies
# make a binary dependency list, loop it - popout with opts
command -v monitor-sensor >/dev/null 2>&1 || { echo >&2 "I require monitor-sensor but it's not installed.  Aborting."; exit 1; }
command -v onboard >/dev/null 2>&1 || { echo >&2 "I require onboard but it's not installed.  Aborting."; exit 1; }
command -v xmodmap >/dev/null 2>&1 || { echo >&2 "I require xmodmap but it's not installed.  Aborting."; exit 1; }

### main script

# check for running instance exit if exists
myname=$(basename $0)
runningPID=$(ps -ef | grep ".*bash.*$myname" | grep -v "grep \| $$" | awk '{print $2}')
if [[ $runningPID != "" ]] ; then
    echo $myname is already running with PID $runningPID
    exit
fi

#cleanup last run
LOG=/tmp/sensor.log
: > $LOG
killall -q -v monitor-sensor

# Launch monitor-sensor and output
monitor-sensor >> $LOG &
STATE=$LOG

PID=$!
# kill monitor-sensor and rm log if this script exits
trap "[ ! -e /proc/$PID ] || kill $PID && rm $LOG" SIGHUP SIGINT SIGQUIT SIGTERM SIGPIPE
LASTORIENT='unset'

echo 'monitoring for screen rotation...'
while [ -d /proc/$PID ] ; do
    sleep 0.05
    while inotifywait -qq -e modify $STATE; do
        line=$(tail -n1 $STATE | sed -E  '/orient/!d;s/.*orient.*: ([a-z\-]*)\)??/\1/;' )
        # read a line from the pipe, set var if not whitespace
        [[ $line == *[^[:space:]]* ]] || continue
        ORIENT=$line
        if [[ "$ORIENT" != "$LASTORIENT" ]]; then
            LASTORIENT=ORIENT
            # Set the actions to be taken for each possible orientation
            case "$ORIENT" in
            normal)
              rotatescreen -n;;
            bottom-up)
              rotatescreen -u;;
            right-up)
              rotatescreen -r;;
            left-up)
              rotatescreen -l;;
            esac
        fi
    done
done
