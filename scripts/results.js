#!/usr/bin/env node

import { existsSync } from 'node:fs';
import csv from 'csvtojson';
import tablemark from 'tablemark';
import { stringify } from 'csv-stringify/sync';

const args = process.argv.slice( 2 );

const title = args[ 0 ];
const beforeFile = args[ 1 ];
const afterFile = args[ 2 ];
const output = args[ 3 ];
const skipFormatting = args[ 4 ];

if ( ! existsSync( beforeFile ) ) {
	console.error( `File not found: ${ beforeFile }` );
	process.exit( 1 );
}

if ( ! existsSync( afterFile ) ) {
	console.error( `File not found: ${ afterFile }` );
	process.exit( 1 );
}

/**
 * Format test results as a Markdown table.
 *
 * @param {Array<Record<string,string|number|boolean>>} results Test results.
 *
 * @return {string} Markdown content.
 */
function formatAsMarkdownTable( results ) {
	if ( ! results?.length ) {
		return '';
	}

	return tablemark( results, {
		caseHeaders: false,
		columns: [
			{ align: 'center' },
			{ align: 'center' },
			{ align: 'center' },
			{ align: 'center' },
		],
	} );
}

/**
 * Format test results as CSV.
 *
 * @param {Array<Record<string,string|number|boolean>>} results Test results.
 *
 * @return {string} CSV content.
 */
function formatAsCsv( results ) {
	if ( ! results?.length ) {
		return '';
	}

	const headings = Object.keys( results[ 0 ] );
	const rows = results.map( ( result ) => {
		const row = [];
		headings.forEach( ( heading ) => {
			if ( result[ heading ] ) {
				row.push( result[ heading ] );
			} else {
				row.push( '' );
			}
		} );
		return row;
	} );

	return stringify( [ headings, ...rows ] );
}

/**
 * Simplify the data into a summary table, showing only the p50 (mean) results.
 *
 * @param {Record<string,Record<string,string|number|boolean>>} results Test results.
 *
 * @return {Array<Record<string,string|number|boolean>>} Simplified test results.
 */
function simplifyData( results ) {
	const simplified = [];
	for ( const result in results ) {
		// Only include results where the first column contains "(p50)".
		if ( 0 <= result[ 0 ].indexOf( '(p50)' ) ) {
			simplified.push( result );
		}
	}
	return simplified;
}

/**
 * @type {Array<{file: string, title: string, results: Record<string,string|number|boolean>[]}>}
 */
let beforeStats = [];

/**
 * @type {Array<{file: string, title: string, results: Record<string,string|number|boolean>[]}>}
 */
let afterStats;

try {
	beforeStats = await csv( {
		noheader: true,
		headers: [ 'key', 'value' ],
	} ).fromFile( beforeFile );
} catch {
	console.error( `Could not read file: ${ beforeFile }` );
	process.exit( 1 );
}

try {
	afterStats = await csv( {
		noheader: true,
		headers: [ 'key', 'value' ],
	} ).fromFile( afterFile );
} catch {
	console.error( `Could not read file: ${ afterFile }` );
	process.exit( 1 );
}

const comparison = [];

for ( const i in beforeStats ) {
	const before = beforeStats[ i ];
	const after = afterStats[ i ];

	const { key, value } = before;

	const valueBefore = Number( value );
	const valueAfter = Number( after.value );

	if ( ! Number.isFinite( Number( value ) ) ) {
		continue;
	}

	const diffPct = valueAfter / valueBefore - 1;
	const diffAbs = valueAfter - valueBefore;

	if ( skipFormatting && 'false' !== skipFormatting ) {
		comparison.push( {
			Metric: key,
			Before: valueBefore,
			After: valueAfter,
			'Diff %': diffPct,
			'Diff abs.': diffAbs,
		} );
		continue;
	}

	comparison.push( {
		Metric: key,
		Before: `${ valueBefore } ms`,
		After: `${ valueAfter } ms`,
		'Diff %': `${ ( diffPct * 100 ).toFixed( 2 ) }%`,
		'Diff abs.': `${ diffAbs.toFixed( 2 ) } ms`,
	} );
}

if ( 'csv' === output ) {
	console.log( `${ title },,,,` );
	console.log( formatAsCsv( comparison ) );
} else {
	console.log( `**${ title }**\n` );
	const simplifiedData = simplifyData( comparison );
	console.log( `***Summary***\n` );
	console.log( formatAsMarkdownTable( simplifiedData ) );
	console.log( `***Details***\n` );
	console.log( formatAsMarkdownTable( comparison ) );
}
console.log();
