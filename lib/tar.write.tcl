# Tarball handling functions to create a tarball
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

namespace eval ::tarcel {

  namespace eval tar {
    namespace export {[a-z]*}
    namespace ensemble create
  }


  proc tar::create {_files} {
    set tarball ""
    dict for {filename contents} $_files {
      set unixFilename [toUnixFilename $filename]
      append tarball [MakeHeader $unixFilename $contents]
      append tarball [MakeFileRecords $contents]
    }

    append tarball [FinishArchive]
  }


  #############################
  # Internal commands
  #############################

  proc tar::MakeHeader {filename contents} {
    set header ""
    set filesize [string length $contents]
    set freeFilenameBytes [expr {100 - [string length $filename]}]

    append header [format %s $filename]
    append header [binary format "a$freeFilenameBytes" {}]
    append header [binary format a24 {}]
    append header "[format %-11o $filesize] "
    append header "[format %11o [clock seconds]] "
    append header "        "
    append header "0"
    append header [binary format a100 {}]

    lassign [CalcHeaderChecksum $header] checksumUnsigned
    set formattedChecksum [format %06o $checksumUnsigned]
    append formattedChecksum "[binary format a1 {}] "
    set header [string replace $header 148 155 $formattedChecksum]

    return [MakeRecord $header]
  }


  proc tar::MakeFileRecords {contents} {
    set records ""
    set filesize [string length $contents]

    set pos 0
    while {$pos < $filesize} {
      append records [MakeRecord [string range $contents $pos end]]
      incr pos 512
    }

    return $records
  }


  proc tar::FinishArchive {} {
    set result [MakeRecord {}]
    append result [MakeRecord {}]
    return $result
  }

}
