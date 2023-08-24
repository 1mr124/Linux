#!/usr/bin/env bash

# all the  pachages needed in the script
packgeNeeded=("dmenu" "graphicsmagick-imagemagick-compat" "xclip" "espeak")


# check if all used packages are installed
# dpkg -s $1 &> /dev/null [ $? -eq 0 ]  0 > installed , 1 > not installed

function installAllPackages(){
    read -p "Do you want to install missing Packages [y]: " answer
    if [[ $answer =~ [yY] ]];then sudo apt-get install -y ${packgeNeeded[@]}  ;else echo You must install all packges && exit ;fi
    
}


# Check for all needed packges first  - if one is missing > install all
dpkg -s ${packgeNeeded[@]} > /dev/null 2>&1 || installAllPackages 


choice=$(echo -e "Copy\nCrop\nFull" | dmenu -i -p "Chosse")

case $choice in
  Copy)
	import png:- | xclip -selection clipboard -t image/png
    ;;
  Crop)
	gnome-screenshot -a && espeak Area
    ;;
  Full)
	gnome-screenshot && espeak Full
    ;;
  *)
	espeak "Error"
    ;;
esac
