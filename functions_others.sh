#!/usr/bin/env bash


#trap exit_canary EXIT HUP INT TERM

usage() {
        echo "Usage: "
        echo "$(basename "$0") [OPTIONS]"
        echo "    If no options setted, each options are random options available:"
        echo "        --help: view this help"
        echo "        --loop: set in seconds time between 2 run"
        echo "        --folder: set folder where set downloaded images"
        echo "        --src: source where get picture; multiple arguments are available"
        echo "        --opt: option to wallpaper (zoom, spanned, ...)"
        echo "        --search: search are keywords; multiple arguments are available"
        echo "        --collection: if source is unsplash, --collection contains id from collection and name; multiple arguments are available"
        echo "        --test: open feh to view pictures"
        echo "        --file: if --src or sources contain file, define file with picture"
        echo "        --no-debug: disabled debug"
        echo "        --no-notif: disabled notif"
}

log_debug() { if [[ "$DEBUG" == "True" ]]; then echo "$*" >> "$LOG_FILE"; fi }

get_last_date_access() { if [[ -f "$1" ]]; then echo `stat -tc "%Y" "$1" | cut -d' ' -f1`; fi; }

send_notif() {
    if [[ "$NOTIF" == "True" ]]; then
        log_debug "$1"
        notify-send --urgency="$urgency" --icon=$ICON --expire-time=$EXPIRETIME "$1"
    fi
}

reset_vars(){
        if [[ ! -z "$source" ]]; then unset source;fi
        if [[ ! -z "$search" ]]; then unset search;fi
        if [[ ! -z "$collection" ]]; then unset collection;fi
        if [[ ! -z "$monitors" ]]; then unset monitors;fi
        if [[ ! -z "$file_path" ]]; then unset file_path;fi
}

check_only_instance(){
    log_debug "check_only_instance"
    if [[ -f "$folder_path/$LOCK_FILE" ]]; then log_debug "Script already run; exit";exit 1;
    else touch "$folder_path/$LOCK_FILE";
    fi

}

exit_wallpaper(){
    if [[ -f "$folder_path/$LOCK_FILE" ]]; then log_debug "Script exit"; rm "$folder_path/$LOCK_FILE"; fi
    exit 1;
}