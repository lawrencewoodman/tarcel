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
  Compile fred.tcl
}


#################################
# Internal commands
#################################

proc parcel::PutsFile {filename} {
  set fd [open $filename r]
  puts "\n\n"
  puts [read $fd]
  puts "\n\n"
  close $fd
}


proc parcel::Compile {outFilename} {
  global LibDir
  variable archive

  puts [[config::getArchive] export encodedFiles]
  PutsFile [file join $LibDir embeddedchan.tcl]
  PutsFile [file join $LibDir base64archive.tcl]
  PutsFile [file join $LibDir pvfs.tcl]
  PutsFile [file join $LibDir launcher.tcl]
  puts "pvfs::mount \[Base64Archive new \$encodedFiles\] ."
  puts "launcher::init"
  puts [config::getInitScript]
  puts "launcher::finish"
}


lassign $argv manifestFilename
parcel::main $manifestFilename
