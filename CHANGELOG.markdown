# Changelog

## 1.4.0
* Expressions support matching true/false booleans (Boyan Tabakov)
* `--slice` option added to jgrep to get array elements (Jon McKenzie)
* `-i` option to read file supported without a TTY (Jon McKenzie)
* `-n` streaming option from 1.3.2 reinstated
* Performance fix: string splitting replaced with character access
* Performance fix: regexes replaced with simpler string methods
* Tests fixed and enabled on Travis CI
