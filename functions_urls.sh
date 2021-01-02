#!/usr/bin/env bash

get_random_user_agent() {
    if [[ ! -f "$USER_AGENT_FILE" ]]; then exit 0; fi

    user_agent_list=()
    while IFS='' read -r line || [[ -n "$line" ]]; do
        user_agent_list+=("$line")
    done < "$USER_AGENT_FILE"
    ua="${user_agent_list[$(($RANDOM % ${#user_agent_list[@]}))]}"
    echo "User-Agent: $ua"

}

check_ping() { echo `ping -qc1 8.8.8.8 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"FAIL") }'`; }

get_proxy() {
    proxy_curl=""
    proxy_curl_user=""

    if [[ -n "$PROXY" ]] && [[ "$PROXY" != "False" ]]; then proxy_curl=" --proxy $PROXY"; fi
    if [[ -n "$PROXYUSER" ]] && [[ "$PROXYUSER" != "False" ]]; then proxy_curl_user=" --proxy-user $PROXYUSER"; fi

    echo "$proxy_curl$proxy_curl_user"
}

get_image_from_google() {
    if [[ -z "$search" ]] || [[ -z "$GOOGLE_PATH" ]]; then
        log_debug "$source : no search or no GOOGLE_PATH | $search $GOOGLE_PATH"
        exit 0
    fi
    sites=""
    file="$folder_path/logs/$source-"`echo "$search" | sed 's/ /-/'`".txt"

    if [[ -n "$google_size" ]];then size="-s $google_size";fi
    if [[ -n "$google_max_result" ]];then max_result="-l $google_max_result";fi
    if [[ -n "$forbidden_site" ]];then
        for s in "${forbidden_site[@]}"; do
            sites="$sites$s,"
        done
        sites=${sites%.*}
        sites="-iu $sites"
    fi

    ggl_command=""
    last_date_access=`get_last_date_access "$file"`
    log_debug "get_last_date_access $last_date_access"
    if [[ -f "$file" ]] && [[ "$last_date_access" -ge "$DATE_LIMIT" ]]; then
        url_images=(`cat "$file"`)
    else
        log_debug "renew list"
        ggl_command="python3 \"$GOOGLE_PATH\" -k \"$search\" \"$sites\" $max_result -nd -p $size -t \"photo\""
        url_images=(`$ggl_command | \
            grep 'Image URL:' | \
            sed 's/.* \([^"]*\)/\1/'`)
        echo "${url_images[@]}" > "$file"
    fi

    if [[ -z "$url_images" ]]; then
        log_debug "command : $ggl_command"
        log_debug "$source : array url_images empty $search $size"

        if [[ -f "$file" ]]; then
            rm "$file"
        fi
        exit 0
    else
        log_debug "$source : array url_images ${#url_images[@]}"
        echo "${url_images[$(($RANDOM % ${#url_images[@]}))]}"
    fi

}

get_image_from_qwant() {
    if [[ -z "$search" ]];then
        log_debug "$source : no search"
        exit 0
    fi
    sites=""
    site="https://api.qwant.com/api/search/images"
    file="$folder_path/logs/$source-"`echo "$search" | sed 's/ /-/'`".txt"

    if [[ -n "$qwant_size" ]];then size="$qwant_size";else size="all";fi
    if [[ -n "$forbidden_site" ]];then
        for s in "${forbidden_site[@]}"; do
            sites="$sites -site:$s"
        done
    fi

    last_date_access=`get_last_date_access "$file"`
    log_debug "get_last_date_access $last_date_access"
    if [[ -f "$file" ]] && [[ "$last_date_access" -ge "$DATE_LIMIT" ]]; then
        url_images=(`cat "$file"`)
    else
        log_debug "renew list"
        url_images=(`curl -SsLG \
            -H "$(get_random_user_agent)" \
            --data-urlencode "q=$search$sites" \
            --data-urlencode "size=$size" \
            --data-urlencode "imagetype=photo" \
            --data-urlencode "safesearch=1" \
            --data-urlencode "uiv=4" \
            --data-urlencode "t=images" \
            --url "$site" \
            $(get_proxy) | \
                sed 's/[,{}]/\n/g' | \
                grep '"media"' | \
                sed 's/.*:"\([^"]*\)"/\1/g' | \
                sed 's/\\\//g'`)
        echo "${url_images[@]}" > "$file"
    fi

    if [[ -z "$url_images" ]]; then
        log_debug "$source : array url_images empty $search"

        if [[ -f "$file" ]]; then
            rm "$file"
        fi
        exit 0
    else
        log_debug "$source : array url_images ${#url_images[@]}"
        echo "${url_images[$(($RANDOM % ${#url_images[@]}))]}"
    fi

}

