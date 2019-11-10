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
        confirmed = process.argv.pop() === 'confirm'
    ;
    console.log( confirmed ? `Running in write mode` : `Running in dry mode`);
    traverse( cwd, ( filePath, fileDir ) => {
        let
            fileExt = Path.extname( filePath ).substr( 1 )
        ;
        if ( ! FileType.extensions.has( fileExt )) {
            return;
        }
        let
            headBuffer = ReadChunk.sync( filePath, 0, FileType.minimumBytes ),
            typeInfo = FileType( headBuffer )
        ;
        if ( ! typeInfo ) {
            return;
        }
        let
            realExt = typeInfo.ext
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
        if ( confirmed ) {
            Fs.renameSync( filePath, newPath );
        }
    }, ( dirPath, dir ) => {
        console.log(`Checking ${dirPath}/`);
    });
}

main();
