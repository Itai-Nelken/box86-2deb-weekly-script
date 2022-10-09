#!/bin/bash

#define the directory where box86 will be installed
DIR="$HOME/Documents/box86-auto-build"
#define the directory where the deb will be moved to
DEBDIR="$HOME/Documents/box86-auto-build/debs"
#define the email variable
if [[ ! -f "$DIR/email" ]]; then
	echo -e "$(tput setaf 6)$(tput bold)enter your email:$(tput sgr 0)"
	read EMAIL
	while true; do
	echo "Do you want to save this email? (y/n)"
	read answer
	if [[ "$answer" == "y" ]] || [[ "$answer" == "Y" ]] || [[ "$answer" == "yes" ]] || [[ "$answer" == "YES" ]]; then
		echo "ok, saving this email."
		echo "$EMAIL" > $DIR/email
		touch $DIR/box86-2deb-weekly_log.log
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
	EMAIL="$(cat $DIR/email)"
fi
#define the gpg key password variable
if [[ ! -f "$DIR/gpgpass" ]]; then
	echo -e "$(tput setaf 6)$(tput bold)enter your gpg key password:$(tput sgr 0)"
	read GPGPASS
	while true; do
	echo "Do you want to save this gpg key password? (y/n)"
	read answer
	if [[ "$answer" == "y" ]] || [[ "$answer" == "Y" ]] || [[ "$answer" == "yes" ]] || [[ "$answer" == "YES" ]]; then
		echo "ok, saving this password."
		echo "$GPGPASS" > $DIR/gpgpass
		touch $DIR/box86-2deb-weekly_log.log
		echo "[ $(date) ] saved gpg key password." >> $DIR/box86-2deb-weekly_log.log
		break
	elif [[ "$answer" == "n" ]] || [[ "$answer" == "N" ]] || [[ "$answer" == "no" ]] || [[ "$answer" == "NO" ]]; then
		echo "ok, won't save this password."
		break
	else
		echo -e "$(tput setaf 3)invalid option '$answer'$(tput sgr 0)"
	fi

	done
else
	GPGPASS="$(cat $DIR/gpgpass)"
fi

function error() {
	echo -e "\e[91m$1\e[39m"
	echo "[ $(date) ] | ERROR | $1" >> $DIR/box86-2deb-weekly_log.log
	exit 1
}

function warning() {
	echo -e "$(tput setaf 3)$(tput bold)$1$(tput sgr 0)"
	echo "[ $(date) ] | WARNING | $1" >> $DIR/box86-2deb-weekly_log.log
}

#compile box86 function
function compile-box86(){
	echo "compiling box86..."
	cd ~/Documents/box86-auto-build || error "Failed to change directory! (line 71)"
	git clone https://github.com/ptitSeb/box86 || error "Failed to git clone box86 repo! (line 72)"
	cd box86 || error "Failed to change directory! (line 73)"
	mkdir build; cd build; cmake .. -DRPI4=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo || error "Failed to run cmake! (line 74)"
	make -j4 || error "Failed to run make! (line 75)"
	#get current directory path
	BUILDDIR="$(pwd)" || error "Failed to set BUILDDIR variable! (line 77)"
}

#get just compiled (not installed) box86 version
#USAGE: get-box86-version <option>
#OPTIONS: ver = box86 version (example: 0.2.1); commit: box86 commit (example: db176ad3).
function get-box86-version() {
	if [[ $1 == "ver" ]]; then
		BOX86VER="$(./box86 -v | cut -c21-25)"
	elif [[ $1 == "commit" ]]; then
		BOX86COMMIT="$(./box86 -v | cut -c27-34)"
	fi
}

