# Base 64 archive
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

if {[info object isa object Base64Archive] &&
    [info object isa class Base64Archive]} {
  return
}

package require base64


::oo::class create Base64Archive {
  variable files

  constructor {{_encodedFiles {}}} {
    set files [dict create]

    my AddEncodedFiles $_encodedFiles
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


  # TODO: Fix encoding for non ascii input
  # TODO: Catch any errors
  method export {varName} {
    set result ""
    append result "set $varName \{\n"
    dict for {filename contents} $files {
      set encoding [::base64::encode $contents]
      append result "  $filename \{$encoding\}\n"
    }
    append result "\}\n"
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
  method AddEncodedFiles {_encodedFiles} {
    dict for {filename encoding} $_encodedFiles {
      dict set files $filename [::base64::decode $encoding]
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
