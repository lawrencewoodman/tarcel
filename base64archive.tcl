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
      # TODO: Make sure file is a file and not a dir
      set filenameWithoutDir [file tail $filename]
      set importedFilename [file join $importPoint $filenameWithoutDir]
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

}
