#!/bin/sh

removedoublequotes(){
  echo "$(sed 's/^"//g;s/"$//g')"
}

YI_HACK_PREFIX="/home/yi-hack"

. $YI_HACK_PREFIX/www/cgi-bin/validate.sh

if ! $(validateQueryString $QUERY_STRING); then
    printf "Content-type: application/json\r\n\r\n"
    printf "{\n"
    printf "\"%s\":\"%s\"\\n" "error" "true"
    printf "}"
    exit
fi

ACTION="none"

PARAM="$(echo $QUERY_STRING | cut -d'=' -f1)"
VAL="$(echo $QUERY_STRING | cut -d'=' -f2)"
PWD=""
PWD2=""

if [ "$PARAM" == "action" ]; then
     ACTION=$VAL
fi

if [ $ACTION == "scan" ]; then

    printf "Content-type: application/json\r\n\r\n"
    printf "{\"wifi\":[\n"

    LIST=`$YI_HACK_PREFIX/bin/iwlist wlan0 scan | grep "ESSID:" | cut -d : -f 2 | grep -v -e '^$'`

    IFS="\""
    for l in $LIST; do
        if [ ! -z $(echo $l | tr -d ' ') ]; then
            printf "\"$l\", \n"
        fi
    done

    printf "\"\"]}\n"

elif [ $ACTION == "save" ]; then

    read -r POST_DATA
    rm -f /tmp/configure_wifi.cfg

    # Validate json
    VALID=$(echo "$POST_DATA" | jq -e . >/dev/null 2>&1; echo $?)
    if [ "$VALID" != "0" ]; then
        printf "Content-type: application/json\r\n\r\n"
        printf "{\n"
        printf "\"%s\":\"%s\"\\n" "error" "true"
        printf "}"
        exit
    fi
    KEYS=$(echo "$POST_DATA" | jq keys_unsorted[])
    for KEY in $KEYS; do
        KEY=$(echo $KEY | removedoublequotes)
        VALUE=$(echo "$POST_DATA" | jq -r .$KEY)
        if [ $KEY == "WIFI_ESSID" ]; then
            KEY="wifi_ssid"
            echo "$KEY=$VALUE" >> /tmp/configure_wifi.cfg
        elif [ $KEY == "WIFI_PASSWORD" ]; then
            PWD=$VALUE
            KEY="wifi_psk"
            echo "$KEY=$VALUE" >> /tmp/configure_wifi.cfg
        elif [ $KEY == "WIFI_PASSWORD2" ]; then
            PWD2=$VALUE
        fi
    done

    if [ "$PWD" == "$PWD2" ]; then
        $YI_HACK_PREFIX/script/configure_wifi.sh
        sleep 1
        rm -f /tmp/configure_wifi.cfg

        printf "Content-type: application/json\r\n\r\n"
        printf "{\n"
        printf "\"%s\":\"%s\"\\n" "error" "false"
        printf "}"
    else
        rm -f /tmp/configure_wifi.cfg

        printf "Content-type: application/json\r\n\r\n"
        printf "{\n"
        printf "\"%s\":\"%s\"\\n" "error" "true"
        printf "}"
    fi

fi
