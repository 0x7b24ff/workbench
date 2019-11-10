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
            filePath = Path.resolve( dir, name ),
            fileStat = Fs.statSync( filePath )
        ;
        if ( fileStat.isDirectory() ) {
            if ( dirHandler ) {
                dirHandler( filePath, dir );
            }
            traverse( filePath, fileHandler, dirHandler );
        } else if ( fileStat.isFile() ) {
            if ( fileHandler ) {
                fileHandler( filePath, dir );
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
    traverse( cwd, ( filePath, fileDir ) => {
        let
            oldName = Path.basename( filePath ),
            regexp = new RegExp( pattern )
        ;
        if ( ! regexp.test( oldName )) {
            console.log(`Skip ${oldName}`);
            return;
        }
        let
            newName = oldName.replace( regexp, replacement ),
            newPath = `${fileDir}/${newName}`
        ;
        console.log(`Renaming ${oldName} to ${newName} in ${fileDir}`);
        if ( confirmed ) {
            Fs.renameSync( filePath, newPath );
        }
    });
}

main();
