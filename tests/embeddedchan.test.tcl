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


test read-2 {Ensure reads from correct position on second or more reads} -setup {
  set text {This is some text to demonstrate a possible problem}
  set fd [embeddedChan::open $text]
  set result [list]
} -body {
  lappend result [embeddedChan::read $fd 9]
  lappend result [embeddedChan::read $fd 5]
  lappend result [embeddedChan::read $fd 3]
} -cleanup {
  embeddedChan::finalize $fd
} -result [list {This is s} {ome t} {ext}]


cleanupTests
