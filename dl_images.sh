#!/usr/bin/env bash

DATE=$(date +"%F")
TIME=$(date +"%T")
folder_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "$folder_path/functions_urls.sh" ]]; then echo "Missing functions_urls.sh file"; exit 1; fi

. "$folder_path/functions_urls.sh"

DEBUG="True"
USER_AGENT_FILE="$folder_path/.user_agent"
DATE_LIMIT="$(date +"%s" -d 1days)"
GOOGLE_PATH="/home/henri/Projects/scripts/google-images-download/google_images_download/google_images_download.py"
LOG_FILE="log.txt"

count=20
image="False"
monitor=""
srcs=()
searches=()
collections=()
while echo $1 | grep -q ^-; do
  case "$1" in
    -h|--help) usage; exit 0;;
    --folder) FOLDER="$2"; shift;;
    --count) count="$2"; shift;;
    --opt) option="$2"; shift;;
    --src) srcs+=("$2"); shift;;
    --search) searches+=("$2"); shift;;
    *) echo "Bad argument"; usage; exit 0;;
  esac
  shift
done

if [[ -z "${FOLDER+x}" ]]; then echo "Missing folder argument"; exit 1; fi
if [[ ! -d "$FOLDER" ]]; then mkdir -p "$FOLDER"; exit 1; fi

log_debug() { if [[ "$DEBUG" == "True" ]]; then echo $* >> "$LOG_FILE"; fi }

main() {
    source="${srcs[$(($RANDOM % ${#srcs[@]}))]}"

    for search in "${searches[@]}"; do
        folder="$FOLDER/$search"
        if [[ ! -d "$folder" ]]; then log_debug "folder creation $folder"; mkdir -p "$folder"; fi

        i=0
        while [[ $i -le $count ]]; do
            file_path=`get_wallpaper`
            echo "$file_path"
            ((i++))
        done
    done
}

get_wallpaper() {
    url_image=`get_image_from_${source}`
    if [[ "$url_image" == //* ]] || [[ "$url_image" == http://* ]] || [[ "$url_image" == https://* ]]; then
        file_path=`download_picture "$url_image"`

        mime_type=`file --mime-type "$file_path" | cut -d':' -f2 | sed 's/ //g'`
        echo "$file_path"
    else
        echo "protocol error: not recognized: $url_image"
    fi
}

main
exit 0