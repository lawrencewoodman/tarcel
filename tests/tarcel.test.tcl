package require Tcl 8.6
package require tcltest
package require fileutil
namespace import tcltest::*

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]
set TarcelDir [file normalize [file join $ThisScriptDir ..]]


source [file join $ThisScriptDir "test_helpers.tcl"]
source [file join $LibDir "parameters.tcl"]
source [file join $LibDir "tar.tcl"]
source [file join $LibDir "tararchive.tcl"]
source [file join $LibDir "embeddedchan.tcl"]
source [file join $LibDir "config.tcl"]
source [file join $LibDir "compiler.tcl"]


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


cleanupTests

