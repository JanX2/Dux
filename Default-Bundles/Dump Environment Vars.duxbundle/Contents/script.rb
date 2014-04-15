#!/usr/bin/ruby

print "working directory: #{Dir.pwd}\n\n"
print "current file: " + ENV['DuxCurrentFile'] + "\n\n"

print "ENV:\n"
ENV.each do |key, value|
  print "#{key}: #{value}\n"
end
