#! /usr/bin/env tclsh
# A utility to package files into a 'parcel'.
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#
package require base64
package require configurator
namespace import configurator::*


namespace eval parcel {
  variable imports [dict create]
}


proc parcel::getConfig {filename} {
  set exposeCmds {
    set set
  }
  set slaveCmds {
    import parcel::import
  }

  set fd [open $filename r]
  set scriptIn [read $fd]
  close $fd
  parseConfig -keys {} -exposeCmds $exposeCmds -slaveCmds $slaveCmds $scriptIn
}


proc parcel::import {interp files importPoint} {
  variable imports
  dict set imports $importPoint $files
}


proc parcel::encodeFiles {} {
  variable imports

  set encodedFiles [dict create]

  dict for {importPoint files} $imports {
    foreach filename $files {
      set filenameWithoutDir [file tail $filename]
      set importedFilename [file join $importPoint $filenameWithoutDir]
      set fd [open $filename r]
      set contents [read $fd]
      close $fd
# TODO: Fix encoding for non ascii input
# TODO: Catch any errors
      dict set encodedFiles $importedFilename [::base64::encode $contents]
    }
  }

  return $encodedFiles
}


proc parcel::putsEncodedFilesSetLine {encodedFiles} {
  puts "set encodedFiles \{"
  dict for {filename encoding} $encodedFiles {
    puts "  $filename \{$encoding\}"
  }
  puts "\}\n\n"
}

proc parcel::putsFile {filename} {
  set fd [open $filename r]
  puts "\n\n"
  puts [read $fd]
  puts "\n\n"
  close $fd
}


proc parcel::compile {encodedFiles outFilename} {
  putsEncodedFilesSetLine $encodedFiles
  putsFile "embeddedchan.tcl"
  putsFile "launcher.tcl"
  puts "launcher::init \$encodedFiles"
  puts "source [lindex $encodedFiles 0]"
  puts "launcher::finish"
}


lassign $argv filename
set files [parcel::getConfig $filename]
set encodedFiles [parcel::encodeFiles]
parcel::compile $encodedFiles fred.tcl
