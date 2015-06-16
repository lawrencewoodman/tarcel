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
  set fd [::tarcel::embeddedChan::open $text]
} -body {
  ::tarcel::embeddedChan::read $fd 9
} -cleanup {
  ::tarcel::embeddedChan::finalize $fd
} -result {This is s}


test read-2 {Ensure reads from correct position on second or more reads} -setup {
  set text {This is some text to demonstrate a possible problem}
  set fd [::tarcel::embeddedChan::open $text]
  set result [list]
} -body {
  lappend result [::tarcel::embeddedChan::read $fd 9]
  lappend result [::tarcel::embeddedChan::read $fd 5]
  lappend result [::tarcel::embeddedChan::read $fd 3]
} -cleanup {
  ::tarcel::embeddedChan::finalize $fd
} -result [list {This is s} {ome t} {ext}]


test seek-1 {Ensure that will seek to correct place when base start} -setup {
  set text {This is some text to demonstrate a possible problem}
  set fd [::tarcel::embeddedChan::open $text]
  set result [list]
} -body {
  lappend result [::tarcel::embeddedChan::seek $fd 22 start]
  lappend result [::tarcel::embeddedChan::read $fd 7]
} -cleanup {
  ::tarcel::embeddedChan::finalize $fd
} -result {22 emonstr}


test seek-2 {Ensure that will seek to correct place when base end} -setup {
  set text {This is some text to demonstrate a possible problem}
  set fd [::tarcel::embeddedChan::open $text]
  set result [list]
} -body {
  lappend result [::tarcel::embeddedChan::seek $fd -6 end]
  lappend result [::tarcel::embeddedChan::read $fd 4]
} -cleanup {
  ::tarcel::embeddedChan::finalize $fd
} -result {44 prob}


test seek-3 {Ensure that will seek to correct place when base current} -setup {
  set text {This is some text to demonstrate a possible problem}
  set fd [::tarcel::embeddedChan::open $text]
  set result [list]
} -body {
  lappend result [::tarcel::embeddedChan::seek $fd 22 start]
  lappend result [::tarcel::embeddedChan::seek $fd 4 current]
  lappend result [::tarcel::embeddedChan::read $fd 4]
} -cleanup {
  ::tarcel::embeddedChan::finalize $fd
} -result {22 26 stra}


cleanupTests
