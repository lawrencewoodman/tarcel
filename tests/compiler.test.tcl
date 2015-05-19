package require Tcl 8.6
package require tcltest
namespace import tcltest::*

# Add module dir to tm paths
set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]


source [file join $LibDir "config.tcl"]
source [file join $LibDir "compiler.tcl"]


test compile-1 {Ensure that you can access the files in the parcel from the init script} -setup {
  set startDir [pwd]
  cd $FixturesDir

  set manifest {
    set appFiles [list \
      [file join eater eater.tcl] \
      [file join eater lib foodplurals.tcl]
    ]

    import $appFiles [file join lib]

    init {
      source [file join lib eater eater.tcl]
      eat orange
    }
  }
  set config [config::parse $manifest]
  set parcel [compiler::compile $config]
  set int [interp create]
} -body {
  $int eval $parcel
} -cleanup {
  interp delete $int
  cd $startDir
} -result {I like eating oranges}


cleanupTests
