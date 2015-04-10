#! /bin/bash

# # # # # # # # # # # # # # # # # # # # 
#
#				: cDock 
# Maintained By	: Wolfgang Baird
# Version		: 7.2.1
# Updated		: Apr / 05 / 2015
#
# # # # # # # # # # # # # # # # # # # # 

#	Functions
app_clean() {
	killall "cDock Agent"
	
	file_cleanup \
	/Library/Application\ Support/SIMBL/Plugins/BlackDock.bundle \
	"$HOME"/Library/Application\ Support/SIMBL/Plugins/BlackDock.bundle \
	"$HOME"/Library/Application\ Support/SIMBL/Plugins/ColorfulSidebar.bundle \
	"$HOME"/Library/Application\ Support/SIMBL/Plugins/cDock.bundle \
	"$HOME"/Library/LaunchAgents/com.w0lf.BlackDock.plist \
	"$HOME"/Library/LaunchAgents/com.w0lf.cDock.plist \
	"$HOME"/Library/LaunchAgents/org.w0lf.cDock.plist \
	"$HOME"/Library/Application\ Scripts/BlackDock \
	"$HOME"/Library/Application\ Scripts/cDock \
	"$HOME"/Library/Application\ Support/cDock
	
	$PlistBuddy "Set cdockActive 0" "$cdock_pl" || $PlistBuddy "Add cdockActive integer 0" "$cdock_pl"
	$PlistBuddy "Set colorfulsidebarActive 0" "$cdock_pl" || $PlistBuddy "Add colorfulsidebarActive integer 0" "$cdock_pl"
	defaults write org.w0lf.cDock theme -string "None"
	osascript -e 'tell application "System Events" to delete login item "cDock Agent"'
	
	echo "Cleaned"
}
app_has_updated() {
	# Read current theme if there is one
	current_theme=$($PlistBuddy "Print theme:" "$cdock_pl" 2>/dev/null || echo -n None)
	
	# Directory junk
	dir_check /tmp/cDock_junk/active
	dir_check /tmp/cDock_junk/themes
	dir_check "$HOME"/Library/Application\ Support/cDock/theme_stash
	
	# Save theme folder, logs, and current theme if one was active
	if [[ $current_theme != "None" ]]; then
		rsync -ru "$HOME"/Library/Application\ Support/cDock/themes/"$current_theme" /tmp/cDock_junk/active
	fi
	rsync -ru "$HOME"/Library/Application\ Support/cDock/.bak /tmp/cDock_junk
	rsync -ru "$HOME"/Library/Application\ Support/cDock/themes /tmp/cDock_junk
	rsync -ru "$HOME"/Library/Application\ Support/cDock/logs /tmp/cDock_junk
	
	# Clean out everything cDock
	app_clean			
	dir_setup
	
	# Move back application support directory
	rsync -ruv "$app_support"/ "$HOME"/Library/Application\ Support/cDock
	
	# Move back bundles if they were installed
	(($colorfulsidebar_active)) && { ln -s "$app_bundles"/ColorfulSidebar.bundle "$HOME/Library/Application Support"/SIMBL/Plugins/ColorfulSidebar.bundle; defaults write org.w0lf.cDock colorfulsidebarActive 1; launch_agent; }
	(($cdock_active)) && { ln -s "$app_bundles"/cDock.bundle "$HOME/Library/Application Support"/SIMBL/Plugins/cDock.bundle; defaults write org.w0lf.cDock cdockActive 1; launch_agent; }
	defaults write org.w0lf.cDock theme "$current_theme"
	
	# Move back theme folder, logs, and current theme if one was active
	rsync -ru /tmp/cDock_junk/themes/ "$HOME"/Library/Application\ Support/cDock/theme_stash
	rsync -ru /tmp/cDock_junk/logs "$HOME"/Library/Application\ Support/cDock
	rsync -ru /tmp/cDock_junk/.bak "$HOME"/Library/Application\ Support/cDock
	if [[ $current_theme != "None" ]]; then
		rsync -ru /tmp/cDock_junk/active/"$current_theme" "$HOME"/Library/Application\ Support/cDock/themes
	fi
	
	# Restart logging
	app_logging
}
app_logging() {
	log_dir="$HOME"/Library/Application\ Support/cDock/logs
	for (( c=1; c<6; c++ )); do if [ ! -e "$log_dir"/${c}.log ]; then touch "$log_dir"/${c}.log; fi; done
	for (( c=5; c>1; c-- )); do cat "$log_dir"/$((c - 1)).log > "$log_dir"/${c}.log; done
	> "$log_dir"/1.log
	exec &>"$log_dir"/1.log
	echo -e "This is some basic logging information about your system and what is installed on it"
	echo -e "This should also contain information about the last time cDock was run"
	echo -e "This is not uploaded unless you email it to me\n"
	echo -e "Feel free to browse through this and remove anything you do not feel comfortable sharing\n"
	sw_vers
	echo "ScriptDirectory: $scriptDirectory"
	echo "Date: $(date)"
	ls -dl "$HOME/Library/Application Support"
	ls -dl "$HOME/Library/Preferences/org.w0lf.cDock.plist"
	$PlistBuddy "Print" "$cdock_pl"
	echo -e "\n"
}
apply_main() {
		reboot_dock=true
		
		# Custom dock
		dock_theme="${pop0}"
		if [[ $pop0 = "Custom" ]]; then	
			custom_dock=true
			install_dock=true
		elif [[ $pop0 = "None" ]]; then
			install_dock=false
			file_cleanup "$HOME"/Library/Application\ Support/SIMBL/Plugins/cDock.bundle
			plistbud "Set" "cdockActive" "integer" "0" "$cdock_pl"
			plistbud "Set" "theme" "string" "$dock_theme" "$cdock_pl"
		else
			install_dock=true
			echo "Theme: $pop0"
		fi
		
		# Check for other SIMBL bundles
		plugin_list=""
		plugin_list_1=""
		displayWarning=$($PlistBuddy "Print displayWarning:" "$cdock_pl" 2>/dev/null || echo 1)
		for item in "$HOME/Library/Application Support/SIMBL/Plugins/"*; do
			if [[ "$item" != *cDock.bundle && "$item" != *ColorfulSidebar.bundle && "$item" != "$HOME/Library/Application Support/SIMBL/Plugins/*" ]]; then
				found_Warning=1
				plugin_list="$item[return]$plugin_list"
				plugin_list_1="$item $plugin_list_1"
			fi
		done
		if [[ $found_Warning = "1" && $displayWarning = "1" ]]; then alert_window; fi
			
		# dupe dock plist
		pl_alt=/tmp/com.apple.dock.plist
		cp -f "$dock_plist" "$pl_alt"
		
 		# Show Only Active Applications
		if [[ $chk2 -eq 1 ]]; then
			plistbud "Set" "static-only" "bool" "true" "$pl_alt"
		else
			plistbud "Set" "static-only" "bool" "false" "$pl_alt"
		fi
		
		# Dim hidden items
		if [[ $chk3 -eq 1 ]]; then
			plistbud "Set" "showhidden" "bool" "true" "$pl_alt"
		else
			plistbud "Set" "showhidden" "bool" "false" "$pl_alt"
		fi
		
		# Lock dock contents
		if [[ $chk4 -eq 1 ]]; then
			plistbud "Set" "contents-immutable" "bool" "true" "$pl_alt"
		else
			plistbud "Set" "contents-immutable" "bool" "false" "$pl_alt"
		fi
		
		# Mouse over highlight
		if [[ $chk5 -eq 1 ]]; then
			plistbud "Set" "mouse-over-hilite-stack" "bool" "true" "$pl_alt"
		else
			plistbud "Set" "mouse-over-hilite-stack" "bool" "false" "$pl_alt"
		fi
		
		# No bounce
		if [[ $chk9 -eq 1 ]]; then
			plistbud "Set" "no-bouncing" "bool" "true" "$pl_alt"
			plistbud "Set" "launchanim" "bool" "false" "$pl_alt"
		else
			plistbud "Set" "no-bouncing" "bool" "false" "$pl_alt"
			plistbud "Set" "launchanim" "bool" "true" "$pl_alt"
		fi
		
		# Single app mode
		if [[ $chk10 -eq 1 ]]; then
			plistbud "Set" "single-app" "bool" "true" "$pl_alt"
		else
			plistbud "Set" "single-app" "bool" "false" "$pl_alt"
		fi
		
		# Change the Dock’s Position // Mav only
		if [[ $pop4 != "" ]]; then
			$PlistBuddy "Set pinning $pop4" $pl_alt || $PlistBuddy "Add pinning string $pop4" $pl_alt
		fi
		
		# App icon counts
		a_count=$($PlistBuddy "Print persistent-apps:" $pl_alt | grep -a "    Dict {" | wc -l | tr -d ' ')
		a_spacers=$($PlistBuddy "Print persistent-apps:" $pl_alt | grep -a "spacer-tile" | wc -l | tr -d ' ')
		
		# Document icon counts
		d_count=$($PlistBuddy "Print persistent-others:" $pl_alt | grep -a "    Dict {" | wc -l | tr -d ' ')
		d_spacers=$($PlistBuddy "Print persistent-others:" $pl_alt | grep -a "spacer-tile" | wc -l | tr -d ' ')
		
		# Recent Items Folder
		if [[ $chk6 -eq 1 ]]; then
			(( $($PlistBuddy "Print persistent-others:" $pl_alt | grep -a recents-tile | wc -l) )) || { \
				$PlistBuddy "Add persistent-others array" $pl_alt; \
				$PlistBuddy "Add persistent-others: dict" $pl_alt; \
				$PlistBuddy "Add persistent-others:$d_count:tile-type string recents-tile" $pl_alt; \
				$PlistBuddy "Add persistent-others:$d_count:tile-data dict" $pl_alt; \
				$PlistBuddy "Add persistent-others:$d_count:tile-data:list-type integer 1" $pl_alt; }	
		else
			for (( idx=0; idx < $d_count; idx++ )); do
				if [[ $($PlistBuddy "Print persistent-others:$idx:tile-type" $pl_alt) = "recents-tile" ]]; then
					$PlistBuddy "Delete persistent-others:$idx" $pl_alt
					idx=$_count
				fi
			done
		fi
		
		# Tooltips
		dock_hide_tooltips=$($PlistBuddy "Print TrashName" /System/Library/CoreServices/Dock.app/Contents/Resources/en.lproj/InfoPlist.strings || echo Trash)
		if [[ $dock_hide_tooltips = "Trash" ]]; then dock_hide_tooltips=0; else dock_hide_tooltips=1; fi
		if [[ $chk7 -eq 1 ]]; then
			if [[ $dock_hide_tooltips = 0 ]]; then tooltips_hide; dock_hide_tooltips = 1; fi
		else
			if [[ $dock_hide_tooltips = 1 ]]; then tooltips_restore; dock_hide_tooltips = 0; fi
		fi
		echo "Tooltips hidden: "$dock_hide_tooltips
		
		# Finder and Trash close
		dock_FT_can_kill=$($PlistBuddy "Print trash" /System/Library/CoreServices/Dock.app/Contents/Resources/DockMenus.plist | grep 1004 || echo "")
		if [[ $dock_FT_can_kill = "" ]]; then dock_FT_can_kill=0; else dock_FT_can_kill=1; fi
		if [[ $chk8 -eq 1 ]]; then
			if [[ $dock_FT_can_kill = 0 ]]; then closable_FinderTrash_ENABLE; dock_FT_can_kill=1; fi
		else
			if [[ $dock_FT_can_kill = 1 ]]; then closable_FinderTrash_DISABLE; dock_FT_can_kill=0; fi
		fi
		echo "Trash and Finder removable: "$dock_FT_can_kill
		
		if [[ $a_count -gt 0 ]]; then a_count=$(( $a_count - 1 )); fi
		if [[ $d_count -gt 0 ]]; then d_count=$(( $d_count - 1 )); fi
		
		# App Spacers
		if [[ $a_spacers != $pop1 ]]; then
			_alt=$(( $pop1 - $a_spacers ))
			if [[ $_alt -gt 0 ]]; then
				for ((a=0; a < $_alt ; a++)); do
					a_count=$(( $a_count + 1 ))
					$PlistBuddy "Add persistent-apps: dict" $pl_alt
					$PlistBuddy "Add persistent-apps:$a_count:tile-type string spacer-tile" $pl_alt
				done
			else
				for ((a=0; a <= $a_count ; a++)); do
					if [[ $_alt -lt 0 ]]; then
						if [[ $($PlistBuddy "Print persistent-apps:$a:tile-type" $pl_alt) = "spacer-tile" ]]; then
							$PlistBuddy "Delete persistent-apps:$a" $pl_alt
							a=$(( $a - 1 ))
							a_count=$(( $a_count - 1 ))
							_alt=$(( $_alt + 1 ))
						fi
					fi
				done  
			fi         
		fi
		
		# Document Spacers
		if [[ $d_spacers != $pop2 ]]; then
			_alt=$(( $pop2 - $d_spacers ))
			if [[ $_alt -gt 0 ]]; then
				for ((a=0; a < $_alt ; a++)); do
					d_count=$(( $d_count + 1 ))
					$PlistBuddy "Add persistent-others: dict" $pl_alt
					$PlistBuddy "Add persistent-others:$d_count:tile-data dict" $pl_alt
					$PlistBuddy "Add persistent-others:$d_count:tile-type string spacer-tile" $pl_alt
				done
			else
				for ((a=0; a <= $d_count ; a++)); do
					if [[ $_alt -lt 0 ]]; then
						if [[ $($PlistBuddy "Print persistent-others:$a:tile-type" $pl_alt) = "spacer-tile" ]]; then
							$PlistBuddy "Delete persistent-others:$a" $pl_alt
							a=$(( $a - 1 ))
							d_count=$(( $d_count - 1 ))
							_alt=$(( $_alt + 1 ))
						fi
					fi
				done  
			fi         
		fi
		
		# Magnification level
		if [[ $pop91 = "Off" ]]; then
			plistbud "Set" "magnification" "bool" "false" "$pl_alt"
		else
			plistbud "Set" "magnification" "bool" "true" "$pl_alt"
			plistbud "Set" "largesize" "integer" "$pop91" "$pl_alt"
		fi
		
		# Autohide
		if [[ $pop92 = "Off" ]]; then
			plistbud "Set" "autohide" "bool" "false" "$pl_alt"
		else
			plistbud "Set" "autohide" "bool" "true" "$pl_alt"
			if [[ $pop92 = "Fast" ]]; then
				plistbud "Set" "autohide-time-modifier" "real" "0.01" "$pl_alt"
			elif [[ $pop92 = "Slow" ]]; then
				plistbud "Set" "autohide-time-modifier" "real" "2.5" "$pl_alt"
			else
				plistbud "Set" "autohide-time-modifier" "real" "1.0" "$pl_alt"
			fi
		fi
		
		# Tile (Icon) size
		plistbud "Set" "tilesize" "integer" "$pop90" "$pl_alt"
		
		# push plist changes
		defaults import com.apple.dock $pl_alt
		
		if [[ $install_dock = "true" ]]; then install_cdock_bundle; fi
		install_finish
}
apply_settings() {
	pwd_req=false
	plistbud "Set" "autoCheck" "integer" "$swchk0" "$cdock_pl"
	plistbud "Set" "autoInstall" "integer" "$swchk2" "$cdock_pl"
	plistbud "Set" "betaUpdates" "integer" "$swchk3" "$cdock_pl"
	plistbud "Set" "displayWarning" "integer" "$swchk5" "$cdock_pl"
	(($swchk1)) && { plistbud "Set" "lastupdateCheck" "integer" "0" "$cdock_pl"; update_check; }
	(($swchk4)) && { if [[ "$swpop0" != "Select a restore point" ]]; then defaults import "$dock_plist" "$save_folder"/"$swpop0"; reboot_dock=true; main_window_establish; refresh_win=true; fi; }
	(($swchk6)) && { app_clean; reboot_dock=true; }
	(($swchk7)) && { rm "$dock_plist"; reboot_dock=true; }
	if (($swchk8)); then
		if [[ ! -e "$HOME"/Library/Application\ Support/SIMBL/Plugins/ColorfulSidebar.bundle ]]; then install_finder_bundle; fi
	else
		if [[ -e "$HOME"/Library/Application\ Support/SIMBL/Plugins/ColorfulSidebar.bundle ]]; then 
			file_cleanup "$HOME"/Library/Application\ Support/SIMBL/Plugins/ColorfulSidebar.bundle
			plistbud "Set" "colorfulsidebarActive" "integer" "0" "$cdock_pl"
			reboot_finder=true
		fi
	fi
	fOT_switch=0
	if [[ "$finder_folders_on_top2" = "Folder" ]]; then
		if (($swchk9)); then
			finder_folders_on_top2=" Folder"
			pwd_req=true; 
			reboot_finder=true;
			folders_OT=1;
			fOT_switch=1;
		fi
	else
		if ! (($swchk9)); then
			finder_folders_on_top2="Folder"
			pwd_req=true; 
			reboot_finder=true;
			folders_OT=0;
			fOT_switch=1;
		fi
	fi
	if (($swchk10)); then pwd_req=true; reboot_dock=true; fi
	if [[ $pwd_req = true ]]; then
		ask_pass
		if [[ $fOT_switch = "1" ]]; then folders_on_top; fi
		if (($swchk10)); then reset_icon_cache; fi
	fi
	install_finish
}
ask_pass() {
	
pass_window="
*.title = cDock
*.floating = 1
*.transparency = 1.00
*.autosavekey = cDock_pass0
pw0.type = password
pw0.label = Password required to continue...
pw0.mandatory = 1
pw0.width = 100
pw0.x = -10
pw0.y = 4"

pass_fail_window="
*.title = cDock
*.floating = 1
*.transparency = 1.00
*.autosavekey = cDock_pass1
pw0.type = password
pw0.label = Incorrect password, try again...
pw0.mandatory = 1
pw0.width = 100
pw0.x = -10
pw0.y = 4"
	
	pass_attempt=0
	pass_success=0
	while [ $pass_attempt -lt 5 ]; do
		sudo_status=$(sudo echo null 2>&1)
		if [[ $sudo_status != "null" ]]; then
			if [[ $pass_attempt > 0 ]]; then
				pashua_run "$pass_fail_window" 'utf8' "$scriptDirectory"
			else
				pashua_run "$pass_window" 'utf8' "$scriptDirectory"
			fi
			echo "$pw0" | sudo -Sv
			sudo_status=$(sudo echo null 2>&1)
			if [[ $sudo_status = "null" ]]; then
				pass_attempt=5
				pass_success=1
			else
				pass_attempt=$(( $pass_attempt + 1 ))
				echo -e "Incorrect or no password entered"
			fi
			pw0=""
		else
			pass_attempt=5
			pass_success=1
			sudo -v
		fi
	done
	
	if [[ $pass_success = 1 ]]; then
		echo "_success"
	fi
}
backup_dock_plist() {
	dir_check "$save_folder"
	my_time=$(date)
	cp "$dock_plist" "$save_folder"/"$my_time".plist
}
closable_FinderTrash_ENABLE() {
	pass_res=$(ask_pass)
	if [[ $pass_res = "_success" ]]; then
		if [[ ! -e /System/Library/CoreServices/Dock.app/Contents/Resources/DockMenus.backup.plist ]]; then
			sudo mv /System/Library/CoreServices/Dock.app/Contents/Resources/DockMenus.plist /System/Library/CoreServices/Dock.app/Contents/Resources/DockMenus.backup.plist
		fi
		sudo rm /System/Library/CoreServices/Dock.app/Contents/Resources/DockMenus.plist
		sudo cp "$scriptDirectory"/_Menus_custom.plist /System/Library/CoreServices/Dock.app/Contents/Resources/DockMenus.plist
		echo "DockMenu plist edited"
	fi
}
closable_FinderTrash_DISABLE() {
	pass_res=$(ask_pass)
	if [[ $pass_res = "_success" ]]; then
		sudo rm /System/Library/CoreServices/Dock.app/Contents/Resources/DockMenus.plist
		if [[ -e /System/Library/CoreServices/Dock.app/Contents/Resources/DockMenus.backup.plist ]]; then
			sudo mv -f /System/Library/CoreServices/Dock.app/Contents/Resources/DockMenus.backup.plist /System/Library/CoreServices/Dock.app/Contents/Resources/DockMenus.plist
		else
			sudo cp -f "$scriptDirectory"/_Menus_stock.plist /System/Library/CoreServices/Dock.app/Contents/Resources/DockMenus.plist
		fi
		echo "DockMenu plist restored"
	fi
}
dir_check() {
	if [[ ! -e "$1" ]]; then mkdir -pv "$1"; fi
}
dir_setup() {
	dir_check "$HOME"/Library/Application\ Support/cDock
	dir_check "$HOME"/Library/Application\ Support/cDock/logs
	dir_check "$HOME"/Library/Application\ Support/cDock/.bak
	dir_check "$HOME"/Library/Application\ Support/SIMBL/Plugins
	dir_check "$HOME"/Library/Application\ Support/wUpdater/logs
}
email_me() {
subject=cDock
address=aguywithlonghair@gmail.com
theAttachment1="$log_dir"/1.log
theAttachment2="$log_dir"/apps.log
nill=""

echo "tell application \"Mail\"
    set theEmail to make new outgoing message with properties {visible:true, subject:\"${subject}\", content:\"${nill}\"}
    tell theEmail
        make new recipient at end of to recipients with properties {address:\"${address}\"}
		make new attachment with properties {file name:\"${theAttachment1}\"} at after the last paragraph
		make new attachment with properties {file name:\"${theAttachment2}\"} at after the last paragraph
    end tell
end tell" | osascript

osascript -e 'tell application "Mail" to activate'
}
file_cleanup() {
	for str in "$@"; do 
		if [[ -e "$str" ]]; then
			if [[ -d "$str" ]]; then
				rm -rv "$str"
			else
				rm -v "$str"
			fi
		fi
	done
}
folders_on_top() {
	if [[ $folders_OT = 1 ]]; then
		sudo /usr/libexec/PlistBuddy -c "Set Folder \" Folder\"" /System/Library/CoreServices/Finder.app/Contents/Resources/English.lproj/InfoPlist.strings
	else
		sudo /usr/libexec/PlistBuddy -c "Set Folder \"Folder\"" /System/Library/CoreServices/Finder.app/Contents/Resources/English.lproj/InfoPlist.strings
	fi
}
get_preferences() {
	rez=$($PlistBuddy "Print autoCheck:" "$cdock_pl" 2>/dev/null)	
	if [[ $rez != [0-1] ]]; then
		echo "creating cdock plist"
		defaults write "$cdock_pl" null 0
	fi
	
	# Dock Preferences
	dock_static_only=$($PlistBuddy "Print static-only:" "$dock_plist" 2>/dev/null || echo 0)									# Show Only Active Applications
	dock_largesize=$($PlistBuddy "Print largesize:" "$dock_plist" 2>/dev/null || echo 42)									   	# Maximum Magnification Level
	dock_magnification=$($PlistBuddy "Print magnification:" "$dock_plist" || echo 0)											# Magnification enabled status
	dock_showhidden=$($PlistBuddy "Print showhidden:" "$dock_plist" 2>/dev/null || echo 1)									  	# Dim hidden items
	dock_contents_immutable=$($PlistBuddy "Print contents-immutable:" "$dock_plist" 2>/dev/null || echo 0)						# Lock dock contents
	dock_mouse_over_hilite_stack=$($PlistBuddy "Print mouse-over-hilite-stack:" "$dock_plist" 2>/dev/null || echo 0)			# Mouse over highlight
	dock_single_app=$($PlistBuddy "Print single-app:" "$dock_plist" 2>/dev/null || echo 0)										# Single app mode
	dock_no_bouncing=$($PlistBuddy "Print no-bouncing:" "$dock_plist" 2>/dev/null || echo 0)									# App bounce for notifications
	dock_autohide_delay=$($PlistBuddy "Print autohide-delay:" "$dock_plist" 2>/dev/null || echo 0)								# Delay for dock hiding
	dock_autohide_time_modifier=$($PlistBuddy "Print autohide-time-modifier:" "$dock_plist" 2>/dev/null || echo 0)				# Speed modifier for dock hiding
	dock_autohide=$($PlistBuddy "Print autohide:" "$dock_plist" 2>/dev/null || echo 0)											# Autohide the dock
	
	# Dock advanced pref
	dock_hide_tooltips=$($PlistBuddy "Print TrashName" /System/Library/CoreServices/Dock.app/Contents/Resources/en.lproj/InfoPlist.strings || echo Trash)
	dock_FT_can_kill=$($PlistBuddy "Print trash" /System/Library/CoreServices/Dock.app/Contents/Resources/DockMenus.plist | grep 1004 || echo "")
	
	# Mavericks only dock preferences
	dock_pinning=$($PlistBuddy "Print pinning:" "$dock_plist" 2>/dev/null || echo middle)									   	# Dock Position // Mav only (start, end, middle)
	dock_use_new_list_stack=$($PlistBuddy "Print use-new-list-stack:" "$dock_plist" 2>/dev/null || echo 0)						# Improved list view // Mav only
	
	# Finder preferences
	finder_folders_on_top=$(/$PlistBuddy "Print Folder" /System/Library/CoreServices/Finder.app/Contents/Resources/English.lproj/InfoPlist.strings || echo Folder)
	finder_folders_on_top2="$finder_folders_on_top"
	
	# cDock preferences
	update_auto_check=$($PlistBuddy "Print autoCheck:" "$cdock_pl" 2>/dev/null || { $PlistBuddy "Add autoCheck integer 1" "$cdock_pl"; echo 1; } ) 			# Automatic update checking
	update_auto_install=$($PlistBuddy "Print autoInstall:" "$cdock_pl" 2>/dev/null || { $PlistBuddy "Add autoInstall integer 0" "$cdock_pl"; echo 0; } ) 	# Automatic update installation
	beta_updates=$($PlistBuddy "Print betaUpdates:" "$cdock_pl" 2>/dev/null || echo 0) 																		# Beta updates
	displayWarning=$($PlistBuddy "Print displayWarning:" "$cdock_pl" 2>/dev/null || echo 1) 																# Display SIMBL warnings
	
	# Change true/false to 1/0
	if [[ $finder_folders_on_top = " Folder" ]]; then finder_folders_on_top=1; else finder_folders_on_top=0; fi
	
	if [[ $dock_hide_tooltips = "Trash" ]]; then dock_hide_tooltips=0; else dock_hide_tooltips=1; fi
	if [[ $dock_FT_can_kill = "" ]]; then dock_FT_can_kill=0; else dock_FT_can_kill=1; fi
	
	if [[ $dock_single_app = true ]]; then dock_single_app=1; else dock_single_app=0; fi
	if [[ $dock_no_bouncing = true ]]; then dock_no_bouncing=1; else dock_no_bouncing=0; fi
	if [[ $dock_autohide = true ]]; then dock_autohide=1; else dock_autohide=0; fi
		
	if [[ "$dock_autohide" -eq "0" ]]; then 
		dock_autohide_val="Off"
	else
		if [[ "$dock_autohide_time_modifier" < "1.0" ]]; then
			dock_autohide_val="Fast"
		elif [[ "$dock_autohide_time_modifier" > "1.0" ]]; then
			dock_autohide_val="Slow"
		else
			dock_autohide_val="Med"
		fi
	fi
	
	if [[ $dock_magnification = true ]]; then dock_magnification=1; else dock_magnification=0; fi
	if [[ $dock_static_only = true ]]; then dock_static_only=1; else dock_static_only=0; fi
	if [[ $dock_showhidden = true ]]; then dock_showhidden=1; else dock_showhidden=0; fi
	if [[ $dock_contents_immutable = true ]]; then dock_contents_immutable=1; else dock_contents_immutable=0; fi
	if [[ $dock_mouse_over_hilite_stack = true ]]; then dock_mouse_over_hilite_stack=1; else dock_mouse_over_hilite_stack=0; fi
	if [[ $dock_use_new_list_stack = true ]]; then dock_use_new_list_stack=1; else dock_use_new_list_stack=0; fi
}
import_theme_() {
	rv=$($cocoa_path fileselect \
		--title "cDock Theme Import"\
	    --text "Pick any number of cDock theme folders to import" \
	    --with-directory $HOME/Documents/ \
		--select-only-directories \
		--select-multiple)
	if [ -n "$rv" ]; then
	    ### Loop over lines returned by fileselect
	    echo -e "$rv" | while read file; do
	        ### Check if it's a directory
	        if [ -d "$file" ]; then
	            echo "Importing Theme: $file"
				theme_name=$(basename "$file")
				if [[ -d "$app_themes/$theme_name" ]]; then
					mv "$app_themes/$theme_name" "$app_themes/$theme_name"_$(date +%s)
				fi
				mv "$file" "$app_themes"
	        ### Else a regular file
	        elif [ -e "$file" ]; then
	            echo "Ignoring regular file: $file"
	        fi
	    done
	else
	    echo "No files chosen"
	fi
}
install_cdock_bundle() {
	reboot_dock=true
	start_agent=true
	launch_agent
	rsync -ru "$app_support"/ "$HOME"/Library/Application\ Support/cDock
	
	# Symbolic link bundle
	if [[ ! -e "$HOME/Library/Application Support/SIMBL/Plugins/cDock.bundle" ]]; then ln -s "$app_bundles"/cDock.bundle "$HOME/Library/Application Support"/SIMBL/Plugins/cDock.bundle; fi
	
	# Mirror check
	if [[ $($PlistBuddy "Print hide-mirror:" "$dock_plist") != false ]]; then defaults write com.apple.dock hide-mirror -bool false; fi
	
	# DockMod check
	if [[ $($PlistBuddy "Print dockmod-enabled:" "$dock_plist") != false ]]; then defaults write com.apple.dock dockmod-enabled -bool false; fi
	
	# If custom dock is selected open settings and "instructions" for user also open dock refresher
	if ($custom_dock); then 
		open ./"Dock Refresh".app
		open -e "$HOME"/Library/Application\ Support/cDock/themes/Custom/settings.txt
		open -e "$HOME"/Library/Application\ Support/cDock/settings\ info.rtf
		custom_dock=false
	fi
	
	$PlistBuddy "Set cdockActive 1" "$cdock_pl" || $PlistBuddy "Add cdockActive integer 1" "$cdock_pl"
	defaults write org.w0lf.cDock theme -string "${dock_theme}"
}
install_finder_bundle() {
	reboot_finder=true
	start_agent=true
	launch_agent
	
	# Symbolic link bundle
	if [[ ! -e "$HOME/Library/Application Support/SIMBL/Plugins/ColorfulSidebar.bundle" ]]; then ln -s "$app_bundles"/ColorfulSidebar.bundle "$HOME/Library/Application Support"/SIMBL/Plugins/ColorfulSidebar.bundle; fi
	
	# 10.10+ checking to determine icon plist
	icns="icons10.9.plist"
	if [[ $mvr != "<" ]]; then icns="icons10.10.plist"; fi		
	
	cp -f "$app_bundles"/"$icns" "$app_bundles"/ColorfulSidebar.bundle/Contents/Resources/icons.plist
	plistbud "Set" "colorfulsidebarActive" "integer" "1" "$cdock_pl"
	echo -n "Finished installing colored finder sidebar bundle"
}
install_finish() {
	if ($reboot_dock); then killall "Dock"; fi
	if ($reboot_finder); then killall "Finder"; fi
	if ($start_agent); then
		ps ax | grep [c]Dock\ Agent || { echo -e "Starting dockmonitor"; open "$cdock_path"; }
	fi
	# logging info
	ls -l "$HOME"/Library/Application\ Support/SIMBL/Plugins
	
	custom_dock=false
	install_dock=false
	reboot_finder=false
	reboot_dock=false
	start_agent=false
}
launch_agent() {
	# Blacklist apps that have been reported to crash for SIMBL
	espl="$HOME"/Library/Preferences/com.github.norio-nomura.SIMBL-Agent.plist
	if [[ ! -e "$espl" ]]; then
		touch "$espl"
	fi
	$PlistBuddy "Add SIMBLApplicationIdentifierBlacklist array" "$espl"
	plistbud "Set" "SIMBLApplicationIdentifierBlacklist:0" "string" "com.skype.skype" "$espl"
	plistbud "Set" "SIMBLApplicationIdentifierBlacklist:1" "string" "com.FilterForge.FilterForge4" "$espl"
	# $PlistBuddy "Set SIMBLApplicationIdentifierBlacklist:0 com.skype.skype" "$espl" || $PlistBuddy "Add SIMBLApplicationIdentifierBlacklist:0 string com.skype.skype" "$espl"
	
	# Add agent to startup items
	osascript <<EOD
		tell application "System Events"
			make new login item at end of login items with properties {path:"$cdock_path", hidden:false}
		end tell
EOD
}
pashua_run() {
	# Write config file
	pashua_configfile=`/usr/bin/mktemp /tmp/pashua_XXXXXXXXX`
	echo "$1" > $pashua_configfile

	# Find Pashua binary. We do search both . and dirname "$0"
	bundlepath="Pashua.app/Contents/MacOS/Pashua"
	if [ "$3" = "" ]
	then
		mypath=$(dirname "$0")
		for searchpath in "$mypath/Pashua" "$mypath/$bundlepath" "./$bundlepath" \
						  "/Applications/$bundlepath" "$HOME/Applications/$bundlepath"
		do
			if [ -f "$searchpath" -a -x "$searchpath" ]
			then
				pashuapath=$searchpath
				break
			fi
		done
	else
		# Directory given as argument
		pashuapath="$3/$bundlepath"
	fi

	if [ ! "$pashuapath" ]
	then
		echo "Error: Pashua could not be found"
		exit 1
	fi

	# Manage encoding
	if [ "$2" = "" ]
	then
		encoding=""
	else
		encoding="-e $2"
	fi

	# Get result
	result=$("$pashuapath" $encoding $pashua_configfile | perl -pe 's/ /;;;/g;')

	# Remove config file
	rm $pashua_configfile

	# Parse result
	for line in $result
	do
		key=$(echo $line | sed 's/^\([^=]*\)=.*$/\1/')
		value=$(echo $line | sed 's/^[^=]*=\(.*\)$/\1/' | sed 's/;;;/ /g')
		varname=$key
		varvalue="$value"
		eval $varname='$varvalue'
	done

}
plistbud() {
	pb=/usr/libexec/PlistBuddy" -c"
	# $1 - Set or Delete
	# $2 - name
	# $3 - type
	# $4 - value
	# $5 - plist
	if [[ $1 = "Set" ]]; then
		$pb "Set $2 $4" "$5" || $pb "Add $2 $3 $4" "$5"
	elif [[ $1 = "Delete" ]]; then
		$pb "Delete $2" "$5"
	fi
}
remove_broken_dock_items() {
	a_count=$($PlistBuddy "Print persistent-apps:" $pl_alt | grep -a "    Dict {" | wc -l | tr -d ' ')
	d_count=$($PlistBuddy "Print persistent-others:" $pl_alt | grep -a "    Dict {" | wc -l | tr -d ' ')
	
	for ((a=0; a <= $a_count ; a++)); do
		# tile-type=file-tile
		# tile-type = spacer-tile
		
		item_path=$($PlistBuddy "Print persistent-apps:$a:tile-data:file-data:_CFURLString" $pl_alt)
		item_path=${item_path#file://}
		if [[ ! -e "$item_path" ]]; then
			$PlistBuddy "Delete persistent-apps:$a" $pl_alt
			a=$(( $a - 1 ))
		fi
	done
	
	for ((a=0; a <= $d_count ; a++)); do
		# tile-type = directory-tile
		# tile-type = recents-tile
		# tile-type = spacer-tile
		
		item_path=$($PlistBuddy "Print persistent-others:$a:tile-data:file-data:_CFURLString" $pl_alt)
		item_path=${item_path#file://}
		if [[ ! -e "$item_path" ]]; then
			$PlistBuddy "Delete persistent-others:$a" $pl_alt
			a=$(( $a - 1 ))
		fi
	done
	
	plistbuddy "Print persistent-others:0:tile-data:file-data:_CFURLString" ~/Library/Preferences/com.apple.dock.plist 
}
reset_icon_cache() {
	sudo find /private/var/folders/ -name com.apple.dock.iconcache -exec rm {} \;
	sudo find /private/var/folders/ -name com.apple.iconservices -exec rm -rf {} \;
	sudo "$app_directory"/Contents/Resources/updates/wUpdater.app/Contents/Resource/trash /Library/Caches/com.apple.iconservices.store
	#sudo mv /Library/Caches/com.apple.iconservices.store com.apple.ic
}
restore_stock_plist() {
	echo "Sample Text"
}
simbl_disable() {
		dir_check "$HOME/Library/Application Support/SIMBL/Disbaled"
		for item in "$plugin_list_1"; do
			bundle_name=$(basename "$item")
			item=$(echo $item)
			mv "$item" "$HOME/Library/Application Support/SIMBL/Disbaled/$bundle_name"
		done
}
tooltips_hide() {
	if [[ ! -e "$backup_name_data" ]]; then tooltips_record_name_data; fi
	ask_pass
	sudo $PlistBuddy "Set TrashName \"\"" /System/Library/CoreServices/Dock.app/Contents/Resources/en.lproj/InfoPlist.strings
	for ((a=0; a < $a_count ; a++)); do plistbud "Set" "persistent-apps:$a:tile-data:file-label" "string" "" "$pl_alt"; done
	for ((a=0; a < $d_count ; a++)); do plistbud "Set" "persistent-others:$a:tile-data:file-label" "string" "" "$pl_alt"; done
}
tooltips_record_name_data() {
	bakdat=""
	for ((a=0; a < $a_count ; a++)); do
		bakdat="$bakdat$($PlistBuddy "Print persistent-apps:$a:GUID" "$pl_alt")"
		bakdat="$bakdat:$($PlistBuddy "Print persistent-apps:$a:tile-data:file-label" "$pl_alt")"
		bakdat="$bakdat
"
	done
	for ((a=0; a < $d_count ; a++)); do
		bakdat="$bakdat$($PlistBuddy "Print persistent-others:$a:GUID" "$pl_alt")"
		bakdat="$bakdat:$($PlistBuddy "Print persistent-others:$a:tile-data:file-label" "$pl_alt")"
		bakdat="$bakdat
"
	done
	echo "$bakdat" > "$backup_name_data"
}
tooltips_restore() {
	ask_pass
	sudo $PlistBuddy "Set TrashName \"Trash\"" /System/Library/CoreServices/Dock.app/Contents/Resources/en.lproj/InfoPlist.strings
	if [[ -e "$backup_name_data" ]]; then
		bakdat=$(cat "$backup_name_data")
		for ((a=0; a < $a_count ; a++)); do	
			guid=$($PlistBuddy "Print persistent-apps:$a:GUID" "$pl_alt")
			name=$(echo "$bakdat" | grep $guid | cut -d ':' -f 2)
			if [[ $name != "" ]]; then plistbud "Set" "persistent-apps:$a:tile-data:file-label" "string" "$name" "$pl_alt"; fi
		done
		for ((a=0; a < $d_count ; a++)); do
			guid=$($PlistBuddy "Print persistent-others:$a:GUID" "$pl_alt")
			name=$(echo "$bakdat" | grep $guid | cut -d ':' -f 2)
			if [[ $name != "" ]]; then plistbud "Set" "persistent-others:$a:tile-data:file-label" "string" "$name" "$pl_alt"; fi
		done
		rm "$backup_name_data"
	fi
}
update_check() {
	cur_date=$(date "+%y%m%d")	
	lastupdateCheck=$($PlistBuddy "Print lastupdateCheck:" "$cdock_pl" 2>/dev/null || defaults write org.w0lf.cDock "lastupdateCheck" 0 2>/dev/null)
	
	# If we haven't already checked for updates today
	if [[ "$lastupdateCheck" != "$cur_date" ]]; then	
		results=$(ping -c 1 -t 5 "http://www.sourceforge.net" 2>/dev/null || echo "Unable to connect to internet")
		if [[ $results = *"Unable to"* ]]; then
			echo "ping failed : $results"
		else
			echo "ping success"
			beta_updates=$($PlistBuddy "Print betaUpdates:" "$cdock_pl" 2>/dev/null || echo -n 0)
			update_auto_install=$($PlistBuddy "Print autoInstall:" "$cdock_pl" 2>/dev/null || { defaults write org.w0lf.cDock "autoInstall" 0; echo -n 0; } )

			# Stable urls
			dlurl="http://sourceforge.net/projects/cdock/files/latest"
			verurl="http://sourceforge.net/projects/cdock/files/version.txt"
			logurl="http://sourceforge.net/projects/cdock/files/versionInfo.txt"

			# Beta or Stable updates
			if [[ $beta_updates -eq 1 ]]; then
				stable_version=$(verres $(curl -\# -L "http://sourceforge.net/projects/cdock/files/version.txt") $(curl -\# -L "http://sourceforge.net/projects/cdock/files/cDock%20Beta/versionBeta.txt"))
	
				if [[ $stable_version = "<" ]]; then
					# Beta urls
					dlurl="http://sourceforge.net/projects/cdock/files/cDock%20Beta/current.zip"
					verurl="http://sourceforge.net/projects/cdock/files/cDock%20Beta/versionBeta.txt"
					logurl="http://sourceforge.net/projects/cdock/files/cDock%20Beta/versionInfoBeta.txt"
				fi
			fi
		
			defaults write org.w0lf.cDock "lastupdateCheck" "${cur_date}"
			./updates/wUpdater.app/Contents/MacOS/wUpdater c "$app_directory" org.w0lf.cDock $curver $verurl $logurl $dlurl $update_auto_install &
		fi
	fi
}
vercomp() {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}
verres() {
	vercomp "$1" "$2"
	case $? in
		0) output='=';;
        1) output='>';;
        2) output='<';;
	esac
	echo $output
}
where_are_we() {
	if [[ "$app_directory" != "/Applications/"* && "$app_directory" != "$HOME/Applications/"* ]]; then
		waw_qb=0
		waw_ab=0
		
		info_popup="
*.transparency=1
*.title = Welcome to cDock

# Introductory text
welcometb.type = text
welcometb.default = cDock is best kept in your Applications folder. Click continue to have cDock move itself to /Applications
welcometb.width = 300

# Quit button
waw_qb.type = cancelbutton
waw_qb.label = Quit

# Accept button
waw_ab.type = defaultbutton
waw_ab.label = Continue
"
		pashua_run "$info_popup" 'utf8'
		
		if [[ $waw_qb = "1" ]]; then
			exit
		fi
		
		if [[ $waw_ab = "1" ]]; then
			echo "$app_directory"
			"$app_directory"/Contents/Resources/updates/wUpdater.app/Contents/Resource/trash "/Applications/cDock.app"
			mv -v "$app_directory" /Applications/cDock.app
			/Applications/cDock.app/Contents/Resources/relaunch &
			exit
		fi
	fi
}

#	Windows
evaltxt() { txty=$((txty - 24)); }
evalsel() { sely=$((sely - 24)); }
evalchx() { chxy=$((chxy - 20)); }
alert_window() {
	db_=0
	alertz="
		*.transparency=1
		*.floating = 1
		*.title = Alert
	
		# Introductory text
		altx1.type = text
		altx1.default = Warning cDock has detected that you have other SIMBL plugins installed![return][return]These may negatively effect performance of your system. If you are not aware of what these are cDock can disable them for you.[return][return]Click Continue to have cDock automatically disable them.[return]Click Cancel to leave them be.
		altx1.width = 500
		
		# Plugins
		altb1.type = textbox
		altb1.default = $plugin_list
		altb1.width = 500
		altb1.height = 100

		# No annoyance
		zzz.type = checkbox
		zzz.label = Don't show this message again
		zzz.default = 1

		# Cancel button
		cb_.type = button
		cb_.label = Cancel
	
		# Accept button
		db_.type = defaultbutton
		db_.label = Continue"
	pashua_run "$alertz" 'utf8'
	
	if [[ $zzz = "1" ]]; then zzz=0; else zzz=1; fi
	displayWarning=$zzz
	plistbud "Set" "displayWarning" "integer" "$zzz" "$cdock_pl"
	if [[ $db_ -eq 1 ]]; then
		simbl_disable	
	fi
}
first_run_window() {
	welcome=$(cat "$app_windows"/welcome.txt)
	donor_list=$(tr -d '\n' < "$app_windows"/donors.txt)
	welcome="$welcome
	welcometb0.default = $donor_list
	img.path = "$app_directory"/Contents/Resources/appIcon.icns"
	pashua_run "$welcome" 'utf8'
}
settings_window_establish() {
	settings_window=$(cat "$app_windows"/settings.txt)
	settings_window="$settings_window
swchk0.default = $update_auto_check
swchk1.default = 0
swchk2.default = $update_auto_install
swchk3.default = $beta_updates
swchk4.default = 0
swchk5.default = $displayWarning
swchk6.default = 0
swchk7.default = 0
swchk8.default = $colorfulsidebar_active
swchk9.default = $finder_folders_on_top
swchk10.default = 0
swchk11.default = 0

swpop0.option = Select a restore point
swOK.type = defaultbutton"

	if [[ -e "$save_folder" ]]; then
		for bk in "$save_folder/"*; do
			if [[ "$bk" != *"*" ]]; then
				file_name=$(basename "$bk")
				settings_window="$settings_window
swpop0.option = $file_name"
			fi
		done
	else
		echo "Backups folder doesn't exist!"
	fi
}
settings_window_update() {
	settings_window=$(echo "$settings_window" | sed -e "/default/d")
	settings_window="$settings_window
swchk0.default = $swchk0
swchk1.default = 0
swchk2.default = $swchk2
swchk3.default = $swchk3
swchk4.default = 0
swchk5.default = $swchk5
swchk6.default = 0
swchk7.default = 0
swchk8.default = $swchk8
swchk9.default = $swchk9
swchk10.default = 0
swchk11.default = 0

swpop0.option = Select a restore point
swOK.type = defaultbutton"

	if [[ -e "$save_folder" ]]; then
		for bk in "$save_folder/"*; do
			if [[ "$bk" != *"*" ]]; then
				file_name=$(basename "$bk")
				settings_window="$settings_window
swpop0.option = $file_name"
			fi
		done
	else
		echo "Backups folder doesn't exist!"
	fi
}
settings_window_draw() {
	swOK=0
	swchk0=0
	swchk2=0
	pashua_run "$settings_window" 'utf8'
	if [[ $swOK -eq 1 ]]; then
		settings_window_update
		apply_settings
	fi
}
main_window_establish() {
	txty=200
	sely=194
	chxy=198
	if [[ "$mvr" = "<" ]]; then
		txty=230
		sely=224
		chxy=228
	fi
	if [[ $curver = *.*.*.* ]]; then
		my_title="cDock Beta - $curver"
	else
		my_title="cDock - $curver"
	fi

	# Window Appearance
	main_window=$(cat "$app_windows"/main.txt)
	main_window="$main_window
	*.title = $my_title"
	
	# Theme
	main_window="$main_window
	tb0.y = $txty"
	
	main_window="$main_window	
	pop0.y = $sely"
			
	cur_theme=$($PlistBuddy "Print theme:" "$cdock_pl")
	if [[ "$cur_theme" = "" ]]; then 
	main_window="$main_window
	pop0.default = None";
	else 
	main_window="$main_window
	pop0.default = $cur_theme"; 
	fi
	evaltxt
	evalsel
	
	# Import theme
	main_window="$main_window
	tb12.y = $txty"
	
	main_window=$main_window"	
	themeb.y = $sely"
	evaltxt
	evalsel
	
	# Autohide text
	main_window="$main_window
	tb20.y = $txty"
	
	main_window="$main_window
	pop92.option = Off
	pop92.option = Slow
	pop92.option = Med
	pop92.option = Fast
	pop92.default = $dock_autohide_val
	pop92.x = 140
	pop92.y = $sely"
	evaltxt
	evalsel
	
	# Dock position
	if [[ "$mvr" = "<" ]]; then
	main_window="$main_window
	tb4.tooltip = SAMPLE TEXT
	tb4.type = text
	tb4.height = 0
	tb4.width = 150
	tb4.x = 0
	tb4.default = Dock position:
	tb4.y = $txty"
	main_window="$main_window
	pop4.type = popup
	pop4.width = 75
	pop4.option = start
	pop4.option = middle
	pop4.option = end
	pop4.default = $dock_pinning
	pop4.x = 125
	pop4.y = $sely"
	evaltxt
	evalsel
	fi
	
	# Magnification
	main_window="$main_window
	tb11.y = $txty"
	
	main_window="$main_window
	pop91.y = $sely"
			
	for val in {16..248}; do 
	main_window="$main_window
	pop91.option = $val"; 
	done
	
	mag=$($PlistBuddy "Print magnification:" "$dock_plist")
	if [[ $mag = true ]]; then
	tsize=$($PlistBuddy "Print largesize:" "$dock_plist")
	tsize=${tsize%%.*}
	main_window="$main_window
	pop91.default = $tsize"
	else
	main_window="$main_window
	pop91.default = Off"
	fi	
	evaltxt
	evalsel
	
	# Tile Size
	main_window="$main_window
	tb10.y = $txty"
		
	main_window="$main_window
	pop90.y = $sely"
			
	for val in {16..128}; do 
	main_window="$main_window
	pop90.option = $val"; 
	done
	
	tsize=$($PlistBuddy "Print tilesize:" "$dock_plist" || echo "50.0")
	tsize=${tsize%%.*}
	main_window="$main_window
	pop90.default = $tsize"	
	evaltxt
	evalsel
	
	# App spacer text
	main_window="$main_window
	tb1.y = $txty"
	evaltxt
	
	# App spacers
	for val in {0..10}; do 
	main_window="$main_window
	pop1.option = $val"; 
	done
	
	main_window="$main_window
	pop1.default = $($PlistBuddy "Print persistent-apps:" "$dock_plist" | grep -a "spacer-tile" | wc -l)
	pop1.y = $sely"
	evalsel

	# Doc spacers text
	main_window="$main_window
	tb2.y = $txty"
	evaltxt

	# Doc spacers
	for val in {0..10}; do 
	main_window="$main_window
	pop2.option = $val"; 
	done

	main_window="$main_window
	pop2.default = $($PlistBuddy "Print persistent-others:" "$dock_plist" | grep -a "spacer-tile" | wc -l)
	pop2.y = $sely"
	evalsel

	# Active applications
	main_window=$main_window"
	chk2.default = $dock_static_only
	chk2.y = $chxy"
	evalchx

	# Dim hidden items
	main_window=$main_window"
	chk3.default = $dock_showhidden
	chk3.y = $chxy"
	evalchx

	# Lock dock contents
	main_window=$main_window"
	chk4.default = $dock_contents_immutable
	chk4.y = $chxy"
	evalchx

	# Mouse over highlight
	main_window=$main_window"
	chk5.default = $dock_mouse_over_hilite_stack
	chk5.y = $chxy"
	evalchx

	# Recents Folder
	rf_en=$($PlistBuddy "Print persistent-others:" $dock_plist | grep -a recents-tile | wc -l)
	main_window=$main_window"
	chk6.default = $rf_en
	chk6.y = $chxy"
	evalchx

	# Hide tooltips
	main_window=$main_window"
	chk7.default = $dock_hide_tooltips
	chk7.y = $chxy"
	evalchx
	
	# Finder and Trash
	main_window=$main_window"
	chk8.default = $dock_FT_can_kill
	chk8.y= $chxy"
	evalchx

	# No app bounce
	main_window=$main_window"
	chk9.default = $dock_no_bouncing
	chk9.y= $chxy"
	evalchx
	
	# Single app mode
	main_window=$main_window"
	chk10.default = $dock_single_app
	chk10.y= $chxy"
	evalchx

	if [[ "$mvr" = "<" ]]; then
	# Enhanced list view
	main_window=$main_window"
	chk8.tooltip = When enabled folders set to list view will use larger icons and allow dragging icons just like in grid view.
	chk8.type = checkbox
	chk8.label = Improved list view
	chk8.default = 0
	chk8.x = 225
	chk8.y = $chxy"
	evalchx
	fi

	# Settings text
	main_window="$main_window
	tb19.y = $txty"
	evaltxt

	# Settings button
	main_window=$main_window"	
	settingb.y = $sely"
	evalsel
	
	main_window="$main_window
	db.type = defaultbutton"
	
	# Themes
	if [[ -e "$app_themes" ]]; then
		for theme in "$HOME/Library/Application Support/cDock/themes/"*
		do
			theme_name=$(basename "$theme")
			main_window="$main_window
	pop0.option = $theme_name"
		done
	fi
}
main_window_update() {
	main_window=$(echo "$main_window" | sed -e "/default/d")
	main_window="$main_window
db.type = defaultbutton

# chk1.default = $chk1
chk2.default = $chk2
chk3.default = $chk3
chk4.default = $chk4
chk5.default = $chk5
chk6.default = $chk6
chk7.default = $chk7
chk8.default = $chk8
chk9.default = $chk9
chk10.default = $chk10

pop0.default = $pop0
pop1.default = $pop1
pop2.default = $pop2
# pop3.default = $pop3

pop90.default = $pop90
pop91.default = $pop91
pop92.default = $pop92"
		
	# Themes
	if ! [[ -e "$app_themes" ]]; then echo "User themes folder doesn't exist!"; fi
	for theme in "$HOME/Library/Application Support/cDock/themes/"*
	do
		theme_name=$(basename "$theme")
		main_window="$main_window
pop0.option = $theme_name"
	done
		
	if [[ "$mvr" = "<" ]]; then
		main_window="$main_window
tb4.default = Dock position:
pop4.default = $pop4"
	fi
}
main_window_draw() {
	pashua_run "$main_window" 'utf8'

	# Settings button clicked
	if [[ $settingb -eq 1 ]]; then
		settingb=0
		# Open settings window
		settings_window_draw
		# Reopen main window when settings window closes
		if [[ $refresh_win = false ]]; then main_window_update; refresh_win=true; fi
		main_window_draw
	fi
	
	# Import theme button clicked
	if [[ $themeb -eq 1 ]]; then
		themeb=0
		import_theme_
		main_window_update
		main_window_draw
	fi
	
	# Donate button clicked
	if [[ $donateb -eq 1 ]]; then open "http://goo.gl/vF92sf"; fi
	
	# Email button clicked
	if [[ $emailb -eq 1 ]]; then email_me; fi

	# Apply button clicked
	if [[ $db -eq 1 ]]; then
		echo -e "\nApply Button Clicked\n"
		$PlistBuddy "Print" "$dock_plist" > "$log_dir"/apps.log & 
		db=0
		main_window_update
		{ backup_dock_plist; apply_main; } &
		main_window_draw		
	fi
}

#	Strings
start_time=$(date +%s)
scriptDirectory=$(cd "${0%/*}" && echo $PWD)
app_support="$scriptDirectory"/support
app_bundles="$scriptDirectory"/bundles
app_directory="$scriptDirectory"
for i in {1..2}; do app_directory=$(dirname "$app_directory"); done
cdock_path="$app_directory"/Contents/Resources/helpers/"cDock Agent".app
cocoa_path="$app_directory"/Contents/Resources/updates/wUpdater.app/Contents/Resource/cocoaDialog.app/Contents/MacOS/CocoaDialog
app_themes="$HOME"/Library/'Application Support'/cDock/themes
save_folder="$HOME"/Library/'Application Support'/cDock/.bak
backup_name_data="$HOME"/Library/'Application Support'/cDock/.app_name_data.bak
PlistBuddy=/usr/libexec/PlistBuddy" -c"
dock_plist="$HOME"/Library/Preferences/com.apple.dock.plist
cdock_pl="$HOME"/Library/Preferences/org.w0lf.cDock.plist
curver=$($PlistBuddy "Print CFBundleShortVersionString" "$app_directory"/Contents/Info.plist)
mvr=$(verres $(sw_vers -productVersion) "10.10")

lang=$(locale | grep LANG | cut -d\" -f2 | cut -d_ -f1)
# if [[ -e "$scriptDirectory"/windows/"$lang" ]]; then
# 	app_windows="$scriptDirectory"/windows/"$lang"
# else
# 	app_windows="$scriptDirectory"/windows/en
# fi
app_windows="$scriptDirectory"/windows/zh

#	Integers
a_count=0
d_count=0

#	Windows
main_window=""
settings_window=""
alert_window=""
first_run_window=""
dock_theme=""
plugin_list=""

# 	Boolean variables
custom_dock=false
install_dock=false
reboot_finder=false
reboot_dock=false
refresh_win=false
start_agent=false
pwd_req=false
folders_OT=0

# Find our location
where_are_we

# Start logging
app_logging

# Check firstrun
if [[ ! -e "$HOME"/Library/Preferences/org.w0lf.cDock.plist ]]; then do_firstrun=true; else do_firstrun=false; fi
	
# Read preferences
get_preferences

# Setup directories
dir_setup

# Check bundles
[ -e "$HOME"/Library/Application\ Support/SIMBL/Plugins/ColorfulSidebar.bundle ] && { colorfulsidebar_active=1; $PlistBuddy "Set colorfulsidebarActive 1" "$cdock_pl" || $PlistBuddy "Add colorfulsidebarActive integer 1" "$cdock_pl"; }
[ -e "$HOME"/Library/Application\ Support/SIMBL/Plugins/cDock.bundle ] && { cdock_active=1; $PlistBuddy "Set cdockActive 1" "$cdock_pl" || $PlistBuddy "Add cdockActive integer 1" "$cdock_pl"; }

# Check if app has been opened before and if it's a newer version than saved in the preferences
if [[ $do_firstrun = "true" ]]; then
	first_run_window
else
	vernum=$($PlistBuddy "Print version" "$cdock_pl")
	if [[ $(verres $curver $vernum) = ">" ]]; then app_has_updated; fi
fi

# Make sure themes are synced
if [[ ! -e "$HOME/Library/Application Support/cDock/themes" ]]; then rsync -ruv "$app_support"/ "$HOME"/Library/Application\ Support/cDock; fi

# Version
$PlistBuddy "Set version $curver" "$cdock_pl" || $PlistBuddy "Add version string $curver" "$cdock_pl"

# Check for updates
if [[ $update_auto_check == 1 ]]; then 
	update_check &
fi

# Set up windows
main_window_establish
settings_window_establish

# Log time it took to open cDock
total_time=$(( $(date +%s) - $start_time ))
echo -e "Approximate startup time is ${total_time} seconds\n"

# Show main window
main_window_draw

#END