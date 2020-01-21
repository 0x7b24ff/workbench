#! /usr/bin/env node

const
	Fs = require('fs'),
	Path = require('path')
;

function padStart( value, length, padding = '0' ) {
	let
		str = String( value )
	;
	if ( str.length >= length ) {
		return str;
	}
	return padding.repeat( length - str.length ) + str;
}

function main () {
	(async () => {

		let
			start = Number( process.argv[2] ) || 1,
			pad = 3,
			confirm = ( process.argv[ process.argv.length - 1 ] === 'confirm' ),
			cwd = process.cwd(),
			files = Fs.readdirSync( Path.resolve( cwd )),
			cursor = start
		;
		for ( let filename of files ) {
			let
				number = String( cursor++ ),
				prefix = padStart( number, pad, '0' ),
				newName = `${prefix}_${filename}`
			;
			console.log(`Renaming ${filename} to ${newName}`);
			if ( confirm ) {
				Fs.renameSync(`${cwd}${Path.sep}${filename}`, `${cwd}${Path.sep}${newName}`);
			}
		}

	})().catch(( err ) => {
		console.error( err );
		throw err;
	});
}

main();
