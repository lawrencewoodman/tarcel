package require Tcl 8.6
package require tcltest
package require fileutil
namespace import tcltest::*

# Add module dir to tm paths
set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]


source [file join $ThisScriptDir "test_helpers.tcl"]
source [file join $LibDir "tar.tcl"]
source [file join $LibDir "tararchive.tcl"]
source [file join $LibDir "embeddedchan.tcl"]
source [file join $LibDir "config.tcl"]
source [file join $LibDir "compiler.tcl"]


test compile-1 {Ensure that you can access the files in the tarcel from the init script} -setup {
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
  set config [::tarcel::Config new]
  set tarcel [compiler::compile [$config parse $manifest]]
  set tempFilename [TestHelpers::writeToTempFile $tarcel]
  set int [interp create]
} -body {
  $int eval source $tempFilename
} -cleanup {
  interp delete $int
  cd $startDir
} -result {I like eating oranges}


test compile-2 {Ensure can source a tarcelled file} -setup {
  set startDir [pwd]
  cd $FixturesDir

  set announcerManifest {
    set files [list \
      [file join announcer announcer.tcl] \
    ]

    import $files [file join lib]

    init {
      source [file join lib announcer announcer.tcl]
    }
  }
  set eaterManifest {
    set appFiles [list \
      [file join eater eater.tcl] \
      [file join eater lib foodplurals.tcl]
    ]

    set modules [list [file join @tmpDir announcer-0.1.tm]]

    import $appFiles [file join lib]
    fetch $modules modules

    init {
      ::tcl::tm::path add modules
      package require announcer
      source [file join lib eater eater.tcl]
      announce [eat orange]
    }
  }
  set tmpDir [file join [::fileutil::tempdir] tarcelTest_[clock milliseconds]]
  file mkdir $tmpDir
  set eaterConfig [::tarcel::Config new]
  set announcerConfig [::tarcel::Config new]
  set eaterManifest [string map [list @tmpDir $tmpDir] $eaterManifest]
  set announcerTarcel [
    compiler::compile [$announcerConfig parse $announcerManifest]
  ]
  set fd [open [file join $tmpDir announcer-0.1.tm] w]
  puts $fd $announcerTarcel
  close $fd
  set eaterTarcel [compiler::compile [$eaterConfig parse $eaterManifest]]
  set tempEaterFilename [TestHelpers::writeToTempFile $eaterTarcel]
  set int [interp create]
} -body {
  $int eval source $tempEaterFilename
} -cleanup {
  interp delete $int
  cd $startDir
} -result {ANNOUNCE: I like eating oranges}


cleanupTests