get_image_from_picsum() {
    if [[ -z "$width" ]];then width=1024;fi
    if [[ -z "$height" ]];then height=768;fi

    echo "https://picsum.photos/$width/$height/?random"

}

get_image_from_pixabay() {
    if [[ -z "$search" ]] || [[ -z "$pixabay_key" ]];then
        log_debug "$source : no search or no key | $search $pixabay_key"
        exit 0
    fi
    if [[ -z "$width" ]];then width=1024;fi
    if [[ -z "$height" ]];then height=768;fi
    if [[ -z "$orientation" ]];then orientation="horizontal";fi
    site="https://pixabay.com/api/"
    file="$folder_path/logs/$source-"`echo "$search" | sed 's/ /-/'`".txt"

    last_date_access=`get_last_date_access "$file"`
    log_debug "get_last_date_access $last_date_access"
    if [[ -f "$file" ]] && [[ "$test" != "1" ]] && [[ "$last_date_access" -ge "$DATE_LIMIT" ]]; then
        url_images=(`cat "$file"`)
    else
        log_debug "renew list"
        response=`curl -SsLG \
            -H "$(get_random_user_agent)" \
            --data-urlencode "key=$pixabay_key" \
            --data-urlencode "q=$search" \
            --data-urlencode "image_type=photo" \
            --data-urlencode "min_width=$width" \
            --data-urlencode "min_height=$height" \
            --data-urlencode "orientation=$orientation" \
            --url "$site" \
            $(get_proxy)`

        url_images=(`echo $response| \
                sed 's/[,{}]/\n/g' | \
                grep 'largeImageURL' | \
                sed 's/.*:"\([^"]*\)"/\1/g'`)

        id_images=(`echo $response| \
                sed 's/[,{}]/\n/g' | \
                grep '"id"' | \
                sed 's/.*:\([^"]*\)/\1/g'`)

        path_images=()
        echo "${url_images[@]}" > "$file"
        for i in "${!url_images[@]}"; do
            url="${url_images[$i]}"
            extension="${url##*.}"
            if [[ -z "$extension" ]]; then extension="jpg"; fi

            image_name="${id_images[$i]}.$extension"
            path_img=`download_picture "$url" "$image_name"`
            path_images+=("$path_img")

        done
    fi

    if [[ -z "$path_images" ]]; then
        log_debug "$source : array path_images empty $search $width $height $orientation"

        if [[ -f "$file" ]]; then
            rm "$file"
        fi
        exit 0
    else
        log_debug "$source : array path_images ${#path_images[@]}"
        echo "${path_images[$(($RANDOM % ${#path_images[@]}))]}"
    fi

}

get_image_from_pexels() {
    if [[ -z "$search" ]];then
        log_debug "$source : no search"
        exit 0
    fi
    site="https://www.pexels.com/search/$search/"
    file="$folder_path/logs/$source-"`echo "$search" | sed 's/ /-/'`".txt"

    last_date_access=`get_last_date_access "$file"`
    log_debug "get_last_date_access $last_date_access"
    if [[ -f "$file" ]] && [[ "$last_date_access" -ge "$DATE_LIMIT" ]]; then
        url_images=(`cat "$file"`)
    else
        log_debug "renew list"
        url_images=(`curl -SsLG \
            -H "$(get_random_user_agent)" \
            --url "$site" \
            $(get_proxy) | \
                sed 's/</\n</g' | \
                grep '<img' | \
                sed 's/.*src="\([^"]*\)".*/\1/'  | \
                grep 'https://images.pexels.com/photos/' | \
                sed 's/\([^"]*\)?.*/\1/'`)
        echo "${url_images[@]}" > "$file"
    fi

    if [[ -z "$url_images" ]]; then
        log_debug "$source : array url_images empty $search"

        if [[ -f "$file" ]]; then
            rm "$file"
        fi
        exit 0
    else
        log_debug "$source : array url_images ${#url_images[@]}"
        echo "${url_images[$(($RANDOM % ${#url_images[@]}))]}"
    fi

}

