package require Tcl 8.6
package require tcltest
namespace import tcltest::*

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]


source [file join $ThisScriptDir "test_helpers.tcl"]
source [file join $LibDir "version.tcl"]
source [file join $LibDir "xplatform.tcl"]
source [file join $LibDir "parameters.tcl"]
source [file join $LibDir "tar.read.tcl"]
source [file join $LibDir "tar.write.tcl"]
source [file join $LibDir "tararchive.read.tcl"]
source [file join $LibDir "tararchive.write.tcl"]
source [file join $LibDir "embeddedchan.tcl"]
source [file join $LibDir "config.tcl"]
source [file join $LibDir "compiler.tcl"]


test compile-1 {Ensure that you can access the files in the tarcel from the init script} -setup {
  set startDir [pwd]
  cd $FixturesDir

  set dotTarcel {
    set appFiles [list \
      [file join eater eater.tcl] \
      [file join eater lib foodplurals.tcl]
    ]

    import [file join lib] $appFiles

    config set init {
      source [file join lib eater eater.tcl]
      eat orange
    }
  }
  set config [::tarcel::Config new]
  lassign [compiler::compile [$config parse $dotTarcel]] startScript tarball
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

    import [file join lib] $files

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

    import [file join lib] $appFiles
    fetch modules $modules

    config set init {
      ::tcl::tm::path add modules
      package require announcer
      source [file join lib eater eater.tcl]
      announce [eat orange]
    }
  }
  set tmpDir [TestHelpers::makeTempDir]
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
      ::welcome::welcome fred
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


test compile-4 {Ensure that a tarcel has a header to say that it is a tarcel} -setup {
  set dotTarcel {
    config set init {
      puts "hello"
    }
  }
  set config [::tarcel::Config new]
  lassign [compiler::compile [$config parse $dotTarcel]] startScript tarball
  set startScriptLines [split $startScript \n]
  set header [list]
  foreach startScriptLine $startScriptLines {
    if {[string match {#*} $startScriptLine]} {
      if {![string match {######*} $startScriptLine]} {
        lappend header $startScriptLine
      }
    } else {
      break;
    }
  }

  set headerLinesLookingFor [list]
  foreach headerLine $header {
    if {[regexp {^#.*?Tarcel v\d+\.\d+.*?$} $headerLine] ||
        [regexp {^#.*?project page.*?$} $headerLine] ||
        [regexp {^#.*?vlifesystems.com/projects/tarcel.*?$} $headerLine]} {
      lappend headerLinesLookingFor $headerLine
    }
  }
} -body {
  llength $headerLinesLookingFor
} -result {3}


test compile-5 {Ensure that only files needed are included in startup tarball} -setup {
  set dotTarcel {
    config set init {
      puts "hello"
    }
  }
  set config [::tarcel::Config new]
  lassign [compiler::compile [$config parse $dotTarcel]] startScript tarball
} -body {
  lsort [::tarcel::tar getFilenames $tarball]
} -result [list \
  [file join config info] \
  [file join config init.tcl] \
  [file join lib commands.tcl] \
  [file join lib embeddedchan.tcl] \
  [file join lib parameters.tcl] \
  [file join lib tar.read.tcl] \
  [file join lib tararchive.read.tcl] \
  [file join lib tvfs.tcl] \
  [file join lib xplatform.tcl] \
  [file join main.tar]
]


test compile-6 {Ensure that you can add a hashbang line} -setup {
  set dotTarcel {
    config set hashbang "/usr/bin/env tclsh"
    config set init {
      puts "hello"
    }
  }
  set config [::tarcel::Config new]
} -body {
  lassign [compiler::compile [$config parse $dotTarcel]] startScript tarball
  set startScriptLines [split $startScript \n]
  lindex $startScriptLines 0
} -result {#!/usr/bin/env tclsh}


test compile-7 {Ensure that a hashbang line isn't added unless specified} -setup {
  set dotTarcel {
    config set hashbang "/usr/bin/env tclsh"
    config set init {
      puts "hello"
    }
  }
  set config [::tarcel::Config new]
} -body {
  lassign [compiler::compile [$config parse $dotTarcel]] startScript tarball
  set startScriptLines [split $startScript \n]
  set firstLine [lindex $startScriptLines 0]
  string match {#*} $firstLine
} -result {1}


cleanupTests
