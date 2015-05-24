package require Tcl 8.6
package require tcltest
namespace import tcltest::*

# Add module dir to tm paths
set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]


source [file join $LibDir "parcellauncher.tcl"]

proc ::parcel::loadSources {} {
  ::parcel::eval {
    set ThisScriptDir [file dirname [info script]]
    set LibDir [file join $ThisScriptDir .. lib]
    source [file join $LibDir "embeddedchan.tcl"]
    source [file join $LibDir "binarchive.tcl"]
    source [file join $LibDir "pvfs.tcl"]
    source [file join $LibDir "launcher.tcl"]
  }
}

test source-1 {Ensure that info script returns correct location when an encoded file sourced, including before and after a source} -setup {
  ::parcel::init
  ::parcel::loadSources
  ::parcel::eval {
    set infoScriptAScript {
      set ThisDir [file dirname [info script]]
      set a1InfoScript [info script]
      set bInfoScript [source [file join $ThisDir lib info_script_b.tcl]]
      set a2InfoScript [info script]
      list $a1InfoScript $a2InfoScript  $bInfoScript
    }
    set infoScriptBScript {
      info script
    }

    set archive [BinArchive new]
    $archive importContents $infoScriptAScript \
                            [file join lib app info_script_a.tcl]
    $archive importContents $infoScriptBScript \
                            [file join lib app lib info_script_b.tcl]
    pvfs::mount $archive .
    launcher::init ::parcel::evalInMaster \
                   ::parcel::invokeHiddenInMaster \
                   ::parcel::transferChanToMaster
  }
  ::parcel::createAliases
} -body {
  namespace eval aTester {
    source [file join lib app info_script_a.tcl]
  }
} -cleanup {
  ::parcel::finish
  namespace delete aTester
} -result [list [file join lib app info_script_a.tcl] \
                [file join lib app info_script_a.tcl] \
                [file join lib app lib info_script_b.tcl]]


