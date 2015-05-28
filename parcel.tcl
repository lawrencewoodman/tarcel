#! /usr/bin/env tclsh
# A utility to package files into a 'parcel'.
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#


set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir lib]
source [file join $LibDir tararchive.tcl]
source [file join $LibDir config.tcl]
source [file join $LibDir compiler.tcl]


proc main {manifestFilename} {
  set startDir [pwd]
  cd [file dirname $manifestFilename]
  set config [Config new]
  set configSettings [$config load [file tail $manifestFilename]]
  cd $startDir

  set parcel [compiler::compile $configSettings]
  if {[dict exists $configSettings outputFilename]} {
    set outputFilename [dict get $configSettings outputFilename]
    puts "Output filename: $outputFilename"
    set fd [open $outputFilename w]
    puts $fd $parcel
    close $fd
  } else {
    puts $parcel
  }
}


lassign $argv manifestFilename
main $manifestFilename
