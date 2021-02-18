#!/bin/bash

#define the directory where box86 will be installed
DIR="$HOME/Documents/box86-auto-build"
#define the directory where the deb will be moved to
DEBDIR="$HOME/Documents/box86-auto-build/debs"
#current date in YY/MM/DD format
NOWDAY="`printf '%(%Y-%m-%d)T\n' -1`"

function error() {
	echo -e "\e[91m$1\e[39m"
 	exit 1
 	break
}

#compile box86 function
function compile-box86(){
	echo "compiling box86..."
	cd ~/Documents/box86-auto-build || error "Failed to change directory! (line 17)"
	git clone https://github.com/ptitSeb/box86 || error "Failed to git clone box86 repo! (line 18)"
	cd box86 || error "Failed to change directory! (line 18)"
	mkdir build; cd build; cmake .. -DRPI4=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo || error "Failed to run cmake! (line 20)"
	make -j4 || error "Failed to run make! (line 20)"
	#get current directory path
	BUILDDIR="`pwd`" || error "Failed to set BUILDDIR variable! (line 23)"
}

#get just compiled (not installed) box86 version
#USAGE: get-box86-version <option>
#OPTIONS: ver = box86 version (example: 0.2.1); commit: box86 commit (example: db176ad3).
function get-box86-version() {
	if [[ $1 == "ver" ]]; then
		BOX86VER="`./box86 -v | cut -c21-25`"
	elif [[ $1 == "commit" ]]; then
		BOX86COMMIT="`./box86 -v | cut -c27-34`"
	fi
}

#package box86 into a deb using checkinstall function
function package-box86() {
	cd $BUILDDIR || error "Failed to change directory to $BUILDDIR! (line 39)"
	#create the doc-pak directory and copy to it the readme, usage, changelog and license.
	#this will go in /usr/doc/box86 when the deb is installed.
	mkdir doc-pak || error "Failed to create doc-pak! (line 42)"
	cp $DIR/box86/README.md $BUILDDIR/doc-pak || error "Failed to copy README.md to doc-pak! (line 43)"
	cp $DIR/box86/CHANGELOG.md $BUILDDIR/doc-pak || error "Failed to copy CHANGELOG.md to doc-pak! (line 44)"
	cp $DIR/box86/USAGE.md $BUILDDIR/doc-pak || error "Failed to copy USAGE.md to doc-pak! (line 45)"
	cp $DIR/box86/LICENSE $BUILDDIR/doc-pak || error "Failed to copy LICENSE to doc-pak! (line 46)"
	#create description-pak.
	#checkinstall will use this for the deb's control file description and summary entries.
	echo "Linux Userspace x86 Emulator with a twist

	Box86 lets you run x86 Linux programs (such as games)
	on non-x86 Linux, like ARM 
	(host system needs to be 32bit little-endian).">description-pak || error "Failed to create description-pak! (line 53)"

	#get the just compiled box86 version using the get-box86-version function.
	get-box86-version ver  || error "Failed to get box86 version! (line 56)"
	#use checkinstall to package box86 into a deb.
	#all the options are so checkinstall doesn't ask any questions but still has the data it needs.
	sudo checkinstall -y -D --pkgversion="$BOX86VER" --provides="box86" --conflicts="qemu-user-static" --pkgname="box86" --install="no" make install || error "Failed to run checkinstall! (line 59)"
}

function clean-up() {
	#make a folder with the name of the current date (YY/MM/DD format)
	mkdir -p $DEBDIR/$NOWDAY || error "Failed to create folder for deb! (line 64)"
	#make a file with the current sha1 (commit) of the box86 version just compiled.
	get-box86-version commit || error "Failed to get box86 commit (sha1)! (line 71)"
	echo $BOX86COMMIT > $DEBDIR/$NOWDAY/sha1.txt || error "Failed to write box86 commit (sha1) to sha1.txt! (line 67)"
	#move the deb to the directory for the debs. if it fails, try again as root
	mv box86*.deb $DEBDIR/$NOWDAY || sudo mv box86*.deb $DEBDIR/$NOWDAY || error "Failed to move deb! (line 69)"
	#compress the folder with the dabe and sha1.txt into a tar.xz archive
	tar -cjf $DEBDIR/$NOWDAY.tar.xz $NOWDAY/
	#remove the box86 folder
	cd $DIR || error "Failed to change directory to $DIR! (line 71)"
	sudo rm -rf box86 || error "Failed to remoce box86 folder! (line 72)"
}

# main loop, this runs for always until stopped.
# the code inside assigns the current day to the NOW variable
#then it checks if the day is thursday, if yes it compiles & packages box86
#then it cleans up and waits for 7 days (604800 seconds).
#after 7 days it checks if the day is thursday (it should be),
#if yes it repeats what is described above.
while true; do
	#get the current day (example output: Thu (thursday))
	NOW="`date | cut -c1-3`"
	#if the current day is thursday, compile and package box86
	if [[ "$NOW" == "Thu" ]]; then
		echo "today is thursday"
		echo "compile time!"
		compile-box86 || error "Failed to run compile-box86 function! (line 88)"
		package-box86 || error "Failed to run package-box86 function! (line 89)"
		clean-up || error "Failed to run clean-up function! (line 90)"
		#clear the screen (scrolling up)
		clear -x
		#print message
		echo "waiting for 7 days..."
		#sleep for 7 days
		sleep 604800 || error "Failed to sleep for 7 days! (line 92)"
	fi

done
