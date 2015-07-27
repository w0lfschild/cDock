#! /bin/bash

simbl_setup() {
  lib_plug="/Library/Application Support/SIMBL/Plugins"
  if [[ ! -e /Library/ScriptingAdditions/SIMBL.osax || ! -e /Library/LaunchAgents/net.culater.SIMBL.Agent.plist ]]; then
    open "$simbl_inst"
    imma_let_you_finish    
  fi
  dir_check "$lib_plug"
}

imma_let_you_finish() {
  # echo "But Beyonce had the greatest albumn of all time"
  inst_id1=$(ps ax | grep [C]oreServices/Installer | sed -e 's/^[ \t]*//' | cut -f1 -d" ")

  # If dock has been restarted it will have a new ID
  while [[ $inst_id1 != "" ]]; do
    inst_id1=$(ps ax | grep [C]oreServices/Installer | sed -e 's/^[ \t]*//' | cut -f1 -d" ")
    sleep .5
  done
}

simbl_run() {
  exec "$injec_path" &
  sleep 1
	simbl_id=$(ps ax | grep [M]acOS/SIMBL | sed -e 's/^[ \t]*//' | cut -f1 -d" ")
	if [[ -z $simbl_id ]]; then
		exec "/Library/ScriptingAdditions/SIMBL.osax/Contents/Resources/SIMBL Agent.app/Contents/MacOS/SIMBL Agent" &
	fi
}
