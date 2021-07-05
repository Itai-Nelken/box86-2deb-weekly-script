#!/bin/bash

#wait for 1 minute to avoid conflicts with box86 script
sleep 60
cd ~/Documents/box86-2deb-weekly-script
bash run-once-box64-2deb-weekly-script.sh
exit $?

