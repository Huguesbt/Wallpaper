#!/usr/bin/env bash

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
        if [[ -z "$1" ]]; then break; fi
        monitor=`echo $property | sed 's/.*\/\(monitor[[:digit:]]*\)\/.*/\1/'`

        xfconf-query -c xfce4-desktop -p "$property" -s "$1"

        if [[ -z "$monitors" ]]; then monitors+=("$monitor")
        elif [[ "${monitors[@]}" != *"$monitor"* ]]; then shift; monitors+=("$monitor"); fi
    done

}

get_wallpaper() {
    url_image=""
    i=0

    while [[ -z "$url_image" ]]; do
        log_debug "Get url_image to monitor $monitor"
        url_image=`get_image_from_${source}`
        i=$((i + 1))

        if [ "$i" -ge "5" ] && [[ -z "$url_image" ]]; then
            log_debug "no url_image from $i times; exit";exit 0;
        fi
        if [[ -z "$url_image" ]]; then sleep 1; fi
    done

    if [[ "$test" == 1 ]]; then
        log_debug "test $url_image"
        if [[ -z "$noopen" ]]; then
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
    log_debug date
    if [[ `check_ping` == *"FAIL"* ]]; then source="folder";
    elif [[ -z "$source" ]]; then source="${sources[$(($RANDOM % ${#sources[@]}))]}";fi

    search="${searches[$(($RANDOM % ${#searches[@]}))]}";

    if [[ "$source" == "unsplash" ]] && [[ -n "$searches" ]] && [[ -n "$collections" ]]; then
        array=("search" "collection")

        case="${array[$(($RANDOM % ${#array[@]}))]}";
        if [[ "$case" == "collection" ]]; then
            collection="${collections[$(($RANDOM % ${#collections[@]}))]}";
            unset search
        fi
    fi
    log_debug "Source $source | Search : $search | Collection : $collection"

    monitors=("$(get_monitors)")
    if [[ -n "$monitors" ]]; then
        files_path=()
        for monitor in "${monitors[@]}";do
            log_debug "Monitor $monitor"
            file_path="$(get_wallpaper)"

            if [[ -n "$file_path" ]]; then files_path+=("$file_path");fi
        done
    else
        file_path="$(get_wallpaper)"

        if [[ -n "$file_path" ]]; then files_path=("$file_path");fi
    fi

    if [[ -n "$files_path" ]]; then
        set_wallpaper_${wp_fct} "${files_path[@]}"
        send_notif "$source : $search $collection"
    elif [[ "$test" != 1 ]]; then
        log_debug "Empty array files_path; rerun"
        reset_vars
        sleep 5s

        main
        exit 0
    fi
}