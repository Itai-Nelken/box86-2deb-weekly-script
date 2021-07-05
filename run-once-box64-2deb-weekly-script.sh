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
		touch $DIR/box64-2deb-weekly_log.log
		echo "[ $(date) ] saved email ($EMAIL)." >> $DIR/box64-2deb-weekly_log.log
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
		touch $DIR/box64-2deb-weekly_log.log
		echo "[ $(date) ] saved gpg key password." >> $DIR/box64-2deb-weekly_log.log
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
    echo "[ $(date) ] | ERROR | $1" >> $DIR/box64-2deb-weekly_log.log
	exit 1
 	break
}

function warning() {
	echo -e "$(tput setaf 3)$(tput bold)$1$(tput sgr 0)"
    echo "[ $(date) ] | WARNING | $1" >> $DIR/box64-2deb-weekly_log.log
}

#compile box86 function
function compile-box64(){
	echo "compiling box64..."
	cd ~/Documents/box86-auto-build || error "Failed to change directory! (line 71)"
	git clone https://github.com/ptitSeb/box64 || error "Failed to git clone box86 repo! (line 72)"
	cd box64 || error "Failed to change directory! (line 73)"
	mkdir build; cd build; cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DARM_DYNAREC=1 || error "Failed to run cmake! (line 74)"
	make -j4 || error "Failed to run make! (line 75)"
	#get current directory path
	BUILDDIR="$(pwd)" || error "Failed to set BUILDDIR variable! (line 77)"
}

#get just compiled (not installed) box86 version
#USAGE: get-box64-version <option>
#OPTIONS: ver = box64 version (example: 0.2.1); commit: box64 commit (example: db176ad3).
function get-box64-version() {
	if [[ $1 == "ver" ]]; then
		BOX64VER="$(./box64 -v | cut -c21-25)"
	elif [[ $1 == "commit" ]]; then
		BOX64COMMIT="$(./box64 -v | cut -c27-34)"
	fi
}

#package box86 into a deb using checkinstall function
function package-box64() {
	cd $BUILDDIR || error "Failed to change directory to $BUILDDIR! (line 93)"
	#create the doc-pak directory and copy to it the readme, usage, changelog and license.
	#this will go in /usr/doc/box86 when the deb is installed.
	mkdir doc-pak || error "Failed to create doc-pak! (line 96)"
	cp $DIR/box64/README.md $BUILDDIR/doc-pak || error "Failed to copy README.md to doc-pak! (line 97)"
	cp $DIR/box64/CHANGELOG.md $BUILDDIR/doc-pak || error "Failed to copy CHANGELOG.md to doc-pak! (line 98)"
	cp $DIR/box64/USAGE.md $BUILDDIR/doc-pak || error "Failed to copy USAGE.md to doc-pak! (line 99)"
	cp $DIR/box64/LICENSE $BUILDDIR/doc-pak || error "Failed to copy LICENSE to doc-pak! (line 100)"
	
	#create description-pak.
	#checkinstall will use this for the deb's control file description and summary entries.
	echo "Box64 lets you run x86_64 Linux programs (such as games) on non-x86_64 Linux systems, like ARM (host system needs to be 64bit little-endian)">description-pak || error "Failed to create description-pak! (line 104)"
	echo "#!/bin/bash
	echo 'restarting systemd-binfmt...'
	systemctl restart systemd-binfmt">postinstall-pak || error "Failed to create postinstall-pak! (line 107)"
	
	#get the just compiled box86 version using the get-box64-version function.
	get-box64-version ver  || error "Failed to get box86 version! (line 110)"
	get-box64-version commit || error "Failed to get box86 commit (sha1)! (line 111)"
	DEBVER="$(echo "$BOX64VER+$(date +"%F" | sed 's/-//g').$BOX64COMMIT")" || error "Failed to generate box86 version for the deb! (line 112)"
	#use checkinstall to package box86 into a deb.
	#all the options are so checkinstall doesn't ask any questions but still has the data it needs.
	sudo checkinstall -y -D --pkgversion="$DEBVER" --arch="arm64" --provides="box64" --conflicts="qemu-user-static" --pkgname="box64" --install="no" make install || error "Failed to run checkinstall! (line 115)"
}

