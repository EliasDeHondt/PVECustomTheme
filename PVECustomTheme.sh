#!/bin/bash
############################
# @author Elias De Hondt   #
# @see https://eliasdh.com #
# @since 04/10/2024        #
############################

umask 022

RED='\033[0;31m'
BRED='\033[0;31m\033[1m'
GRN='\033[92m'
WARN='\033[93m'
BOLD='\033[1m'
REG='\033[0m'
CHECKMARK='\033[0;32m\xE2\x9C\x94\033[0m'

TEMPLATE_FILE="/usr/share/pve-manager/index.html.tpl"
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/"
SCRIPTPATH="${SCRIPTDIR}$(basename "${BASH_SOURCE[0]}")"

OFFLINEDIR="${SCRIPTDIR}offline"

REPO=${REPO:-"EliasDH-com/PVECustomTheme"}
DEFAULT_TAG="master"
TAG=${TAG:-$DEFAULT_TAG}
BASE_URL="https://raw.githubusercontent.com/$REPO/$TAG"

OFFLINE=false


if [[ $EUID -ne 0 ]]; then
    echo -e >&2 "${BRED}Root privileges are required to perform this operation${REG}";
    exit 1
fi

hash sed 2>/dev/null || { 
    echo -e >&2 "${BRED}sed is required but missing from your system${REG}";
    exit 1;
}

hash pveversion 2>/dev/null || { 
    echo -e >&2 "${BRED}PVE installation required but missing from your system${REG}";
    exit 1;
}

if test -d "$OFFLINEDIR"; then
    echo "Offline directory detected, entering offline mode."
    OFFLINE=true
else
    hash curl 2>/dev/null || { 
        echo -e >&2 "${BRED}cURL is required but missing from your system${REG}";
        exit 1;
    }
fi

