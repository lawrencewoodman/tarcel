package require Tcl 8.6
package require tcltest
namespace import tcltest::*

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]


source [file join $LibDir "launcher.tcl"]
source [file join $ThisScriptDir "test_helpers.tcl"]


proc ::tarcel::launcher::loadSources {} {
  ::tarcel::launcher::eval {
    set ThisScriptDir [file dirname [info script]]
    set LibDir [file join $ThisScriptDir .. lib]
    source [file join $LibDir "parameters.tcl"]
    source [file join $LibDir "xplatform.tcl"]
    source [file join $LibDir "embeddedchan.tcl"]
    source [file join $LibDir "tar.tcl"]
    source [file join $LibDir "tararchive.tcl"]
    source [file join $LibDir "tvfs.tcl"]
  }
}


test mount-1 {Ensure that you can mount multiple archives at same mount point} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set textA {This is some text in textA}
    set textB {This is some text in textA}
    set archiveA [::tarcel::TarArchive new]
    set archiveB [::tarcel::TarArchive new]
    $archiveA importContents $textA [file join text texta.txt]
    $archiveB importContents $textB [file join text textb.txt]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archiveA .
    tvfs::mount $archiveB .
  }
  ::tarcel::launcher::createAliases
} -body {
  list [file exists [file join text texta.txt]] \
       [file exists [file join text textb.txt]]
} -cleanup {
  ::tarcel::launcher::finish
} -result {1 1}


test source-1 {Ensure that info script returns correct location when an encoded file sourced, including before and after a source} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
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

    set archive [::tarcel::TarArchive new]
    $archive importContents $infoScriptAScript \
                            [file join lib app info_script_a.tcl]
    $archive importContents $infoScriptBScript \
                            [file join lib app lib info_script_b.tcl]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  namespace eval aTester {
    source [file join lib app info_script_a.tcl]
  }
} -cleanup {
  ::tarcel::launcher::finish
  namespace delete aTester
} -result [list [file join lib app info_script_a.tcl] \
                [file join lib app info_script_a.tcl] \
                [file join lib app lib info_script_b.tcl]]


test source-2 {Ensure that package require for a module outside of the tarcel works in the correct namespace} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      package require greeterExternal
      namespace import greeterExternal::*
      hello fred
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  ::tcl::tm::path add $FixturesDir
  source [file join lib app main.tcl]
} -cleanup {
  ::tcl::tm::path remove $FixturesDir
  ::tarcel::launcher::finish
  namespace delete ::greeterExternal
} -result {hello fred (from external greeter)}


test source-3 {Ensure that package require for a module inside the tarcel works} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
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

    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  ::tcl::tm::path add [file join lib modules]
  source [file join lib app main.tcl]
} -cleanup {
  ::tcl::tm::path remove [file join lib modules]
  ::tarcel::launcher::finish
  namespace delete ::greeterInternal
} -result {hello fred (from internal greeter)}


test source-4 {Ensure that package require for a module inside the tarcel works with a fully normalized tm path} -setup {
  TestHelpers::allowPackageRerequire greeterInternal
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
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

    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  ::tcl::tm::path add [file normalize [file join lib modules]]
  source [file normalize [file join lib app main.tcl]]
} -cleanup {
  ::tcl::tm::path remove [file join lib modules]
  ::tarcel::launcher::finish
  namespace delete ::greeterInternal
  TestHelpers::resetPackageRerequire
} -result {hello fred (from internal greeter)}


test open-1 {Ensure that read works correctly for files when no count given} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set niceDayText {
      This is a very nice day
      oh yes it is
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $niceDayText [file join text nice_day.txt]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  set fd [open [file join text nice_day.txt] r]
  set result [read $fd]
  close $fd
  set result
} -cleanup {
  ::tarcel::launcher::finish
} -result {
      This is a very nice day
      oh yes it is
    }


test open-2 {Ensure that read works correct for files when count given} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set niceDayText {This is a very nice day}
    set archive [::tarcel::TarArchive new]
    $archive importContents $niceDayText [file join text nice_day.txt]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
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
  ::tarcel::launcher::finish
} -result {{This is} { a ver} {y nice day} {}}


test open-3 {Ensure that gets works correctly for files} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set niceDayText {This is a very nice day
      and so is this}
    set archive [::tarcel::TarArchive new]
    $archive importContents $niceDayText [file join text nice_day.txt]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
  set result [list]
} -body {
  set fd [open [file join text nice_day.txt] r]
  lappend result [gets $fd]
  lappend result [gets $fd]
  lappend result [gets $fd]
  close $fd
  set result
} -cleanup {
  ::tarcel::launcher::finish
} -result {{This is a very nice day} {      and so is this} {}}


test file-exists-1 {Ensure that 'file exists' finds directories within directory paths} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  file exists [file join lib modules]
} -cleanup {
  ::tarcel::launcher::finish
} -result {1}