function clean-up() {
	#current date in YY/MM/DD format
	NOWDAY="$(printf '%(%Y-%m-%d)T\n' -1)" || error 'Failed to get current date! (line 124)'
	#make a folder with the name of the current date (YY/MM/DD format)
	mkdir -p $DEBDIR/box64-$NOWDAY || error "Failed to create folder for deb! (line 126)"
	#make a file with the current sha1 (commit) of the box86 version just compiled.
	echo $BOX64COMMIT > $DEBDIR/box64-$NOWDAY/sha1.txt || error "Failed to write box86 commit (sha1) to sha1.txt! (line 128)"
	#move the deb to the directory for the debs. if it fails, try again as root
	mv box86*.deb $DEBDIR/box64-$NOWDAY || sudo mv box64*.deb $DEBDIR/box64-$NOWDAY || error "Failed to move deb! (line 130)"
	#remove the home directory from the deb
	cd $DEBDIR/box64-$NOWDAY || error "Failed to change directory to $DEBDIR/box64-$NOWDAY! (line 132)"
	FILE="$(basename *.deb)" || error "Failed to get deb filename! (line 133)"
	FILEDIR="$(echo $FILE | cut -c1-28)" || error "Failed to generate name for directory for the deb! (line 134)"
	dpkg-deb -R $FILE $FILEDIR || error "Failed to extract the deb! (line 135)"
	rm -r $FILEDIR/home || warning "Failed to remove home folder from deb! (line 136)"
	#cd $FILEDIR/usr || error "Failed to cd into '$FILEDIR/usr/'! (line 137)"
	#mv local/bin/ . || error "Failed to move 'bin' to '.'! (line 138)"
	#rm -r local/ || error "Failed to remove 'local'! (line 13)"
	#cd ../../ || error "Failed to go 2 directories up! (line 140)"
	rm -f $FILE || error "Failed to remove old deb! (line 141)"
	dpkg-deb -b $FILEDIR $FILE || error "Failed to repack the deb! (line 142)"
	rm -r $FILEDIR || error "Failed to remove temporary deb directory! (line 143)"
	cd $DEBDIR || error "Failed to change directory to $DEBDIR! (line 144)"
	#compress the folder with the deb and sha1.txt into a tar.xz archive
	tar -cJf box64-$NOWDAY.tar.xz box64-$NOWDAY/ || error "Failed to compress today's build into a tar.xz archive! (line 146)"
	#remove the box86 folder
	cd $DIR || error "Failed to change directory to $DIR! (line 148)"
	sudo rm -rf box64 || error "Failed to remove box86 folder! (line 149)"
}

