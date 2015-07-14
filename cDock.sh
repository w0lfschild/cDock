#! /bin/bash

# # # # # # # # # # # # # # # # # # # #
#
# cDock
# Maintained By			: Wolfgang Baird
# Version				: 8.2
# Updated				: Jul / 05 / 2015
#
# # # # # # # # # # # # # # # # # # # #

#BEGIN

#	Load all our functions
source ./functions/shared_functions.sh
source ./functions/base_functions.sh
source ./functions/window_functions.sh
source ./functions/simbl.sh

#	Strings
start_time=$(date +%s)
scriptDirectory=$(cd "${0%/*}" && echo $PWD)
app_support="$scriptDirectory"/support
app_bundles="$scriptDirectory"/bundles
app_helpers="$scriptDirectory"/helpers
app_directory="$scriptDirectory"
for i in {1..2}; do app_directory=$(dirname "$app_directory"); done
simbl_inst="$app_directory"/Contents/Resources/helpers/SIMBL-0.9.9.pkg
injec_path="$app_directory"/Contents/Resources/helpers/inject.sh
cdock_path="$app_directory"/Contents/Resources/helpers/"cDock Agent".app
wupdt_path="$app_directory"/Contents/Resources/updates/wUpdater.app/Contents/MacOS/wUpdater
cocoa_path="$app_directory"/Contents/Resources/updates/wUpdater.app/Contents/Resource/cocoaDialog.app/Contents/MacOS/CocoaDialog
appsupport_dir="$HOME"/Library/'Application Support'/cDock
app_themes="$HOME"/Library/'Application Support'/cDock/themes
save_folder="$HOME"/Library/'Application Support'/cDock/.bak
backup_name_data="$HOME"/Library/'Application Support'/cDock/.app_name_data.bak
PlistBuddy=/usr/libexec/PlistBuddy" -c"
dock_plist="$HOME"/Library/Preferences/com.apple.dock.plist
cdock_pl="$HOME"/Library/Preferences/org.w0lf.cDock.plist
curver=$($PlistBuddy "Print CFBundleShortVersionString" "$app_directory"/Contents/Info.plist)
mvr=$(verres $(sw_vers -productVersion) "10.10")

# Boolean variables
custom_dock=false
install_dock=false
reboot_finder=false
reboot_dock=false
refresh_win=false
start_agent=false
pwd_req=false
folders_OT=0

where_are_we												# Make sure we're in /Applications or ~/Applications
app_logging													# Start logging
firstrun_check 												# Check if it's the firstrun
get_preferences												# Read all the preferences we need to show
dir_setup													# Setup all our directories
check_bundles												# Check if our bundles are already in place
window_setup												# Set up windows
firstrun_display_check										# Check if app has been opened before and if it's a newer version than saved in the preferences
# first_run_window; exit									# Testing...
sync_themes													# Make sure themes are synced
launch_agent												# Setup that launch agent
plistbud "Set" "version" "string" "$curver" "$cdock_pl"		# Set version
simbl_setup													# Make sure we got that sweet sweet SIMBL installed
simbl_run &													# Make sure we got that sweet sweet SIMBL running and injected
open -a "$cdock_path" &										# Start Agent

# Check for updates
if [[ $update_auto_check == 1 ]]; then
	# 1 wupdater_path 2 app_directory 3 curver 4 update_auto_install 5 update_interval
	update_check "$wupdt_path" "$app_directory" "$curver" "$update_auto_install" "n" &
fi

# Log time it took to open cDock
total_time=$(( $(date +%s) - $start_time ))
echo -e "Approximate startup time is ${total_time} seconds\n"

# Show main window
if [[ $launch_menu_applet == "1" ]]; then
	if [[ -z $(ps ax | grep [c]Dock_refresh) ]]; then
		open ./helpers/cDock_refresh.app
	fi
fi

main_window_draw

#END
