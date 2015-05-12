# The script to launch the application from the embedded scripts.
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

namespace eval launcher {
  namespace export open source file glob
}


proc launcher::init {} {
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
    if {[pvfs::exists [lindex $args 1]]} {
      return 1
    }
  }
  ::launcher::realFile {*}$args
}


proc launcher::source {args} {
  set switchesWithValue {-encoding}
  lassign [GetSwitches $switchesWithValue {} {*}$args] switches argsLeft

  if {[llength $argsLeft] != 1} {
    uplevel 1 ::launcher::realSource {*}$args
  }

  set filename $argsLeft
  set contents [pvfs::read $filename]
  if {$contents ne {}} {
    set callingScript [info script]
    info script $filename
    if {[dict exist $switches -encoding]} {
      set res [
        uplevel 1 [
          encoding convertfrom [dict get $switches -encoding] $contents
        ]
      ]
    } else {
      set res [uplevel 1 $contents]
    }
    info script $callingScript
  } else {
    set res [uplevel 1 ::launcher::realSource {*}$args]
  }

  return $res
}


proc launcher::open {args} {
  lassign $args filename
  if {[pvfs::exists $filename]} {
    set contents [pvfs::read $filename]
    return [embeddedChan::open $contents]
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
  set directory [file split [file normalize $directory]]
  set lastDirectoryPartIndex [expr {[llength $directory] - 1}]
  set result [list]

  set vFilenames [pvfs::ls]
  foreach vFilename $vFilenames {
    set splitVFilename [file split [file normalize $vFilename]]
    set possibleCommonDir [
      lrange $splitVFilename 0 $lastDirectoryPartIndex
    ]

    if {$directory == $possibleCommonDir} {
      set comparePart [
        file join [lrange $splitVFilename \
                          [expr {$lastDirectoryPartIndex+1}] \
                          end]
      ]

      foreach pattern $patterns {
        if {[string match $pattern $comparePart]} {
          lappend result $vFilename
        }
      }
    }
  }

  return $result
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
