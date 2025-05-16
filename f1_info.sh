#!/bin/bash

# Replace when it's not running locally
API_URL="http://127.0.0.1:5000/events/next"

RESPONSE=$(curl -s "$API_URL")

COUNTRY=$(echo "$RESPONSE" | jq -r '.Country')
echo "Next Race in: $COUNTRY"
echo "------------------------"

# Loop through all fields (excluding "Country")
FIELDS=$(echo "$RESPONSE" | jq -r 'to_entries[] | select(.key != "Country") | @base64')

for field in $FIELDS; do
    _jq() {
        echo "$field" | base64 --decode | jq -r "$1"
    }

    KEY=$(_jq '.key')
    VALUE=$(_jq '.value')

    echo ""
    echo "$KEY:"
    
    if echo "$VALUE" | jq -e 'type == "object"' > /dev/null; then
        SESSIONS=$(echo "$VALUE" | jq -r 'to_entries[] | @base64')

        for session in $SESSIONS; do
            decode() {
                echo "$session" | base64 --decode | jq -r "$1"
            }

            SUBKEY=$(decode '.key')
            SUBVALUE=$(decode '.value')

            if [[ "$SUBVALUE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]; then
                # Convert UTC to local time
                LOCAL_DATE=$(date -d "$SUBVALUE" +"%d.%m.%Y %H:%M")
                echo "  $SUBKEY: $LOCAL_DATE"
            elif [ "$SUBKEY" = "time_until_event" ]; then
                CLEANED=$(echo "$SUBVALUE" | sed -E 's/([0-9]+) days ([0-9]+):([0-9]+):.*/\1 days \2 hours \3 minutes/')
                echo "  Time Until Event: $CLEANED"
            elif [ "$SUBKEY" = "status" ]; then
                echo "  Status: $SUBVALUE"
            else
                echo "  $SUBKEY: $SUBVALUE"
            fi
        done
    else
        echo "  $VALUE"
    fi
done

