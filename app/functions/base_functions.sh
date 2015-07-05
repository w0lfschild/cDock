#! /bin/bash

# Base functions used by cDock

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

	plistbud "set" "cdockActive" "integer" "0" "$cdock_pl"
	plistbud "set" "colorfulsidebarActive" "integer" "0" "$cdock_pl"
	defaults write org.w0lf.cDock theme -string "None"
	osascript -e 'tell application "System Events" to delete login item "cDock Agent"'
	osascript -e 'tell application "System Events" to delete login item "cDock Agent"'

	echo "Clean up complete"
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

	rm -r /tmp/cDock_junk

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
  ( set -o posix ; set ) | less > "$log_dir"/variables_functions.log
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

		# Enhanced list view // Mav only
		if [[ $chk13 -eq 1 ]]; then
			plistbud "Set" "use-new-list-stack" "bool" "true" "$pl_alt"
		else
			plistbud "Set" "use-new-list-stack" "bool" "false" "$pl_alt"
		fi

		# Change the Dock’s Position // Mav only
		if [[ $pop4 != "" ]]; then
			plistbud "Set" "pinning" "string" "$pop4" "$pl_alt"
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
    dock_findtrashname
    dock_hide_tooltips=$($PlistBuddy "Print TrashName" "$dock_trashname" || echo Trash)
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
	plistbud "Set" "menu_applet" "integer" "$swchk12" "$cdock_pl"
	(($swchk1)) && { plistbud "Set" "lastupdateCheck" "integer" "0" "$cdock_pl"; update_check "$wupdt_path" "$app_directory" "$curver" "$update_auto_install" "n"; }
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

backup_dock_plist() {
	dir_check "$save_folder"
	my_time=$(date)
	cp "$dock_plist" "$save_folder"/"$my_time".plist
}

check_bundles() {
  [ -e "$HOME"/Library/Application\ Support/SIMBL/Plugins/ColorfulSidebar.bundle ] && { colorfulsidebar_active=1; $PlistBuddy "Set colorfulsidebarActive 1" "$cdock_pl" || $PlistBuddy "Add colorfulsidebarActive integer 1" "$cdock_pl"; }
  [ -e "$HOME"/Library/Application\ Support/SIMBL/Plugins/cDock.bundle ] && { cdock_active=1; $PlistBuddy "Set cdockActive 1" "$cdock_pl" || $PlistBuddy "Add cdockActive integer 1" "$cdock_pl"; }
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

dock_findtrashname() {
	dock_trashname=/System/Library/CoreServices/Dock.app/Contents/Resources/en.lproj/Localizable.strings
	if [[ -e /System/Library/CoreServices/Dock.app/Contents/Resources/en.lproj/InfoPlist.strings ]]; then
		dock_trashname=/System/Library/CoreServices/Dock.app/Contents/Resources/en.lproj/InfoPlist.strings
	fi
}

email_me() {
  rm "$log_dir"/logs.zip
	pushd "$log_dir"
	zip -u logs.zip *
	popd
	subject=cDock
	address=aguywithlonghair@gmail.com
	theAttachment1="$log_dir"/logs.zip
	nill=""

echo "tell application \"Mail\"
  set theEmail to make new outgoing message with properties {visible:true, subject:\"${subject}\", content:\"${nill}\"}
  tell theEmail
      make new recipient at end of to recipients with properties {address:\"${address}\"}
			make new attachment with properties {file name:\"${theAttachment1}\"} at after the last paragraph
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

firstrun_check() {
  if [[ ! -e "$HOME"/Library/Preferences/org.w0lf.cDock.plist ]]; then
    do_firstrun=true
  else
    do_firstrun=false
  fi
}

firstrun_display_check() {
  if [[ $do_firstrun = "true" ]]; then
  	first_run_window
  else
  	vernum=$($PlistBuddy "Print version" "$cdock_pl")
  	if [[ $(verres $curver $vernum) = ">" ]]; then app_has_updated; fi
  fi
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
	dock_findtrashname
	dock_hide_tooltips=$($PlistBuddy "Print TrashName" "$dock_trashname" || echo Trash)
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
	launch_menu_applet=$($PlistBuddy "Print menu_applet:" "$cdock_pl" 2>/dev/null || { $PlistBuddy "Add menu_applet integer 1" "$cdock_pl"; echo 1; })

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
			open -R "$app_themes"
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

	plistbud "Set" "cdockActive" "integer" "1" "$cdock_pl"
	#$PlistBuddy "Set cdockActive 1" "$cdock_pl" || $PlistBuddy "Add cdockActive integer 1" "$cdock_pl"
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
	if ($start_agent); then
		killall -s cDock\ Agent || { echo -e "Starting dockmonitor"; open "$cdock_path"; }
	fi

	if ($reboot_dock); then killall "Dock"; fi
	if ($reboot_finder); then
		if [[ $(lsof -c Finder | grep MacOS/XtraFinder) ]]; then
			killall "Finder"
			open -b com.trankynam.XtraFinder
		elif [[ $(lsof -c Finder | grep MacOS/TotalFinder) ]]; then
			killall "Finder"
			open -b com.binaryage.totalfinder
		else
			killall "Finder"
		fi
	fi

	exec "$injec_path" &

	# logging info
	ls -l "$HOME"/Library/Application\ Support/SIMBL/Plugins
	ls -l /Library/Application\ Support/SIMBL/Plugins

	custom_dock=false
	install_dock=false
	reboot_finder=false
	reboot_dock=false
	start_agent=false
}

launch_agent() {
	# Blacklist apps that have been reported to crash for SIMBL
	espl=("$HOME"/Library/Preferences/com.github.norio-nomura.SIMBL-Agent.plist "$HOME"/Library/Preferences/net.culater.SIMBL_Agent.plist)
	for zzz in ${espl[@]}; do
		if [[ ! -s "$zzz" ]]; then rm "$zzz"; fi
		$PlistBuddy "Add SIMBLApplicationIdentifierBlacklist array" "$zzz" &>/dev/null
		plistbud "Set" "SIMBLApplicationIdentifierBlacklist:0" "string" "com.skype.skype" "$zzz"
		plistbud "Set" "SIMBLApplicationIdentifierBlacklist:1" "string" "com.FilterForge.FilterForge4" "$zzz"
	done
	# Add agent to startup items
	osascript <<EOD
		tell application "System Events"
			make new login item at end of login items with properties {path:"$cdock_path", hidden:false}
		end tell
EOD
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

sync_themes() {
  if [[ ! -e "$HOME/Library/Application Support/cDock/themes" ]]; then
    rsync -ruv "$app_support"/ "$HOME"/Library/Application\ Support/cDock
  fi
}

tooltips_hide() {
	if [[ ! -e "$backup_name_data" ]]; then tooltips_record_name_data; fi
	ask_pass
  dock_findtrashname
	sudo $PlistBuddy "Set TrashName \"\"" "$dock_trashname"
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
