#! /usr/bin/env bash

find . -type f -iname '.DS_Store' -print -exec rm -f {} \;
find . -type f -iname '._.DS_Store' -print -exec rm -f {} \;

