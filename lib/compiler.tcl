# Parcel compiler
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

namespace eval compiler {
}


proc compiler::compile {channelId config} {
  global LibDir
  global parcelScript
  variable archive
  set archive [dict get $config archive]

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
  puts $channelId [$archive export encodedFiles]
  puts $channelId "pvfs::mount \[Base64Archive new \$encodedFiles\] ."
  puts $channelId "}"

  puts $channelId "::parcel::eval {"
  puts -nonewline $channelId "launcher::init ::parcel::evalInMaster "
  puts -nonewline $channelId "::parcel::invokeHiddenInMaster "
  puts $channelId "::parcel::transferChanToMaster"
  puts $channelId "}"
  puts $channelId [dict get $config init]
}



#################################
# Internal commands
#################################

proc compiler::PutsFile {channelId filename} {
  set fd [open $filename r]
  puts $channelId "\n\n"
  puts $channelId [read $fd]
  puts $channelId "\n\n"
  close $fd
}
