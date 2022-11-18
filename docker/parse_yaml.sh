#!/bin/bash
set -e

# Prints all keys in a yaml tree.
#
# Modifications:
# - Dots (".") are replaced with two underscores ("__").
# - Hyphens ("-") are replaced with one underscore ("_").
#
# $1 - the yaml file
# $2 - optional prefix to be added to all keys
function parse_yaml {
    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_\.\-]*' fs=$(echo @|tr @ '\034')
    sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
    awk -F$fs '{
        indent = length($1)/2;
        vname[indent] = $2;
        for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("__")}
            gsub(/\-/, "_", vn);
            gsub(/\-/, "_", $2);
            gsub(/\./, "__", vn);
            gsub(/\./, "__", $2);
            printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
        }
    }'
}

parse_yaml "$@"
