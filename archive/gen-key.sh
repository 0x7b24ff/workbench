#! /usr/bin/env bash

NAME=$1

if [ -z "${NAME}" ]
then
    echo "Usage: $0 NAME"
    exit 1
fi

keytool -genkey -keyalg RSA -keysize 2048 -validity 4096 -alias ${NAME} -keystore ${NAME}.keystore
