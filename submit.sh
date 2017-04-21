#!/bin/sh
zip -r image.zip src haxelib.json README.md -x "*/\.*"
haxelib submit image.zip
rm image.zip 2> /dev/null
