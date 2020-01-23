#!/bin/bash
####################
#
# Variables
#
####################

primary_packages="zsh git curl wget vim neovim python python-pip python-pynvim gcc ruby"
i3_packages="polybar i3-gaps i3lock cairo libxcb xcb-proto xcb-util-image xcb-util-wm xcb-util-xrm alsa-lib wireless_tools rofi"


####################
#
# Installing required packages
#
####################

echo "Do you want to install packages? [yes or no]"
read package_answer
if [[ $package_answer == "yes" ]] || [[ $package_answer == "y" ]]; then
	echo "Do you want i3 and i3-related packages to be installed? [yes or no]"
	read i3_answer
	platform=$(uname);
	# If the platform is Linux, try an apt-get to install zsh and then recurse
	if [[ $platform == 'Linux' ]]; then
		if [[ -f /bin/pacman ]]; then
			sudo pacman -S --needed $primary_packages
 	 		if [[ $i3_answer == "yes" ]] || [[ $i3_answer == "y" ]]; then
				sudo pacman -S --needed $i3_packages
			fi
		fi
 		if [[ -f /bin/apt ]]; then
			for package in $primary_packages; do
				sudo apt install $package
			done
			if [[ $i3_answer == "yes" ]] || [[ $i3_answer == "y" ]]; then
				for package in $i3_packages; do
					sudo apt install $package
				done
			fi
		fi
	fi
fi


