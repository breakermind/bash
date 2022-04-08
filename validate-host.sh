#!/bin/bash

# First

DOMAIN=api.app.xx
[ -z "$(dig +short "www.$DOMAIN")" ]  &&  echo "www.$DOMAIN could not be looked up"
[ -z "$(dig +short "$DOMAIN")" ]  &&  echo "$DOMAIN could not be looked up"

exit

## Second

Valid() {
    data="$1"
    if grep -oP '(?=^.{4,253}$)(^(?:[a-zA-Z0-9](?:(?:[a-zA-Z0-9\-]){0,61}[a-zA-Z0-9])?\.)+([a-zA-Z]{2,}|xn--[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])$)' <<<"${data}" >/dev/>
      return 0
      # do second check using host command if regex above detected as false and finally return either true or false based host command
    else
      host "${data}" >/dev/null 2>&1
      retval=$?
      return "${retval}"
    fi
}

if Valid "$DOMAIN"; then
        echo "Validated"
else
        echo "Error"
fi

exit
