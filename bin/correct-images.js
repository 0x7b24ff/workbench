#! /usr/bin/env node

const
    Fs = require('fs'),
    Path = require('path'),
    ReadChunk = require('read-chunk'),
    FileType = require('file-type')
;

function traverse( dir, fileHandler, dirHandler = null ) {
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
            if ( dirHandler ) {
                dirHandler( filePath, dir );
            }
            traverse( filePath );
        } else if ( fileStat.isFile() ) {
            if ( fileHandler ) {
                dirHandler( filePath, dir );
            }
        } else {
            // Skip
        }
    });
}

function main() {
    let
        cwd = Path.resolve( process.cwd() ),
        dryRun = !! process.argv[2]
    ;
    if ( dryRun ) {
        console.log(`Running in dry mode`);
    }
    traverse( cwd, ( filePath, fileDir ) => {
        let
            headBuffer = readChunk.sync( filePath, 0, fileType.minimumBytes ),
            typeInfo = FileType( headBuffer ),
            realExt = '.' + typeInfo.ext,
            fileExt = Path.extname( filePath )
        ;
        if ( fileExt === realExt ) {
            return;
        }
        let
            oldName = Path.basename( filePath ),
            newName = Path.basename( oldName, fileExt ) + realExt,
            newPath = fileDir + Path.sep + newName
        ;
        console.log(`Renaming ${oldName} to ${newName}`);
        if ( ! dryRun ) {
            Fs.renameSync( filePath, newPath );
        }
    }, ( dirPath, dir ) => {
        console.log(`Checking ${dirPath}`);
    });
}

main();
