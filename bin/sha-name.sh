#! /usr/bin/env bash

DIR=`pwd`
BITS=$1
USAGE="$0 BITS"

if [ ! -d "$BITS" ]; then
    BITS=1
fi

for file in $DIR/*.*; do
    mv -v -f "$file" "$(shasum -a$BITS "$file" | cut -d' ' -f1).${file##*.}";
done

