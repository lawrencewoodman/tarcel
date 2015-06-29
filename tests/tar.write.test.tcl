package require Tcl 8.6
package require tcltest
namespace import tcltest::*

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file join $ThisScriptDir fixtures]

source [file join $ThisScriptDir "test_helpers.tcl"]
source [file join $LibDir "xplatform.tcl"]
source [file join $LibDir "tar.read.tcl"]
source [file join $LibDir "tar.write.tcl"]
namespace import ::tarcel::tar


test create-1 {Ensure that when run on windows will convert paths to unix in tarball} -setup {
  TestHelpers::changeFileSeparator windows
  set files {
    {foo\~bar\baz} {hello I'm baz}
    {foo\~bar\notbaz} {hello I'm not baz}
  }
  set tarball [tar create $files]
  TestHelpers::changeFileSeparator unix
} -body {
  tar getFile $tarball {foo/~bar/baz}
} -cleanup {
  TestHelpers::resetFileSeparator
} -result {hello I'm baz}


if {[catch {exec tar --help}]} {
  puts stderr "Skipping test create-2 as couldn't run tar command"
  skip create-2
}

test create-2 {Ensure that current date is assigned to each file} -setup {
  set files {
    baz {hello I'm baz}
    notbaz {hello I'm not baz}
  }
  set tarball [tar create $files]
  set fd [file tempfile tarFilename]
  fconfigure $fd -translation binary
  puts -nonewline $fd $tarball
  close $fd
} -body {
  set dir [split [exec tar -tvf $tarFilename] "\n"]
  set numCorrectDates 0
  set currentDate [clock format [clock seconds] -format {%Y-%m-%d}]
  foreach fileInfo $dir {
    if {[string match "*$currentDate*" $fileInfo]} {
      incr numCorrectDates
    }
  }
  set numCorrectDates
} -result 2


cleanupTests
