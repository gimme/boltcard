#!/bin/bash
set -e

# Add config.yaml if missing.
if [ ! -f /data/config.yaml ]; then
    cp ./resources/config.yaml /data/
    chmod a+rw /data/config.yaml
fi

# Verify certificate exists.
[ ! -f /data/tls.cert ] && { echo "Missing certificate: tls.cert"; exit 1; }
export LN_TLS_FILE=/data/tls.cert

# Verify macaroon exists.
MACAROON_FILE=$(find /data/ -maxdepth 1 -name "*.macaroon")
if [ ! "$MACAROON_FILE" ]; then
    MACAROON_HEX_FILE=$(find /data/ -maxdepth 1 -name "*.macaroon.hex")
    if [ "$MACAROON_HEX_FILE" ]; then
        echo "Converting macaroon hex to binary..."
        xxd -r -p $MACAROON_HEX_FILE /data/boltcard.macaroon
        rm -f $MACAROON_HEX_FILE
        MACAROON_FILE=/data/boltcard.macaroon
    else
        echo "Missing .macaroon or .macaroon.hex file."
        exit 1
    fi
fi
export LN_MACAROON_FILE=$MACAROON_FILE
