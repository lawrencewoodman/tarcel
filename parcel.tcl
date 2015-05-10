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

set ThisScriptDir [file dirname [info script]]
source [file join $ThisScriptDir base64archive.tcl]


namespace eval parcel {
  variable archive [Base64Archive new]
}


proc parcel::main {manifestFilename} {
  set files [GetConfig $manifestFilename]
  Compile fred.tcl
}


#################################
# Internal commands
#################################

proc parcel::GetConfig {filename} {
  set exposeCmds {
    set set
  }
  set slaveCmds {
    import parcel::Import
    fetch parcel::Fetch
  }

  set fd [open $filename r]
  set scriptIn [read $fd]
  close $fd
  parseConfig -keys {} -exposeCmds $exposeCmds -slaveCmds $slaveCmds $scriptIn
}


proc parcel::Import {interp files importPoint} {
  variable archive
  $archive importFiles $files $importPoint
}


proc parcel::Fetch {interp files importPoint} {
  variable archive
  $archive fetchFiles $files $importPoint
}


proc parcel::PutsFile {filename} {
  set fd [open $filename r]
  puts "\n\n"
  puts [read $fd]
  puts "\n\n"
  close $fd
}


proc parcel::Compile {outFilename} {
  variable archive
  puts [$archive export encodedFiles]
  PutsFile "embeddedchan.tcl"
  PutsFile "base64archive.tcl"
  PutsFile "pvfs.tcl"
  PutsFile "launcher.tcl"
  puts "pvfs::mount \[Base64Archive new \$encodedFiles\] ."
  puts "launcher::init"
  puts "source [lindex [$archive ls] 0]"
  puts "launcher::finish"
}


lassign $argv manifestFilename
parcel::main $manifestFilename
