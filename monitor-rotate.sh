#!/bin/sh
# Auto rotate screen based on device orientation

# Screen orientation and launcher location is set based upon accelerometer position
# This script should be added to startup applications for the user

command -v monitor-sensor >/dev/null 2>&1 || { echo >&2 "I require monitor-sensor but it's not installed.  Aborting."; exit 1; }
command -v xmodmap >/dev/null 2>&1 || { echo >&2 "I require xmodmap but it's not installed.  Aborting."; exit 1; }

# switch to cwd
cd $PWD

#cleanup last run
LOG=sensor.log
: > sensor.log
killall -q -v monitor-sensor

# Launch monitor-sensor and output
monitor-sensor >> $LOG &
STATE=$LOG

PID=$!
# kill monitor-sensor if this script exits
trap "[ ! -e /proc/$PID ] || kill $PID" SIGHUP SIGINT SIGQUIT SIGTERM SIGPIPE
LASTORIENT='unset'
echo 'monitoring for screen rotation...'
while [ -d /proc/$PID ] ; do
    sleep 0.05
    # meh
    while inotifywait -q -e modify $STATE; do
        line=$(tail -n1 $STATE | sed -E  '/orient/!d;s/.*orient.*: ([a-z\-]*)\)??/\1/;' )
        # read a line from the pipe, set var if not whitespace
        [[ $line == *[^[:space:]]* ]] || continue
        ORIENT=$line
        if [[ "$ORIENT" != "$LASTORIENT" ]]; then
            LASTORIENT=ORIENT
            # Set the actions to be taken for each possible orientation
            case "$ORIENT" in
            normal)
              ./rotate-screen.sh -n;;
            bottom-up)
              ./rotate-screen.sh -u;;
            right-up)
              ./rotate-screen.sh -r;;
            left-up)
              ./rotate-screen.sh -l;;
            esac
        fi
    done
done
echo exiting
