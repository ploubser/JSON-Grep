#!/usr/bin/env ruby

require 'jgrep.rb'
require 'rubygems'
require 'json'
require 'pp'

json = STDIN.read

result = JSON.parse(JGrep::jgrep((json), ARGV[0]))
pp result

puts "-------------"
puts "JGrep returned #{result.size} documents"
