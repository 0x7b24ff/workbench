#! /usr/bin/env node

const
    Fs = require('fs'),
    Path = require('path')
;

const
    RE_FUNC = /@\{([A-Z]+)\:?([^{}]*)\}/g,
    DELIMITER_PARAMS = ',',
    DELIMITER_ASSIGN = '=',
    DEFAULT_OPTIONS = {
        directory: true,
        file: true,
        recursive: false
    }
;

function main() {
    // Usage
    if ( process.argv.length < 4 ) {
        console.log(`Usage: $0 [OPTIONS] PATTERN FILENAME [confirm]
Arguments:
    PATTERN - A JavaScript regular expression to match the files
    FILENAME - The new filename for the matched files, with extra functionality
    Default in dry mode, pass "confirm" as the last argument to run in write mode`);
        process.exit( 1 );
        return;
    }
    // Arguments and options
    let
        cwd = Path.resolve( process.cwd() ),
        argCursor = 2,
        options = parseOptions( process.argv[ argCursor ]),
        pattern, replacement, confirmed
    ;
    // Pattern and replacement
    argCursor += Number( !! options );
    pattern = process.argv[ argCursor++ ];
    replacement = process.argv[ argCursor++ ];
    confirmed = process.argv[ argCursor ] === 'confirm';
    console.log( confirmed ? `Running in write mode` : `Running in dry mode`);
    console.log(`PATTERN: ${pattern}`);
    console.log(`REPLACEMENT: ${replacement}`);
    // Default options if null
    options = options || DEFAULT_OPTIONS;
    // Parameters
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
    // Process
    let
        traverseHandler = ( fileName, fileDir, filePath ) => {
            regexRename({
                fileName,
                fileDir,
                pattern,
                replacement,
                filters,
                confirmed
            });
        }
    ;
    scanDir({
        dir: cwd,
        fileHandler: options.file ? traverseHandler : null,
        dirHandler: options.directory ? traverseHandler : null,
        recursive: options.recursive
    });
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

function parseOptions( text ) {
	text = text.trim();
    if ( text[0] !== '-' ) {
        return null;
    }
    let
        options = Object.assign({}, DEFAULT_OPTIONS );
    ;
    text.substr( 1 ).split('').forEach(( v ) => {
        switch ( v ) {
        case 'd':
            options.directory = true;
            break;
        case 'f':
            options.file = true;
            break;
        case 'r':
            options.recursive = true;
            break;
        }
    });
    return options;
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

function regexRename({
    fileName,
    fileDir,
    pattern,
    replacement,
    filters = [],
    confirmed = false
}) {
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
        newPath = `${fileDir}/${newName}`,
        filePath = `${fileDir}/${fileName}`
    ;
    console.log(`Renaming ${fileName} to ${newName} in ${fileDir}`);
    if ( confirmed ) {
        Fs.renameSync( filePath, newPath );
    }
}

function scanDir({
    dir,
    fileHandler = null,
    dirHandler = null,
    recursive = false
}) {
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
            if ( recursive ) {
                scanDir({
                    dir: path,
                    fileHandler,
                    dirHandler,
                    recursive
                });
            }
        } else if ( stat.isFile() ) {
            if ( fileHandler ) {
                fileHandler( name, dir, path );
            }
        } else {
            // Skip
        }
    });
}

main();
