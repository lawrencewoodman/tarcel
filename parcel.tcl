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


proc main {manifestFilename} {
  set startDir [pwd]
  cd [file dirname $manifestFilename]
  config::load [file tail $manifestFilename]
  cd $startDir

  set outputFilename [config::getConfigVar outputFilename]

  if {$outputFilename eq {}} {
    Compile stdout
  } else {
    puts "Output filename: $outputFilename"
    set fd [open $outputFilename w]
    Compile $fd
    close $fd
  }
}


#################################
# Internal commands
#################################

proc PutsFile {channelId filename} {
  set fd [open $filename r]
  puts $channelId "\n\n"
  puts $channelId [read $fd]
  puts $channelId "\n\n"
  close $fd
}


proc Compile {channelId} {
  global LibDir
  global parcelScript
  variable archive

  puts $channelId "if {!\[namespace exists ::parcel\]} {"
  PutsFile $channelId [file join $LibDir parcellauncher.tcl]
  puts $channelId "::parcel::init"
  puts $channelId "::parcel::eval {"
  PutsFile $channelId [file join $LibDir embeddedchan.tcl]
  PutsFile $channelId [file join $LibDir base64archive.tcl]
  PutsFile $channelId [file join $LibDir pvfs.tcl]
  PutsFile $channelId [file join $LibDir launcher.tcl]
  puts $channelId "}"
  puts $channelId "::parcel::createAliases"
  puts $channelId "}"

  puts $channelId "::parcel::eval {"
  puts $channelId [[config::getArchive] export encodedFiles]
  puts $channelId "pvfs::mount \[Base64Archive new \$encodedFiles\] ."
  puts $channelId "}"

  puts $channelId "::parcel::eval {"
  puts -nonewline $channelId "launcher::init ::parcel::evalInMaster "
  puts -nonewline $channelId "::parcel::invokeHiddenInMaster "
  puts $channelId "::parcel::transferChanToMaster"
  puts $channelId "}"
  puts $channelId [config::getInitScript]
}


lassign $argv manifestFilename
main $manifestFilename
