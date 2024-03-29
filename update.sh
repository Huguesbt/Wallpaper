#!/usr/bin/env bash

re='^[0-9]+$'
DATE=$(date +"%F")
TIME=$(date +"%T")
folder_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOCK_FILE=".locked"
IMPORT_FILES=(".env" "functions_others.sh" "functions_urls.sh" "functions_wallpaper.sh" )
SEARCH_FILE="$folder_path/.search"
COLLECTION_FILE="$folder_path/.collection"
USER_AGENT_FILE="$folder_path/.user_agent"

for file in "${IMPORT_FILES[@]}"; do
    path="$folder_path/$file"
    if [[ ! -f "$path" ]]; then echo "Missing $path file"; exit 1;
    else source "$path";
    fi
done

LOG_FILE="$folder_path/logs/$DATE-$LOG_FILE"

trap exit_wallpaper EXIT HUP INT TERM

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
    --loop) loop="$2"; shift;;
    --no-open) noopen="1";;
    --folder) folder="$2"; shift;;
    --opt) option="$2"; shift;;
    --fct) wp_fct="$2"; shift;;
    --src) srcs+=("$2"); shift;;
    --search) searches+=("$2"); shift;;
    --collection) collections+=("$2"); shift;;
    --file) file_list="$2"; shift;;
    --no-debug) DEBUG="False";;
    --no-notif) NOTIF="False";;
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
    check_only_instance

    loop_s=$loop"s"
    log_debug "Function running all $loop_s"

    while true; do
        log_debug "Run at $(date +"%T")";
	main;
	reset_vars;
	log_debug "Next run at $(date +"%T" --date=@$(($(date +%s) + $loop)))";
	sleep $loop_s;
    done
else
    main
fi
exit 0
