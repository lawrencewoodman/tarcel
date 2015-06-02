# Helper functions for the tests

package require fileutil

namespace eval TestHelpers {
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


proc TestHelpers::writeToTempFile {contents} {
  set fd [file tempfile filename]
  puts -nonewline $fd $contents
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
  set tempDir [file join [fileutil::tempdir] tarcel_tests_[clock milliseconds]]
  file mkdir $tempDir
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


namespace eval ::tarcel::launcher {
  proc finish {} {
    variable launcherInt
    interp alias {} ::open {}
    interp alias {} ::source {}
    interp alias {} ::file {}
    interp alias {} ::glob {}
    interp expose {} open
    interp expose {} source
    interp expose {} file
    interp expose {} glob
    interp delete $launcherInt
  }
}
