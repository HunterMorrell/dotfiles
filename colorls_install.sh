#!/bin/sh

sudo pacman -Sy ruby
PATH="/home/hunter/.gem/2.5.0/bin:$PATH"
gem install colorls
