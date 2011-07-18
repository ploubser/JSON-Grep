#!/usr/bin/env ruby

require 'jgrep.rb'
require 'rubygems'
require 'json'
require 'pp'

json = JSON::load(File.read("mc.json"))
result = JGrep::jgrep(json, ARGV[0])
pp result

puts "-------------"
puts "JGrep returned #{result.size} documents out of a possible #{json.size}"
