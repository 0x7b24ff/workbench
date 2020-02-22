#! /usr/bin/env bash

SRC_BASE=$(realpath $1)
DST_BASE=$(realpath $2)

if [ ! -d "$SRC_BASE" ];
then
    echo "The source folder does not exist: ${SRC_BASE}"
    exit 1
fi

if [ ! -d "$DST_BASE" ];
then
    echo "The destination folder does not exist: ${DST_BASE}"
    exit 1
fi

FOLDERS=($(ls -d1 ${SRC_BASE}/*/))

for folder in "${FOLDERS[@]}"
do
    REL_PATH=$(realpath --relative-to=$SRC_BASE $folder)
    SRC="${folder}"
    DST="${DST_BASE}/${REL_PATH}"
    if [ ! -d "$DST" ];
    then
        echo "Destination ${DST} not exists, skipped"
    else
        echo "Syncing from ${SRC} to ${DST}"
	    rsync -avh --delete "${SRC_BASE}/${folder}/" "${DST_BASE}/${folder}/"
    fi
done

echo "All done"
