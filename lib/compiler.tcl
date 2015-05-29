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
  set noStartupCode false
  foreach option $options {
    if {$option eq "-nostartupcode"} {
      set noStartupCode true
    } else {
      return -code error "invalid option for compile: $option"
    }
  }

  set config [lindex $args end]
  set archive [dict get $config archive]
  set tarArchive [$archive export]
  set result ""

  if {!$noStartupCode} {
    append result "if {!\[namespace exists ::tarcel\]} {\n"
    append result [IncludeFile [file join $LibDir tarcellauncher.tcl]]
    append result "::tarcel::init\n"
    append result "::tarcel::eval {\n"
    append result [IncludeFile [file join $LibDir embeddedchan.tcl]]
    append result [IncludeFile [file join $LibDir tararchive.tcl]]
    append result [IncludeFile [file join $LibDir tvfs.tcl]]
    append result "tvfs::init ::tarcel::evalInMaster "
    append result "::tarcel::invokeHiddenInMaster "
    append result "::tarcel::transferChanToMaster\n"
    append result "}\n"
    append result "::tarcel::createAliases\n"
    append result "}\n"
  }

  append result "::tarcel::eval {\n"
  append result "set archive \[TarArchive new\]\n"
  append result "\$archive load \[info script\]\n"
  append result "tvfs::mount \$archive .\n"
  append result "}\n"

  append result [dict get $config init]
  append result "\u001a$tarArchive"

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
