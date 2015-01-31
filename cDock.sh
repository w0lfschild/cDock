#!/bin/bash

# # # # # # # # # # # # # # # # # # # # 
#
# Maintained By	: Wolfgang Baird
# Version		: 6.4.0.2
# Updated		: Jan / 31 / 2015
#
# # # # # # # # # # # # # # # # # # # # 

# Required for pashua windows
pashua_run() {

	# Write config file
	pashua_configfile=`/usr/bin/mktemp /tmp/pashua_XXXXXXXXX`
	echo "$1" > $pashua_configfile

	# Find Pashua binary. We do search both . and dirname "$0"
	# , as in a doubleclickable application, cwd is /
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

# Only run if we have a newer version then the last time cDock was opened
has_updated() {
	# Read current theme if there is one
	current_theme=$($PlistBuddy "Print theme:" "$cdock_pl" 2>/dev/null || echo -n None)
	
	# Directory junk
	dir_check /tmp/cDock_junk/active
	dir_check /tmp/cDock_junk/themes
	dir_check "$HOME"/Library/Application\ Support/cDock/theme_stash
	
	# Save current theme and theme folder
	rsync -ru "$HOME"/Library/Application\ Support/cDock/themes/"$current_theme" /tmp/cDock_junk/active
	rsync -ru "$HOME"/Library/Application\ Support/cDock/themes /tmp/cDock_junk
	rsync -ru "$HOME"/Library/Application\ Support/cDock/logs /tmp/cDock_junk
	
	# Clean out everything cDock
	app_clean			
	directory_setup
	
	# Move back application support directory
	rsync -ruv "$app_support"/ "$HOME"/Library/Application\ Support/cDock
	
	# Move back bundles if they were installed
	(($colorfulsidebar_active)) && { ln -s "$app_bundles"/ColorfulSidebar.bundle "$HOME/Library/Application Support"/SIMBL/Plugins/ColorfulSidebar.bundle; defaults write org.w0lf.cDock colorfulsidebarActive 1; launch_agent; }
	(($cdock_active)) && { ln -s "$app_bundles"/cDock.bundle "$HOME/Library/Application Support"/SIMBL/Plugins/cDock.bundle; defaults write org.w0lf.cDock cdockActive 1; launch_agent; }
	defaults write org.w0lf.cDock theme "$current_theme"
	
	# Move back theme folder and current theme if one was active
	rsync -ru /tmp/cDock_junk/themes/ "$HOME"/Library/Application\ Support/cDock/theme_stash
	rsync -ru /tmp/cDock_junk/active/"$current_theme" "$HOME"/Library/Application\ Support/cDock/themes
	rsync -ru /tmp/cDock_junk/logs "$HOME"/Library/Application\ Support/cDock
}

# Version checking
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

# Directories settup and checking
dir_check() {
	if [[ ! -e "$1" ]]; then mkdir -pv "$1"; fi
}
directory_setup() {
	dir_check "$HOME"/Library/Application\ Support/cDock
	dir_check "$HOME"/Library/Application\ Support/cDock/logs
	dir_check "$HOME"/Library/Application\ Support/SIMBL/Plugins
	dir_check "$HOME"/Library/Application\ Support/wUpdater/logs
}

# Logging
logging() {
	log_dir="$HOME"/Library/Application\ Support/cDock/logs
	for (( c=1; c<6; c++ )); do if [ ! -e "$log_dir"/${c}.log ]; then touch "$log_dir"/${c}.log; fi; done
	for (( c=5; c>1; c-- )); do cat "$log_dir"/$((c - 1)).log > "$log_dir"/${c}.log; done
	> "$log_dir"/1.log
	exec &>"$log_dir"/1.log
	echo "This is some basic logging information about your system and what is installed on it"
	echo "This should also contain information about the last time cDock was run"
	echo "This is not uploaded unless you email it to me"
	echo ""
	echo "Feel free to browse through this and remove anything you do not feel comfortable sharing"
	echo ""
	sw_vers
	echo "ScriptDirectory: $scriptDirectory"
	echo "Date: $(date)"
	echo -e "\n\n"
	ls -dl "$HOME/Library/Application Support"
	echo -e "\n\n"
	ls -dl "$HOME/Library/Preferences/org.w0lf.cDock.plist"
	$PlistBuddy "Print" "$cdock_pl"
	echo -e "\n\n"
	app_array=""
	for app in /Applications/*; do
		if [[ "$app" = *.app ]]; then
app_array="$(basename "$app") $($PlistBuddy "Print CFBundleVersion:" "$app"/Contents/Info.plist) $($PlistBuddy "Print CFBundleIdentifier:" "$app"/Contents/Info.plist)
$app_array"	
		fi
	done && echo "$app_array" > "$log_dir"/apps.log &
}

# Check location
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

# Update checking
check_for_updates() {
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

# Launch agent setup
launch_agent() {
	# Blacklist apps that have been reported to crash for SIMBL
	#defaults write com.github.norio-nomura.SIMBL-Agent "SIMBLApplicationIdentifierBlacklist" '("com.skype.skype")'
	$PlistBuddy "Add SIMBLApplicationIdentifierBlacklist array" "$HOME"/Library/Preferences/com.github.norio-nomura.SIMBL-Agent.plist
	$PlistBuddy "Add SIMBLApplicationIdentifierBlacklist: string com.skype.skype" "$HOME"/Library/Preferences/com.github.norio-nomura.SIMBL-Agent.plist
	
	# Add agent to startup items
	osascript <<EOD
		tell application "System Events"
			make new login item at end of login items with properties {path:"$cdock_path", hidden:false}
		end tell
EOD
}

# Bundles 
install_finder_bundle() {
	launch_agent
	
	# Symbolic link bundle
	if [[ ! -e "$HOME/Library/Application Support/SIMBL/Plugins/ColorfulSidebar.bundle" ]]; then ln -s "$app_bundles"/ColorfulSidebar.bundle "$HOME/Library/Application Support"/SIMBL/Plugins/ColorfulSidebar.bundle; fi
	
	# 10.10+ checking to determine icon plist
	mvr=$(verres $(sw_vers -productVersion) "10.10")
	icns="icons10.9.plist"
	if [[ $mvr != "<" ]]; then icns="icons10.10.plist"; fi		
	cp -f "$app_bundles"/"$icns" "$app_bundles"/ColorfulSidebar.bundle/Contents/Resources/icons.plist
	
	# Finish up
	$PlistBuddy "Set colorfulsidebarActive 1" "$cdock_pl"
	killfinder=true
	dockify=true
	echo -n "Finished installing"
}
install_cdock_bundle() {
	launch_agent
	
	rsync -ruv "$app_support"/ "$HOME"/Library/Application\ Support/cDock
	
	# Symbolic link bundle
	if [[ ! -e "$HOME/Library/Application Support/SIMBL/Plugins/cDock.bundle" ]]; then ln -s "$app_bundles"/cDock.bundle "$HOME/Library/Application Support"/SIMBL/Plugins/cDock.bundle; fi
	
	# Mirror check
	if [[ $($PlistBuddy "Print hide-mirror:" "$dock_plist") != false ]]; then defaults write com.apple.dock hide-mirror -bool false; fi
	
	# DockMod check
	if [[ $($PlistBuddy "Print dockmod-enabled:" "$dock_plist") != false ]]; then defaults write com.apple.dock dockmod-enabled -bool false; fi
	
	# If custom dock is selected open settings and "instructions" for user also open dock refresher
	if ($customdock); then 
		open ./"Dock Refresh".app
		open -e "$HOME"/Library/Application\ Support/cDock/themes/Custom/settings.txt
		open -e "$HOME"/Library/Application\ Support/cDock/settings\ info.rtf
		customdock=false
	fi
	
	$PlistBuddy "Delete cdockActive" "$cdock_pl"
	$PlistBuddy "Add cdockActive integer 1" "$cdock_pl"
	defaults write org.w0lf.cDock theme -string "${dock_theme}"
	dockify=true
}

# Preferences
get_preferences() {
	dock_static_only=$($PlistBuddy "Print static-only:" "$dock_plist" 2>/dev/null || echo 0)															# Show Only Active Applications
	dock_largesize=$($PlistBuddy "Print largesize:" "$dock_plist" 2>/dev/null || echo 42) 																# Maximum Magnification Level
	dock_pinning=$($PlistBuddy "Print pinning:" "$dock_plist" 2>/dev/null || echo middle) 																# Dock Position // Mav only (start, end, middle)
	dock_showhidden=$($PlistBuddy "Print showhidden:" "$dock_plist" 2>/dev/null || echo 1) 																# Dim hidden items
	dock_contents_immutable=$($PlistBuddy "Print contents-immutable:" "$dock_plist" 2>/dev/null || echo 0) 												# Lock dock contents
	dock_mouse_over_hilite_stack=$($PlistBuddy "Print mouse-over-hilite-stack:" "$dock_plist" 2>/dev/null || echo 0) 									# Mouse over highlight
	
	update_auto_check=$($PlistBuddy "Print autoCheck:" "$cdock_pl" 2>/dev/null || { $PlistBuddy "Add autoCheck integer 1" "$cdock_pl"; echo -n 1; } ) 			# Automatic update checking
	update_auto_install=$($PlistBuddy "Print autoInstall:" "$cdock_pl" 2>/dev/null || { $PlistBuddy "Add autoInstall integer 0" "$cdock_pl"; echo -n 0; } ) 	# Automatic update installation
	beta_updates=$($PlistBuddy "Print betaUpdates:" "$cdock_pl" 2>/dev/null || echo -n 0) 																		# Beta updates
	displayWarning=$($PlistBuddy "Print displayWarning:" "$cdock_pl" 2>/dev/null || echo 1) 																	# Display SIMBL warnings
	
	if [[ $dock_static_only = true ]]; then dock_static_only=1; else dock_static_only=0; fi
	if [[ $dock_showhidden = true ]]; then dock_showhidden=1; else dock_showhidden=0; fi
	if [[ $dock_contents_immutable = true ]]; then dock_contents_immutable=1; else dock_contents_immutable=0; fi
	if [[ $dock_mouse_over_hilite_stack = true ]]; then dock_mouse_over_hilite_stack=1; else dock_mouse_over_hilite_stack=0; fi
}

# Do things when apply is clicked
get_results() {
		# Custom dock
		if [[ $pop0 = "Current" ]]; then
			echo "???"
			install_dock=false
		elif [[ $pop0 = "Custom" ]]; then	
			customdock=true
			install_dock=true
			dock_theme="${pop0}"
		elif [[ $pop0 = "None" ]]; then
			install_dock=false
			file_cleanup "$HOME"/Library/Application\ Support/SIMBL/Plugins/cDock.bundle
			$PlistBuddy "Delete cdockActive" "$cdock_pl"
			$PlistBuddy "Add cdockActive 0" "$cdock_pl"
			#defaults write org.w0lf.cDock theme -string "None"
			killall "Dock"
		else
			echo "$pop0"
			install_dock=true
			dock_theme="${pop0}"
		fi
		
		# Finder colored sidebars
		install_finder=false
		if [[ $chk1 -eq 1 ]]; then
			if [[ ! -e "$HOME"/Library/Application\ Support/SIMBL/Plugins/ColorfulSidebar.bundle ]]; then { install_finder_bundle; install_finder=true; } fi
		else
			if [[ -e "$HOME"/Library/Application\ Support/SIMBL/Plugins/ColorfulSidebar.bundle ]]; then 
				file_cleanup "$HOME"/Library/Application\ Support/SIMBL/Plugins/ColorfulSidebar.bundle
				$PlistBuddy "Set colorfulsidebarActive 0" "$cdock_pl"
				killall "Finder"
			fi
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
		if [[ $found_Warning = "1" && $displayWarning = "1" ]]; then alw; fi
			
		
		# dupe dock plist
		pl_alt=/tmp/com.apple.dock.plist
		cp -f "$dock_plist" "$pl_alt"
		
 		# Show Only Active Applications
		if [[ $chk2 -eq 1 ]]; then
			$PlistBuddy "Set static-only true" $pl_alt
		else
			$PlistBuddy "Set static-only false" $pl_alt
		fi
		
		# Dim hidden items
		if [[ $chk3 -eq 1 ]]; then
			$PlistBuddy "Set showhidden true" $pl_alt
		else
			$PlistBuddy "Set showhidden false" $pl_alt
		fi
		
		# Lock dock contents
		if [[ $chk4 -eq 1 ]]; then
			$PlistBuddy "Set contents-immutable true" $pl_alt
		else
			$PlistBuddy "Set contents-immutable false" $pl_alt
		fi
		
		# Mouse over highlight
		if [[ $chk5 -eq 1 ]]; then
			$PlistBuddy "Set mouse-over-hilite-stack true" $pl_alt
		else
			$PlistBuddy "Set mouse-over-hilite-stack false" $pl_alt
		fi
		
		# Change the Dock’s Position // Mav only
		if [[ $pop4 != "" ]]; then
			$PlistBuddy "Set pinning $pop4" $pl_alt
		fi
		
		# App icon counts
		a_count=$($PlistBuddy "Print persistent-apps:" $pl_alt | grep -a "    Dict {" | wc -l)
		a_count=$(( $a_count - 1 ))
		a_spacers=$($PlistBuddy "Print persistent-apps:" $pl_alt | grep -a "spacer-tile" | wc -l)
		
		# Document icon counts
		d_count=$($PlistBuddy "Print persistent-others:" $pl_alt | grep -a "    Dict {" | wc -l)
		d_count=$(( $d_count - 1 ))
		d_spacers=$($PlistBuddy "Print persistent-others:" $pl_alt | grep -a "spacer-tile" | wc -l)
		
		# Recent Items Folder
		if [[ $chk6 -eq 1 ]]; then
			(( $($PlistBuddy "Print persistent-others:" $pl_alt | grep -a recents-tile | wc -l) )) || { $PlistBuddy "Add persistent-others: dict" $pl_alt; $PlistBuddy "Add persistent-others:$d_count:tile-type string recents-tile" $pl_alt; $PlistBuddy "Add persistent-others:$d_count:tile-data dict" $pl_alt; $PlistBuddy "Add persistent-others:$d_count:tile-data:list-type integer 1" $pl_alt; }	
		else
			for (( idx=0; idx < $d_count; idx++ )); do
				if [[ $($PlistBuddy "Print persistent-others:$idx:tile-type" $pl_alt) = "recents-tile" ]]; then
					$PlistBuddy "Delete persistent-others:$idx" $pl_alt
					idx=$_count
				fi
			done
		fi
		
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
		if [[ $pop91 = "Disabled" ]]; then
			$PlistBuddy "Set magnification bool false" $pl_alt
		else
			$PlistBuddy "Set magnification bool true" $pl_alt
			$PlistBuddy "Set largesize $pop91" $pl_alt
		fi
		
		# Tile (Icon) size
		$PlistBuddy "Set tilesize $pop90" $pl_alt
		
		# push plist changes
		defaults import com.apple.dock $pl_alt
}

# Clean possibly outdated files
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
	
	$PlistBuddy "Set cdockActive 0" "$cdock_pl"
	$PlistBuddy "Set colorfulsidebarActive 0" "$cdock_pl"
	defaults write org.w0lf.cDock theme -string "None"
	
	osascript -e 'tell application "System Events" to delete login item "cDock Agent"'
	
	echo "Cleaned"
}

# Move non cDock bundles
simbl_disable() {
		dir_check "$HOME/Library/Application Support/SIMBL/Disbaled"
		for item in "$plugin_list_1"; do
			bundle_name=$(basename "$item")
			item=$(echo $item)
			mv "$item" "$HOME/Library/Application Support/SIMBL/Disbaled/$bundle_name"
		done
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

about_cDock() {
	echo "Sample Text"
}

backup_dock_plist() {
	dir_check "$save_folder"
	my_time=$(date)
	cp -v "$dock_plist" "$save_folder"/"$my_time".plist
}

# 
#	Pushua Windows
#

evaltxt() { txty=$((txty - 24)); }
evalsel() { sely=$((sely - 24)); }
evalchx() { chxy=$((chxy - 20)); }

# First timers only
frw() {
	source "$app_windows"/welcome.txt
	welcome="$welcome
	img.path = "$app_directory"/Contents/Resources/appIcon.icns
	"
	pashua_run "$welcome" 'utf8'
}

# Alert
alw() {
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
		cb_.type = cancelbutton
		cb_.label = Cancel
	
		# Accept button
		db_.type = defaultbutton
		db_.label = Continue
	"
	pashua_run "$alertz" 'utf8'
	
	if [[ $zzz = "1" ]]; then zzz=0; else zzz=1; fi
	$PlistBuddy "Add displayWarning integer $zzz" "$cdock_pl"
	if [[ $db_ -eq 1 ]]; then
		simbl_disable
	fi
}

# Settings Window
establish_settings_window() {
	settings_window=$(cat "$app_windows"/settings.txt)
	settings_window="$settings_window
swchk0.default = $update_auto_check
swchk3.default = $beta_updates
swchk2.default = $update_auto_install
swchk5.default = $displayWarning
swpop0.option = Select a resotre point
swchk6.default = 0
swchk4.default = 0
swchk1.default = 0
swOK.type = defaultbutton"

	# backups
	if ! [[ -e "$save_folder" ]]; then echo "Backups folder doesn't exist!"; fi
	for bk in "$save_folder/"*
	do
		if [[ "$bk" != *"*" ]]; then
			file_name=$(basename "$bk")
			settings_window="$settings_window
swpop0.option = $file_name"
		fi
	done
}
update_settings_window() {
	settings_window=$(echo "$settings_window" | sed -e "/default/d")
	settings_window="$settings_window
swchk0.default = $swchk0
swchk3.default = $swchk3
swchk2.default = $swchk2
swchk5.default = $swchk5
swpop0.option = Select a resotre point
swchk6.default = 0
swchk4.default = 0
swchk1.default = 0
swOK.type = defaultbutton"

	# backups
	if ! [[ -e "$save_folder" ]]; then echo "Backups folder doesn't exist!"; fi
	for bk in "$save_folder/"*
	do
		if [[ "$bk" != *"*" ]]; then
			file_name=$(basename "$bk")
			settings_window="$settings_window
swpop0.option = $file_name"
		fi
	done
}
draw_settings_window() {
	swOK=0
	swchk0=0
	swchk2=0
	
	pashua_run "$settings_window" 'utf8'
	
	if [[ $swOK -eq 1 ]]; then
		update_settings_window
		
		$PlistBuddy "Delete autoCheck" "$cdock_pl"
		$PlistBuddy "Add autoCheck integer $swchk0" "$cdock_pl"
		$PlistBuddy "Delete autoInstall" "$cdock_pl"
		$PlistBuddy "Add autoInstall integer" "$cdock_pl"
		$PlistBuddy "Delete betaUpdates" "$cdock_pl"
		$PlistBuddy "Add betaUpdates integer $swchk3" "$cdock_pl"
		$PlistBuddy "Delete displayWarning" "$cdock_pl"
		$PlistBuddy "Add displayWarning integer $swchk5" "$cdock_pl"
		(($swchk1)) && { $PlistBuddy "Set lastupdateCheck 0" "$cdock_pl"; check_for_updates; }
		(($swchk4)) && { if [[ "$swpop0" != "Select a resotre point" ]]; then defaults import "$dock_plist" "$save_folder"/"$swpop0"; killall Dock; establish_main_window; refresh_win=true; fi; }
		(($swchk6)) && { app_clean; killall Dock; }
	fi
}

# Main Window
establish_main_window() {
	txty=184
	sely=180
	chxy=184
	
	if [[ $curver = *.*.*.* ]]; then
		my_title="cDock Beta - $curver"
	else
		my_title="cDock - $curver"
	fi

	# Window Appearance
	main_window="$main_window
*.title = $my_title
*.floating = 1
*.transparency = 1.00
*.autosavekey = cDock"
	
	# Theme
	main_window="$main_window
tb0.tooltip = Custom Dock themes will replace the Dock background with something different. 3D themes only show with the dock set to the bottom otherwise the Dock will appear transparent.
tb0.type = text
tb0.height = 0
tb0.width = 150
tb0.x = 0
tb0.y = $txty"
	
	main_window="$main_window	
pop0.type = popup
pop0.width = 120
pop0.option = None
pop0.x = 80
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
	
	# Dock position
	mvr=$(verres $(sw_vers -productVersion) "10.10")
	if [[ "$mvr" = "<" ]]; then
		main_window="$main_window
tb4.type = text
tb4.height = 0
tb4.width = 150
tb4.x = 0
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
tb11.tooltip = Magnification level of the dock. Having this option set to anything other than Disabled will make your Dock icons grow larger as you move your mouse over them. Higher numbers mean larger icons.
tb11.type = text
tb11.height = 0
tb11.width = 150
tb11.x = 0
tb11.y = $txty"
	
	main_window="$main_window
pop91.type = popup
pop91.width = 100
pop91.x = 100
pop91.y = $sely"
	
	main_window="$main_window
pop91.option = Disabled";		
	
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
pop91.default = Disabled"
	fi
	
	evaltxt
	evalsel
	
	# Tile Size
	main_window="$main_window
tb10.tooltip = Size of the dock icons in square pixels.
tb10.type = text
tb10.height = 0
tb10.width = 150
tb10.x = 0
tb10.y = $txty"
		
	main_window="$main_window
pop90.type = popup
pop90.width = 60
pop90.x = 140
pop90.y = $sely"
			
	for val in {16..128}; do 
		main_window="$main_window
pop90.option = $val"; 
	done
	
	tsize=$($PlistBuddy "Print tilesize:" "$dock_plist")
	tsize=${tsize%%.*}
	main_window="$main_window
pop90.default = $tsize"
	
	evaltxt
	evalsel
	
	# App spacer text
	main_window="$main_window
tb1.tooltip = Application spacers are simply a transparent icon. They can be dragged and re-arranged in the dock however you would like. To remove an application spacer either drag it out of the dock or right click on it to get the remove option.
tb1.type = text
tb1.height = 0
tb1.width = 150
tb1.x = 0
tb1.y = $txty"
	evaltxt
	
	# App spacers
	for val in {0..10}; do 
		main_window="$main_window
pop1.option = $val"; 
	done
	
	main_window="$main_window
pop1.type = popup
pop1.width = 50
pop1.default = $($PlistBuddy "Print persistent-apps:" "$dock_plist" | grep -a "spacer-tile" | wc -l)
pop1.x = 150
pop1.y = $sely"
	evalsel
	
	# Doc spacers text
	main_window="$main_window
tb2.tooltip = Document spacers are simply a transparent icon. They can be dragged and re-arranged in the dock however you would like. To remove a document spacer either drag it out of the dock or right click on it to get the remove option.
tb2.type = text
tb2.height = 0
tb2.width = 150
tb2.x = 0
tb2.y = $txty"
	evaltxt
	
	# Doc spacers
	
	for val in {0..10}; do 
		main_window="$main_window
pop2.option = $val"; 
	done
	
	main_window="$main_window
pop2.type = popup
pop2.width = 50
pop2.default = $($PlistBuddy "Print persistent-others:" "$dock_plist" | grep -a "spacer-tile" | wc -l)
pop2.x = 150
pop2.y = $sely"
	evalsel
	
	# Active applications
	main_window=$main_window"
chk2.tooltip = With this option enabled the Dock will only show icons of running (open) applications. Everything else will be hidden.
chk2.type = checkbox
chk2.label = Show only active apps
chk2.default = $dock_static_only
chk2.x = 225
chk2.y = $chxy"
	evalchx
	
	# Dim hidden items
	main_window=$main_window"
chk3.tooltip = With this option enabled open applications that are hidden using (⌘+H) will appear dim in the Dock.
chk3.type = checkbox
chk3.label = Dim hidden items
chk3.default = $dock_showhidden
chk3.x = 225
chk3.y = $chxy"
	evalchx
	
	# Lock dock contents
	main_window=$main_window"
chk4.tooltip = Having this option enabled will prevent you from adjusting the contents of the Dock.
chk4.type = checkbox
chk4.label = Lock dock contents
chk4.default = $dock_contents_immutable
chk4.x = 225
chk4.y = $chxy"
	evalchx
	
	# Mouse over highlight
	main_window=$main_window"
chk5.tooltip = Having this option enabled will add mouse over highlight when viewing folders in the Dock in the Grid view.
chk5.type = checkbox
chk5.label = Mouse over highlight
chk5.default = $dock_mouse_over_hilite_stack
chk5.x = 225
chk5.y = $chxy"
	evalchx
	
	# Recents Folder
	rf_en=$($PlistBuddy "Print persistent-others:" $dock_plist | grep -a recents-tile | wc -l)
	main_window=$main_window"
chk6.tooltip = Show recent items folder in Dock. Can be set to show Applications, Documents, Servers, Volumes or Items with a right or control click.
chk6.type = checkbox
chk6.label = Recents folder
chk6.default = $rf_en
chk6.x = 225
chk6.y = $chxy"
	evalchx
	
	# Hide tooltips
	main_window=$main_window"
chk7.tooltip = Hide or show application name popups on the Dock. Finder, Trash and New items added to the Dock will still show.
chk7.type = checkbox
chk7.label = Hide item tooltips
chk7.disabled = 1
chk7.default = 0
chk7.x = 225
chk7.y = $chxy"
	evalchx
	
	# Colored Finder sidebar
	# evalchx
	main_window=$main_window"
chk1.tooltip = Having this option enabled will add color to your Finder sidebar.
chk1.type = checkbox
chk1.label = Colored Finder sidebar
chk1.default = $colorfulsidebar_active
chk1.x = 225
chk1.y = $chxy"
	evalchx
	
	# Settings button
	main_window=$main_window"	
settingb.type = button
settingb.label = Settings
settingb.x = -6
settingb.y = 22"
	
	# Email button
	main_window=$main_window"	
emailb.type = button
emailb.label = Email
emailb.x = -6
emailb.y = 0"
	
	# Donate button
	main_window=$main_window"
donateb.type = button
donateb.label = Donate 
donateb.x = 80
donateb.y = 22"
		
	# Bug report
	main_window=$main_window"
bugb.type = button
bugb.label = Report
bugb.x = 80
bugb.y = 0"
	
	# Cancel button
	main_window=$main_window"
cb.type = cancelbutton
cb.label = Quit"
	
	# Accept button
	main_window=$main_window"
db.label = Apply"

}
update_main_window() {
	main_window=$(echo "$main_window" | sed -e "/default/d")
	main_window="$main_window
db.type = defaultbutton

tb0.default = Dock theme:
tb1.default = Application spacers:
tb2.default = Document spacers:
tb10.default = Icon Size:
tb11.default = Magnification:

chk1.default = $chk1
chk2.default = $chk2
chk3.default = $chk3
chk4.default = $chk4
chk5.default = $chk5
chk6.default = $chk6

pop0.default = $pop0
pop1.default = $pop1
pop2.default = $pop2

pop90.default = $pop90
pop91.default = $pop91"
		
	# Themes
	if ! [[ -e "$app_themes" ]]; then echo "User themes folder doesn't exist!"; fi
	for theme in "$HOME/Library/Application Support/cDock/themes/"*
	do
		theme_name=$(basename "$theme")
		main_window="$main_window
pop0.option = $theme_name"
	done
		
	mvr=$(verres $(sw_vers -productVersion) "10.10")
	if [[ "$mvr" = "<" ]]; then
		main_window="$main_window
tb4.default = Dock position:
pop4.default = $pop4"
	fi
}
draw_main_window() {
	pashua_run "$main_window" 'utf8'

	# Settings button clicked
	if [[ $settingb -eq 1 ]]; then
		settingb=0
		
		# Open settings window
		draw_settings_window
		
		# Reopen main window when settings window closes
		if [[ $refresh_win = false ]]; then update_main_window; refresh_win=true; fi
		draw_main_window
	fi
	
	# Donate button clicked
	if [[ $donateb -eq 1 ]]; then 
		open "http://goo.gl/vF92sf"
	fi
	
	# Report bug button clicked
	if [[ $bugb -eq 1 ]]; then 
		open "https://sourceforge.net/p/cdock/tickets/new/"
		open -R "$HOME/Library/Application Support/cDock/logs/1.log" 
	fi
	
	# Email button clicked
	if [[ $emailb -eq 1 ]]; then
		email_me
	fi

	# Apply button clicked
	if [[ $db -eq 1 ]]; then
		db=0
		update_main_window
		{ backup_dock_plist; get_results; defaults write org.w0lf.cDock theme -string "$pop0"; do_stuff; } &
		draw_main_window		
	fi
}
do_stuff() {
	if ($install_dock); then install_cdock_bundle; fi
	killall "Dock"
	if ($killfinder); then killall "Finder"; fi
	if ($dockify); then
		open "$cdock_path"
		echo -e "Finished installing, starting dockmonitor...\n"
	fi
}

#
#	Variables
#

# String variables
start_time=$(date +%s)
scriptDirectory=$(cd "${0%/*}" && echo $PWD)
app_support="$scriptDirectory"/support
app_bundles="$scriptDirectory"/bundles
app_windows="$scriptDirectory"/windows
app_directory="$scriptDirectory"
for i in {1..2}; do app_directory=$(dirname "$app_directory"); done
cdock_path="$app_directory"/Contents/Resources/helpers/"cDock Agent".app
app_themes="$HOME"/Library/'Application Support'/cDock/themes
save_folder="$HOME"/Library/'Application Support'/cDock/.bak

PlistBuddy=/usr/libexec/PlistBuddy" -c"
dock_plist="$HOME"/Library/Preferences/com.apple.dock.plist
cdock_pl="$HOME"/Library/Preferences/org.w0lf.cDock.plist

curver=$($PlistBuddy "Print CFBundleShortVersionString" "$app_directory"/Contents/Info.plist)
main_window=""
settings_window=""
alert_window=""
first_run_window=""
dock_theme=""
plugin_list=""

# Boolean variables
customdock=false
dockify=false
install_dock=false
killfinder=false
refresh_win=false

#
#	App execution
#

# Find our location
where_are_we

# Start logging
logging

# Check firstrun
if [[ ! -e "$HOME"/Library/Preferences/org.w0lf.cDock.plist ]]; then do_firstrun=true; else do_firstrun=false; fi

# Read preferences
get_preferences

# Setup directories
directory_setup

# Check bundles
[ -e "$HOME"/Library/Application\ Support/SIMBL/Plugins/ColorfulSidebar.bundle ] && { colorfulsidebar_active=1; $PlistBuddy "Delete colorfulsidebarActive" "$cdock_pl"; $PlistBuddy "Add colorfulsidebarActive integer 1" "$cdock_pl"; }
[ -e "$HOME"/Library/Application\ Support/SIMBL/Plugins/cDock.bundle ] && { cdock_active=1; $PlistBuddy "Delete cdockActive" "$cdock_pl"; $PlistBuddy "Add cdockActive integer 1" "$cdock_pl"; }

# Check if app has been opened before and if it's a newer version than saved in the preferences
if [[ $do_firstrun = "true" ]]; then
	frw
else
	vernum=$($PlistBuddy "Print version" "$cdock_pl")
	if [[ $(verres $curver $vernum) = ">" ]]; then has_updated; fi
fi

# Make sure themes are synced
if [[ ! -e "$HOME/Library/Application Support/cDock/themes" ]]; then rsync -ruv "$app_support"/ "$HOME"/Library/Application\ Support/cDock; fi

# Version
$PlistBuddy "Delete version" "$cdock_pl"
$PlistBuddy "Add version string $curver" "$cdock_pl"

# Check for updates
if [[ $update_auto_check == 1 ]]; then 
	check_for_updates &
fi

# Set up windows
update_main_window
establish_main_window
update_settings_window
establish_settings_window

# Log time it took to open cDock
total_time=$(( $(date +%s) - $start_time ))
echo -e "Approximate startup time is ${total_time} seconds\n"

# Show main window
draw_main_window

#END