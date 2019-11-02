#! /usr/bin/env bash

DIR=$1
SEARCH=$2
REPLACE=$3
PATTERN=$4
USAGE="xs DIR SEARCH REPLACE [PATTERN]"

if [ -z "$PATTERN" ]; then
    PATTERN=$SEARCH
fi

if [ ! -d "$DIR" ]; then
    echo $USAGE
    exit 1
fi
if [ -z "$SEARCH" ]; then
    echo $USAGE
    exit 1
fi

grep -rn "$SEARCH" $DIR | awk -F: '{ print $1 }' | uniq | xargs sed -i '' -E "s/$PATTERN/$REPLACE/g"
