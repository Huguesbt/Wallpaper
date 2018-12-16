#!/usr/bin/env bash

usage() {
        echo "Usage: "
        echo "$(basename "$0") [OPTIONS]"
        echo "If no options setted, each options are random"
        echo "options available:"
        echo "--help: view this help"
        echo "--src: source where get picture"
        echo "--opt: option to wallpaper (zoom, spanned, ...)"
        echo "--search: search are keywords"
        echo "--collection: if source is unsplash, --collection contains id from collection and name"
        echo "--test: open feh to view pictures"
}

log_debug() { if [[ "$DEBUG" == "True" ]]; then echo $* >> "$LOG_FILE"; fi }

send_notif() {
    if [[ "$NOTIF" == "True" ]]; then
        notify-send --urgency=$urgency --icon=$ICON --expire-time=$EXPIRETIME "$1"
    fi
}


set_wallpaper_gsettings() {
    log_debug "set_wallpaper_gsettings"
    gsettings set org.gnome.desktop.background picture-uri file://$1
    gsettings set org.gnome.desktop.background picture-options $option

}

set_wallpaper_xfce4() {
    log_debug "set_wallpaper_xfce4"
    xfce4-set-wallpaper "$1"

}

set_wallpaper_xfconf() {
    log_debug "set_wallpaper_xfconf"
    properties=(`xfconf-query -c xfce4-desktop -p /backdrop -l | grep -e "screen.*/monitor.*image-path$" -e "screen.*/monitor.*/last-image$"`)

    monitors=()
    for property in "${properties[@]}"; do
        monitor=`echo $property | sed 's/.*\/\(monitor[[:digit:]]*\)\/.*/\1/'`
        if [[ "$1" == "" ]]; then break; fi

        xfconf-query -c xfce4-desktop -p "$property" -s "$1"
        if [[ "$monitors" == "" ]]; then monitors+=("$monitor")
        elif [[ "${monitors[@]}" != *"$monitor"* ]]; then shift; monitors+=("$monitor"); fi
    done

}

get_wallpaper() {
    url_image=""
    i=0

    while [[ "$url_image" == "" ]]; do
        log_debug "Get url_image to $monitor"
        url_image=`get_image_from_${source}`
        i=$((i + 1))

        if [ "$i" -ge "5" ] && [[ "$url_image" == "" ]]; then
            log_debug "no url_image from $i times; exit";exit 0;
        fi
        if [[ "$url_image" == "" ]]; then sleep 1; fi
    done

    if [[ "$test" == 1 ]]; then
        log_debug "test $url_image"
        if [[ "$noopen" == "" ]]; then
            nohup feh --scale-down "$url_image" &>/dev/null &
        fi
    elif [[ "$url_image" == file://* ]] || [[ "$url_image" == /* ]]; then
        echo "$url_image"
    elif [[ "$url_image" == //* ]] || [[ "$url_image" == http://* ]] || [[ "$url_image" == https://* ]]; then
        file_path=`download_picture "$url_image"`

        mime_type=`file --mime-type "$file_path" | cut -d':' -f2 | sed 's/ //g'`
        if [[ "$mime_type" == image/* ]]; then
            echo "$file_path"
        else
            if [[ -f "$file_path" ]]; then log_debug "mimetype is $mime_type"; fi

            log_debug "rerun"
            echo `get_wallpaper`
            exit 0
        fi
    else
        log_debug "protocol error: not recognized: $url_image"
    fi
}

get_monitors() {
    if [[ "xfconf" == *"$wp_fct"* ]]; then
        echo `xrandr --query | grep ' connected' | sed 's/\([^"]*\) connected .*/\1/'`
    fi

}

main() {
    if [[ `check_ping` == *"FAIL"* ]]; then source="folder";
    elif [[ -z "$source" ]]; then source="${sources[$(($RANDOM % ${#sources[@]}))]}";fi

    if [[ -z "$search" ]] && [[ -z "$collection" ]]; then
        if [[ ! -f "$SEARCH_FILE" ]]; then echo "Missing .search file"; exit 1; fi

            searches=()
            while IFS='' read -r line || [[ -n "$line" ]]; do
                searches+=("$line")
            done < "$SEARCH_FILE"
        search="${searches[$(($RANDOM % ${#searches[@]}))]}";
        collection="_"
    fi

    if [[ "$source" == "unsplash" ]] && [[ "$search" != "" ]] && [[ "$collection" != "" ]]; then
        array=("search" "collection")
        case="${array[$(($RANDOM % ${#array[@]}))]}";
        if [[ "$case" == "collection" ]] && [[ ! -f "$COLLECTION_FILE" ]]; then
            collections=()
            while IFS='' read -r line || [[ -n "$line" ]]; do
                collections+=("$line")
            done < "$COLLECTION_FILE"
            collection="${collections[$(($RANDOM % ${#collections[@]}))]}";
            unset search
        else
            unset collection
        fi
    fi
    log_debug "Source $source | Search : $search | Collection : $collection"

    monitors=(`get_monitors`)
    if [[ "$monitors" != "" ]]; then
        files_path=()
        for monitor in ${monitors[@]};do
            log_debug "Monitor $monitor"
            file_path=`get_wallpaper`

            if [[ "$file_path" != "" ]]; then files_path+=("$file_path");fi
        done
    else
        file_path=`get_wallpaper`

        if [[ "$file_path" != "" ]]; then files_path=("$file_path");fi
    fi

    if [[ "$files_path" != "" ]]; then
        set_wallpaper_${wp_fct} "${files_path[@]}"
        send_notif "$source : $search $collection"
    elif [[ "$test" != 1 ]]; then
        log_debug "Empty array files_path; rerun"
        if [[ ! -z "$source" ]]; then unset source;fi
        if [[ ! -z "$search" ]]; then unset search;fi
        if [[ ! -z "$collection" ]]; then unset collection;fi
        if [[ ! -z "$monitors" ]]; then unset monitors;fi
        if [[ ! -z "$file_path" ]]; then unset file_path;fi

        sleep 5
        main
        exit 0
    fi
}