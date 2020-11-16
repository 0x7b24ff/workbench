#! /usr/bin/env bash

if [ "$1" = "delete" ]; then
    find . -type f \( ! -iname "*.png" -a ! -iname "*.jpg" -a ! -iname "*.jpeg" -a ! -iname "*.gif" \) -print -exec rm -f {} \;
else
    find . -type f \( ! -iname "*.png" -a ! -iname "*.jpg" -a ! -iname "*.jpeg" -a ! -iname "*.gif" \) -print
fi

