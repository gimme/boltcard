#!/bin/bash
set -e

CONF_PREFIX=CONF_

# Convert config.yaml tree to local variables with a prefix.
eval $(./parse_yaml.sh /data/config.yaml $CONF_PREFIX)


# Maps a config key to an environment variable.
#
# $1 - the config key
# $2 - the output variable name
# $3 - optional modifier
# $4 - optional default value
function map_config {
    local new_var=$1
    local new_var=${new_var//\./__}
    local new_var=${new_var//-/_}
    local old_var=$2
    local tmp=$CONF_PREFIX$new_var
    local val=${!tmp}
    # Provide default value.
    if [ ! "$val" ]; then
        if [ -v 4 ]; then
            val="$4"
            sed -i -E "s/$1:.*/$1: $val/g" /data/config.yaml
        fi
    fi
    eval $3
    export $old_var=$val
}

# Converts val from true/false to ENABLE/DISABLE when evaluated.
convert_boolean="[ \${val,,} = true ] && val=ENABLE || val=DISABLE"


# Mappings
map_config "aes-decrypt-key"    "AES_DECRYPT_KEY" "" "$(openssl rand -hex 32)"
map_config "domain"             "HOST_DOMAIN"
map_config "fee.percent"        "FEE_LIMIT_PERCENT"
map_config "fee.base"           "FEE_LIMIT_SAT"
map_config "function.lnurlp"    "FUNCTION_LNURLP" "$convert_boolean"
map_config "function.lnurlw"    "FUNCTION_LNURLW" "$convert_boolean"
map_config "ln.host"            "LN_HOST"
map_config "ln.port"            "LN_PORT"
map_config "log.level"          "LOG_LEVEL" "" "PRODUCTION"
map_config "withdraw.max"       "MAX_WITHDRAW_SATS"
map_config "withdraw.min"       "MIN_WITHDRAW_SATS"

# Constants
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=card_db
export DB_USER=cardapp
[[ -v DB_PASSWORD ]] || DB_PASSWORD=database_password
export DB_PASSWORD=$DB_PASSWORD
export HOST_PORT=9000
