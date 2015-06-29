# Tarball handling functions
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

namespace eval ::tarcel {

  namespace eval tar {
    namespace export {[a-z]*}
    namespace ensemble create
    namespace import ::tarcel::xplatform::toUnixFilename
  }


  proc tar::getFile {tarball requestFilename} {
    set pos 0
    set unixRequestFilename [toUnixFilename $requestFilename]

    while {1} {
      lassign [ReadNextFile $tarball $pos] filename contents pos
      if {$filename eq ""} {break}
      if {$filename eq $unixRequestFilename} {
        return $contents
      }
    }

    return -code error "file not found: $requestFilename"
  }


  proc tar::exists {tarball checkFilename} {
    set pos 0
    set unixCheckFilename [toUnixFilename $checkFilename]

    while {1} {
      lassign [ReadNextFile $tarball $pos] filename contents pos
      if {$filename eq ""} {break}
      if {$filename eq $unixCheckFilename} {
        return 1
      }
    }

    return 0
  }

  proc tar::getFilenames {tarball} {
    set filenames [list]
    set pos 0

    while {1} {
      lassign [ReadNextFile $tarball $pos] filename contents pos
      if {$filename eq ""} {break}
      lappend filenames $filename
    }

    return $filenames
  }


  proc tar::extractTarball {script} {
    regsub {^(.*?\u001a)(.*)$} $script {\2}
  }


  proc tar::extractTarballFromFile {filename} {
    set fd [open $filename r]
    fconfigure $fd -translation binary
    set contents [read $fd]
    close $fd
    extractTarball $contents
  }


  #############################
  # Internal commands
  #############################

  proc tar::ReadNextFile {tarball pos} {
    lassign [ReadHeader $tarball $pos] filename filesize pos
    if {$filename eq ""} {return {{} 0 0}}
    lassign [ReadContents $tarball $pos $filesize] contents pos
    return [list $filename $contents $pos]
  }


  proc tar::ReadRecord {tarball pos} {
    set endPos [expr {$pos + 511}]
    set record [string range $tarball $pos $endPos]
    list $record [expr {$endPos + 1}]
  }


  proc tar::ReadHeader {tarball pos} {
    lassign [ReadRecord $tarball $pos] header newPos
    if {![IsValidHeader $header]} {
      return -code error "invalid tar archive header"
    }
    set filename [string trim [string range $header 0 99]]
    set filesize [string trim [string range $header 124 135]]
    set filesize [scan $filesize %o]
    list $filename $filesize $newPos
  }


  proc tar::MakeRecord {contents} {
    set sizedContents [string range $contents 0 511]
    set bytesShort [expr {512 - [string length $sizedContents]}]
    set record $sizedContents
    append record [binary format "a$bytesShort" {}]
  }


  proc tar::IsValidHeader {header} {
    set checksum [string trim [string range $header 148 155]]
    set checksum [scan $checksum %o]
    lassign [CalcHeaderChecksum $header] unsignedChecksum signedChecksum
    if {$checksum == $unsignedChecksum ||
        $checksum == $signedChecksum ||
        $header eq [MakeRecord {}] } {
      return 1
    }

    return 0
  }


  proc tar::ReadContents {tarball pos filesize} {
    set result ""
    set bytesRead 0
    while {$bytesRead < $filesize} {
      set recordTruncatePoint [expr {$filesize - $bytesRead - 1}]
      lassign [ReadRecord $tarball $pos] record pos
      append result [
        string range $record 0 $recordTruncatePoint
      ]
      incr bytesRead 512
    }
    list $result $pos
  }


  proc tar::CalcHeaderChecksum {header} {
    set bytes [split $header {}]
    set checksumUnsigned 0
    set checksumSigned 0
    set pos 0

    foreach byte $bytes {
      # Take checksum bytes to be spaces
      if {$pos >= 148 && $pos <= 155} {
        set byte " "
      }
      binary scan $byte c signedByte
      set unsignedByte [expr { $signedByte & 0xff }]
      incr checksumUnsigned $unsignedByte
      incr checksumSigned $signedByte
      incr pos
    }

    list $checksumUnsigned $checksumSigned
  }

  namespace export tar
}
