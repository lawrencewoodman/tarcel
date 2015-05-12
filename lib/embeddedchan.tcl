# A reflected channel to handle embedded files.
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#
namespace eval embeddedChan {
  variable files [dict create]
  variable supportedSubCommands {
    initialize
    finalize
    watch
    read
  }
  namespace export -clear {*}$supportedSubCommands
  # TODO: Work out what the following does
  namespace ensemble create -subcommands {}
}

proc embeddedChan::open {contents} {
  variable files
  set chanid [chan create read [namespace current]]

  dict set files $chanid [
    dict create pos 0 \
                readWatch 0 \
                contents $contents
  ]

  return $chanid
}


proc embeddedChan::initialize {chanid mode} {
  variable supportedSubCommands

  namespace ensemble create -command ::$chanid
  return [join $supportedSubCommands " "]
}


proc embeddedChan::finalize {chanid} {
  variable files

  dict unset files $chanid
}


proc embeddedChan::watch {chanid events} {
  variable files

  puts [info level 0]
  if {$read in $events} {
    dict set files $chanid readWatch 1
  } else {
    dict set files $chanid readWatch 0
  }
}


proc embeddedChan::read {chanid count} {
  variable files
  set pos [dict get $files $chanid pos]
  set readEndPos [expr {$pos + $count -1}]
  set result [
    string range [dict get $files $chanid contents] \
                 $pos \
                 $readEndPos
  ]

  dict set files $chanid pos [expr {$pos + $count + 1}]

  if {[dict get $files $chanid readWatch]} {
    chan postevent $chanid read
  }

  return $result
}
