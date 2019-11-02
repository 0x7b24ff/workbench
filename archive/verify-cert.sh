#! /usr/bin/env bash

NAME=$1

if [ -z "${NAME}" ]
then
    echo "Usage: $0 NAME"
    exit 1
fi

openssl req -verify -text -noout -in ${NAME}
