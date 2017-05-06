#!/bin/bash
# This script rotates the screen and touchscreen input 90 degrees each time it is called, 
# also disables the touchpad, and enables the virtual keyboard accordingly

# Contributors: Ruben Barkow: https://gist.github.com/rubo77/daa262e0229f6e398766

#### configuration
# find your Touchscreen and Touchpad device with `xinput`
TouchscreenDevice='ELAN Touchscreen'
TouchpadDevice='SynPS/2 Synaptics TouchPad'
KeyboardDevice='AT Translated Set 2 keyboard'

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

if [ "$1" == "-u" ]
then
  echo "Upside down"
  xrandr -o inverted
  xinput set-prop "$TouchscreenDevice" 'Coordinate Transformation Matrix' $inverted
  xinput disable "$TouchpadDevice"
  xinput disable "$KeyboardDevice"
  [[  `pgrep onboard` ]] || onboard &
elif [ "$1" == "-l" ]
then
  echo "90° to the left"
  xrandr -o left
  xinput set-prop "$TouchscreenDevice" 'Coordinate Transformation Matrix' $left
  xinput disable "$TouchpadDevice"
  xinput disable "$KeyboardDevice"
  [[  `pgrep onboard` ]] || onboard &
elif [ "$1" == "-r" ]
then
  echo "90° right up"
  xrandr -o right
  xinput set-prop "$TouchscreenDevice" 'Coordinate Transformation Matrix' $right
  xinput disable "$TouchpadDevice"
  xinput disable "$KeyboardDevice"
  [[  `pgrep onboard` ]] || onboard &
else
  echo "Back to normal"
  xrandr -o normal
  xinput set-prop "$TouchscreenDevice" 'Coordinate Transformation Matrix' $normal
  xinput enable "$TouchpadDevice"
  xinput enable "$KeyboardDevice"
  killall -q onboard
fi