test file-exists-2 {Ensure that 'file exists' returns when files aren't found} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  file exists [file join lib modules bob]
} -cleanup {
  ::tarcel::launcher::finish
} -result {0}


test file-exists-3 {Ensure that 'file exists' handles file normalization} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  file exists [file join lib .. lib modules greeterInternal-0.1.tm]
} -cleanup {
  ::tarcel::launcher::finish
} -result {1}


test file-exists-4 {Ensure that 'file exists' can look for a fully normalized filename} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  file exists [file normalize [file join lib modules greeterInternal-0.1.tm]]
} -cleanup {
  ::tarcel::launcher::finish
} -result {1}


test file-exists-5 {Ensure that 'file exists' handles files relative to mount point} -setup {
  set startDir [pwd]
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
  cd $FixturesDir
} -body {
  file exists [file normalize [file join .. .. lib modules greeterInternal-0.1.tm]]
} -cleanup {
  ::tarcel::launcher::finish
  cd $startDir
} -result {1}


test file-isfile-1 {Ensure that 'file isfile' returns if a location is a file} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  file isfile [file join lib modules greeterInternal-0.1.tm]
} -cleanup {
  ::tarcel::launcher::finish
} -result {1}


test file-isfile-2 {Ensure that 'file isfile' returns 0 if a location is a directory} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  file isfile [file join lib modules]
} -cleanup {
  ::tarcel::launcher::finish
} -result {0}


test file-isfile-3 {Ensure that 'file isfile' returns 0 if location doesn't exist} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      hello
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  file isfile bob
} -cleanup {
  ::tarcel::launcher::finish
} -result {0}


test file-isfile-4 {Ensure that 'file isfile' handles file normalization} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  file isfile [file join lib .. lib modules greeterInternal-0.1.tm]
} -cleanup {
  ::tarcel::launcher::finish
} -result {1}


test glob-1 {Ensure that glob -directory works on encoded files} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  glob -directory [file join lib modules] *.tm
} -cleanup {
  ::tarcel::launcher::finish
} -result [list [file join lib modules greeterInternal-0.1.tm]]


test glob-2 {Ensure that glob -directory works with -nocomplain} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  glob -nocomplain -directory [file join lib modules] bob
} -cleanup {
  ::tarcel::launcher::finish
} -result {}



test glob-3 {Ensure that glob -directory complains if nothing found and -nocomplain not passed} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  glob -directory [file join lib modules] *.fred
} -cleanup {
  ::tarcel::launcher::finish
} -result {no files matched glob pattern "*.fred"} -returnCodes {error}


test glob-4 {Ensure that glob -directory compares the directory properly, so that it doesn't match part of the directory and then use the filename tail for the pattern match} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  expr {"./greeterInternal-0.1.tm" ni [glob -directory . *]}
} -cleanup {
  ::tarcel::launcher::finish
} -result {1}


test glob-5 {Ensure that glob -directory returns directory names} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main main.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  glob -directory [file join lib app] *
} -cleanup {
  ::tarcel::launcher::finish
} -result [list [file join lib app main]]


test glob-6 {Ensure that glob -directory returns a directory name only once} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      hello
    }
    set hello2Script {
      hello
      hello
    }
    set greeterInternalScript {
      proc hello {} {
        return "hello"
      }
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main main.tcl]
    $archive importContents $hello2Script [file join lib app main hello2.tcl]
    $archive importContents $greeterInternalScript \
                            [file join lib modules greeterInternal-0.1.tm]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  glob -directory [file join lib app] *
} -cleanup {
  ::tarcel::launcher::finish
} -result [list [file join lib app main]]


test glob-7 {Ensure that glob -directory doesn't repeat entries found in real fs and virtual fs} -setup {
  set startDir [pwd]
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set mainScript {
      hello
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join tests app main main.tcl]
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
  cd [file join $ThisScriptDir ..]
} -body {
  llength [lsearch -all [glob -directory . *] ./tests]
} -cleanup {
  ::tarcel::launcher::finish
  cd $startDir
} -result 1


if {![TestHelpers::makeLibWelcome]} {
  puts stderr "Skipping test load-1 as couldn't build libwelcome"
  skip load-1
}

test load-1 {Ensure can load a library from within tarcel} -setup {
  ::tarcel::launcher::init
  ::tarcel::launcher::loadSources
  ::tarcel::launcher::eval {
    set thisDir [file dirname [info script]]
    set files [list [file join tests fixtures libwelcome libwelcome.so]]
    set archive [::tarcel::TarArchive new]
    $archive fetchFiles $files lib
    tvfs::init ::tarcel::evalInMaster \
               ::tarcel::invokeHiddenInMaster \
               ::tarcel::transferChanToMaster
    tvfs::mount $archive .
  }
  ::tarcel::launcher::createAliases
} -body {
  namespace eval aTester {
    load lib/libwelcome.so
    welcome fred
  }
} -cleanup {
  ::tarcel::launcher::finish
  namespace delete aTester
} -result {Welcome fred}


cleanupTests
