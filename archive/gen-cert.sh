#! /usr/bin/env bash

NAME=$1

if [ -z "${NAME}" ]
then
    echo "Usage: $0 NAME"
    exit 1
fi

openssl req -new -newkey rsa:2048 -nodes -days 4096 -keyout ${NAME}.key -out ${NAME}.csr
