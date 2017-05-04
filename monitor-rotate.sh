#!/bin/sh
# Auto rotate screen based on device orientation

# Screen orientation and launcher location is set based upon accelerometer position
# This script should be added to startup applications for the user

command -v monitor-sensor >/dev/null 2>&1 || { echo >&2 "I require monitor-sensor but it's not installed.  Aborting."; exit 1; }
command -v xmodmap >/dev/null 2>&1 || { echo >&2 "I require xmodmap but it's not installed.  Aborting."; exit 1; }

# switch between pipe and filemode
FML='file'

#cleanup last run
LOG=sensor.log
: > sensor.log
killall -q -v monitor-sensor

# create FIFO
PIPE=/var/run/user/$UID/sensorpipe
[ -e $PIPE ] || mkfifo $PIPE

# Launch monitor-sensor and output
if [ $FML == 'file' ]; then
    monitor-sensor >> $LOG &
    STATE=$LOG
    elif [ $FML == 'pipe' ]; then
    monitor-sensor >> $PIPE &
    STATE=$PIPE
fi

PID=$!
# kill monitor-sensor if this script exits
trap "[ ! -e /proc/$PID ] || kill $PID" SIGHUP SIGINT SIGQUIT SIGTERM SIGPIPE
LASTORIENT='unset'
echo 'monitoring for screen rotation...'
while [ -d /proc/$PID ] ; do
    sleep 0.05
    #if read line <$PIPE; then
    if read line <$STATE; then
    #while read line ; do
        line=$(echo $line | sed -E  '/orient/!d;s/.*orient.*: ([a-z\-]*)\)??/\1/;' )
        # read a line from the pipe, set var if not whitespace
        [[ $line == *[^[:space:]]* ]] || continue
        ORIENT=$line
        if [[ "$ORIENT" != "$LASTORIENT" ]]; then
            LASTORIENT=ORIENT
            # Set the actions to be taken for each possible orientation
            case "$ORIENT" in
            normal)
              /opt/rotate-screen.sh -n;;
            bottom-up)
              /opt/rotate-screen.sh -u;;
            right-up)
              /opt/rotate-screen.sh -r;;
            left-up)
              /opt/rotate-screen.sh -l;;
            esac
        fi
    fi
    #done  <(inotifywait -qm -e modify $PIPE) 
done
echo exiting
