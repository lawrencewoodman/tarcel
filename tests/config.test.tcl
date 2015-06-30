package require Tcl 8.6
package require tcltest
namespace import tcltest::*

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]


source [file join $ThisScriptDir "test_helpers.tcl"]
source [file join $LibDir "version.tcl"]
source [file join $LibDir "xplatform.tcl"]
source [file join $LibDir "tar.read.tcl"]
source [file join $LibDir "tar.write.tcl"]
source [file join $LibDir "tararchive.read.tcl"]
source [file join $LibDir "tararchive.write.tcl"]
source [file join $LibDir "config.tcl"]
source [file join $LibDir "compiler.tcl"]

namespace import ::tarcel::tar


test parse-tarcel-1 {Ensure that tarcel will use a .tarcel to package files relative to the .tarcel file and add it to the tarcel} -setup {
  set startDir [pwd]
  cd $FixturesDir

  set dotTarcel {
    tarcel modules [file join eater eater.tarcel]

    config set init {
      source [file join modules eater-0.1.tm]
      eat orange
    }
  }
  set config [::tarcel::Config new]
  lassign [compiler::compile [$config parse $dotTarcel]] \
          startScript \
          tarball
  set tempFilename [
    TestHelpers::writeTarcelToTempFile $startScript $tarball
  ]
  set int [interp create]
} -body {
  $int eval source $tempFilename
} -cleanup {
  interp delete $int
  cd $startDir
} -result {I like eating oranges}


test parse-tarcel-2 {Ensure that when using tarcel to create a tarcel that the resulting file doesn't include all the setup code} -setup {
  set startDir [pwd]
  cd $FixturesDir

  set dotTarcel {
    tarcel modules [file join eater eater.tarcel]

    config set init {
      source [file join modules eater-0.1.tm]
      eat orange
    }
  }
  set config [::tarcel::Config new]
  set configSettings [$config parse $dotTarcel]
  set archive [dict get $configSettings archive]
  set eaterScript [$archive read [file join modules eater-0.1.tm]]
} -body {
  set eaterTarball [tar extractTarball $eaterScript]
  lsort [tar getFilenames $eaterTarball]
} -cleanup {
  cd $startDir
} -result {config/init.tcl lib/commands.tcl main.tar}


test parse-tarcel-3 {Ensure that tarcel will allow you to pass arguments to args in dot tarcel file} -setup {
  set startDir [pwd]
  cd $FixturesDir

  set dotTarcel {
    tarcel modules [file join whatargs.tarcel] a b 5 6 c d

    config set init {
      source [file join modules whatargs.tcl]
      whatArgs
    }
  }
  set config [::tarcel::Config new]
  lassign [compiler::compile [$config parse $dotTarcel]] \
          startScript \
          tarball
  set tempFilename [
    TestHelpers::writeTarcelToTempFile $startScript $tarball
  ]
  set int [interp create]
} -body {
  $int eval source $tempFilename
} -cleanup {
  interp delete $int
  cd $startDir
} -result {args: a b 5 6 c d}


test parse-tarcel-4 {Ensure that tarcel's args is an empty list if not passed} -setup {
  set startDir [pwd]
  cd $FixturesDir

  set dotTarcel {
    tarcel modules [file join whatargs.tarcel]

    config set init {
      source [file join modules whatargs.tcl]
      whatArgs
    }
  }
  set config [::tarcel::Config new]
  lassign [compiler::compile [$config parse $dotTarcel]] \
          startScript \
          tarball
  set tempFilename [
    TestHelpers::writeTarcelToTempFile $startScript $tarball
  ]
  set int [interp create]
} -body {
  $int eval source $tempFilename
} -cleanup {
  interp delete $int
  cd $startDir
} -result {args: }


