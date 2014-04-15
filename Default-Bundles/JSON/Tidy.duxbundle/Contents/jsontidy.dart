#!/usr/bin/env /Users/abhi/bin/dart/dart-sdk/bin/dart

import 'dart:io';
import 'dart:json';

main()
{
  var input = new Options().arguments[0];
  var parsed_input = parse(input);
  
  print(stringify(parsed_input)); // Dart doesn't currently have any equivalent to ruby's JSON.pretty_generate()
}
