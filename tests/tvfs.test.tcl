package require Tcl 8.6
package require tcltest
namespace import tcltest::*

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]


source [file join $LibDir "tarcellauncher.tcl"]
source [file join $ThisScriptDir "test_helpers.tcl"]


proc ::tarcel::loadSources {} {
  ::tarcel::eval {
    set ThisScriptDir [file dirname [info script]]
    set LibDir [file join $ThisScriptDir .. lib]
    source [file join $LibDir "embeddedchan.tcl"]
    source [file join $LibDir "tararchive.tcl"]
    source [file join $LibDir "tvfs.tcl"]
  }
}


test mount-1 {Ensure that you can mount multiple archives at same mount point} -setup {
  ::tarcel::init
  ::tarcel::loadSources
  ::tarcel::eval {
    set textA {This is some text in textA}
    set textB {This is some text in textA}
    set archiveA [TarArchive new]
    set archiveB [TarArchive new]
    $archiveA importContents $textA [file join text texta.txt]
    $archiveB importContents $textB [file join text textb.txt]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archiveA .
    tvfs::mount $archiveB .
  }
  ::tarcel::createAliases
} -body {
  list [file exists [file join text texta.txt]] \
       [file exists [file join text textb.txt]]
} -cleanup {
  ::tarcel::finish
} -result {1 1}


test source-1 {Ensure that info script returns correct location when an encoded file sourced, including before and after a source} -setup {
  ::tarcel::init
  ::tarcel::loadSources
  ::tarcel::eval {
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

    set archive [TarArchive new]
    $archive importContents $infoScriptAScript \
                            [file join lib app info_script_a.tcl]
    $archive importContents $infoScriptBScript \
                            [file join lib app lib info_script_b.tcl]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::createAliases
} -body {
  namespace eval aTester {
    source [file join lib app info_script_a.tcl]
  }
} -cleanup {
  ::tarcel::finish
  namespace delete aTester
} -result [list [file join lib app info_script_a.tcl] \
                [file join lib app info_script_a.tcl] \
                [file join lib app lib info_script_b.tcl]]


test source-2 {Ensure that package require for a module outside of the tarcel works in the correct namespace} -setup {
  ::tarcel::init
  ::tarcel::loadSources
  ::tarcel::eval {
    set mainScript {
      package require greeterExternal
      namespace import greeterExternal::*
      hello fred
    }
    set archive [TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::createAliases
} -body {
  ::tcl::tm::path add $FixturesDir
  source [file join lib app main.tcl]
} -cleanup {
  ::tcl::tm::path remove $FixturesDir
  ::tarcel::finish
  namespace delete ::greeterExternal
} -result {hello fred (from external greeter)}


test source-3 {Ensure that package require for a module inside the tarcel works} -setup {
  ::tarcel::init
  ::tarcel::loadSources
  ::tarcel::eval {
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

    set archive [TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::createAliases
} -body {
  ::tcl::tm::path add [file join lib modules]
  source [file join lib app main.tcl]
} -cleanup {
  ::tcl::tm::path remove [file join lib modules]
  ::tarcel::finish
  namespace delete ::greeterInternal
} -result {hello fred (from internal greeter)}


test open-1 {Ensure that read works correctly for files when no count given} -setup {
  ::tarcel::init
  ::tarcel::loadSources
  ::tarcel::eval {
    set niceDayText {
      This is a very nice day
      oh yes it is
    }
    set archive [TarArchive new]
    $archive importContents $niceDayText [file join text nice_day.txt]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::createAliases
} -body {
  set fd [open [file join text nice_day.txt] r]
  set result [read $fd]
  close $fd
  set result
} -cleanup {
  ::tarcel::finish
} -result {
      This is a very nice day
      oh yes it is
    }


test open-2 {Ensure that read works correct for files when count given} -setup {
  ::tarcel::init
  ::tarcel::loadSources
  ::tarcel::eval {
    set niceDayText {This is a very nice day}
    set archive [TarArchive new]
    $archive importContents $niceDayText [file join text nice_day.txt]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::createAliases
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
  ::tarcel::finish
} -result {{This is} { a ver} {y nice day} {}}


test open-3 {Ensure that gets works correctly for files} -setup {
  ::tarcel::init
  ::tarcel::loadSources
  ::tarcel::eval {
    set niceDayText {This is a very nice day
      and so is this}
    set archive [TarArchive new]
    $archive importContents $niceDayText [file join text nice_day.txt]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::createAliases
  set result [list]
} -body {
  set fd [open [file join text nice_day.txt] r]
  lappend result [gets $fd]
  lappend result [gets $fd]
  lappend result [gets $fd]
  close $fd
  set result
} -cleanup {
  ::tarcel::finish
} -result {{This is a very nice day} {      and so is this} {}}


test file-exists-1 {Ensure that 'file exists' finds directories within directory paths} -setup {
  ::tarcel::init
  ::tarcel::loadSources
  ::tarcel::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::createAliases
} -body {
  file exists [file join lib modules]
} -cleanup {
  ::tarcel::finish
} -result {1}


test file-exists-2 {Ensure that 'file exists' returns when files aren't found} -setup {
  ::tarcel::init
  ::tarcel::loadSources
  ::tarcel::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::createAliases
} -body {
  file exists [file join lib modules bob]
} -cleanup {
  ::tarcel::finish
} -result {0}


test glob-1 {Ensure that glob -directory works on encoded files} -setup {
  ::tarcel::init
  ::tarcel::loadSources
  ::tarcel::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::createAliases
} -body {
  glob -directory [file join lib modules] *.tm
} -cleanup {
  ::tarcel::finish
} -result [list [file join lib modules greeterInternal-0.1.tm]]


test glob-2 {Ensure that glob -directory works with -nocomplain} -setup {
  ::tarcel::init
  ::tarcel::loadSources
  ::tarcel::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::createAliases
} -body {
  file exists [file join lib modules bob]
} -cleanup {
  ::tarcel::finish
} -result {0}



test glob-3 {Ensure that glob -directory complains if nothing found and -nocomplain not passed} -setup {
  ::tarcel::init
  ::tarcel::loadSources
  ::tarcel::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::createAliases
} -body {
  glob -directory [file join lib modules] *.fred
} -cleanup {
  ::tarcel::finish
} -result {no files matched glob pattern "*.fred"} -returnCodes {error}


cleanupTests
