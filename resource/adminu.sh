#!/bin/bash

exec &>./_simbl.log
sudo ./SIMBL\ Uninstaller.app/Contents/MacOS/SIMBL\ Uninstaller &
number=0
num=0
while [[ $num -lt 120 ]]; do
	#say $num
	#echo $num > ./count.log
   	number=$(ps -acx | grep SIMBL\ Uninstaller | wc -l)
	if [[ $number -gt 0 ]]; then
		num=$(($num + 120))
		osascript -e 'tell application "Finder" to set visible of process "SIMBL Uninstaller" to false'
		sleep 3
		sudo killall "SIMBL Uninstaller"
		exit
	fi
	num=$(($num + 1))
	sleep 1
done