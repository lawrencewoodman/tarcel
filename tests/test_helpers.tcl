# Helper functions for the tests

package require fileutil

namespace eval TestHelpers {
  variable fileSeparator [file separator]
  variable reRequirePackages [list]
}

proc TestHelpers::fileCompare {filename fileContents} {
  set fd [open $filename r]
  set contents [read $fd]
  close $fd
  if {$contents eq $fileContents} {
    return 0
  } else {
    return -1
  }
}


rename file TestHelpers::OldFile
interp alias {} file {} TestHelpers::File
proc TestHelpers::changeFileSeparator {style} {
  variable fileSeparator
  if {$style eq "windows"} {
    set fileSeparator "\\"
  } elseif {$style eq "unix"} {
    set fileSeparator {/}
  } else {
    return -code error "style not recognized: $style"
  }
}


proc TestHelpers::resetFileSeparator {} {
  variable fileSeparator
  set fileSeparator [TestHelpers::OldFile separator]
}


rename package TestHelpers::OldPackage
interp alias {} package {} TestHelpers::Package
proc TestHelpers::allowPackageRerequire {packages} {
  variable reRequirePackages
  set reRequirePackages $packages
}


proc TestHelpers::resetPackageRerequire {} {
  variable reRequirePackages
  set reRequirePackages [list]
}


proc TestHelpers::writeTarcelToTempFile {startScript tarball} {
  set fd [file tempfile filename]
  puts -nonewline $fd $startScript
  fconfigure $fd -translation binary
  puts -nonewline $fd $tarball
  close $fd
  return $filename
}


proc TestHelpers::readFromFilename {filename} {
  set fd [open $filename r]
  set result [read $fd]
  close $fd
  return $result
}


proc TestHelpers::makeTempDir {} {
  set fd [::file tempfile mainTempFile]
  close $fd
  set mainTempDir [::file dirname $mainTempFile]
  while {1} {
    try {
      set tempDir [::file join $mainTempDir tarcel_tests_[clock milliseconds]]
      ::file mkdir $tempDir
      break
    } on error {} {}
  }

  return $tempDir
}


proc TestHelpers::globAll {{dir {}} {mFiles {}}} {
  set files [glob -nocomplain -type f -directory $dir *]
  set dirs [glob -nocomplain -type d -directory $dir *]
  set mFiles [list {*}$mFiles {*}$files]

  foreach dirDescent $dirs {
    set filesInDir [globAll $dirDescent $mFiles]
    set mFiles [list {*}$mFiles {*}$filesInDir]
  }

  return [lsort -unique $mFiles]
}


proc TestHelpers::makeLibWelcome {} {
  set buildSuccess 0
  set startDir [pwd]
  set thisDir [file dirname [info script]]
  set libwelcomeDir [file join $thisDir fixtures libwelcome]

  try {
    cd $libwelcomeDir
    exec make clean
    exec make
    set buildSuccess 1
  } on error {} {}

  cd $startDir
  return $buildSuccess
}


proc TestHelpers::File {args} {
  variable fileSeparator

  if {[lindex $args] >= 1} {
    lassign $args command
    switch $command {
      separator {return $fileSeparator}
      join {return [join [lrange $args 1 end] $fileSeparator]}
    }
  }

  uplevel 1 TestHelpers::OldFile {*}$args
}


proc TestHelpers::Package {args} {
  variable reRequirePackages

  if {[llength $args] == 2 && [lindex $args 0] eq "require"} {
    set packageName [lindex $args 1]
    if {$packageName in $reRequirePackages} {
      set version [
        uplevel #0 [list TestHelpers::OldPackage require $packageName]
      ]
      set ifneeded [package ifneeded $packageName $version]
      uplevel #0 $ifneeded
      return $version
    }
  }

  uplevel 1 [list TestHelpers::OldPackage {*}$args]
}


namespace eval ::tarcel::launcher {
  proc finish {} {
    variable launcherInt
    interp alias {} ::open {}
    interp alias {} ::source {}
    interp alias {} ::file {}
    interp alias {} ::glob {}
    interp alias {} ::load {}
    interp expose {} open
    interp expose {} source
    interp expose {} file
    interp expose {} glob
    interp expose {} load
    interp delete $launcherInt
  }
}
