# Tar archive
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

::oo::class create TarArchive {
  variable files

  constructor {} {
    set files [dict create]
  }


  # tarball begins immediately after first ^z (0x1a)
  method load {filename} {
    if {[::pvfs::exists $filename]} {
      set contents [::pvfs::read $filename]
    } else {
      set fd [open $filename r]
      set contents [read $fd]
      close $fd
    }

    set tarball [regsub "^(.*?\u001a)(.*)$" $contents {\2}]
    set filenames [my TarGetFilenames $tarball]

    foreach filename $filenames {
      dict set files $filename [my TarGetFile $tarball $filename]
    }
  }


  method importFiles {_files importPoint} {
    foreach filename $_files {
      if {![my IsValidImportFilename $filename]} {
        return -code error "can't import file: $filename"
      }
      set importedFilename [
        my RemoveDotFromFilename [file join $importPoint $filename]
      ]
      set fd [open $filename r]
      set contents [read $fd]
      close $fd
      dict set files $importedFilename $contents
    }
  }


  method fetchFiles {_files importPoint} {
    foreach filename $_files {
      if {![my IsValidFetchFilename $filename]} {
        return -code error "can't fetch file: $filename"
      }
      set importedFilename [
        my RemoveDotFromFilename [file join $importPoint [file tail $filename]]
      ]
      set fd [open $filename r]
      set contents [read $fd]
      close $fd
      dict set files $importedFilename $contents
    }
  }


  method importContents {contents filename} {
    dict set files $filename $contents
  }


  method export {} {
    my TarCreate $files
  }


  method ls {} {
    dict keys $files
  }


  method exists {filename} {
    dict exists $files $filename
  }


  method read {filename} {
    dict get $files $filename
  }


  ######################
  # Private methods
  ######################

  method Write {dir filename contents} {
    file mkdir [file join $dir [file dirname $filename]]
    set finalFilename [file join $dir $filename]
    set fd [open $finalFilename w]
    puts -nonewline $fd $contents
    close $fd
  }


  method RemoveDotFromFilename {filename} {
    set splitFilename [file split $filename]
    set outFilename [list]

    foreach e $splitFilename {
      if {$e ne "."} {
        lappend outFilename $e
      }
    }

    return [file join {*}$outFilename]
  }


  method IsValidImportFilename {filename} {
    if {![file isfile $filename]} {
      return 0
    }

    set splitFilename [file split $filename]

    foreach e $splitFilename {
      if {$e eq ".."} {
        return 0
      }
    }

    return 1
  }


  method IsValidFetchFilename {filename} {
    if {![file isfile $filename]} {
      return 0
    }

    return 1
  }


  method TarReadRecord {tarball pos} {
    set endPos [expr {$pos + 511}]
    set record [string range $tarball $pos $endPos]
    list $record [expr {$endPos + 1}]
  }


  method TarReadHeader {tarball pos} {
    lassign [my TarReadRecord $tarball $pos] header newPos
    if {![my TarValidHeader $header]} {
      return -code error "invalid tar archive header"
    }
    set filename [string trim [string range $header 0 99]]
    set filesize [string trim [string range $header 124 135]]
    set filesize [scan $filesize %o]
    list $filename $filesize $newPos
  }


  method TarValidHeader {header} {
    set checksum [string trim [string range $header 148 155]]
    set checksum [scan $checksum %o]
    lassign [my TarCalcChecksum $header] unsignedChecksum signedChecksum
    if {$checksum == $unsignedChecksum ||
        $checksum == $signedChecksum ||
        $header eq [my TarMakeRecord {}] } {
      return 1
    }

    return 0
  }


  method TarReadContents {tarball pos filesize} {
    set result ""
    set bytesRead 0
    while {$bytesRead < $filesize} {
      set recordTruncatePoint [expr {$filesize - $bytesRead - 1}]
      lassign [my TarReadRecord $tarball $pos] record pos
      append result [
        string range $record 0 $recordTruncatePoint
      ]
      incr bytesRead 512
    }
    list $result $pos
  }


  method TarGetFilenames {tarball} {
    set filenames [list]
    set pos 0

    while {1} {
      lassign [my TarReadHeader $tarball $pos] filename filesize pos
      if {$filename eq ""} {break}
      lassign [my TarReadContents $tarball $pos $filesize] contents pos
      lappend filenames $filename
    }

    return $filenames
  }


  method TarGetFile {tarball requestFilename} {
    set pos 0

    while {1} {
      lassign [my TarReadHeader $tarball $pos] filename filesize pos
      if {$filename eq ""} {break}
      lassign [my TarReadContents $tarball $pos $filesize] contents pos
      if {$filename eq $requestFilename} {
        return $contents
      }
    }

    return -code error "file not found: $requestFilename"
  }


  method TarCreate {_files} {
    set tarball ""
    dict for {filename contents} $_files {
      append tarball [my TarMakeHeader $filename $contents]
      append tarball [my TarMakeFileRecords $contents]
    }

    append tarball [my TarFinishArchive]
  }


  method TarMakeHeader {filename contents} {
    set header ""
    set filesize [string length $contents]
    set freeFilenameBytes [expr {100 - [string length $filename]}]

    append header [format %s $filename]
    append header [binary format "a$freeFilenameBytes" {}]
    append header [binary format a24 {}]
    append header "[format %-11o $filesize] "
    append header [binary format a12 {}]
    append header "        "
    append header "0"
    append header [binary format a100 {}]

    lassign [my TarCalcChecksum $header] checksumUnsigned
    set formattedChecksum [format %06o $checksumUnsigned]
    append formattedChecksum "[binary format a1 {}] "
    set header [string replace $header 148 155 $formattedChecksum]

    return [my TarMakeRecord $header]
  }


  method TarCalcChecksum {header} {
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


  method TarMakeFileRecords {contents} {
    set records ""
    set filesize [string length $contents]

    set pos 0
    while {$pos < $filesize} {
      append records [my TarMakeRecord [string range $contents $pos end]]
      incr pos 512
    }

    return $records
  }


  method TarMakeRecord {contents} {
    set sizedContents [string range $contents 0 511]
    set bytesShort [expr {512 - [string length $sizedContents]}]
    set record $sizedContents
    append record [binary format "a$bytesShort" {}]
  }


  method TarFinishArchive {} {
    set result [my TarMakeRecord {}]
    append result [my TarMakeRecord {}]
    return $result
  }

}

