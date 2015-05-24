# Binary archive
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

::oo::class create BinArchive {
  variable files

  constructor {} {
    set files [dict create]
  }


  # binary contents data begins immediately after first ^z (0x1a)
  method load {filename fileSizes} {
    if {[info commands ::pvfs::exists] ne "" && [::pvfs::exists $filename]} {
      set contents [::pvfs::read $filename]
      set fd [embeddedChan::open $contents]
    } else {
      set fd [open $filename r]
    }
    my SeekToStartOfBinaryContents $fd
    dict for {filename size} $fileSizes {
      dict set files $filename [read $fd $size]
    }
    close $fd
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
    variable files
    set numFiles [dict size $files]

    set fileSizes [
      dict map {filename contents} $files {
        set size [string length $contents]
      }
    ]

    set binArchive ""

    dict for {filename contents} $files {
      append binArchive $contents
    }

    return [list $fileSizes $binArchive]
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

  method SeekToStartOfBinaryContents {chan} {
    seek $chan 0
    while {[read $chan 1] ne "\u001a"} {
    }
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
}