#package box86 into a deb using checkinstall function
function package-box86() {
	cd $BUILDDIR || error "Failed to change directory to $BUILDDIR! (line 93)"
	#create the doc-pak directory and copy to it the readme, usage, changelog and license.
	#this will go in /usr/doc/box86 when the deb is installed.
	mkdir doc-pak || error "Failed to create doc-pak! (line 96)"
	cp $DIR/box86/docs/README.md $BUILDDIR/doc-pak || error "Failed to copy README.md to doc-pak! (line 97)"
	cp $DIR/box86/docs/CHANGELOG.md $BUILDDIR/doc-pak || error "Failed to copy CHANGELOG.md to doc-pak! (line 98)"
	cp $DIR/box86/docs/USAGE.md $BUILDDIR/doc-pak || error "Failed to copy USAGE.md to doc-pak! (line 99)"
	cp $DIR/box86/LICENSE $BUILDDIR/doc-pak || error "Failed to copy LICENSE to doc-pak! (line 100)"
	cp $DIR/box86/docs/X86WINE.md $BUILDDIR/doc-pak || error "Failed to copy X86WINE.md to doc-pak! (line 101)"
	#create description-pak.
	#checkinstall will use this for the deb's control file description and summary entries.
	echo "Linux Userspace x86 Emulator with a twist.

	Box86 lets you run x86 Linux programs (such as games)
	on non-x86 Linux, like ARM 
	(host system needs to be 32bit little-endian. 
	64bit ARM works with mutliarch or chroot).">description-pak || error "Failed to create description-pak! (line 108)"
	echo "#!/bin/bash
	KARCH=$(uname -m)
	if [ "$KARCH" = "aarch64" ] || [ "$KARCH" = "aarch64-linux-gnu" ] || [ "$KARCH" = "arm64" ] || [ "$KARCH" = "aarch64_be" ]; then
		echo -e \"\e[1;31mDetected an ARM processor running in 64-bit mode.\nInstalling multiarch armhf library for box86.\e[0m\"
		sudo dpkg --add-architecture armhf && sudo apt-get update
		sudo apt-get install libc6:armhf -y # needed to run box86:armhf on aarch64
	fi
	echo 'restarting systemd-binfmt...'
	if ! systemctl restart systemd-binfmt ; then
		echo -e \"\e[1;31mFailed to restart systemd-binfmt! box86 won't get called automatically.\nrebooting might help.\e[0m\"
	fi
	">postinstall-pak || error "Failed to create postinstall-pak! (line 114)"
	
	#get the just compiled box86 version using the get-box86-version function.
	get-box86-version ver  || error "Failed to get box86 version! (line 117)"
	get-box86-version commit || error "Failed to get box86 commit (sha1)! (line 118)"
	DEBVER="$(echo "$BOX86VER+$(date +"%F" | sed 's/-//g').$BOX86COMMIT")" || error "Failed to generate box86 version for the deb! (line 119)"
	#use checkinstall to package box86 into a deb.
	#all the options are so checkinstall doesn't ask any questions but still has the data it needs.
	sudo checkinstall -y -D --pkgversion="$DEBVER" --provides="box86" --conflicts="qemu-user-static" --pkgname="box86" --install="no" make install || error "Failed to run checkinstall! (line 122)"
}

function clean-up() {
	#current date in YY/MM/DD format
	NOWDAY="$(printf '%(%Y-%m-%d)T\n' -1)" || error 'Failed to get current date! (line 127)'
	#make a folder with the name of the current date (YY/MM/DD format)
	mkdir -p $DEBDIR/$NOWDAY || error "Failed to create folder for deb! (line 129)"
	#make a file with the current sha1 (commit) of the box86 version just compiled.
	echo $BOX86COMMIT > $DEBDIR/$NOWDAY/sha1.txt || error "Failed to write box86 commit (sha1) to sha1.txt! (line 131)"
	#move the deb to the directory for the debs. if it fails, try again as root
	mv box86*.deb $DEBDIR/$NOWDAY || sudo mv box86*.deb $DEBDIR/$NOWDAY || error "Failed to move deb! (line 133)"
	#remove the home directory from the deb
	cd $DEBDIR/$NOWDAY || error "Failed to change directory to $DEBDIR/$NOWDAY! (line 135)"
	FILE="$(basename *.deb)" || error "Failed to get deb filename! (line 136)"
	FILEDIR="$(echo $FILE | cut -c1-28)" || error "Failed to generate name for directory for the deb! (line 137)"
	dpkg-deb -R $FILE $FILEDIR || error "Failed to extract the deb! (line 138)"
	rm -r $FILEDIR/home || warning "Failed to remove home folder from deb! (line 139)"
	#cd $FILEDIR/usr || error "Failed to cd into '$FILEDIR/usr/'! (line 140)"
	#mv local/bin/ . || error "Failed to move 'bin' to '.'! (line 141)"
	#rm -r local/ || error "Failed to remove 'local'! (line 142)"
	#cd ../../ || error "Failed to go 2 directories up! (line 143)"
	rm -f $FILE || error "Failed to remove old deb! (line 144)"
	dpkg-deb -b $FILEDIR $FILE || error "Failed to repack the deb! (line 145)"
	rm -r $FILEDIR || error "Failed to remove temporary deb directory! (line 146)"
	cd $DEBDIR || error "Failed to change directory to $DEBDIR! (line 147)"
	#compress the folder with the deb and sha1.txt into a tar.xz archive
	tar -cJf $NOWDAY.tar.xz $NOWDAY/ || error "Failed to compress today's build into a tar.xz archive! (line 149)"
	#remove the box86 folder
	cd $DIR || error "Failed to change directory to $DIR! (line 151)"
	sudo rm -rf box86 || error "Failed to remove box86 folder! (line 152)"
}

