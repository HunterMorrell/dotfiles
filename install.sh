#!/bin/sh
####################
#
# Variables
#
####################

repos_dir=~/repos/
dotfiles_dir=~/repos/dotfiles
primary_packages="zsh firefox git curl wget vim neovim python python-pip python-pynvim gcc ruby termite"
i3_packages="polybar i3-gaps i3lock cairo libxcb xcb-proto xcb-util-image xcb-util-wm xcb-util-xrm alsa-lib wireless_tools rofi"


####################
#
# You have some choices to make...
#
####################

# echo "How much information do you want? Choose one of the following numbers:"
# echo "1) Full               - Give me all the details."
# echo "2) Moderate (Default) - I just want to know my options and what you're doing."
# echo "3) Minimal            - Give me errors or give me death."
# echo "4) None               - No customization. Just run the script already."
# read -p "Answer (1-4): " verbose_answer

# while [ $verbose_answer -lt 1 -o $verbose_answer -gt 4 ]; do
#   echo ""
#   echo "Whatever you wrote doesn't match the choices. Try again. Use a number between 1-4."
#   read verbose_answer
# done

# echo ""

#echo "Do you want the full install or would you like customization options? [full\\options]"
#read $install_answer


####################
#
# Installing required packages
#
####################

echo "Do you want to install packages?"
read -p "Answer (yes or no): " package_answer
if [[ $package_answer == "yes" ]] || [[ $package_answer == "y" ]]; then
  echo "Do you want i3 and i3-related packages to be installed?"
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

echo ""

####################
#
# Setting up SSH Keys
#
####################

echo "Open another terminal and create your SSH key (if you already have, just ignore this) with: ssh-keygen -t rsa -b 4096 -C \"your_email@example.com\""
echo "Don't forget to add it to Github! Press <ENTER> to continue once this has been done."
read -p "Answer (yes or no): " pass_answer

echo ""

####################
#
# Setting up SSH-Ident
#
####################

echo "Do you want to use SSH-Ident (github.com/ccontavalli/ssh-ident) to manage your SSH logins?"
read -p "Answer (yes or no): " ssh_answer
if [[ $ssh_answer == "yes" ]] || [[ $ssh_answer == "y" ]]; then
	wget -O ~/ssh https://raw.githubusercontent.com/ccontavalli/ssh-ident/master/ssh-ident; chmod 0755 ~/ssh; sudo mv ~/ssh /usr/local/bin
fi

echo ""


####################
#
# Creating directory structure
#
####################

echo "Creating directory structure"
mkdir $repos_dir

echo ""


####################
#
# Cloning and installing repos
#
####################

echo "Cloning and installing repos"
cd $repos_dir

echo "Do you want to install Nerd Fonts (github.com/ryanoasis/nerd-fonts)?"
echo "Warning: This is a large download and might take a while."
read -p "Answer (yes or no): " fonts_answer
if [[ $fonts_answer == "yes" ]] || [[ $fonts_answer == "y" ]]; then
	git clone git@github.com:ryanoasis/nerd-fonts.git
	./nerd-fonts/install.sh
fi

echo "Do you want to install dotfiles?"
read -p "Answer (yes or no): " dotfiles_answer
if [[ $dotfiles_answer == "yes" ]] || [[ $dotfiles_answer == "y" ]]; then
	git clone --recurse-submodules git@github.com:HunterMorrell/dotfiles.git
  cd ./dotfiles
  # Iterates recursively through all submodules and checkouts the master branch
  # Default status is detached HEAD at a static commit, so this resolves that
  git submodule foreach --recursive git checkout master
fi

gem install colorls

#echo "light"
#git clone git@github.com:haikarainen/light.git

#echo "UserCSS-Styles"
#git clone git@github.com:HunterMorrell/UserCSS-Styles.git

#echo "polybar"
#git clone --recursive https://github.com/polybar/polybar
#cd polybar
#sudo ./build.sh

echo ""


####################
#
# Configuring ZSH
#
####################

echo "Do you want to install and configure ZSH with Oh-My-ZSH?"
read -p "Answer (yes or no): " zsh_answer
if [[ $zsh_answer == "yes" ]] || [[ $zsh_answer == "y" ]]; then
	echo "Once this finishes, it might put you in a new shell. If you see a prompt and the script doesn't continue, just enter 'exit' (without the single quotes) and hit enter. Press any key and enter to continue."
	read null_answer
	# Test to see if zshell is installed.  If it is:
	if [[ -f /bin/zsh ]] || [[ -f /usr/bin/zsh ]]; then
    		# Clone my oh-my-zsh repository from GitHub only if it isn't already present
    		if [[ ! -d $dir/oh-my-zsh/ ]]; then
        		sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
    		fi
    		# Set the default shell to zsh if it isn't currently set to zsh
    		if [[ ! $(echo $SHELL) == $(which zsh) ]]; then
        		chsh -s $(which zsh)
    		fi
	else
	    	# If zsh isn't installed, get the platform of the current machine
    		platform=$(uname);
    		# If the platform is Linux, try an apt-get to install zsh and then recurse
    		if [[ $platform == 'Linux' ]]; then
        		if [[ -f /etc/redhat-release ]]; then
            			sudo dnf -y install zsh
        		fi
        		if [[ -f /etc/debian_version ]]; then
            			sudo apt -y install zsh
       			fi
    		fi
	fi
fi

echo ""


###################
#
# Symlinking
#
####################

echo "Symlinking..."

echo "Home"
cd ~/repos/dotfiles/general
ln -sf ~/repos/dotfiles/general/.aliases ~
ln -sf ~/repos/dotfiles/general/.config/* ~/.config/
ln -sf ~/repos/dotfiles/general/.exports ~
ln -sf ~/repos/dotfiles/general/.xinitrc ~
ln -sf ~/repos/dotfiles/general/.Xresources ~
ln -sf ~/repos/dotfiles/general/.xserverrc ~


echo "Do you want to symlink the Vim dotfiles?"
read -p "Answer (yes or no): " vim_answer
if [[ $vim_answer == "yes" ]] || [[ $vim_answer == "y" ]]; then
	echo "Vim"
	ln -sf ~/repos/dotfiles/vim ~
	mv ~/vim ~/.vim
	cd ~/repos/dotfiles/vim
	ln -sf ~/repos/dotfiles/vim/.vimrc ~
	if [ ! -d "~/.local/share/nvim/site" ]; then
		mkdir -p ~/.local/share/nvim/site
	fi
  ln -sf ~/repos/dotfiles/vim/rplugin.vim ~/.local/share/nvim/
	ln -sf ~/repos/dotfiles/vim/colors ~/.local/share/nvim/site/
	ln -sf ~/repos/dotfiles/vim/pack ~/.local/share/nvim/site/
fi

echo "Do you want to symlink the ZSH dotfiles?"
read -p "Answer (yes or no): " zsh_answer
if [[ $zsh_answer == "yes" ]] || [[ $zsh_answer == "y" ]]; then
	echo "zsh"
	cd ~/repos/dotfiles/zsh
	ln -sf ~/repos/dotfiles/zsh/.zshrc ~
	ln -sf ~/repos/dotfiles/zsh/.zprofile ~
fi

echo ""

####################
#
# Setting up machine-specific configurations
#
####################


