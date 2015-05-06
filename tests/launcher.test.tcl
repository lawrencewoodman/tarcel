package require Tcl 8.6
package require tcltest
namespace import tcltest::*

# Add module dir to tm paths
set ThisScriptDir [file dirname [info script]]
set LibDir [file normalize [file join $ThisScriptDir .. lib]]

source [file join $ThisScriptDir .. "embeddedchan.tcl"]
source [file join $ThisScriptDir .. "launcher.tcl"]


test source-1 {Ensure that info script returns correct location when an encoded file sourced} -setup {
  set infoScriptScript {
    set ret [info script]
  }
  set encodedFiles [
    dict create lib/info_script.tcl \
                [::base64::encode $infoScriptScript]
  ]
} -body {
  launcher::init $encodedFiles
  source lib/info_script.tcl
  set ret
} -cleanup {
  launcher::finish
} -result {lib/info_script.tcl}


test open-1 {Ensure that read works correctly for files when no count given} -setup {
  set niceDayText {
    This is a very nice day
    oh yes it is
  }
  set encodedFiles [
    dict create text/nice_day.txt \
                [::base64::encode $niceDayText]
  ]
} -body {
  launcher::init $encodedFiles
  set fd [open "text/nice_day.txt" r]
  set result [read $fd]
  close $fd
  set result
} -cleanup {
  launcher::finish
} -result {
    This is a very nice day
    oh yes it is
  }


test open-2 {Ensure that read works correct for files when count given} -setup {
  set niceDayText {This is a very nice day}
  set encodedFiles [
    dict create text/nice_day.txt \
                [::base64::encode $niceDayText]
  ]
  set result [list]
} -body {
  launcher::init $encodedFiles
  set fd [open "text/nice_day.txt" r]
  lappend result [read $fd 7]
  lappend result [read $fd 6]
  lappend result [read $fd 20]
  lappend result [read $fd 20]
  close $fd
  set result
} -cleanup {
  launcher::finish
} -result {{This is} { a ver} {y nice day} {}}


test open-2 {Ensure that gets works correctly for files} -setup {
  set niceDayText {This is a very nice day
    and so is this}
  set encodedFiles [
    dict create text/nice_day.txt \
                [::base64::encode $niceDayText]
  ]
  set result [list]
} -body {
  launcher::init $encodedFiles
  set fd [open "text/nice_day.txt" r]
  lappend result [gets $fd]
  lappend result [gets $fd]
  lappend result [gets $fd]
  close $fd
  set result
} -cleanup {
  launcher::finish
} -result {{This is a very nice day} {    and so is this} {}}


cleanupTests