function upload-deb() {
	#copy the new deb and tar.xz
	cp $DEBDIR/$NOWDAY/box86*.deb $HOME/Documents/weekly-box86-debs/debian/pool/ || error "Failed to copy new deb! (line 157)"
	cp $DEBDIR/$NOWDAY.tar.xz $HOME/Documents/weekly-box86-debs/debian/source/$NOWDAY.tar.xz || error "Failed to copy new tar.xz archive! (line 158)"
	#remove apt files
	rm $HOME/Documents/weekly-box86-debs/debian/Packages || warning "Failed to remove old 'Packages' file! (line 160)"
	rm $HOME/Documents/weekly-box86-debs/debian/Packages.gz || warning "Failed to remove old 'Packages.gz' archive! (line 161)"
	rm $HOME/Documents/weekly-box86-debs/debian/Release || warning "Failed to remove old 'Release' file! (line 162)"
	rm $HOME/Documents/weekly-box86-debs/debian/Release.gpg || warning "Failed to remove old 'Release.gpg' file! (line 163)"
	rm $HOME/Documents/weekly-box86-debs/debian/InRelease || warning "Failed to remove old 'InRelease' file! (line 164)"
	#create new apt files
	cd $HOME/Documents/weekly-box86-debs/debian/ || error "Failed to change directory! (line 166)"
	#create 'Packages' and 'Packages.gz'
	dpkg-scanpackages --multiversion . > Packages || error "Failed to create new 'Packages' file! (line 168)"
	gzip -k -f Packages || error "Failed to create new 'Packages.gz' file! (line 169)"
	#Release, Release.gpg, InRelease
	cp $HOME/Documents/box86-2deb-weekly-script/Release-template $HOME/Documents/weekly-box86-debs/debian/Release || error "Failed to copy Release file! (line 171)"
	#touch Release
	#echo -e "\nDate: `LANG=C date -Ru`" >> Release || error "Failed to write date to 'Release' file (line 173)"
	#echo -e 'MD5Sum:' >> Release || error "Failed to write 'MD5Sum:' to 'Release'! (line 174)"
	#printf ' '$(md5sum Packages.gz | cut --delimiter=' ' --fields=1)' %16d Packages.gz' $(wc --bytes Packages.gz | cut --delimiter=' ' --fields=1) >> Release || error "Failed to write md5sums to 'Release'! (line 175)"
	#printf '\n '$(md5sum Packages | cut --delimiter=' ' --fields=1)' %16d Packages' $(wc --bytes Packages | cut --delimiter=' ' --fields=1) >> Release || error "Failed to write md5sums to 'Release'! (line 176)"
	#echo -e '\nSHA256:' >> Release || error "Failed to write 'SHA256:' to 'Release'! (line 177)"
	#printf ' '$(sha256sum Packages.gz | cut --delimiter=' ' --fields=1)' %16d Packages.gz' $(wc --bytes Packages.gz | cut --delimiter=' ' --fields=1) >> Release || error "Failed to write sha256sums to 'Release'! (line 178)"
	#printf '\n '$(sha256sum Packages | cut --delimiter=' ' --fields=1)' %16d Packages' $(wc --bytes Packages | cut --delimiter=' ' --fields=1) >> Release || error "Failed to write sha256sums to 'Release'! (line 179)"
	echo -e "\n$(apt-ftparchive release .)" >> Release
	gpg --default-key "${EMAIL}" --batch --pinentry-mode="loopback" --passphrase="$GPGPASS" -abs -o - Release > Release.gpg
	gpg --default-key "${EMAIL}" --batch --pinentry-mode="loopback" --passphrase="$GPGPASS" --clearsign -o - Release > InRelease
	cd .. || error "Failed to move one directory up! (line 183)"
	git fetch || error "Failed to run 'git fetch'! (line 184)"
	git pull || error "Failed to run 'git pull'! (line 185)"
	git stage debian/ || error "Failed to stage 'debs/'! (line 186)"
	echo "updated box86 to commit $BOX86COMMIT, version $BOX86VER" > commit.txt || error "Failed to create file with commit message! (line 187)"
	git commit --file=commit.txt || error "Failed to commit new deb! (line 188)"
	git push || error "Failed to run 'git push'! (line 189)"
	rm -f commit.txt || error "Failed to remove commit message file! (line 190)"
	cd $DIR || error "Failed to change directory to $DIR! (line 191)"
}

# Run everything #
echo "compile time!"
compile-box86 || error "Failed to run compile-box86 function! (line 196)"
package-box86 || error "Failed to run package-box86 function! (line 197)"
clean-up || error "Failed to run clean-up function! (line 198)"
#clear the screen (scrolling up)
clear -x
#write to the log file that build and packaging are complete
touch box86-2deb-weekly_log.log
TIME="$(date)"
echo "
=============================
$TIME
=============================" >> box86-2deb-weekly_log.log
NOWTIME="$(date +"%T")"
echo "[$NOWTIME | $NOWDAY] build and packaging complete." >> box86-2deb-weekly_log.log
upload-deb || error "Failed to upload deb! (line 210)"
#write to log that uploading is complete
NOWTIME="$(date +"%T")"
echo "[$NOWTIME | $NOWDAY] uploading complete." >> box86-2deb-weekly_log.log

