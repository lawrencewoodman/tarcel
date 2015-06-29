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
  set initTarball [MakeInitTarball $mainTarball $config $incStartupCode]

  set headerComment {#########################################################
# This file is a tarcel created by Tarcel v@version
# To find out more about Tarcel go to the project page:
#   http://vlifesystems.com/projects/tarcel/
#########################################################
}

  set headerComment [
    string map [list @version $::tarcel::version] $headerComment
  ]

  set startScript $headerComment
  append startScript [IncludeFile [file join $LibDir xplatform.tcl]]
  append startScript [IncludeFile [file join $LibDir tar.read.tcl]]

  append startScript {
    namespace eval ::tarcel {
      set tarball [::tarcel::tar::extractTarballFromFile [info script]]
      uplevel 1 [::tarcel::tar::getFile $tarball lib/commands.tcl]
    }
    ::tarcel::commands::launch $::tarcel::tarball]
  }

  append startScript "\u001a"
  list $startScript $initTarball
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


proc compiler::MakeInfo {config} {
  set info [dict create]
  set configVars {homepage version}

  foreach configVar $configVars {
    if {[dict exists $config $configVar]} {
      dict set info $configVar [dict get $config $configVar]
    }
  }

  dict set info tarcel_version $::tarcel::version

  return $info
}


proc compiler::MakeInitTarball {mainTarball config includeStartupCode} {
  variable LibDir

  if {$includeStartupCode} {
    set files [dict create \
      lib/commands.tcl [ReadFile [file join $LibDir commands.tcl]] \
      main.tar $mainTarball \
      config/info [MakeInfo $config] \
      lib/parameters.tcl [ReadFile [file join $LibDir parameters.tcl]] \
      lib/xplatform.tcl [ReadFile [file join $LibDir xplatform.tcl]] \
      lib/embeddedchan.tcl [ReadFile [file join $LibDir embeddedchan.tcl]] \
      lib/tar.read.tcl [ReadFile [file join $LibDir tar.read.tcl]] \
      lib/tararchive.read.tcl [ReadFile [file join $LibDir tararchive.read.tcl]] \
      lib/tvfs.tcl [ReadFile [file join $LibDir tvfs.tcl]]
    ]
  } else {
    set files [dict create \
      lib/commands.tcl [ReadFile [file join $LibDir commands.tcl]] \
      main.tar $mainTarball
    ]
  }

  if {[dict exists $config init]} {
    dict set files config/init.tcl [dict get $config init]
  }

  ::tarcel::tar create $files
}
