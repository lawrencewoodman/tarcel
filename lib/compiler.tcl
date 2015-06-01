# Tarcel compiler
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

namespace eval compiler {
  variable LibDir [file normalize [file dirname [info script]]]
}


proc compiler::compile {args} {
  variable LibDir

  set options [lrange $args 0 end-1]
  set incStartupCode true
  foreach option $options {
    if {$option eq "-nostartupcode"} {
      set incStartupCode false
    } else {
      return -code error "invalid option for compile: $option"
    }
  }

  set config [lindex $args end]
  set archive [dict get $config archive]
  set mainTarball [$archive export]
  set result ""
  set initTarball [MakeInitTarball $mainTarball $config $incStartupCode]

  append result [IncludeFile [file join $LibDir tar.tcl]]
  append result "namespace eval ::tarcel {\n"
  append result "  variable tarball \[::tarcel::tar::extractTarballFromFile "
  append result "\[info script\]\]\n"
  append result "  uplevel 1 \[::tarcel::tar::getFile \$tarball commands.tcl\]\n"
  append result "}\n"
  append result "::tarcel::commands::launch\n"
  append result "\u001a$initTarball"

  return $result
}



#################################
# Internal commands
#################################

proc compiler::IncludeFile {filename} {
  set result ""
  set fd [open $filename r]
  append result "\n\n\n"
  append result [read $fd]
  append result "\n\n\n"
  close $fd
  return $result
}


proc compiler::ReadFile {filename} {
  set fd [open $filename r]
  set contents [read $fd]
  close $fd
  return $contents
}


proc compiler::MakeInitTarball {mainTarball config includeStartupCode} {
  variable LibDir

  if {$includeStartupCode} {
    set files [dict create \
      commands.tcl [ReadFile [file join $LibDir commands.tcl]] \
      main.tar $mainTarball \
      lib/launcher.tcl [ReadFile [file join $LibDir launcher.tcl]] \
      lib/embeddedchan.tcl [ReadFile [file join $LibDir embeddedchan.tcl]] \
      lib/tar.tcl [ReadFile [file join $LibDir tar.tcl]] \
      lib/tararchive.tcl [ReadFile [file join $LibDir tararchive.tcl]] \
      lib/tvfs.tcl [ReadFile [file join $LibDir tvfs.tcl]]
    ]
  } else {
    set files [dict create \
      commands.tcl [ReadFile [file join $LibDir commands.tcl]] \
      main.tar $mainTarball
    ]
  }

  if {[dict exists $config init]} {
    dict set files init.tcl [dict get $config init]
  }

  ::tarcel::tar create $files
}