if [ "$OFFLINE" = false ]; then
    curl -sSf -f https://raw.githubusercontent.com/ &> /dev/null || {
        echo -e >&2 "${BRED}Could not establish a connection to GitHub (https://raw.githubusercontent.com)${REG}";
        exit 1;
    }

    if [ $TAG != $DEFAULT_TAG ]; then
        if !([[ $TAG =~ [0-9] ]] && [ ${#TAG} -ge 7 ] && (! [[ $TAG =~ ['!@#$%^&*()_+.'] ]]) ); then 
            echo -e "${WARN}It appears like you are using a non-default tag. For security purposes, please use the SHA-1 hash of said tag instead${REG}"
        fi
    fi
fi

PVEVersion=$(pveversion --verbose | grep pve-manager | cut -c 14- | cut -c -6)
PVEVersionMajor=$(echo $PVEVersion | cut -d'-' -f1)

function checkSupported {   
    if [ "$OFFLINE" = false ]; then
        local SUPPORTED=$(curl -f -s "$BASE_URL/meta/supported")
    else
        local SUPPORTED=$(cat "$OFFLINEDIR/meta/supported")
    fi

    if [ -z "$SUPPORTED" ]; then 
        if [ "$OFFLINE" = false ]; then
            echo -e "${WARN}Could not reach supported version file ($BASE_URL/meta/supported). Skipping support check.${REG}"
        else
            echo -e "${WARN}Could not find supported version file ($OFFLINEDIR/meta/supported). Skipping support check.${REG}"
        fi
    else 
        local SUPPORTEDARR=($(echo "$SUPPORTED" | tr ',' '\n'))
        if ! (printf '%s\n' "${SUPPORTEDARR[@]}" | grep -q -P "$PVEVersionMajor"); then
            echo -e "${WARN}You might encounter issues because your version ($PVEVersionMajor) is not matching currently supported versions ($SUPPORTED)."
            echo -e "If you do run into any issues on >newer< versions, please consider opening an issue at https://github.com/EliasDH-com/PVECustomTheme/issues.${REG}"
        fi
    fi
}

function isInstalled {
    if (grep -Fq "<link rel='stylesheet' type='text/css' href='/pve2/css/dh_style.css'>" $TEMPLATE_FILE &&
        grep -Fq "<script type='text/javascript' src='/pve2/js/dh_patcher.js'></script>" $TEMPLATE_FILE &&
        [ -f "/usr/share/pve-manager/css/dh_style.css" ] && [ -f "/usr/share/pve-manager/js/dh_patcher.js" ]); then 
        true
    else 
        false
    fi
}

function install {
    if isInstalled; then
        echo -e "${RED}Theme already installed${REG}"
        exit 2
    else
        checkSupported

        echo -e "${CHECKMARK} Backing up template file"
        cp $TEMPLATE_FILE $TEMPLATE_FILE.bak

        echo -e "${CHECKMARK} Downloading stylesheet"

        if [ "$OFFLINE" = false ]; then
            curl -s $BASE_URL/PVECustomTheme/sass/PVECustomTheme.css > /usr/share/pve-manager/css/dh_style.css
        else
            cp "$OFFLINEDIR/PVECustomTheme/sass/PVECustomTheme.css" /usr/share/pve-manager/css/dh_style.css
        fi

        echo -e "${CHECKMARK} Downloading patcher"
        if [ "$OFFLINE" = false ]; then
            curl -s $BASE_URL/PVECustomTheme/js/PVECustomTheme.js > /usr/share/pve-manager/js/dh_patcher.js
        else
            cp "$OFFLINEDIR/PVECustomTheme/js/PVECustomTheme.js" /usr/share/pve-manager/js/dh_patcher.js
        fi

        echo -e "${CHECKMARK} Applying changes to template file"
        if !(grep -Fq "<link rel='stylesheet' type='text/css' href='/pve2/css/dh_style.css'>" $TEMPLATE_FILE); then
            echo "<link rel='stylesheet' type='text/css' href='/pve2/css/dh_style.css'>" >> $TEMPLATE_FILE
        fi 
        if !(grep -Fq "<script type='text/javascript' src='/pve2/js/dh_patcher.js'></script>" $TEMPLATE_FILE); then
            echo "<script type='text/javascript' src='/pve2/js/dh_patcher.js'></script>" >> $TEMPLATE_FILE
        fi 

        if [ "$OFFLINE" = false ]; then
            local IMAGELIST=$(curl -f -s "$BASE_URL/meta/imagelist")
        else 
            local IMAGELIST=$(cat "$OFFLINEDIR/meta/imagelist")
        fi

        local IMAGELISTARR=($(echo "$IMAGELIST" | tr ',' '\n'))
        echo -e "Downloading images (0/${#IMAGELISTARR[@]})"
        ITER=0
        for image in "${IMAGELISTARR[@]}"
        do
                if [ "$OFFLINE" = false ]; then
                    curl -s $BASE_URL/PVECustomTheme/images/$image > /usr/share/pve-manager/images/$image
                else
                    cp "$OFFLINEDIR/PVECustomTheme/images/$image" /usr/share/pve-manager/images/$image
                fi
                ((ITER++))
                echo -e "\e[1A\e[KDownloading images ($ITER/${#IMAGELISTARR[@]})"
        done
        echo -e "\e[1A\e[K${CHECKMARK} Downloading images (${#IMAGELISTARR[@]}/${#IMAGELISTARR[@]})"

        echo -e "Theme installed."
        then exit 0
    fi
}

function uninstall {
    if ! isInstalled; then
        echo -e "${RED}Theme not installed${REG}"
        exit 2
    else
        echo -e "${CHECKMARK} Removing stylesheet"
        rm /usr/share/pve-manager/css/dh_style.css

        echo -e "${CHECKMARK} Removing patcher"
        rm /usr/share/pve-manager/js/dh_patcher.js

        echo -e "${CHECKMARK} Reverting changes to template file"
        sed -i "/<link rel='stylesheet' type='text\/css' href='\/pve2\/css\/dh_style.css'>/d" /usr/share/pve-manager/index.html.tpl
        sed -i "/<script type='text\/javascript' src='\/pve2\/js\/dh_patcher.js'><\/script>/d" /usr/share/pve-manager/index.html.tpl

        echo -e "${CHECKMARK} Removing images"
        rm /usr/share/pve-manager/images/dh_*

        echo -e "Theme uninstalled."
        exit 0
    fi
}

parse_cli()
{
	while test $# -gt -0
	do
		case "$1" in
            install) 
                install
                exit 0
                ;;
            uninstall)
                uninstall
                exit 0
                fi
                ;;
	     *)
				echo -e "${BRED}Error: Got an unexpected argument \"$_key\"${REG}\n"; 
                exit 1;
				;;
		esac
		shift
	done
}

parse_cli "$@"