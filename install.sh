#!/bin/bash
####################
#
# Variables
#
####################

repos_dir=~/repos/
dotfiles_dir=~/repos/dotfiles
packages="zsh polybar radare2"

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
    sudo yum install zsh
  fi
  if [[ -f /etc/debian_version ]]; then
    sudo apt install zsh
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


####################
#
# Configuring ZSH
#
####################

echo "Configuring ZSH"



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




echo "Creating $olddir for backup of any existing dotfiles in ~"
mkdir -p $olddir
echo "...done"

# change to the dotfiles directory
echo "Changing to the $dir directory"
cd $dir
echo "...done"

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks
for file in $files; do
    echo "Moving any existing dotfiles from ~ to $olddir"
    mv ~/.$file $olddir/.$file
done

install_zsh () {
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
            sudo yum install zsh
            install_zsh
        fi
        if [[ -f /etc/debian_version ]]; then
            sudo apt-get install zsh
            install_zsh
        fi
    fi
fi
}

install_zsh

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks from the homedir to any files in the ~/dotfiles directory specified in $files
for file in $files; do
    echo "Moving any existing dotfiles from ~ to $olddir"
    mv ~/.$file ~/dotfiles_old/
    echo "Creating symlink to $file in home directory."
    ln -s $dir/.$file ~/.$file
done

chmod +x ./colorls_install.sh && ./colorls_install.sh
