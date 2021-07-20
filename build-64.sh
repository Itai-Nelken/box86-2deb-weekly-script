#!/bin/bash

DIR="$HOME/Documents/box86-auto-build"
LOG="$DIR/box64-2deb-weekly_log.log"

function error() {
	echo "[$(date)] | ERROR | $@" >> $LOG
	exit 1
}

git clone https://github.com/ptitseb/box64.git || error "failed to clone repository"
cd box64 || error "failed to enter box64 folder"
mkdir build || error "failed to create build folder"
cd build || error "Failed to enter build folder"
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DARM_DYNAREC=1 .. || error "Failed to run cmake"
make -j4
