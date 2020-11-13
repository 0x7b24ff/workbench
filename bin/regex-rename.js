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
            stat = Fs.statSync( filePath )
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

function main() {
    let
        cwd = Path.resolve( process.cwd() ),
        pattern = process.argv[2],
        replacement = process.argv[3],
        confirmed = process.argv.pop() === 'confirm'
    ;
    if ( process.argv.length < 3 ) {
        console.log(`Usage: $0 PATTERN REPLACEMENT [confirm]
Arguments:
    PATTERN -
    REPLACEMENT -
    confirm - Default to dry mode, use the word "confirm" to run in write mode`);
        process.exit( 1 );
        return;
    }
    console.log( confirmed ? `Running in write mode` : `Running in dry mode`);
    console.log(`PATTERN: ${pattern}`);
    console.log(`REPLACEMENT: ${replacement}`);
    traverse( cwd, ( fileName, fileDir, filePath ) => {
        let
            regexp = new RegExp( pattern )
        ;
        if ( ! regexp.test( fileName )) {
            console.log(`Skip ${fileName}`);
            return;
        }
        let
            newName = fileName.replace( regexp, replacement ),
            newPath = `${fileDir}/${newName}`
        ;
        console.log(`Renaming ${fileName} to ${newName} in ${fileDir}`);
        if ( confirmed ) {
            Fs.renameSync( filePath, newPath );
        }
    });
}

main();
