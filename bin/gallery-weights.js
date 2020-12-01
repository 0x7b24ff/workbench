#! /usr/bin/env node

const
    Fs = require('fs'),
    Path = require('path')
;

function traverse( dir, fileHandler, dirHandler = null ) {
    let
        files = Fs.readdirSync( dir )
    ;
    files.forEach(( name ) => {
        if ( name === '.' || name === '..' ) {
            return;
        }
        let
            path = Path.resolve( dir, name ),
            stat = Fs.statSync( path )
        ;
        if ( stat.isDirectory() ) {
            if ( dirHandler ) {
                dirHandler( name, dir, path );
            }
            traverse( path, fileHandler, dirHandler );
        } else if ( stat.isFile() ) {
            if ( fileHandler ) {
                fileHandler( name, dir, path );
            }
        } else {
            // Skip
        }
    });
}

function humanize( size, unitIndex = 0 ) {
    let
        units = [ 'B', 'K', 'M', 'G', 'T' ],
        number = Math.floor( size / 1024 ),
        remainder = Math.ceil( size % 1024 ) / 10
    ;
    if ( number >= 1024 ) {
        return humanize( number, unitIndex++ );
    }
    number += remainder / 100;
    return String( number ) + units[ unitIndex ];
}

function main() {
    let
        cwd = Path.resolve( process.cwd() ),
        map = {}  // { DIR_PATH => { files: 0, size: 0 } }
    ;
    traverse( cwd, ( fileName, fileDir, filePath ) => {
        let
            fileStats = Fs.statSync( filePath )
        ;
        map[ fileDir ].files++;
        map[ fileDir ].size += fileStats.size;
    }, ( dirPath, dir ) => {
        map[ fileDir ] = { files: 0, size: 0 };
    });
    for ( let dir of map ) {
        let
            { files, size } = map[ dir ],
            weight = Math.round( size * 100 / files ) / 100
        ;
        console.log([
            dir,
            humanize( size ),
            files,
            weight
        ].join(','));
    }
}

main();
