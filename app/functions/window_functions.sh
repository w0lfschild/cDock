#! /bin/bash

# Functions pertaining to drawing cDocks main windows

evaltxt() { txty=$((txty - 24)); }
evalsel() { sely=$((sely - 24)); }
evalchx() { chxy=$((chxy - 20)); }

window_setup () {
  # lang=$(locale | grep LANG | cut -d\" -f2 | cut -d_ -f1)
  app_windows="$scriptDirectory"/windows/en
  lang=$($PlistBuddy "print AppleLanguages:0" "$home/Library/Preferences/.GlobalPreferences.plist")
  if [[ $lang = "" ]]; then
    lang=$($PlistBuddy "print AppleLocale" "$home/Library/Preferences/.GlobalPreferences.plist" | cut -d_ -f1)
  fi
  if [[ $lang != "" ]]; then
    if [[ -e "$scriptDirectory"/windows/"$lang" ]]; then
      app_windows="$scriptDirectory"/windows/"$lang"
    fi
  fi

  # app_windows="$scriptDirectory"/windows/it   # Testing...
  main_window_establish
  settings_window_establish
}

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
	img.path = $app_directory/Contents/Resources/appIcon.icns"
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
  swchk12.default = $launch_menu_applet
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
  swchk12.default = $swchk12
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
	txty=220
	sely=214
	chxy=218
	if [[ "$mvr" = "<" ]]; then
		txty=250
		sely=244
		chxy=248
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
	chk13.tooltip = When enabled folders set to list view will use larger icons and allow dragging icons just like in grid view.
	chk13.type = checkbox
	chk13.label = Improved list view
	chk13.default = $dock_use_new_list_stack
	chk13.x = 225
	chk13.y = $chxy"
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
		pop4.default = $pop4
    chk13.default = $chk13"
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
