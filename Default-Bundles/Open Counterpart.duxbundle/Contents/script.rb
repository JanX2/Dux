#!/usr/bin/ruby

currentFile = ENV['DuxCurrentFile']

unless currentFile
  print "No file to open"
  exit
end

if currentFile.match /\.m$/
  newFile = currentFile.sub(/\.m$/, '.h')
elsif currentFile.match /\.h$/
  newFile = currentFile.sub(/\.h$/, '.m')
else
  print "No Counterpart Found"
  exit
end

system "open -a Dux '#{newFile}'"
