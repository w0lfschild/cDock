#!/bin/bash

pashua_run() {

	# Write config file
	pashua_configfile=`/usr/bin/mktemp /tmp/pashua_XXXXXXXXX`
	echo "$1" > $pashua_configfile

	# Find Pashua binary. We do search both . and dirname "$0"
	# , as in a doubleclickable application, cwd is /
	bundlepath="Pashua.app/Contents/MacOS/Pashua"
	if [ "$3" = "" ]
	then
		mypath=`dirname "$0"`
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

} # pashua_run()

#update_info=$(cat /tmp/wUpdater_log.txt)
update_info=$(sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/[return]/g' /tmp/wUpdater_log.txt)

conf="
*.transparency=1
*.title = Updates availible

# Update text
tb.type = textbox
tb.default = $update_info
tb.height = 250
tb.width = 450
tb.disabled = 1
tb.rely = -18

# Auto install
checkers.type = checkbox
checkers.label = Automatically download and install updates
checkers.default = 0
checkers.rely = -10

# Add a cancel button with default label
cb.type=cancelbutton
cb.label=Cancel

db.type = defaultbutton
db.label = Download and Install

b.type = button
b.label = Don't ask again
"

pashua_run "$conf" 'utf8'

echo "Pashua created the following variables:"
echo "  tb  = $tb"
echo "  tx  = $tx"
echo "  ob  = $ob"
echo "  pop = $pop"
echo "  rb  = $rb"
echo "  cb  = $cb"
echo ""

## Notes ##
# Show Only Active Applications
# defaults write com.apple.dock static-only -bool true
# 
# Change the Maximum Magnification Level
# defaults write com.apple.dock largesize -float 256
# 
# Change the Dock’s Position // Mav only
# defaults write com.apple.dock pinning -string start
# start, end, middle
# 
# Dim hidden items
# defaults write com.apple.dock showhidden -bool true
# 
# Add recent items stack
# defaults write com.apple.dock persistent-others -array-add '{ "tile-data" = { "list-type" = 1; }; "tile-type" = "recents-tile"; }'
# 
# App spacer
# defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="spacer-tile";}'
# 
# Documents spacer
# defaults write com.apple.dock persistent-others -array-add '{tile-data={}; tile-type="spacer-tile";}'
#
# Lock dock contents
# defaults write com.apple.Dock contents-immutable -bool true
#
# Mouse over highlight
# defaults write com.apple.dock mouse-over-hilite-stack -bool true
#
# Position on screen
#
#


