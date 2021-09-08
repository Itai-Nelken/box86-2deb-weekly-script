#!/bin/bash
STARTDIR="$(pwd)"
DIR="$HOME/Documents/box86-auto-build"
DEBDIR="$DIR/debs"
BUILDDIR=""
NOWDIR=""
FILEDIR=""
REPODIR="$HOME/Documents/weekly-box86-debs"
EMAIL="$(cat $DIR/email)"
GPGPASS="$(cat $DIR/gpgpass)"
LOG="$DIR/box64-2deb-weekly_log.log"
BOX64VER=""
BOX64COMMIT=""
DEBVER=""
NOWDAY=""
DEB=""
TIME=""
NOWTIME=""

function error() {
	echo "[$(date)] | ERROR | $@" >> $LOG
	exit 1
}
function warning() {
		echo "[$(date)] | WARNING | $@" >> $LOG
}

TIME="$(date)"
echo "
=============================
$TIME
=============================" >> $LOG
#cd $DIR
#git clone https://github.com/ptitseb/box64.git || error "failed to clone repository"
#cd box64 || error "failed to enter box64 folder"
#mkdir build || error "failed to create build folder"
#cd build || error "Failed to enter build folder"
#cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DARM_DYNAREC=1 .. || error "Failed to run cmake"
#make -j4
ds64-run $STARTDIR/build-64.sh
cd $DIR
#BUILDDIR="$(pwd)"
BUILDDIR="$DIR/box64/build"
cd $BUILDDIR
mkdir doc-pak || error "failed to create doc-pak folder"
cp $DIR/box64/docs/README.md doc-pak/ || error "Failed to copy readme to doc-pak"
cp $DIR/box64/docs/CHANGELOG.md doc-pak/ || error "Failed to copy changelog to doc-pak"
cp $DIR/box64/docs/USAGE.md doc-pak/ || error "Failed to copy usage to doc-pak"
cp $DIR/box64/LICENSE doc-pak/ || error "Failed to copy license to doc-pak"
echo "Box64 lets you run x86_64 Linux programs (such as games) on non-x86_64 Linux systems, like ARM (host system needs to be 64bit little-endian)">description-pak || error "Failed to create description-pak"
BOX64VER="$(./box64 -v | cut -c21-25)" || error "Failed to get box64 version"
BOX64COMMIT="$(./box64 -v | cut -c27-34 | sed 's/ //g')" || error "Failed to get box64 commit"
DEBVER="$(echo "$BOX64VER+$(date +"%F" | sed 's/-//g').$BOX64COMMIT")" || error "Failed to generate the deb version"
sudo checkinstall -y -D --pkgversion="$DEBVER" --arch="arm64" --provides="box64" --conflicts="qemu-user-static" --pkgname="box64" --install="no" make install || error "Failed to run checkinstall"
DEB="$(pwd)/$(basename box64*.deb)" || error "Failed to get deb name"
NOWDAY="$(printf '%(%Y-%m-%d)T\n' -1)" || error "failed to get current date!"
NOWDIR="$DEBDIR/box64-$NOWDAY" || error "Failed to generate new build foldername "
mkdir -p $NOWDIR || error "Failed to create new build folder"
echo "$BOX64COMMIT" > $NOWDIR/sha1.txt || error "Failed to generate sha1.txt"
FILEDIR="$(echo $DEB | sed 's/.deb//g')" || error "Failed to get deb name with no file extension"
dpkg-deb -R $DEB $FILEDIR || error "Failed to extract deb"
sudo rm -r $FILEDIR/home || warning "failed to remove home folder from deb (ignore)"
sudo rm $DEB || error "failed to delete old deb"
dpkg-deb -b $FILEDIR $DEB || error "failed to repack deb"
chmod 777 $DEB || error "Failed to change the debs permisions"
rm -r $FILEDIR || error "Failed to delete unpacked deb"
sudo cp $DEB $NOWDIR || error "Failed to move deb to new build folder"
DEB="$NOWDIR/$(basename $DEB)"
cd $DEBDIR || error "Failed to enter $DEBDIR"
tar -cJf box64-$NOWDAY.tar.xz $NOWDIR/ || error "Failed to tar new build folder"
cd $DIR || error "Failed to enter $DIR"
sudo rm -rf box86 || error "Failed to remove box86 folder"
clear -x
touch $LOG || warning "Failed to update log!"
NOWTIME="$(date +"%T")"
echo "[$NOWTIME | $NOWDAY] build and packaging complete" >> $LOG
cp $DEB $REPODIR/debian/pool/ || error "Failed to copy deb to repo"
cp $(dirname $NOWDIR)/box64-$NOWDAY.tar.xz $REPODIR/debian/source/ || error "Failed to copy box64-$NOWDAY.tar.xz to repo"
rm $REPODIR/debian/Packages || warning "Failed to remove old 'Packages' file"
rm $REPODIR/debian/Packages.gz || warning "Failed to remove old 'Packages.gz' file"
rm $REPODIR/debian/Release || warning "Failed to remove old 'Release' file"
rm $REPODIR/debian/Release.gpg || warning "Failed to remove old 'Release.gpg' file"
rm $REPODIR/debian/InRelease || warning "Failed to remove old 'InRelease' file"
cd $REPODIR/debian || error "Failed to enter $REPODIR/debian"
dpkg-scanpackages --multiversion . > Packages || error "Failed to create new 'Packages' file"
gzip -k -f Packages || error "Failed to create new 'Packages.gz' file"
cp $STARTDIR/Release-template $REPODIR/debian/Release || error "Failed to copy 'Release' file"
echo -e "\n$(apt-ftparchive release .)" >> Release
gpg --default-key "${EMAIL}" --batch --pinentry-mode="loopback" --passphrase="$GPGPASS" -abs -o - Release > Release.gpg
gpg --default-key "${EMAIL}" --batch --pinentry-mode="loopback" --passphrase="$GPGPASS" --clearsign -o - Release > InRelease
cd $REPODIR
git fetch
git pull
git stage debian/
git commit -m "updated box64 to commit $BOX64COMMIT, version $BOX64VER"
git push
cd $DIR
rm -rf box64
NOWTIME="$(date +"%T")"
echo "[$NOWTIME | $NOWDAY] uploading complete." >> $LOG

