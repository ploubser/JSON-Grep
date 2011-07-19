#!/usr/bin/env ruby

require 'jgrep'

json = STDIN.read

result = JGrep::jgrep((json), ARGV[0])
puts result unless result == "[]"
