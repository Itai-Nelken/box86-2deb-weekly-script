#!/bin/bash

function error() {
	echo -e "\e[91m$1\e[39m"
 	exit 1
}

DIR="`pwd`"

#check that OS arch is armhf
ARCH="`uname -m`"
if [[ $ARCH == "armv7l" ]] || [[ $ARCH == "arm64" ]] || [[ $ARCH == "aarch64" ]]; then
    if [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 64)" ];then
        error "This script doesn't work on arm64!"
    elif [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 32)" ];then
        echo -e "arch is armhf/armv7l $(tput setaf 2)✔︎$(tput sgr 0)"
    else
        error "Failed to detect OS CPU architecture! Something is very wrong."
    fi
fi

#check that checkinstall is installed
if ! command -v checkinstall &>/dev/null; then
	echo -e "checkinstall is installed $(tput setaf 2)✔︎$(tput sgr 0)"
else
    read -p "checkinstall is required but not installed, do you want to install it? (y/n)?" choice
    case "$choice" in 
    y|Y|yes ) check=1;;
    n|N|no ) echo "can't continue without checkinstall! exiting in 10 seconds"; sleep 10; exit 1;;
    * ) echo "invalid";;
    esac
fi
if [[ $check == "1" ]]; then
    wget https://archive.org/download/macos_921_qemu_rpi/checkinstall_20210123-1_armhf.deb
    sudo apt -f -y install checkinstall_20210123-1_armhf.deb
    rm -f checkinstall_20210123-1_armhf.deb
fi
if [[ -x "$DIR/box86-2deb-auto.sh" ]]; then
	echo -e "script is executable $(tput setaf 2)✔︎$(tput sgr 0)"
else
	echo -e "script isn't executable! $(tput setaf 1)❌$(tput sgr 0)"
	echo "making script executable..."
	sudo chmod +x box86-2deb-auto.sh || error "Failed to mark script as executable!"
	echo -e "done! $(tput setaf 2)✔︎$(tput sgr 0)"
fi
./box86-2deb-auto.sh || error "Failed to start script!"
