# The script to launch the application from the embedded scripts.
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#
package require base64

namespace eval launcher {
  variable encodedFiles
  namespace export open source file glob
}


proc launcher::init {_encodedFiles} {
  variable encodedFiles

  set encodedFiles $_encodedFiles

  rename ::open ::launcher::realOpen
  rename ::source ::launcher::realSource
  rename ::file ::launcher::realFile
  rename ::glob ::launcher::realGlob
  uplevel 1 {namespace import launcher::open}
  uplevel 1 {namespace import launcher::source}
  uplevel 1 {namespace import launcher::file}
  uplevel 1 {namespace import launcher::glob}
}

proc launcher::glob {args} {
  set switchesWithValue {-directory -path -types}
  set switchesWithoutValue {-join -nocomplain -tails}
  set result [list]

  lassign [GetSwitches $switchesWithValue $switchesWithoutValue {*}$args] \
          switches \
          patterns

  if {[dict exists $switches -directory]} {
    set directory [dict get $switches -directory]
    set result [GlobInDir $switches $directory $patterns]
  }

  try {
    set result [list {*}$result {*}[::launcher::realGlob {*}$args]]
  } on error {errorMsg options} {
    if {[string match {no files matched glob pattern*} $errorMsg] &&
        [llength $result] == 0 &&
        ![dict exists $switches -nocomplain]} {
      dict unset options -level
      return -options $options $errorMsg
    }
  }

  return $result
}


proc launcher::file {args} {
  lassign $args command

  if {$command eq "exists" && [llength $args] == 2} {
    if {[FileExists [lindex $args 1]]} {
      return 1
    }
  }
  ::launcher::realFile {*}$args
}


proc launcher::source {args} {
  variable encodedFiles

  set switchesWithValue {-encoding}
  lassign [GetSwitches $switchesWithValue {} {*}$args] switches argsLeft

  if {[llength $argsLeft] != 1} {
    uplevel 1 ::launcher::realSource {*}$args
  }

  set filename $argsLeft
  set encoding [GetEncodedFile $filename]
  if {$encoding ne {}} {
    info script $filename
    set decodedSource [::base64::decode $encoding]
    if {[dict exist $switches -encoding]} {
      uplevel 1 [
        encoding convertfrom [dict get $switches -encoding] $decodedSource
      ]
    } else {
      uplevel 1 [::base64::decode $encoding]
    }
  } else {
    uplevel 1 ::launcher::realSource {*}$args
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
    if {[::file normalize $filename] eq [::file normalize $encodedFilename]} {
      return $encoding
    }
  }

  return {}
}


proc launcher::finish {} {
  uplevel 1 {namespace forget ::launcher::open}
  uplevel 1 {namespace forget ::launcher::source}
  uplevel 1 {namespace forget ::launcher::file}
  uplevel 1 {namespace forget ::launcher::glob}
  rename ::launcher::realOpen ::open
  rename ::launcher::realSource ::source
  rename ::launcher::realFile ::file
  rename ::launcher::realGlob ::glob
}


########################
#  Internal commands
########################

proc launcher::GlobInDir {switches directory patterns} {
  variable encodedFiles

  set directory [file split [file normalize $directory]]
  set lastDirectoryPartIndex [expr {[llength $directory] - 1}]
  set result [list]

  dict for {encodedFilename encoding} $encodedFiles {
    set splitEncodedFilename [file split [file normalize $encodedFilename]]
    set possibleCommonDir [
      lrange $splitEncodedFilename 0 $lastDirectoryPartIndex
    ]

    if {$directory == $possibleCommonDir} {
      set comparePart [
        file join [lrange $splitEncodedFilename \
                          [expr {$lastDirectoryPartIndex+1}] \
                          end]
      ]

      foreach pattern $patterns {
        if {[string match $pattern $comparePart]} {
          lappend result $encodedFilename
        }
      }
    }
  }

  return $result
}


proc launcher::FileExists {name} {
  variable encodedFiles

  set normalizedSplitName [file split [file normalize $name]]
  set lastNamePartIndex [expr {[llength $normalizedSplitName] - 1}]

  dict for {encodedFilename encoding} $encodedFiles {
    set splitEncodedFilename [file split [file normalize $encodedFilename]]
    if {$normalizedSplitName ==
        [lrange $splitEncodedFilename 0 $lastNamePartIndex]} {
      return 1
    }
  }

  return 0
}


proc launcher::GetSwitches {switchesWithValue switchesWithoutValue args} {
  set switches [dict create]
  set numArgs [llength $args]

  for {set argNum 0} {$argNum < $numArgs} {incr argNum} {
    set arg [lindex $args $argNum]
    if {![string match {-*} $arg]} {
      break
    }

    if {$arg in $switchesWithValue && ($argNum + 1 < $numArgs)} {
      set nextArg [lindex $args [expr {$argNum + 1}]]
      dict set switches $arg $nextArg
      incr argNum
    } elseif {$arg in $switchesWithoutValue} {
      dict set switches $arg 1
    } else {
      return -code error "invalid switch"
    }
  }

  set argsLeft [lrange $args $argNum end]
  return [list $switches $argsLeft]
}