test source-2 {Ensure that package require for a module outside of the parcel works in the correct namespace} -setup {
  ::parcel::init
  ::parcel::loadSources
  ::parcel::eval {
    set mainScript {
      package require greeterExternal
      namespace import greeterExternal::*
      hello fred
    }
    set archive [BinArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    pvfs::mount $archive .
    launcher::init ::parcel::evalInMaster \
                   ::parcel::invokeHiddenInMaster \
                   ::parcel::transferChanToMaster
  }
  ::parcel::createAliases
} -body {
  ::tcl::tm::path add $FixturesDir
  source [file join lib app main.tcl]
} -cleanup {
  ::tcl::tm::path remove $FixturesDir
  ::parcel::finish
  namespace delete ::greeterExternal
} -result {hello fred (from external greeter)}


test source-3 {Ensure that package require for a module inside the parcel works} -setup {
  ::parcel::init
  ::parcel::loadSources
  ::parcel::eval {
    set mainScript {
      package require greeterInternal
      namespace import greeterInternal::*
      hello fred
    }

    set greeterInternalScript {
      namespace eval greeterInternal {
        namespace export {[a-z]*}
      }


      proc greeterInternal::hello {who} {
        return "hello $who (from internal greeter)"
      }
    }

    set archive [BinArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    pvfs::mount $archive .
    launcher::init ::parcel::evalInMaster \
                   ::parcel::invokeHiddenInMaster \
                   ::parcel::transferChanToMaster
  }
  ::parcel::createAliases
} -body {
  ::tcl::tm::path add [file join lib modules]
  source [file join lib app main.tcl]
} -cleanup {
  ::tcl::tm::path remove [file join lib modules]
  ::parcel::finish
  namespace delete ::greeterInternal
} -result {hello fred (from internal greeter)}


test open-1 {Ensure that read works correctly for files when no count given} -setup {
  ::parcel::init
  ::parcel::loadSources
  ::parcel::eval {
    set niceDayText {
      This is a very nice day
      oh yes it is
    }
    set archive [BinArchive new]
    $archive importContents $niceDayText [file join text nice_day.txt]
    pvfs::mount $archive .
    launcher::init ::parcel::evalInMaster \
                   ::parcel::invokeHiddenInMaster \
                   ::parcel::transferChanToMaster
  }
  ::parcel::createAliases
} -body {
  set fd [open [file join text nice_day.txt] r]
  set result [read $fd]
  close $fd
  set result
} -cleanup {
  ::parcel::finish
} -result {
      This is a very nice day
      oh yes it is
    }


test open-2 {Ensure that read works correct for files when count given} -setup {
  ::parcel::init
  ::parcel::loadSources
  ::parcel::eval {
    set niceDayText {This is a very nice day}
    set archive [BinArchive new]
    $archive importContents $niceDayText [file join text nice_day.txt]
    pvfs::mount $archive .
    launcher::init ::parcel::evalInMaster \
                   ::parcel::invokeHiddenInMaster \
                   ::parcel::transferChanToMaster
  }
  ::parcel::createAliases
  set result [list]
} -body {
  set fd [open [file join text nice_day.txt] r]
  lappend result [read $fd 7]
  lappend result [read $fd 6]
  lappend result [read $fd 20]
  lappend result [read $fd 20]
  close $fd
  set result
} -cleanup {
  ::parcel::finish
} -result {{This is} { a ver} {y nice day} {}}


test open-3 {Ensure that gets works correctly for files} -setup {
  ::parcel::init
  ::parcel::loadSources
  ::parcel::eval {
    set niceDayText {This is a very nice day
      and so is this}
    set archive [BinArchive new]
    $archive importContents $niceDayText [file join text nice_day.txt]
    pvfs::mount $archive .
    launcher::init ::parcel::evalInMaster \
                   ::parcel::invokeHiddenInMaster \
                   ::parcel::transferChanToMaster
  }
  ::parcel::createAliases
  set result [list]
} -body {
  set fd [open [file join text nice_day.txt] r]
  lappend result [gets $fd]
  lappend result [gets $fd]
  lappend result [gets $fd]
  close $fd
  set result
} -cleanup {
  ::parcel::finish
} -result {{This is a very nice day} {      and so is this} {}}


test file-exists-1 {Ensure that 'file exists' finds directories within directory paths} -setup {
  ::parcel::init
  ::parcel::loadSources
  ::parcel::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [BinArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    pvfs::mount $archive .
    launcher::init ::parcel::evalInMaster \
                   ::parcel::invokeHiddenInMaster \
                   ::parcel::transferChanToMaster
  }
  ::parcel::createAliases
} -body {
  file exists [file join lib modules]
} -cleanup {
  ::parcel::finish
} -result {1}


test file-exists-2 {Ensure that 'file exists' returns when files aren't found} -setup {
  ::parcel::init
  ::parcel::loadSources
  ::parcel::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [BinArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    pvfs::mount $archive .
    launcher::init ::parcel::evalInMaster \
                   ::parcel::invokeHiddenInMaster \
                   ::parcel::transferChanToMaster
  }
  ::parcel::createAliases
} -body {
  file exists [file join lib modules bob]
} -cleanup {
  ::parcel::finish
} -result {0}


test glob-1 {Ensure that glob -directory works on encoded files} -setup {
  ::parcel::init
  ::parcel::loadSources
  ::parcel::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [BinArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    pvfs::mount $archive .
    launcher::init ::parcel::evalInMaster \
                   ::parcel::invokeHiddenInMaster \
                   ::parcel::transferChanToMaster
  }
  ::parcel::createAliases
} -body {
  glob -directory [file join lib modules] *.tm
} -cleanup {
  ::parcel::finish
} -result [list [file join lib modules greeterInternal-0.1.tm]]


test glob-2 {Ensure that glob -directory works with -nocomplain} -setup {
  ::parcel::init
  ::parcel::loadSources
  ::parcel::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [BinArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    pvfs::mount $archive .
    launcher::init ::parcel::evalInMaster \
                   ::parcel::invokeHiddenInMaster \
                   ::parcel::transferChanToMaster
  }
  ::parcel::createAliases
} -body {
  file exists [file join lib modules bob]
} -cleanup {
  ::parcel::finish
} -result {0}



test glob-3 {Ensure that glob -directory complains if nothing found and -nocomplain not passed} -setup {
  ::parcel::init
  ::parcel::loadSources
  ::parcel::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [BinArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    pvfs::mount $archive .
    launcher::init ::parcel::evalInMaster \
                   ::parcel::invokeHiddenInMaster \
                   ::parcel::transferChanToMaster
  }
  ::parcel::createAliases
} -body {
  glob -directory [file join lib modules] *.fred
} -cleanup {
  ::parcel::finish
} -result {no files matched glob pattern "*.fred"} -returnCodes {error}


cleanupTests
