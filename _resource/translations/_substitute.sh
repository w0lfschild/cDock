#!/bin/bash

# v3
# replace eng with translation
# $1 = lang
# $2 = path to strings

scriptDirectory=$(cd "${0%/*}" && echo $PWD)
lang_="$1"
fold_="$scriptDirectory"/"$lang_"
file_=("$fold_"/main.txt "$fold_"/settings.txt "$fold_"/welcome.txt)

if [[ -e "$scriptDirectory"/"$lang_" ]]; then 
	if [[ $lang_ != en ]]; then
		rm -r "$scriptDirectory"/"$lang_"
	fi
fi

if [[ ! -e "$scriptDirectory"/"$lang_" ]]; then
	mkdir "$scriptDirectory"/"$lang_"
	cp -r "$scriptDirectory"/en/ "$scriptDirectory"/"$lang_"
	# echo "$scriptDirectory"/"$lang_"
fi
	
for i in "${file_[@]}"
do
   :
   while read p; do
   	if [[ $p != "" ]]; then
   		text_tag=$(echo "$p" | cut -d= -f1)
		fixed_text=$(echo "$p" | sed 's,/,\\/,g')
		# echo $fixed_text
   		# echo $text_tag
		# echo $p
   		sed -i.bak s/"^$text_tag.*"/"$fixed_text"/g "$i"
   	fi
   done <"$scriptDirectory"/"$lang_"_strings.txt
done

pushd "$fold_"
rm *.bak
popd

echo "FIN"