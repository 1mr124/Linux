#!/usr/bin/env bash


# all the  pachages needed in the script
packgeNeeded=("dmenu" "i3" "i3lock" "espeak")


# check if all used packages are installed
# dpkg -s $1 &> /dev/null [ $? -eq 0 ]  0 > installed , 1 > not installed

function installAllPackages(){
    read -p "Do you want to install missing Packages [y]: " answer
    if [[ $answer =~ [yY] ]];then sudo apt-get install -y ${packgeNeeded[@]}  ;else echo You must install all packges && exit ;fi
    
}


# Check for all needed packges first  - if one is missing > install all
dpkg -s ${packgeNeeded[@]} > /dev/null 2>&1 || installAllPackages 


choice=$(echo -e "Shutdown\nLock\nSleep\nReboot\nQuit" | dmenu -i -p "Chosse")

case $choice in
  Shutdown)
		shutdown now
    	;;
  Lock)
		espeak "HOPE " && i3lock -c "#000033"
		;;
  Sleep)
		i3lock -c "#000033" && systemctl suspend
   		;;
  Reboot)
		reboot
  		;;
  Quit)
		i3-msg exit
		;;
  *)
		espeak "Error "
    	;;
esac
