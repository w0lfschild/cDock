#! /bin/bash

simbl_setup() {
  if [[ ! -e /System/Library/ScriptingAdditions/SIMBL.osax || ! -e /System/Library/LaunchAgents/net.culater.SIMBL.Agent.plist || -h /Library/Application\ Support/SIMBL/Plugins ]]; then
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

simbl_run() {
	simbl_id=$(ps ax | grep [M]acOS/SIMBL | sed -e 's/^[ \t]*//' | cut -f1 -d" ")
	if [[ -z $simbl_id ]]; then
		exec "/System/Library/ScriptingAdditions/SIMBL.osax/Contents/Resources/SIMBL Agent.app/Contents/MacOS/SIMBL Agent" &
	fi
  sleep 1
  osascript -e 'tell application "Dock" to inject SIMBL into Snow Leopard'
  osascript -e 'tell application "Finder" to inject SIMBL into Snow Leopard'
}
