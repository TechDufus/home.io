#!/bin/bash

alias update-flux='sudo apt-get update -y && sudo apt-get --with-new-pkgs upgrade -y && sudo apt autoremove -y && cd /home/techdufus/zelflux && git checkout . && git checkout master && git reset && git pull && sudo reboot'
