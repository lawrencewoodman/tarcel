#! /usr/bin/env tclsh
# A utility to package files into a 'parcel'.
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#
package require base64

proc getFiles {filename} {
  source $filename
  return $files
}


proc encodeFiles {files} {
  set encodedFiles [dict create]

  foreach filename $files {
    set fd [open $filename r]
# TODO: Fix encoding for non ascii input
# TODO: Catch any errors
    dict set encodedFiles $filename [::base64::encode [read $fd]]
    close $fd
  }

  return $encodedFiles
}

proc putsEncodedFilesSetLine {encodedFiles} {
  puts "set encodedFiles \{"
  dict for {filename encoding} $encodedFiles {
    puts "  $filename \{$encoding\}"
  }
  puts "\}\n\n"
}

proc putsFile {filename} {
  set fd [open $filename r]
  puts "\n\n"
  puts [read $fd]
  puts "\n\n"
  close $fd
}


proc compile {encodedFiles outFilename} {
  set launcherFd [open "launcher.tcl" r]
  set launcherContents [read $launcherFd]
  close $launcherFd

  putsEncodedFilesSetLine $encodedFiles
  putsFile "embeddedchan.tcl"
  putsFile "launcher.tcl"
  puts "$launcherContents\n"
  puts "launcher::init \$encodedFiles"
  puts "source [lindex $encodedFiles 0]"
  puts "launcher::finish"
}

lassign $argv filename
set files [getFiles $filename]
set encodedFiles [encodeFiles $files]
compile $encodedFiles fred.tcl
