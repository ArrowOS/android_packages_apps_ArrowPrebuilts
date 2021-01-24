#!/bin/bash

#Constants
CUR_DIR=$(pwd)
DOWN_PATH="$ANDROID_BUILD_TOP/packages/apps/ArrowPrebuilts"
commit_msg=()

#jq check
is_jq=$(which jq)
if [[ -z $is_jq ]]; then
    echo "please install jq (ubuntu)"
    echo "sudo apt install jq"
    exit 0
fi

function fetchPrebuilts() {

    if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
        if [ $1 != "Lawnchair" ]; then
            gh_json=$(curl -s -H "Authorization: token 6b206e2a1fd038dd40b5cee94fafcf556bf19147" "$2")
            file_last_update=$(echo $gh_json | jq -r '.assets[0].updated_at' | date -d `cut -f1 -d"T"` +"%Y%m%d")
            apk_down_url=$(echo $gh_json | jq -r '.assets[0].browser_download_url')
        else
            file_last_update=$(curl -s -L "$2" | grep "latest.apk" | awk '{print $3}')
            file_last_update=$(date -d"$file_last_update" +"%Y%m%d")
            apk_down_url="${2}/latest.apk"
        fi

        if [[ -f "${DOWN_PATH}/${1}/${1}.apk" ]]; then
            FILE_DATE=$(/bin/date +%Y%m%d -d "$(/usr/bin/stat -c %x "${DOWN_PATH}/${1}/${1}.apk")")
        else
            FILE_DATE=000000
        fi

        if [[ $FILE_DATE -ge $file_last_update ]]; then
            echo "We already have the latest version of ${1}"
        else
            echo "Grabbing the latest version of ${1}"
            wget -q -O "${DOWN_PATH}/${1}/${1}.apk" $apk_down_url

            commit_msg+=("- ${1}: Updated to latest build [$file_last_update]\n")

            echo "${1} updated to latest version"
            cd $CUR_DIR
        fi
    else
        echo "Looks like theres no internet connection"
        if [[ -f "${DOWN_PATH}/${1}/${1}.apk" ]]; then
            echo "An old version of ${1} exists, using it for now."
        else
            echo "Nothing found! ${1} won't be available in this build!"
            fi
    fi
}

# parameters
# 1 - App name
# 2 - App apk url
fetchPrebuilts DuckDuckGo https://api.github.com/repos/duckduckgo/Android/releases/latest
fetchPrebuilts SimpleCalendar https://api.github.com/repos/SimpleMobileTools/Simple-Calendar/releases/latest
fetchPrebuilts SimpleGallery https://api.github.com/repos/SimpleMobileTools/Simple-Gallery/releases/latest
fetchPrebuilts Lawnchair https://lawnchairmirror.duckdns.org/lawnchair/latest

# git commit stage
if [ ${#commit_msg[@]} -ne 0 ]; then
    cd $DOWN_PATH
    git add .

    git commit -m "ArrowPrebuilts: Update [check description]" -m "$(echo -e ${commit_msg[*]})"
    echo "Committed locally, push to gerrit!"
fi
