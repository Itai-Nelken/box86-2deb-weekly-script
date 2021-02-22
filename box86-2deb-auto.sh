#!/bin/bash

#define the directory where box86 will be installed
DIR="$HOME/Documents/box86-auto-build"
#define the directory where the deb will be moved to
DEBDIR="$HOME/Documents/box86-auto-build/debs"
#define the email variable
if [[ ! -f "email" ]]; then
	echo -e "$(tput setaf 6)$(tput bold)enter your email:$(tput sgr 0)"
	read EMAIL
	while true; do
	echo "Do you want to save this email? (y/n)"
	read answer
	if [[ "$answer" == "y" ]] || [[ "$answer" == "Y" ]] || [[ "$answer" == "yes" ]] || [[ "$answer" == "YES" ]]; then
		echo "ok, saving this email."
		touch $DIR/box86-2deb-weekly_log.log
		echo "$EMAIL" > email
		echo "[ $(date) ] saved email ($EMAIL)." >> $DIR/box86-2deb-weekly_log.log
		break
	elif [[ "$answer" == "n" ]] || [[ "$answer" == "N" ]] || [[ "$answer" == "no" ]] || [[ "$answer" == "NO" ]]; then
		echo "ok, won't save this email."
		break
	else
		echo -e "$(tput setaf 3)invalid option '$answer'$(tput sgr 0)"
	fi

	done
else
	EMAIL="`cat email`"
fi

function error() {
	echo -e "\e[91m$1\e[39m"
    echo "[ $(date) ] $1" >> box86-2deb-weekly_log.log
 	exit 1
 	break
}

#compile box86 function
function compile-box86(){
	echo "compiling box86..."
	cd ~/Documents/box86-auto-build || error "Failed to change directory! (line 41)"
	git clone https://github.com/ptitSeb/box86 || error "Failed to git clone box86 repo! (line 42)"
	cd box86 || error "Failed to change directory! (line 18)"
	mkdir build; cd build; cmake .. -DRPI4=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo || error "Failed to run cmake! (line 44)"
	make -j4 || error "Failed to run make! (line 45)"
	#get current directory path
	BUILDDIR="`pwd`" || error "Failed to set BUILDDIR variable! (line 47)"
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
	cd $BUILDDIR || error "Failed to change directory to $BUILDDIR! (line 63)"
	#create the doc-pak directory and copy to it the readme, usage, changelog and license.
	#this will go in /usr/doc/box86 when the deb is installed.
	mkdir doc-pak || error "Failed to create doc-pak! (line 66)"
	cp $DIR/box86/docs/README.md $BUILDDIR/doc-pak || error "Failed to copy README.md to doc-pak! (line 67)"
	cp $DIR/box86/docs/CHANGELOG.md $BUILDDIR/doc-pak || error "Failed to copy CHANGELOG.md to doc-pak! (line 68)"
	cp $DIR/box86/docs/USAGE.md $BUILDDIR/doc-pak || error "Failed to copy USAGE.md to doc-pak! (line 69)"
	cp $DIR/box86/docs/LICENSE $BUILDDIR/doc-pak || error "Failed to copy LICENSE to doc-pak! (line 70)"
	#create description-pak.
	#checkinstall will use this for the deb's control file description and summary entries.
	echo "Linux Userspace x86 Emulator with a twist.

	Box86 lets you run x86 Linux programs (such as games)
	on non-x86 Linux, like ARM 
	(host system needs to be 32bit little-endian).">description-pak || error "Failed to create description-pak! (line 77)"
	echo "#!/bin/bash
	echo 'restarting systemd-binfmt...'
	systemctl restart systemd-binfmt">postinstall-pak || error "Failed to create postinstall-pak! (line 80)"

	#get the just compiled box86 version using the get-box86-version function.
	get-box86-version ver  || error "Failed to get box86 version! (line 83)"
	get-box86-version commit || error "Failed to get box86 commit (sha1)! (line 84)"
	#use checkinstall to package box86 into a deb.
	#all the options are so checkinstall doesn't ask any questions but still has the data it needs.
	sudo checkinstall -y -D --pkgversion="$BOX86COMMIT" --provides="box86" --conflicts="qemu-user-static" --pkgname="box86" --install="no" make install || error "Failed to run checkinstall! (line 87)"
}

