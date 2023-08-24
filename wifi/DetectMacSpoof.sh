#!/usr/bin/env bash

# all the  pachages needed in the script
packgeNeeded=("arp-scan")


# echo help if no arguments were given 
if [ $# -eq 0 ]
then
    echo -e "run [ InterfaceName ]\nExample wlan0 "
    exit
fi

# set the interface name 
INTERFACE=$1


# ================================= Functions ================================= #

# check if all used packages are installed
function installAllPackages(){
    read -p "Do you want to install missing Packages [y]: " answer
    if [[ $answer =~ [yY] ]];then sudo apt-get install -y ${packgeNeeded[@]} && exit ;else echo You must install all packges && exit ;fi
    
}


function finish() {
        echo -e "\nDone"
        exit 0
}


# pass interfaceName 
function detectMacSpoof(){
    # get list of all connected ip and mac
    listOfIpMac=$(sudo arp-scan -I $1 --localnet -q -x | cut -f 1 |sort)
    removeDuplication=$(echo -e "$listOfIpMac" | uniq )
    if [[ "$listOfIpMac" == "$removeDuplication" ]] # No change after removing the duplicate
    then
        echo -e "No mac spoofing detected "
    else
        echo -e "Found Duplication ip"
        spoofedIp=$(echo -e "$listOfIpMac" | uniq -d) 
        echo -e "$spoofedIp\n\nWith Mac Adress\n"
        sudo arp-scan -I $1 --localnet -q -x | grep -i "$spoofedIp" 
    fi
}

# ================================= Functions ================================= #


# Check for all needed packges first  - if one is missing > install all
dpkg -s ${packgeNeeded[@]} > /dev/null 2>&1 || installAllPackages 

# ================================= Main ================================= #

# wait for Ctrl + c Signal to exit
trap finish SIGINT

# Check for sudo or root 
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
else
    detectMacSpoof $INTERFACE
fi


