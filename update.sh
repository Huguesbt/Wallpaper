#!/usr/bin/env bash

DATE=$(date +"%F")
TIME=$(date +"%T")
folder_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "$folder_path/.env" ]]; then echo "Missing .env file"; exit 1; fi
if [[ ! -f "$folder_path/functions_urls.sh" ]]; then echo "Missing functions_urls.sh file"; exit 1; fi
if [[ ! -f "$folder_path/functions_wallpaper.sh" ]]; then echo "Missing functions_wallpaper.sh file"; exit 1; fi

. "$folder_path/.env"
. "$folder_path/functions_urls.sh"
. "$folder_path/functions_wallpaper.sh"

SEARCH_FILE="$folder_path/.search"
COLLECTION_FILE="$folder_path/.collection"
USER_AGENT_FILE="$folder_path/.user_agent"

LOG_FILE="$folder_path/logs/$DATE-$LOG_FILE"

log_debug ""
log_debug ""
log_debug "Run at $DATE $TIME"

if [[ "$period" == "False" ]]; then period="0days";fi
DATE_LIMIT="$(date +"%s" -d $period)"

while echo $1 | grep -q ^-; do
  case "$1" in
    -h|--help) usage; exit 0;;
    --test) test="1";;
    --no-open) noopen="1";;
    --src) source="$2"; shift;;
    --opt) option="$2"; shift;;
    --search) search="$2"; shift;;
    --collection) collection="$2"; shift;;
    *) echo "Bad argument"; usage; exit 0;;
  esac
  shift
done

main
exit 0