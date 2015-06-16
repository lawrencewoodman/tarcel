package require Tcl 8.6
package require tcltest
package require fileutil
namespace import tcltest::*

set ThisScriptDir [file dirname [info script]]
set RootDir [file join $ThisScriptDir ..]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]
set TarcelDir [file normalize [file join $ThisScriptDir ..]]


source [file join $ThisScriptDir "test_helpers.tcl"]

if {![TestHelpers::makeLibWelcome]} {
  puts stderr "Skipping test wrap-1 as couldn't build libwelcome"
  skip wrap-1
}


test wrap-1 {Ensure can 'package require' a module/tarcel that is made from a shared library} -setup {
  set startDir [pwd]
  set tempDir [TestHelpers::makeTempDir]

  cd [file join $FixturesDir libwelcome]
  exec tclsh [file join $TarcelDir tarcel.tcl] wrap \
      -o [file join $tempDir welcomefred.tcl] welcomefred.tarcel
} -body {
  exec tclsh [file join $tempDir welcomefred.tcl]
} -cleanup {
  cd $startDir
} -result {Welcome fred}


test wrap-2 {Ensure can wrap itself and then wrap something else} -setup {
  set tempDir [TestHelpers::makeTempDir]

  exec tclsh [file join $TarcelDir tarcel.tcl] wrap \
             -o [file join $tempDir t.tcl] \
             tarcel.tarcel
  exec tclsh [file join $tempDir t.tcl] wrap \
             -o [file join $tempDir h.tcl] \
             [file join $FixturesDir hello hello.tarcel]
} -body {
  exec tclsh [file join $tempDir h.tcl]
} -result {Hello bob, how are you?}


test wrap-3 {Ensure that output file is relative to pwd} -setup {
  set startDir [pwd]
  set tempDir [TestHelpers::makeTempDir]
  cd $tempDir

  exec tclsh [file join $TarcelDir tarcel.tcl] wrap \
             -o h.tcl \
             [file join $FixturesDir hello hello.tarcel]
} -body {
  file exists h.tcl
} -cleanup {
  cd $startDir
} -result 1


cleanupTests
