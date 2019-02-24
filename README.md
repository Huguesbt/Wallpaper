# Wallpaper changer
A linux shell script to change wallpaper randomly

Run `/opt/wallpaper/update.sh --loop 300` to change wallpaper all 5 minutes (300 seconds)
You could set this command as new starter application, but no cron or no systemd are available yet,
need define a dbus to communicate with Xserver

## USAGE
You could run this script with arguments or none

This is with arguments:
```
Usage: 
    update.sh [OPTIONS]
    If no options setted, each options are random
    options available:
        --help: view this help
        --loop: set in seconds time between 2 run
        --folder: set folder where set downloaded images
        --src: source where get picture; multiple arguments are available
        --opt: option to wallpaper (zoom, spanned, ...)
        --search: search are keywords; multiple arguments are available
        --collection: if source is unsplash, --collection contains id from collection and name; multiple arguments are available
        --test: open feh to view pictures
```

To run without argument, you may set `source` variable in .env file and create .search file
See 'CONFIG .env' and '.search'

logs' folder is needed to save pictures' list to not upload list all times, you could choose life duration
to set `period` variable in .env file


## CONFIG .env

.env file contain all environment's variables. Copy .env.sample and update values
```
# path to folder where saved wallpapers REQUIRED
folder=/path/to/folder/wallpapers

# or name of image if you should always save images with same name
image=False

# name of function to update wallpaper
# (xfconf to xfconf-query, xfce4 to xfce4-set-wallpaper, gsettings to gsettings with gnome)
wp_fct=xfconf

# options required by gsettings with gnome
option=zoom

# option required by picsum.photos
width=1980
height=1080

# option to qwant.com
qwant_size=large

# option to google.com
orientation=horizontal

# Path to project google_images_download; required to get images from google
# see https://github.com/hardikvasa/google-images-download.git
GOOGLE_PATH="/path/to/script/google_images_download.py"
google_size=large

# If extension is different, re launch script
extensions=(jpg jpeg png)

# period before request new pictures' list if file already exist
period=-7days

# list of sites where not get pictures, by example pictures bank with mask
forbidden_site=()

# api key to get images from pixabay
pixabay_key=XXXXXXXXX-XXXXXXXXXXXXXXXXXXX

# list sources where calling if not --src as argument;
# function may be exist get_image_from_<website_name>
sources=(
    google
    qwant
    unsplash
    pexels
    pixabay
)

# Options to get notify to each wallpaper change if NOTIF set True (notify-send)
NOTIF=True
urgency=normal
EXPIRETIME=5000
ICON="/Path/to/icon"

# If DEBUG True, save all change in file, one by day in logs' folder
DEBUG=True
LOG_FILE=debug.log

# If set, use --proxy and --proxy-user parameters from curl
PROXY=False
PROXYUSER=False
```

## TIPS

### .search

Create .search file wich list keywords, one by line
No need --search argument
To each run search are randomly choice in file

### .collection

Same things
Create .collection file too which mean name of collection from unsplash.com (format: "id/name", one by line)
If source is unsplash.com, search or collection choose randomly

### .user-agent

A file .user-agent exists and it used to curl, required by website to requests with success


## ADD NEW WEBSITE

If you should add a website, you should update functions_urls.sh and add a new function to request site and
parse results to get picrures' url list

function's name : `get_image_from_<website_name>`

This function take no arguments, all needed's variables are global

function to get random user_agent : get_random_user_agent # return string with header `User-Agent: <user_agent>`
function to get proxy : get_proxy # set empty if not proxy else string with `--proxy` and `--proxy-user` options

## ADD NEW WALLPAPER SOFTWARE

If you should add a new software to change wallpaper, you should update functions_wallpapers.sh and set function to do it

function's name : `set_wallpaper_<software>`

This function take one argument, a list from images, one by monitor if many ( get result from get_monitors )

## DEPENDENCIES

[google-images-download](https://github.com/hardikvasa/google-images-download.git)