get_image_from_unsplash() {
    if [[ -n "$search" ]];then
        site="https://unsplash.com/search/photos/$search"
        file="$folder_path/logs/$source-"`echo "$search" | sed 's/ /-/'`".txt"
    elif [[ -n "$collection" ]]; then
        site="https://unsplash.com/collections/$collection"
        file="$folder_path/logs/$source-"`echo "$collection" | sed 's/\//-/'`".txt"
    else
        log_debug "$source : no search none collection"
        exit 0
    fi

    last_date_access=`get_last_date_access "$file"`
    log_debug "get_last_date_access $last_date_access"
    if [[ -f "$file" ]] && [[ "$last_date_access" -ge "$DATE_LIMIT" ]]; then
        url_images=(`cat "$file"`)
    else
        log_debug "renew list"
        url_images=(`curl -SsLG \
            -H "$(get_random_user_agent)" \
            --url "$site" \
            $(get_proxy) | \
                sed 's/</\n</g' | \
                grep '<img' | \
                sed 's/.*src="\([^"]*\)".*/\1/' | \
                grep 'https://images.unsplash.com/photo-' | \
                sed 's/\([^"]*\)?.*/\1/'`)
        echo "${url_images[@]}" > "$file"
    fi

    if [[ -z "$url_images" ]]; then
        log_debug "$source : array url_images empty $search $collection"

        if [[ -f "$file" ]]; then
            rm "$file"
        fi
        exit 0
    else
        log_debug "$source : array url_images ${#url_images[@]}"
        echo "${url_images[$(($RANDOM % ${#url_images[@]}))]}" | sed 's/\&amp;/\&/g'
    fi

}

get_image_from_folder() {
    log_debug "get_image_from_folder $folder";
    regex_path="$folder/.*/$search/.*"

    if [[ -d "$folder/$source/$search" ]]; then
        image=`find "$folder/$source/$search" -type f | sort -R | tail -n1`;
    elif [[ `find "$folder" -regextype posix-egrep -regex "$regex_path" -type f` != "" ]]; then
        image=`find "$folder" -regextype posix-egrep -regex "$regex_path" -type f | sort -R | tail -n1`;
    else
        image=`find "$folder" -type f | sort -R | tail -n1`;
    fi

    echo "$image";
}

get_image_from_file() {
    log_debug "get_image_from_file $file_list";
    if [[ ! -f "$file_list" ]]; then echo ""; return; fi

    declare -a images
    while IFS=$'\n' read -r line_data; do
        images+=("${line_data}")
    done < "$file_list"

    echo "${images[$RANDOM % ${#images[@]} ]}";
}

download_picture() {
    url_image="$1"
    if [[ -n "$2" ]];then image_name="$2"
    else image_name="${url_image##*/}"
    fi
    log_debug "url_image $url_image"

    if [[ -n "$image" ]] && [[ "$image" != "False" ]]; then image_name="$image-$monitor"; fi

    log_debug "image $image_name"
    if [[ "$source" != "" ]] && [[ "$search" != "" ]]; then
        folder="$folder/$source/$search"
    fi
    if [[ ! -d "$folder" ]]; then mkdir -p "$folder"; fi
    file_path="$folder/$image_name"

    log_debug "file_path $file_path"
    if [[ "$image" == "False" ]] && [[ -f "$file_path" ]]; then
        log_debug "image already exist"
        echo "$file_path";
    else
        if [[ "$url_image" == //* ]]; then url_image="http:$url_image"; fi

        curl -sSLfG "$url_image" -o "$file_path" $(get_proxy)
        echo "$file_path"
    fi
}