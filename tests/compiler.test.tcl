package require Tcl 8.6
package require tcltest
package require fileutil
namespace import tcltest::*

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]


source [file join $ThisScriptDir "test_helpers.tcl"]
source [file join $LibDir "xplatform.tcl"]
source [file join $LibDir "parameters.tcl"]
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

    config set init {
      source [file join lib eater eater.tcl]
      eat orange
    }
  }
  set config [::tarcel::Config new]
  lassign [compiler::compile [$config parse $manifest]] startScript tarball
  set tempFilename [TestHelpers::writeTarcelToTempFile $startScript $tarball]
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

  set announcerDotTarcel {
    set files [list \
      [file join announcer announcer.tcl] \
    ]

    import $files [file join lib]

    config set init {
      source [file join lib announcer announcer.tcl]
    }
  }
  set eaterDotTarcel {
    set appFiles [list \
      [file join eater eater.tcl] \
      [file join eater lib foodplurals.tcl]
    ]

    set modules [list [file join @tmpDir announcer-0.1.tm]]

    import $appFiles [file join lib]
    fetch $modules modules

    config set init {
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
  set eaterDotTarcel [string map [list @tmpDir $tmpDir] $eaterDotTarcel]
  lassign [compiler::compile [$announcerConfig parse $announcerDotTarcel]] \
          announcerStartScript \
          announcerTarball
  set fd [open [file join $tmpDir announcer-0.1.tm] w]
  puts -nonewline $fd $announcerStartScript
  fconfigure $fd -translation binary
  puts -nonewline $fd $announcerTarball
  close $fd
  lassign [compiler::compile [$eaterConfig parse $eaterDotTarcel]] \
          eaterStartScript \
          eaterTarball
  set tempEaterFilename [
    TestHelpers::writeTarcelToTempFile $eaterStartScript $eaterTarball
  ]
  set int [interp create]
} -body {
  $int eval source $tempEaterFilename
} -cleanup {
  interp delete $int
  cd $startDir
} -result {ANNOUNCE: I like eating oranges}


if {![TestHelpers::makeLibWelcome]} {
  puts stderr "Skipping test compile-3 as couldn't build libwelcome"
  skip compile-3
}


test compile-3 {Ensure can 'package require' a module/tarcel that is made from a shared library} -setup {
  set startDir [pwd]
  cd $FixturesDir

  set mainDotTarcel {
    tarcel modules [file join @FixturesDir libwelcome welcome.tarcel]

    config set init {
      ::tcl::tm::path add modules
      package require welcome
      welcome fred
    }
  }
  set mainDotTarcel [
    string map [list @FixturesDir $FixturesDir] $mainDotTarcel
  ]
  set mainConfig [::tarcel::Config new]
  lassign [compiler::compile [$mainConfig parse $mainDotTarcel]] \
          mainStartScript \
          mainTarball
  set mainFilename [
    TestHelpers::writeTarcelToTempFile $mainStartScript $mainTarball
  ]
  set int [interp create]
} -body {
  $int eval source $mainFilename
} -cleanup {
  interp delete $int
  cd $startDir
} -result {Welcome fred}


cleanupTests
