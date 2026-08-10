/**
 * External dependencies
 */
import wpPlugin from '@wordpress/eslint-plugin';

export default [
	{
		ignores: [ '**/build/**', '**/node_modules/**', '**/vendor/**' ],
	},

	...wpPlugin.configs.recommended,

	{
		languageOptions: {
			parserOptions: {
				requireConfigFile: false,
				babelOptions: {
					presets: [ '@wordpress/babel-preset-default' ],
				},
			},
		},
		rules: {
			'import/no-unresolved': [
				'error',
				{
					ignore: [ '^tablemark$', 'csv-stringify/sync' ],
				},
			],
		},
	},

	{
		files: [ 'scripts/**/*.[jt]s' ],
		rules: {
			'no-console': 'off',
		},
	},

	{
		files: [ 'eslint.config.mjs' ],
		rules: {
			'import/no-extraneous-dependencies': 'off',
		},
	},
];
