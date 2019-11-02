#! /usr/bin/env node

const
    Fs = require('fs'),
    Path = require('path')
;

function traverse( dir, handler ) {
    let
        files = Fs.readdirSync( dir )
    ;
    files.forEach(( name ) => {
        if ( name[0] === '.') {
            return;
        }
        let
            filePath = Path.resolve( dir, name ),
            fileStat = Fs.statSync( filePath )
        ;
        if ( fileStat.isDirectory() ) {
            traverse( filePath, handler );
        } else if ( fileStat.isFile() ) {
            handler( filePath, dir );
        } else {
            // Skip
        }
    });
}

function main() {
    let
        cwd = Path.resolve( process.cwd() ),
        level = Number( process.argv[2] ) || 0,
        delimiter = process.argv[3] || '_',
        dryRun = !! process.argv[4]
    ;
    if ( process.argv.length === 2 ) {
        console.log(`Usage: $0 LEVEL [DELIMITER] [DRY]
Arguments:
    LEVEL - Mandatory, LEVEL > 0
    DELIMITER - Default to _
    DRY - Default to NO`);
        process.exit( 1 );
        return;
    }
    if ( dryRun ) {
        console.log(`Running in dry mode`);
    }
    traverse( cwd, ( filePath, fileDir ) => {
        let
            oldName = Path.basename( filePath ),
            stripLevel = level
        ;
        if ( stripLevel === 0 ) {
            console.log(`Illegal strip level: 0`);
            return;
        }
        let
            index = oldName.indexOf('_')
        ;
        if ( index === -1 ) {
            console.log(`Unable to strip ${oldName}, skip`);
            return;
        }
        let
            count = 0
        ;
        while ( count++ < stripLevel - 1 ) {
            index = oldName.indexOf('_', index + 1 );
            if ( index === -1 ) {
                return;
            }
        }
        let
            newName = oldName.substr( index + 1 );
            newPath = `${fileDir}/${newName}`
        ;
        console.log(`Renaming ${oldName} to ${newName} in ${fileDir}`);
        if ( ! dryRun ) {
            Fs.renameSync( filePath, newPath );
        }
    });
}

main();
