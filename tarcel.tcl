#! /usr/bin/env tclsh
# A utility to package files into a 'tarcel'.
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir lib]
source [file join $LibDir tar.tcl]
source [file join $LibDir tararchive.tcl]
source [file join $LibDir config.tcl]
source [file join $LibDir compiler.tcl]


proc handleParameters {parameters} {
     set usage ": tarcel.tcl command value\ncommands:\n"
  append usage "    wrap <.tarcel filename>   - Wrap files using .tarcel file\n"
  append usage "    info <tarcel filename>    - Information about tarcel file\n"

  if {[llength $parameters] != 2} {
    puts stderr "Error: invalid number of arguments\n"
    puts stderr $usage
    exit 1
  }

  lassign $parameters command value
  switch $command {
    wrap {wrap $value}
    info {getInfo $value}
    default {
      puts stderr "Error: invalid command: $command\n"
      puts stderr $usage
      exit 1
    }
  }
}


proc wrap {dotTarcelFilename} {
  cd [file dirname $dotTarcelFilename]
  set config [Config new]
  set configSettings [$config load [file tail $dotTarcelFilename]]

  set tarcel [compiler::compile $configSettings]
  if {[dict exists $configSettings outputFilename]} {
    set outputFilename [dict get $configSettings outputFilename]
    puts "Output filename: $outputFilename"
    set fd [open $outputFilename w]
    puts $fd $tarcel
    close $fd
  } else {
    puts $tarcel
  }
}


proc getInfo {tarcelFilename} {
  set infoScript {
    source [file join lib tar.tcl]
    set tarball [::tarcel::tar::extractTarballFromFile @tarcelFilename]
    eval [::tarcel::tar::getFile $tarball commands.tcl]
    ::tarcel::commands::info $tarball
  }
  set infoScript [
    string map [list @tarcelFilename $tarcelFilename] $infoScript
  ]
  set int [interp create]
  set info [$int eval $infoScript]
  displayInfo $tarcelFilename $info
}


proc displayInfo {tarcelFilename info} {
  puts "Information for tarcel: $tarcelFilename\n"
  if {[dict exists $info homepage]} {
    puts "  Homepage: [dict get $info homepage]"
  }
  if {[dict exists $info version]} {
    puts "  Version: [dict get $info version]"
  }
  puts "  Filenames:"
  foreach filename [dict get $info filenames] {
    puts "    $filename"
  }
}


proc main {parameters} {
  set startDir [pwd]
  handleParameters $parameters
  cd $startDir
}


main $argv
