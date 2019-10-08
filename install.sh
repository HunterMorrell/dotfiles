#!/bin/bash
####################
#
# Variables
#
####################

repos_dir=~/repos/
dotfiles_dir=~/repos/dotfiles
packages="zsh polybar radare2 git alsa-utils build-essential cmake curl dpkg fwupd gcc gdb i3 i3lock light neovim python3 python3-pip ranger rofi ruby rxvt-unicode vim cairo libxcb python2 xcb-proto xcb-util-image xcb-util-wm xcb-util-xrm alsa-lib i3-wm wireless_tools"

####################
#
# Installing required packages
#
####################

echo "Installing required packages"
platform=$(uname);
# If the platform is Linux, try an apt-get to install zsh and then recurse
if [[ $platform == 'Linux' ]]; then
  if [[ -f /etc/redhat-release ]]; then
		for package in $packages; do
			sudo dnf install $package
		done
  fi
  if [[ -f /etc/debian_version ]]; then
		for package in $packages; do
			sudo apt -y install $package
		done
  fi
fi



####################
#
# Creating directory structure
#
####################

echo "Creating directory structure"
mkdir ~/repos
mkdir ~/AppImages
mkdir ~/ISOs
mkdir ~/security
mkdir /virtual_machines


####################
#
# Cloning and installing repos
#
####################

echo "Cloning and installing repos"
cd ~/repos

echo "Nerd Fonts"
git clone git@github.com:ryanoasis/nerd-fonts.git
./nerd-fonts/install.sh

echo "dotfiles"
git clone --recurse-submodules git@github.com:HunterMorrell/dotfiles.git

echo "light"
git clone git@github.com:haikarainen/light.git

echo "UserCSS-Styles"
git clone git@github.com:HunterMorrell/UserCSS-Styles.git

echo "ssh-ident"
mkdir -p ~/bin; wget -O ~/bin/ssh goo.gl/MoJuKB; chmod 0755 ~/bin/ssh

echo "polybar"
git clone --recursive https://github.com/polybar/polybar
cd polybar
sudo ./build.sh

chmod +x ~/repos/dotfiles/general/colorls_install.sh && ~/repos/dotfiles/general/colorls_install.sh


####################
#
# Configuring ZSH
#
####################

echo "Configuring ZSH"

# Test to see if zshell is installed.  If it is:
if [ -f /bin/zsh -o -f /usr/bin/zsh ]; then
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


###################
#
# Symlinking
#
####################

echo "Symlinking"

echo "Home"
cd ~/repos/dotfiles/general
ln -sf ~/repos/dotfiles/general/.aliases ~
ln -sf ~/repos/dotfiles/general/.config ~
ln -sf ~/repos/dotfiles/general/.exports ~
ln -sf ~/repos/dotfiles/general/.xinitrc ~
ln -sf ~/repos/dotfiles/general/.Xresources ~
ln -sf ~/repos/dotfiles/general/.xserverrc ~

echo "Vim"
ln -sf ~/repos/dotfiles/vim ~
mv ~/vim ~/.vim
cd ~/repos/dotfiles/vim
ln -sf ~/repos/dotfiles/vim/.vimrc ~
ln -sf ~/repos/dotfiles/vim/colors ~/.local/share/nvim/site/
ln -sf ~/repos/dotfiles/vim/pack ~/.local/share/nvim/site/

echo "zsh"
cd ~/repos/dotfiles/zsh
ln -sf ~/repos/dotfiles/zsh/.zshrc ~
ln -sf ~/repos/dotfiles/zsh/.zprofile ~


####################
#
# Setting up machine-specific configurations
#
####################


