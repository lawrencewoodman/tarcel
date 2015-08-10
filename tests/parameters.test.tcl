package require Tcl 8.6
package require tcltest
namespace import tcltest::*

set ThisScriptDir [file normalize [file dirname [info script]]]
set LibDir [file join $ThisScriptDir .. lib]

source [file join $ThisScriptDir "test_helpers.tcl"]
source [file join $LibDir "parameters.tcl"]


test getSwitches-1 {Ensure that switch processing stops once -- reached if in switchesWithoutValue} -setup {
  set switchesWithValue {-types -directory}
  set switchesWithoutValue {-nocomplain -- -bob}
} -body {
  set cmdArgs {-types d -directory /tmp -nocomplain -- -bob 7}
  ::tarcel::parameters::getSwitches $switchesWithValue \
                                    $switchesWithoutValue \
                                    {*}$cmdArgs
} -result {{-types d -directory /tmp -nocomplain 1} {-bob 7}}


cleanupTests
