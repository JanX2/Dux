#!/usr/bin/ruby

require 'rubygems'
require 'json' # mac os x does not ship with this gem, use `sudo gem install json` to install it

input = ARGV[0]
parsed_input = JSON.parse(input)
print JSON.pretty_generate(parsed_input)
  