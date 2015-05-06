# A reflected channel to handle embedded files.
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#
namespace eval embeddedChan {
  variable readWatch 0
# TODO: Change name of encodedContents as not really encoded anymore
  variable chanEncodedContents [dict create]
  variable supportedSubCommands {
    initialize
    finalize
    watch
    read
    configure
    cget
    cgetall
    configure
  }
  namespace export -clear {*}$supportedSubCommands
  # TODO: Work out what the following does
  namespace ensemble create -subcommands {}
}

proc embeddedChan::open {encodedContents} {
  variable chanEncodedContents
  set chanid [chan create read [namespace current]]
  dict set chanEncodedContents $chanid [
    dict create pos 0 \
                readWatch 0 \
                encodedContents [::base64::decode $encodedContents]
  ]
  return $chanid
}


proc embeddedChan::initialize {chanid mode} {
  variable supportedSubCommands

  if 0 {
    set map [dict create]
    dict set map finalize    [list ::rchan::finalize $chanid]
    dict set map watch       [list ::rchan::watch $chanid]
    dict set map seek        [list ::rchan::seek $chanid]
    dict set map read        [list ::rchan::read $chanid]
    dict set map cget        [list ::rchan::cget $chanid]
    dict set map cgetall     [list ::rchan::cgetall $chanid]
    dict set map configure   [list ::rchan::configure $chanid]
    dict set map blocking    [list ::rchan::blocking $chanid]

    namespace ensemble create -map $map -command ::$chanid
  }
  namespace ensemble create -command ::$chanid

  return [join $supportedSubCommands " "]
}

proc embeddedChan::finalize {chanid} {
  variable chanEncodedContents

  dict unset chanEncodedContents $chanid
}


proc embeddedChan::watch {chanid events} {
  variable chanEncodedContents

  puts [info level 0]
  if {$read in $events} {
    dict set chanEncodedContents $chanid readWatch 1
  } else {
    dict set chanEncodedContents $chanid readWatch 0
  }
}


proc embeddedChan::read {chanid count} {
  variable chanEncodedContents
  set pos [dict get $chanEncodedContents $chanid pos]
  set result [
    string range [dict get $chanEncodedContents $chanid encodedContents] \
                 $pos \
                 $pos+$count
  ]

  dict set chanEncodedContents $chanid pos [expr {$pos + $count + 1}]

  if {[dict get $chanEncodedContents $chanid readWatch]} {
    chan postevent $chanid read
  }

  return $result
}


proc embeddedChan::blocking { chanid args } {
}


proc embeddedChan::cget {chanid args} {
}


proc embeddedChan::cgetall {chanid args} {
}


proc embeddedChan::configure {chanid args} {
}