function clean-up() {
	#current date in YY/MM/DD format
	NOWDAY="`printf '%(%Y-%m-%d)T\n' -1`" || error 'Failed to get current date! (line 92)'
	#make a folder with the name of the current date (YY/MM/DD format)
	mkdir -p $DEBDIR/$NOWDAY || error "Failed to create folder for deb! (line 94)"
	#make a file with the current sha1 (commit) of the box86 version just compiled.
	echo $BOX86COMMIT > $DEBDIR/$NOWDAY/sha1.txt || error "Failed to write box86 commit (sha1) to sha1.txt! (line 96)"
	#move the deb to the directory for the debs. if it fails, try again as root
	mv box86*.deb $DEBDIR/$NOWDAY || sudo mv box86*.deb $DEBDIR/$NOWDAY || error "Failed to move deb! (line 98)"
	#remove the home directory from the deb
	cd $DEBDIR/$NOWDAY || error "Failed to change directory to $DEBDIR/$NOWDAY! (line 100)"
	FILE="`basename *.deb`" || error "Failed to get deb filename! (line 101)"
	FILEDIR="`echo $FILE | cut -c1-22`" || error "Failed to generate name for directory for the deb! (line 102)"
	dpkg-deb -R $FILE $FILEDIR || error "Failed to extract the deb! (line 103)"
	rm -r $FILEDIR/home
	rm -f $FILE || error "Failed to remove old deb! (line 105)"
	dpkg-deb -b $FILEDIR $FILE || error "Failed to repack the deb! (line 106)"
	rm -r $FILEDIR || error "Failed to remove temporary deb directory! (line 107)"
	cd $DEBDIR || error "Failed to change directory to $DEBDIR! (line 108)"
	#compress the folder with the dabe and sha1.txt into a tar.xz archive
	tar -cJf $NOWDAY.tar.xz $NOWDAY/ || error "Failed to compress today's build into a tar.xz archive! (line 110)"
	#remove the box86 folder
	cd $DIR || error "Failed to change directory to $DIR! (line 112)"
	sudo rm -rf box86 || error "Failed to remove box86 folder! (line 113)"
}

function upload-deb() {
	#copy the new deb and tar.xz
	cp $DEBDIR/$NOWDAY/box86*.deb $HOME/Documents/weekly-box86-debs/debian/pool/ || error "Failed to copy new deb! (line 119)"
	cp $DEBDIR/$NOWDAY.tar.xz $HOME/Documents/weekly-box86-debs/debian/source/$NOWDAY.tar.xz || error "Failed to copy new tar.xz archive! (line 120)"
	#remove apt files
	rm $HOME/Documents/weekly-box86-debs/debian/Packages || error "Failed to remove old 'Packages' file! (line 122)"
	rm $HOME/Documents/weekly-box86-debs/debian/Packages.gz || error "Failed to remove old 'Packages.gz' archive! (line 123)"
	rm $HOME/Documents/weekly-box86-debs/debian/Release || error "Failed to remove old 'Release' file! (line 124)"
	rm $HOME/Documents/weekly_box86_debs/debian/Release.gpg || error "Failed to remove old 'Release.gpg' file! (line 125)"
	rm $HOME/Documents/weekly_box86_debs/debian/InRelease || error "Failed to remove old 'InRelease' file! (line 126)"
	#create new apt files
	cd $HOME/Documents/weekly-box86-debs/debian/ || error "Failed to change directory! (line 128)"
	#create 'Packages' and 'Packages.gz'
	dpkg-scanpackages --multiversion . > Packages || error "Failed to create new 'Packages' file! (line 130)"
	gzip -k -f Packages || error "Failed to create new 'Packages.gz' file! (line 131)"
	#Release, Release.gpg, InRelease
	#cp $HOME/Documents/box86-2deb-weekly-script/Release-template $HOME/Documents/weekly-box86-debs/debian/Release || error "Failed to copy Release file! (line 114)"
	#touch Release
	#echo -e "\nDate: `LANG=C date -Ru`" >> Release || error "Failed to write date to 'Release' file (line 116)"
	#echo -e 'MD5Sum:' >> Release || error "Failed to write 'MD5Sum:' to 'Release'! (line 116)"
	#printf ' '$(md5sum Packages.gz | cut --delimiter=' ' --fields=1)' %16d Packages.gz' $(wc --bytes Packages.gz | cut --delimiter=' ' --fields=1) >> Release || error "Failed to write md5sums to 'Release'! (line 118)"
	#printf '\n '$(md5sum Packages | cut --delimiter=' ' --fields=1)' %16d Packages' $(wc --bytes Packages | cut --delimiter=' ' --fields=1) >> Release || error "Failed to write md5sums to 'Release'! (line 119)"
	#echo -e '\nSHA256:' >> Release || error "Failed to write 'SHA256:' to 'Release'! (line 120)"
	#printf ' '$(sha256sum Packages.gz | cut --delimiter=' ' --fields=1)' %16d Packages.gz' $(wc --bytes Packages.gz | cut --delimiter=' ' --fields=1) >> Release || error "Failed to write sha256sums to 'Release'! (line 121)"
	#printf '\n '$(sha256sum Packages | cut --delimiter=' ' --fields=1)' %16d Packages' $(wc --bytes Packages | cut --delimiter=' ' --fields=1) >> Release || error "Failed to write sha256sums to 'Release'! (line 122)"
	apt-ftparchive release . > Release
	gpg --default-key "${EMAIL}" -abs -o - Release > Release.gpg
	gpg --default-key "${EMAIL}" --clearsign -o - Release > InRelease
	cd .. || error "Failed to move one directory up! (line 145)"
	git fetch || error "Failed to run 'git fetch'! (line 146)"
	git pull || error "Failed to run 'git pull'! (line 147)"
	git stage debs/ || error "Failed to stage 'debs/'! (line 148)"
	echo "updated deb to $BOX86COMMIT" > commit.txt || error "Failed to create file with commit message! (line 149)"
	git commit --file=commit.txt || error "Failed to commit new deb! (line 150)"
	git push || error "Failed to run 'git push'! (line 150)"
	rm -f commit.txt || error "Failed to remove commit message file! (line 152)"
	cd $DIR || error "Failed to change directory to $DIR! (line 153)"
}

