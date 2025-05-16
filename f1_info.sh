#!/bin/bash

pad_line() {
    local text="$1"
    local width=80
    printf "%-${width}s\n" "$text"
}

API_URL="http://127.0.0.1:5000/events/next"
RESPONSE=$(curl -s "$API_URL")

COUNTRY=$(echo "$RESPONSE" | jq -r '.Country')
pad_line "Next Race in: $COUNTRY"
pad_line "------------------------"

FIELDS=$(echo "$RESPONSE" | jq -r 'to_entries[] | select(.key != "Country") | @base64')

for field in $FIELDS; do
    _jq() {
        echo "$field" | base64 --decode | jq -r "$1"
    }

    KEY=$(_jq '.key')
    VALUE=$(_jq '.value')

    pad_line ""
    pad_line "$KEY:"

    if echo "$VALUE" | jq -e 'type == "object"' > /dev/null; then
        SESSIONS=$(echo "$VALUE" | jq -r 'to_entries[] | @base64')

        for session in $SESSIONS; do
            decode() {
                echo "$session" | base64 --decode | jq -r "$1"
            }

            SUBKEY=$(decode '.key')
            SUBVALUE=$(decode '.value')

            if [[ "$SUBVALUE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]; then
                LOCAL_DATE=$(date -d "$SUBVALUE" +"%d.%m.%Y %H:%M")
                pad_line "  $SUBKEY: $LOCAL_DATE"
            elif [ "$SUBKEY" = "time_until_event" ]; then
                CLEANED=$(echo "$SUBVALUE" | sed -E 's/([0-9]+) days ([0-9]+):([0-9]+):.*/\1 days \2 hours \3 minutes/')
                pad_line "  Time Until Event: $CLEANED"
            elif [ "$SUBKEY" = "status" ]; then
                pad_line "  Status: $SUBVALUE"
            else
                pad_line "  $SUBKEY: $SUBVALUE"
            fi
        done
    else
        pad_line "  $VALUE"
    fi
done
