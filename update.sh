#!/usr/bin/env bash

re='^[0-9]+$'
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

srcs=()
searches=()
collections=()
while echo $1 | grep -q ^-; do
  case "$1" in
    -h|--help) usage; exit 0;;
    --test) test="1";;
    --loop) loop="$2";;
    --no-open) noopen="1";;
    --folder) folder="$2"; shift;;
    --opt) option="$2"; shift;;
    --fct) wp_fct="$2"; shift;;
    --src) srcs+=("$2"); shift;;
    --search) searches+=("$2"); shift;;
    --collection) collections+=("$2"); shift;;
    *) echo "Bad argument"; log_debug "Bad argument: $1"; usage; exit 0;;
  esac
  shift
done

if [[ -n "$srcs" ]]; then sources=("$srcs"); fi

if [[ -z "$searches" ]]; then
    if [[ ! -f "$SEARCH_FILE" ]]; then echo "Missing .search file or --search argument"; exit 1; fi

    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [[ "$line" != "#"* ]]; then searches+=("$line"); fi
    done < "$SEARCH_FILE"

fi

if [[ -z "$collections" ]] && [[ -f "$COLLECTION_FILE" ]]; then
    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [[ "$line" != "#"* ]]; then collections+=("$line"); fi
    done < "$COLLECTION_FILE"

fi

if [[ "$folder" == "" ]] || [[ ! -d "$folder" ]]; then
    folder="/tmp"
fi

if [[ $loop =~ $re ]]; then
    loop=$loop"s"
    log_debug "Function running all $loop"
    while true; do log_debug "Run at $(date +"%T")"; main; reset_vars; sleep $loop; done
else
    main
fi
exit 0