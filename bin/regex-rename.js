#! /usr/bin/env node

const
    Fs = require('fs'),
    Path = require('path')
;

const
    RE_FUNC = /@\{([A-Z]+)\:?([^{}]*)\}/g,
    DELIMITER_PARAMS = ',',
    DELIMITER_ASSIGN = '='
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

function parseParameters( text ) {
    let
        params = {}
    ;
    text.split( DELIMITER_PARAMS ).forEach(( v ) => {
        let
            pair = v.split( DELIMITER_ASSIGN )
        ;
        if ( pair[0] ) {
            params[ pair[0].toLowerCase() ] = pair[1];
        }
    });
    return params;
}

function padStart( value, length, padding = '0' ) {
    let
        str = String( value )
    ;
    if ( str.length >= length ) {
        return str;
    }
    return padding.repeat( length - str.length ) + str;
}

function main() {
    let
        cwd = Path.resolve( process.cwd() ),
        pattern = process.argv[2],
        replacement = process.argv[3],
        confirmed = process.argv.pop() === 'confirm'
    ;
    if ( process.argv.length < 3 ) {
        console.log(`Usage: $0 PATTERN FILENAME [confirm]
Arguments:
    PATTERN - A JavaScript regular expression to match the files
    FILENAME - The new filename for the matched files, with extra functionality
    Default in dry mode, pass "confirm" as the last argument to run in write mode`);
        process.exit( 1 );
        return;
    }
    console.log( confirmed ? `Running in write mode` : `Running in dry mode`);
    console.log(`PATTERN: ${pattern}`);
    console.log(`REPLACEMENT: ${replacement}`);
    let
        filters = [],
        matches = RE_FUNC.exec( replacement );
    ;
    while ( matches ) {
        let
            expression = matches[0],
            identifier = matches[1],
            params = parseParameters( matches[2] );
        ;
        switch ( identifier ) {
        case 'INDEX':
            let
                index = Number( params.start ) || 0
            ;
            console.log( params, index );
            filters.push(( name ) => {
                return name.replace( expression, padStart( index++, 3 ));
            });
        }
        matches = RE_FUNC.exec( replacement );
    }
    traverse( cwd, ( fileName, fileDir, filePath ) => {
        let
            regexp = new RegExp( pattern )
        ;
        if ( ! regexp.test( fileName )) {
            console.log(`Skip ${fileName}`);
            return;
        }
        let
            newName = filters.reduce(( name, func ) => {
                return func( name );
            }, fileName.replace( regexp, replacement )),
            newPath = `${fileDir}/${newName}`
        ;
        console.log(`Renaming ${fileName} to ${newName} in ${fileDir}`);
        if ( confirmed ) {
            Fs.renameSync( filePath, newPath );
        }
    });
}

main();
