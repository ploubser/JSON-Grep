# Changelog

## 1.5.1
* Now handles escaped parens when tokenising statements

## 1.5.0
* Dropped support for Ruby 1.8.3
* Added support for modern Ruby versions (Tested up to 2.4.0)
* Added utility method to validate expressions

## 1.4.1
* Fix binary exit code to be 1 when no matches are found (Mickaël Canévet)

## 1.4.0
* Expressions support matching true/false booleans (Boyan Tabakov)
* `--slice` option added to jgrep to get array elements (Jon McKenzie)
* `-i` option to read file supported without a TTY (Jon McKenzie)
* `-n` streaming option from 1.3.2 reinstated
* Performance fix: string splitting replaced with character access
* Performance fix: regexes replaced with simpler string methods
* Tests fixed and enabled on Travis CI
