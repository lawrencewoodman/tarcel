package require Tcl 8.6
package require tcltest
namespace import tcltest::*

# Add module dir to tm paths
set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file join $ThisScriptDir fixtures]

source [file join $LibDir "embeddedchan.tcl"]


test read-1 {Ensure doesn't return more than requested} -setup {
  set text {This is some text}
  set fd [embeddedChan::open $text]
} -body {
  embeddedChan::read $fd 9
} -cleanup {
  embeddedChan::finalize $fd
} -result {This is s}


cleanupTests
