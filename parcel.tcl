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
set LibDir [file join $ThisScriptDir lib]
source [file join $LibDir config.tcl]


namespace eval parcel {
}


proc parcel::main {manifestFilename} {
  set startDir [pwd]
  cd [file dirname $manifestFilename]
  config::load [file tail $manifestFilename]
  cd $startDir

  set outputFilename [config::getConfigVar outputFilename]

  if {$outputFilename eq {}} {
    Compile stdout fred.tcl
  } else {
    puts stderr "parcel::main writing to: $outputFilename"
    set fd [open $outputFilename w]
    Compile $fd fred.tcl
    close $fd
  }
}


#################################
# Internal commands
#################################

proc parcel::PutsFile {channelId filename} {
  set fd [open $filename r]
  puts $channelId "\n\n"
  puts $channelId [read $fd]
  puts $channelId "\n\n"
  close $fd
}


proc parcel::Compile {channelId outFilename} {
  global LibDir
  variable archive

  puts $channelId [[config::getArchive] export encodedFiles]
  PutsFile $channelId [file join $LibDir embeddedchan.tcl]
  PutsFile $channelId [file join $LibDir base64archive.tcl]
  PutsFile $channelId [file join $LibDir pvfs.tcl]
  PutsFile $channelId [file join $LibDir launcher.tcl]
  puts $channelId "pvfs::mount \[Base64Archive new \$encodedFiles\] ."
  puts $channelId "launcher::init"
  puts $channelId [config::getInitScript]
  puts $channelId "launcher::finish"
}


lassign $argv manifestFilename
parcel::main $manifestFilename
