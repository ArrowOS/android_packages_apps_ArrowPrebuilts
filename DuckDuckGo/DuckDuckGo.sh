#!/bin/bash
gh_json_url=https://api.github.com/repos/duckduckgo/Android/releases/latest
CUR_DIR=$(pwd)
DOWN_PATH="$ANDROID_BUILD_TOP/packages/apps/ArrowPrebuilts/DuckDuckGo"

#jq check
is_jq=$(which jq)
if [[ -z $is_jq ]]; then
  echo "please install jq (ubuntu)"
  echo "sudo apt install jq"
  return
fi

if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
	gh_json=$(curl -s -H "Authorization: token af9277f574ba62458ae50e176a9948dee048afe7" "$gh_json_url")
	file_last_update=$(echo $gh_json | jq -r '.assets[0].updated_at' | date -d `cut -f1 -d"T"` +"%Y%m%d")
        apk_down_url=$(echo $gh_json | jq -r '.assets[0].browser_download_url')

	if [[ -f $DOWN_PATH/DuckDuckGo.apk ]]; then
		FILE_DATE=$(/bin/date +%Y%m%d -d "$(/usr/bin/stat -c %x $DOWN_PATH/DuckDuckGo.apk)")
	else
		FILE_DATE=000000
	fi

	if [[ $FILE_DATE -ge $file_last_update ]]; then
		echo "We already have the latest version of DuckDuckGo"
	else
		echo "Grabbing the latest version of DuckDuckGo"
		wget -q -O $DOWN_PATH/DuckDuckGo.apk $apk_down_url

		cd $DOWN_PATH
		git add .
		git commit -m "DuckDuckGo: Updated to latest build [$file_last_update]"

		echo "Updated to latest version and committed locally"
		echo "Push to gerrit"
		cd $CUR_DIR
	fi
else
	echo "Looks like theres no internet connection"
	if [[ -f $DOWN_PATH/DuckDuckGo.apk ]]; then
		echo "An old version of DuckDuckGo exists, using it for now."
	else
		echo "Nothing found! DuckDuckGo won't be available in this build!"
        fi
fi
