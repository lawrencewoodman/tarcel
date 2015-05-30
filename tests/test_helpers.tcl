# Helper functions for the tests

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
