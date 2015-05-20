# Parcel compiler
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
  set result ""

  if {!$noStartupCode} {
    append result "if {!\[namespace exists ::parcel\]} {\n"
    append result [IncludeFile [file join $LibDir parcellauncher.tcl]]
    append result "::parcel::init\n"
    append result "::parcel::eval {\n"
    append result [IncludeFile [file join $LibDir embeddedchan.tcl]]
    append result [IncludeFile [file join $LibDir base64archive.tcl]]
    append result [IncludeFile [file join $LibDir pvfs.tcl]]
    append result [IncludeFile [file join $LibDir launcher.tcl]]
    append result "}\n"
    append result "::parcel::createAliases\n"
    append result "}\n"
  }

  append result "::parcel::eval {\n"
  append result "[$archive export encodedFiles]\n"
  append result "pvfs::mount \[Base64Archive new \$encodedFiles\] .\n"
  append result "}\n"

  append result "::parcel::eval {\n"
  append result "launcher::init ::parcel::evalInMaster "
  append result "::parcel::invokeHiddenInMaster "
  append result "::parcel::transferChanToMaster\n"
  append result "}\n"
  append result [dict get $config init]

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
