#! /bin/bash

simbl_setup() {
  if [[ -e /Library/ScriptingAdditions/SIMBL.osax || ! -e /System/Library/ScriptingAdditions/SIMBL.osax || ! -e /System/Library/LaunchAgents/net.culater.SIMBL.Agent.plist || ! -e /Library/Application\ Support/SIMBL/Plugins || -h /Library/Application\ Support/SIMBL/Plugins ]]; then
    open "$simbl_inst"
    imma_let_you_finish    
  fi
}

imma_let_you_finish() {
  # echo "But Beyonce had the greatest albumn of all time"
  inst_id1=$(ps ax | grep [c]Dock-Helper | sed -e 's/^[ \t]*//' | cut -f1 -d" ")

  # If dock has been restarted it will have a new ID
  while [[ $inst_id1 != "" ]]; do
    inst_id1=$(ps ax | grep [c]Dock-Helper | sed -e 's/^[ \t]*//' | cut -f1 -d" ")
    sleep .5
  done
}

inject_intoPROC() {
  # Kill process then wait for process to inject
  count=0
  killall -s "$1"
  while [[ $count < 20 ]]; do
    if [[ $count < 20 ]]; then
      sleep 0.5
    fi
    if [[ $(killall -s "$1") = *"-TERM"* ]]; then
      count=20
    fi
    count=$(( count + 1 ))
  done
  osascript -e "tell application \"$1\" to inject SIMBL into Snow Leopard"
}

simbl_run() {
  # Make sure SIMBL is running then try injecting
	simbl_id=$(ps ax | grep [M]acOS/SIMBL | sed -e 's/^[ \t]*//' | cut -f1 -d" ")
	if [[ -z $simbl_id ]]; then
		exec "/System/Library/ScriptingAdditions/SIMBL.osax/Contents/Resources/SIMBL Agent.app/Contents/MacOS/SIMBL Agent" &
	fi
  sleep 1
  inject_intoPROC "Dock" &
  inject_intoPROC "Finder" &
}