# main loop, this runs for always until stopped.
# the code inside assigns the current day to the $NOW variable
#then it checks if the day is Thursday, if yes it compiles & packages box86
#then it cleans up and waits for 7 days (604800 seconds).
#after 7 days it checks if the day is Thursday (it should be),
#if yes it repeats what is described above.
while true; do
	#get the current day (example output: Thu (thursday))
	NOW="`date | cut -c1-3`"
	#if the current day is thursday, compile and package box86
	if [[ "$NOW" == "Thu" ]]; then
		echo "today is Thursday,"
		echo "compile time!"
		compile-box86 || error "Failed to run compile-box86 function! (line 169)"
		package-box86 || error "Failed to run package-box86 function! (line 170)"
		clean-up || error "Failed to run clean-up function! (line 171)"
		#clear the screen (scrolling up)
		clear -x
		#write to the log file that build and packaging are complete
		touch box86-2deb-weekly_log.log
		TIME="`date`"
		echo "
		=============================
		$TIME
		=============================" >> box86-2deb-weekly_log.log
		NOWTIME="`date +"%T"`"
		echo "[$NOWTIME | $NOWDAY] build and packaging complete." >> box86-2deb-weekly_log.log
		upload-deb || error "Failed to upload deb! (line 183)"
		#write to log that uploading is complete
		NOWTIME="`date +"%T"`"
		echo "[$NOWTIME | $NOWDAY] uploading complete." >> box86-2deb-weekly_log.log
		#print message
		echo "waiting for 7 days..."
		#count down for 7 days
		DAYSLEFT="7"
		for i in {1..7}; do
			echo "$DAYSLEFT days left..."
			sleep 86400
			DAYSLEFT=$((DAYSLEFT-1))
			touch box86-2deb-weekly_log.log
			echo "[ $(printf '%(%Y-%m-%d)T\n' -1) | $(date +"%T") ] $DAYSLEFT days left until next compile/packaging/upload." >> $DIR/box86-2deb-weekly_log.log
		done
	else
		echo "not today :("
		somevar="10"
		for i in {1..10}; do
			echo "$somevar minutes left..."
			somevar=$(($somevar-1))
			sleep 60
		done
		echo "10 minutes passed"
		sleep 5
		touch box86-2deb-weekly_log.log
		echo "[ $(printf '%(%Y-%m-%d)T\n' -1) | $(date +"%T") ] script is running." >> $DIR/box86-2deb-weekly_log.log
		clear -x

	fi

done
