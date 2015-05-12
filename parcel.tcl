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
  variable additionalModulePaths [list]
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
    list list
    set set
  }
  set slaveCmds {
    add parcel::Add
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


proc parcel::Add {interp type args} {
  switch $type {
    module { AddModule {*}$args }
    modulePath { AddModulePath {*}$args }
    default {
      return -code error "unknown add type: $type"
    }
  }
}


# TODO: Add version number handling
proc parcel::AddModule {args} {
  variable archive
  lassign $args moduleName destination
  set dirPrefix [regsub {^(.*?)([^:]+)$} $moduleName {\1}]
  set dirPrefix [regsub {::} $dirPrefix [file separator]]
  set tailModuleName [regsub {^(.*?)([^:]+)$} $moduleName {\2}]
  set foundModules [list]

  foreach path [::tcl::tm::path list] {
    set possibleModules [
      glob -nocomplain \
           -directory [file join $path $dirPrefix] \
           "$tailModuleName*.tm"
    ]
    foreach moduleFilename $possibleModules {
      set tailFoundModule [file tail $moduleFilename]
      set version [regsub {^(.*?)-(.*?)\.tm$} $tailFoundModule {\2}]
      lappend foundModules [list $moduleFilename $tailFoundModule $version]
    }
  }

  if {[llength $foundModules] == 0} {
    return -code error "Module can't be found: $moduleName"
  }
  set latestModule [lindex [lsort -decreasing -index 2 $foundModules] 0]
  lassign $latestModule fullModuleFilename tailModuleName
  set importPoint [file join $destination $dirPrefix]
  $archive fetchFiles [list $fullModuleFilename] $importPoint
}


proc parcel::AddModulePath {args} {
  variable additionalModulePaths

  set additionalModulePaths [list {*}$additionalModulePaths {*}$args]
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
  variable additionalModulePaths

  puts [$archive export encodedFiles]
  PutsFile "embeddedchan.tcl"
  PutsFile "base64archive.tcl"
  PutsFile "pvfs.tcl"
  PutsFile "launcher.tcl"
  puts "pvfs::mount \[Base64Archive new \$encodedFiles\] ."
  puts "launcher::init"
  foreach additionalModulePath $additionalModulePaths {
    puts "::tcl::tm::path add \[file join \[file dirname \[info script\]\] $additionalModulePath\]"
  }
  puts "source [lindex [$archive ls] 0]"
  puts "launcher::finish"
}


lassign $argv manifestFilename
parcel::main $manifestFilename
