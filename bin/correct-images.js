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

function main() {
    let
        cwd = Path.resolve( process.cwd() ),
        confirmed = process.argv.pop() === 'confirm'
    ;
    console.log( confirmed ? `Running in write mode` : `Running in dry mode`);
    traverse( cwd, ( fileName, fileDir, filePath ) => {
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