function upload-deb() {
	#copy the new deb and tar.xz
	cp $DEBDIR/$NOWDAY/box64*.deb $HOME/Documents/weekly-box86-debs/debian/pool/ || error "Failed to copy new deb! (line 154)"
	cp $DEBDIR/$NOWDAY.tar.xz $HOME/Documents/weekly-box86-debs/debian/source/$NOWDAY.tar.xz || error "Failed to copy new tar.xz archive! (line 155)"
	#remove apt files
	rm $HOME/Documents/weekly-box86-debs/debian/Packages || warning "Failed to remove old 'Packages' file! (line 157)"
	rm $HOME/Documents/weekly-box86-debs/debian/Packages.gz || warning "Failed to remove old 'Packages.gz' archive! (line 158)"
	rm $HOME/Documents/weekly-box86-debs/debian/Release || warning "Failed to remove old 'Release' file! (line 159)"
	rm $HOME/Documents/weekly-box86-debs/debian/Release.gpg || warning "Failed to remove old 'Release.gpg' file! (line 15960)"
	rm $HOME/Documents/weekly-box86-debs/debian/InRelease || warning "Failed to remove old 'InRelease' file! (line 161)"
	#create new apt files
	cd $HOME/Documents/weekly-box86-debs/debian/ || error "Failed to change directory! (line 163)"
	#create 'Packages' and 'Packages.gz'
	dpkg-scanpackages --multiversion . > Packages || error "Failed to create new 'Packages' file! (line 165)"
	gzip -k -f Packages || error "Failed to create new 'Packages.gz' file! (line 166)"
	#Release, Release.gpg, InRelease
	cp $HOME/Documents/box86-2deb-weekly-script/Release-template $HOME/Documents/weekly-box86-debs/debian/Release || error "Failed to copy Release file! (line 168)"
	#touch Release
	#echo -e "\nDate: `LANG=C date -Ru`" >> Release || error "Failed to write date to 'Release' file (line 164)"
	#echo -e 'MD5Sum:' >> Release || error "Failed to write 'MD5Sum:' to 'Release'! (line 165)"
	#printf ' '$(md5sum Packages.gz | cut --delimiter=' ' --fields=1)' %16d Packages.gz' $(wc --bytes Packages.gz | cut --delimiter=' ' --fields=1) >> Release || error "Failed to write md5sums to 'Release'! (line 166)"
	#printf '\n '$(md5sum Packages | cut --delimiter=' ' --fields=1)' %16d Packages' $(wc --bytes Packages | cut --delimiter=' ' --fields=1) >> Release || error "Failed to write md5sums to 'Release'! (line 167)"
	#echo -e '\nSHA256:' >> Release || error "Failed to write 'SHA256:' to 'Release'! (line 168)"
	#printf ' '$(sha256sum Packages.gz | cut --delimiter=' ' --fields=1)' %16d Packages.gz' $(wc --bytes Packages.gz | cut --delimiter=' ' --fields=1) >> Release || error "Failed to write sha256sums to 'Release'! (line 121)"
	#printf '\n '$(sha256sum Packages | cut --delimiter=' ' --fields=1)' %16d Packages' $(wc --bytes Packages | cut --delimiter=' ' --fields=1) >> Release || error "Failed to write sha256sums to 'Release'! (line 122)"
	echo -e "\n$(apt-ftparchive release .)" >> Release
	gpg --default-key "${EMAIL}" --batch --pinentry-mode="loopback" --passphrase="$GPGPASS" -abs -o - Release > Release.gpg
	gpg --default-key "${EMAIL}" --batch --pinentry-mode="loopback" --passphrase="$GPGPASS" --clearsign -o - Release > InRelease
	cd .. || error "Failed to move one directory up! (line 180)"
	git fetch || error "Failed to run 'git fetch'! (line 181)"
	git pull || error "Failed to run 'git pull'! (line 182)"
	git stage debian/ || error "Failed to stage 'debs/'! (line 183)"
	echo "updated box64 to commit $BOX64COMMIT, version $BOX64VER" > commit.txt || error "Failed to create file with commit message! (line 184)"
	git commit --file=commit.txt || error "Failed to commit new deb! (line 185)"
	git push || error "Failed to run 'git push'! (line 186)"
	rm -f commit.txt || error "Failed to remove commit message file! (line 187)"
	cd $DIR || error "Failed to change directory to $DIR! (line 188)"
}

# Run everything #
echo "compile time!"
compile-box64 || error "Failed to run compile-box64 function! (line 204)"
package-box64 || error "Failed to run package-box64 function! (line 205)"
clean-up || error "Failed to run clean-up function! (line 206)"
#clear the screen (scrolling up)
clear -x
#write to the log file that build and packaging are complete
touch box64-2deb-weekly_log.log
TIME="$(date)"
echo "
=============================
$TIME
=============================" >> box64-2deb-weekly_log.log
NOWTIME="$(date +"%T")"
echo "[$NOWTIME | $NOWDAY] build and packaging complete." >> box64-2deb-weekly_log.log
upload-deb || error "Failed to upload deb! (line 217)"
#write to log that uploading is complete
NOWTIME="$(date +"%T")"
echo "[$NOWTIME | $NOWDAY] uploading complete." >> box64-2deb-weekly_log.log
