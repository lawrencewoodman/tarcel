package require Tcl 8.6
package require tcltest
namespace import tcltest::*

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]


source [file join $ThisScriptDir "test_helpers.tcl"]
source [file join $LibDir "xplatform.tcl"]
source [file join $LibDir "tar.tcl"]
source [file join $LibDir "tararchive.tcl"]
source [file join $LibDir "embeddedchan.tcl"]
source [file join $LibDir "config.tcl"]
source [file join $LibDir "compiler.tcl"]


test info-1 {Ensure lists files in tarcel} -setup {
  set startDir [pwd]
  cd $FixturesDir

  set dotTarcel {
    set appFiles [list \
      [file join eater eater.tcl] \
      [file join eater lib foodplurals.tcl]
    ]
    set modules [list \
      [find module configurator]
    ]

    import [file join lib] $appFiles
    fetch modules $modules

    config set init {
      source [file join lib eater eater.tcl]
      eat orange
    }
  }

  set infoScript {
    set ThisDir [file dirname [info script]]
    set LibDir [file join $ThisDir .. lib]
    source [file join $LibDir xplatform.tcl]
    source [file join $LibDir tar.tcl]
    set tarball [::tarcel::tar::extractTarballFromFile @tempFilename]
    eval [::tarcel::tar::getFile $tarball lib/commands.tcl]
    ::tarcel::commands::info $tarball
  }

  set config [::tarcel::Config new]
  lassign [compiler::compile [$config parse $dotTarcel]] startScript tarball
  set tempFilename [TestHelpers::writeTarcelToTempFile $startScript $tarball]
  cd $startDir
  set infoScript [
    string map [list @tempFilename $tempFilename] $infoScript
  ]
  set int [interp create]
  $int eval info script [info script]
} -body {
  $int eval $infoScript
} -cleanup {
  interp delete $int
  cd $startDir
} -result [
  dict create filenames [
    list lib/eater/eater.tcl \
         lib/eater/lib/foodplurals.tcl \
         modules/configurator-0.1.tm
  ]
]


test info-2 {Ensure lists homepage set in tarcel} -setup {
  set startDir [pwd]
  cd $FixturesDir

  set dotTarcel {
    set appFiles [list \
      [file join eater eater.tcl] \
      [file join eater lib foodplurals.tcl]
    ]
    config set homepage "http://example.com/tarcel"
    import [file join lib] $appFiles

    config set init {
      source [file join lib eater eater.tcl]
      eat orange
    }
  }

  set infoScript {
    set ThisDir [file dirname [info script]]
    set LibDir [file join $ThisDir .. lib]
    source [file join $LibDir xplatform.tcl]
    source [file join $LibDir tar.tcl]
    set tarball [::tarcel::tar::extractTarballFromFile @tempFilename]
    eval [::tarcel::tar::getFile $tarball lib/commands.tcl]
    ::tarcel::commands::info $tarball
  }

  set config [::tarcel::Config new]
  lassign [compiler::compile [$config parse $dotTarcel]] startScript tarball
  set tempFilename [TestHelpers::writeTarcelToTempFile $startScript $tarball]
  cd $startDir
  set infoScript [
    string map [list @tempFilename $tempFilename] $infoScript
  ]
  set int [interp create]
  $int eval info script [info script]
} -body {
  dict get [$int eval $infoScript] homepage
} -cleanup {
  interp delete $int
  cd $startDir
} -result {http://example.com/tarcel}


test info-3 {Ensure lists version set in tarcel} -setup {
  set startDir [pwd]
  cd $FixturesDir

  set dotTarcel {
    set appFiles [list \
      [file join eater eater.tcl] \
      [file join eater lib foodplurals.tcl]
    ]
    config set version 0.1
    import [file join lib] $appFiles

    config set init {
      source [file join lib eater eater.tcl]
      eat orange
    }
  }

  set infoScript {
    set ThisDir [file dirname [info script]]
    set LibDir [file join $ThisDir .. lib]
    source [file join $LibDir xplatform.tcl]
    source [file join $LibDir tar.tcl]
    set tarball [::tarcel::tar::extractTarballFromFile @tempFilename]
    eval [::tarcel::tar::getFile $tarball lib/commands.tcl]
    ::tarcel::commands::info $tarball
  }

  set config [::tarcel::Config new]
  lassign [compiler::compile [$config parse $dotTarcel]] startScript tarball
  set tempFilename [TestHelpers::writeTarcelToTempFile $startScript $tarball]
  cd $startDir
  set infoScript [
    string map [list @tempFilename $tempFilename] $infoScript
  ]
  set int [interp create]
  $int eval info script [info script]
} -body {
  dict get [$int eval $infoScript] version
} -cleanup {
  interp delete $int
  cd $startDir
} -result {0.1}


cleanupTests
