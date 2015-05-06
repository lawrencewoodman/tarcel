# The script to launch the application from the embedded scripts.
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#
package require base64

namespace eval launcher {
  variable encodedFiles
  namespace export open source
}


proc launcher::init {_encodedFiles} {
  variable encodedFiles
  set encodedFiles $_encodedFiles
  rename ::open ::launcher::realOpen
  rename ::source ::launcher::realSource
  uplevel 1 {namespace import launcher::open}
  uplevel 1 {namespace import launcher::source}
}


proc launcher::source {args} {
  variable encodedFiles

  set filename [lindex $args end]
  set encoding [GetEncodedFile $filename]
  if {$encoding ne {}} {
    info script $filename
    uplevel 1 [::base64::decode $encoding]
  } else {
    ::launcher::realSource {*}$args
  }
}


proc launcher::open {args} {
  variable encodedFiles
  lassign $args filename
  set encoding [GetEncodedFile $filename]
  if {$encoding ne {}} {
    return [embeddedChan::open $encoding]
  } else {
    ::launcher::realOpen {*}$args
  }
}


proc launcher::GetEncodedFile {filename} {
  variable encodedFiles

  dict for {encodedFilename encoding} $encodedFiles {
    if {[file normalize $filename] eq [file normalize $encodedFilename]} {
      return $encoding
    }
  }

  return {}
}


proc launcher::finish {} {
  uplevel 1 {namespace forget ::launcher::open}
  uplevel 1 {namespace forget ::launcher::source}
  rename ::launcher::realOpen ::open
  rename ::launcher::realSource ::source
}