test parse-find-module-1 {Ensure that requirements can be used to find module} -setup {
  set dotTarcel {
    set modules [list \
      [find module number 0.2-0.3]
    ]


    fetch modules $modules
    config set init {
      source [file join modules number-0.2.5.tm]
      number
    }
  }
  ::tcl::tm::path add [file normalize $FixturesDir]
  set config [::tarcel::Config new]
  lassign [compiler::compile [$config parse $dotTarcel]] \
          startScript \
          tarball
  set tempFilename [
    TestHelpers::writeTarcelToTempFile $startScript $tarball
  ]
  set int [interp create]
} -body {
  $int eval source $tempFilename
} -cleanup {
  interp delete $int
  ::tcl::tm::path remove [file normalize $FixturesDir]
} -result {I'm number 0.2.5}


test parse-get-packageLoadCommands-1 {Ensure that the latest version is used if no requirements given} -setup {
  set dotTarcel {
    set loadCommands [get packageLoadCommands number]
    set latestLoadCommand [lsort -decreasing -index 0 $loadCommands]
    lassign $latestLoadCommand loadCommand version

    set sourceFilename [regsub {^(.*source -encoding [^ ]+ )([^ ]+.*?)$} $loadCommand {\2}]
    fetch modules $sourceFilename

    config set init {
      source [file join modules number-0.4.tm]
      number
    }
  }
  ::tcl::tm::path add [file normalize $FixturesDir]
  set config [::tarcel::Config new]
  lassign [compiler::compile [$config parse $dotTarcel]] \
          startScript \
          tarball
  set tempFilename [
    TestHelpers::writeTarcelToTempFile $startScript $tarball
  ]
  set int [interp create]
} -body {
  $int eval source $tempFilename
} -cleanup {
  interp delete $int
  ::tcl::tm::path remove [file normalize $FixturesDir]
} -result {I'm number 0.4}


test parse-get-packageLoadCommands-2 {Ensure that requirements can be used to find package} -setup {
  set dotTarcel {
    set loadCommands [get packageLoadCommands number 0.2-0.3]
    lassign $loadCommands loadCommand version
    set sourceFilename [regsub {^(.*source -encoding [^ ]+ )([^ ]+.*?)$} $loadCommand {\2}]
    fetch modules $sourceFilename

    config set init {
      source [file join modules number-0.2.5.tm]
      number
    }
  }
  ::tcl::tm::path add [file normalize $FixturesDir]
  set config [::tarcel::Config new]
  lassign [compiler::compile [$config parse $dotTarcel]] \
          startScript \
          tarball
  set tempFilename [
    TestHelpers::writeTarcelToTempFile $startScript $tarball
  ]
  set int [interp create]
} -body {
  $int eval source $tempFilename
} -cleanup {
  interp delete $int
  ::tcl::tm::path remove [file normalize $FixturesDir]
} -result {I'm number 0.2.5}


test parse-config-set-1 {Ensure that can set valid varNames} -setup {
  set dotTarcel {
    config set homepage "http://example.com"
    config set version 0.1
    config set outputFilename "myApp.tcl"
    config set init {puts "hello"}
    config set hashbang {/usr/bin/env tclsh}
  }
  set config [::tarcel::Config new]
} -body {
  set configSettings [$config parse $dotTarcel]
  dict create homepage [dict get $configSettings homepage] \
              version [dict get $configSettings version] \
              init [dict get $configSettings init] \
              outputFilename [dict get $configSettings outputFilename] \
              hashbang [dict get $configSettings hashbang]
} -result [dict create homepage "http://example.com" \
                       version 0.1 \
                       init {puts "hello"} \
                       outputFilename "myApp.tcl" \
                       hashbang {/usr/bin/env tclsh}]


test parse-config-set-2 {Ensure that will raise an error if invalid varName used} -setup {
  set dotTarcel {
    config set bob "hello my name is Bob"
    config set version 0.1
    config set init {puts "hello"}
  }
  set config [::tarcel::Config new]
} -body {
  $config parse $dotTarcel
} -returnCodes {error} -result "invalid variable for config set: bob"


cleanupTests
