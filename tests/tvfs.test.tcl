package require Tcl 8.6
package require tcltest
namespace import tcltest::*

set ThisScriptDir [file normalize [file dirname [info script]]]
set FixturesDir [file join $ThisScriptDir fixtures]

source [file join $ThisScriptDir "test_helpers.tcl"]


test mount-1 {Ensure that you can mount multiple archives at same mount point} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
    set textA {This is some text in textA}
    set textB {This is some text in textA}
    set archiveA [::tarcel::TarArchive new]
    set archiveB [::tarcel::TarArchive new]
    $archiveA importContents $textA [file join text texta.txt]
    $archiveB importContents $textB [file join text textb.txt]
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archiveA .
    ::tarcel::tvfs::mount $archiveB .
  }
} -body {
  $int eval {
    list [file exists [file join text texta.txt]] \
         [file exists [file join text textb.txt]]
  }
} -cleanup {
  interp delete $int
} -result {1 1}


test source-1 {Ensure that info script returns correct location when an encoded file sourced, including before and after a source} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    source [file join lib app info_script_a.tcl]
  }
} -cleanup {
  interp delete $int
} -result [list [file join lib app info_script_a.tcl] \
                [file join lib app info_script_a.tcl] \
                [file join lib app lib info_script_b.tcl]]

test source-2 {Ensure that package require for a module outside of the tarcel works in the correct namespace} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
    set mainScript {
      package require greeterExternal
      namespace import greeterExternal::*
      hello fred
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
    ::tcl::tm::path add $FixturesDir
  }
} -body {
  $int eval {
    source [file join lib app main.tcl]
  }
} -cleanup {
  interp delete $int
} -result {hello fred (from external greeter)}


test source-3 {Ensure that package require for a module inside the tarcel works} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
    ::tcl::tm::path add [file join lib modules]
  }
} -body {
  $int eval {
    source [file join lib app main.tcl]
  }
} -cleanup {
  interp delete $int
} -result {hello fred (from internal greeter)}


test source-4 {Ensure that package require for a module inside the tarcel works with a fully normalized tm path} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
    ::tcl::tm::path add [file normalize [file join lib modules]]
  }
} -body {
  $int eval {
    source [file normalize [file join lib app main.tcl]]
  }
} -cleanup {
  interp delete $int
} -result {hello fred (from internal greeter)}


test source-5 {Ensure that source works properly when called within a proc} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
    set mainScript {
      proc main {} {
        set ThisDir [file dirname [info script]]
        source [file join $ThisDir setaScript.tcl]
        return "a: $a"
      }
      main
    }
    set setaScript {
      set a 5
    }

    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript \
                            [file join lib app main.tcl]
    $archive importContents $setaScript \
                            [file join lib app setaScript.tcl]
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    source [file join lib app main.tcl]
  }
} -cleanup {
  interp delete $int
} -result "a: 5"


test source-6 {Ensure that source can return an error correctly from original source} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
    ::tarcel::tvfs::init
  }
} -body {
  $int eval [string map [list @FixturesDir $FixturesDir] {
    source [file join @FixturesDir nothere.tcl]
  }]
} -cleanup {
  interp delete $int
} -returnCodes {error} -result "couldn't read file \"[file join $FixturesDir nothere.tcl]\": no such file or directory"


test open-1 {Ensure that read works correctly for files when no count given} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
    set niceDayText {
      This is a very nice day
      oh yes it is
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $niceDayText [file join text nice_day.txt]
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    set fd [open [file join text nice_day.txt] r]
    set result [read $fd]
    close $fd
    set result
  }
} -cleanup {
  interp delete $int
} -result {
      This is a very nice day
      oh yes it is
    }


test open-2 {Ensure that read works correct for files when count given} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
    set niceDayText {This is a very nice day}
    set archive [::tarcel::TarArchive new]
    $archive importContents $niceDayText [file join text nice_day.txt]
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
    set result [list]
  }
} -body {
  $int eval {
    set fd [open [file join text nice_day.txt] r]
    lappend result [read $fd 7]
    lappend result [read $fd 6]
    lappend result [read $fd 20]
    lappend result [read $fd 20]
    close $fd
    set result
  }
} -cleanup {
  interp delete $int
} -result {{This is} { a ver} {y nice day} {}}


test open-3 {Ensure that gets works correctly for files} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
    set niceDayText {This is a very nice day
      and so is this}
    set archive [::tarcel::TarArchive new]
    $archive importContents $niceDayText [file join text nice_day.txt]
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
    set result [list]
  }
} -body {
  $int eval {
    set fd [open [file join text nice_day.txt] r]
    lappend result [gets $fd]
    lappend result [gets $fd]
    lappend result [gets $fd]
    close $fd
    set result
  }
} -cleanup {
  interp delete $int
} -result {{This is a very nice day} {      and so is this} {}}


test file-exists-1 {Ensure that 'file exists' finds directories within directory paths} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    file exists [file join lib modules]
  }
} -cleanup {
  interp delete $int
} -result {1}


test file-exists-2 {Ensure that 'file exists' returns when files aren't found} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    file exists [file join lib modules bob]
  }
} -cleanup {
  interp delete $int
} -result {0}


test file-exists-3 {Ensure that 'file exists' handles file normalization} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    file exists [file join lib .. lib modules greeterInternal-0.1.tm]
  }
} -cleanup {
  interp delete $int
} -result {1}


test file-exists-4 {Ensure that 'file exists' can look for a fully normalized filename} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    file exists [file normalize [file join lib modules greeterInternal-0.1.tm]]
  }
} -cleanup {
  interp delete $int
} -result {1}


test file-exists-5 {Ensure that 'file exists' handles files relative to mount point} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
    set ThisScriptDir [file normalize [file dirname [info script]]]
    set RootDir [file join $ThisScriptDir ..]
    set startDir [pwd]
    cd $RootDir
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
    cd $FixturesDir
  }
} -body {
  $int eval {
    file exists [
      file normalize [file join .. .. lib modules greeterInternal-0.1.tm]
    ]
  }
} -cleanup {
  $int eval {
    cd $startDir
  }
  interp delete $int
} -result {1}


test file-isfile-1 {Ensure that 'file isfile' returns if a location is a file} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    file isfile [file join lib modules greeterInternal-0.1.tm]
  }
} -cleanup {
  interp delete $int
} -result {1}


test file-isfile-2 {Ensure that 'file isfile' returns 0 if a location is a directory} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    file isfile [file join lib modules]
  }
} -cleanup {
  interp delete $int
} -result {0}


test file-isfile-3 {Ensure that 'file isfile' returns 0 if location doesn't exist} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
    set mainScript {
      hello
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join lib app main.tcl]
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    file isfile bob
  }
} -cleanup {
  interp delete $int
} -result {0}


test file-isfile-4 {Ensure that 'file isfile' handles file normalization} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    file isfile [file join lib .. lib modules greeterInternal-0.1.tm]
  }
} -cleanup {
  interp delete $int
} -result {1}


test file-isdirectory-1 {Ensure that 'file isdirectory' returns 1 if a location is a directory} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    file isdirectory [file join lib modules]
  }
} -cleanup {
  interp delete $int
} -result {1}


test file-isdirectory-2 {Ensure that 'file isdirectory' returns 0 if a location is a file} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    file isdirectory [file join lib modules greeterInternal-0.1.tm]
  }
} -cleanup {
  interp delete $int
} -result {0}


test glob-1 {Ensure that glob -directory works on encoded files} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    glob -directory [file join lib modules] *.tm
  }
} -cleanup {
  interp delete $int
} -result [list [file join lib modules greeterInternal-0.1.tm]]


test glob-2 {Ensure that glob -directory works with -nocomplain} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    glob -nocomplain -directory [file join lib modules] bob
  }
} -cleanup {
  interp delete $int
} -result {}



test glob-3 {Ensure that glob -directory complains if nothing found and -nocomplain not passed} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    glob -directory [file join lib modules] *.fred
  }
} -cleanup {
  interp delete $int
} -result {no files matched glob pattern "*.fred"} -returnCodes {error}


test glob-4 {Ensure that glob -directory compares the directory properly, so that it doesn't match part of the directory and then use the filename tail for the pattern match} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    expr {"./greeterInternal-0.1.tm" ni [glob -directory . *]}
  }
} -cleanup {
  interp delete $int
} -result {1}


test glob-5 {Ensure that glob -directory returns directory names} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    glob -directory [file join lib app] *
  }
} -cleanup {
  interp delete $int
} -result [list [file join lib app main]]


test glob-6 {Ensure that glob -directory returns a directory name only once} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
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
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    glob -directory [file join lib app] *
  }
} -cleanup {
  interp delete $int
} -result [list [file join lib app main]]


test glob-7 {Ensure that glob -directory doesn't repeat entries found in real fs and virtual fs} -setup {
  set startDir [pwd]
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
    set mainScript {
      hello
    }
    set archive [::tarcel::TarArchive new]
    $archive importContents $mainScript [file join tests app main main.tcl]
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
  cd [file join $ThisScriptDir ..]
} -body {
  $int eval {
    llength [lsearch -all [glob -directory . *] ./tests]
  }
} -cleanup {
  interp delete $int
  cd $startDir
} -result 1


test glob-8 {Ensure that glob will allow -type switch for real fs} -setup {
  set startDir [pwd]
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
    set archive [::tarcel::TarArchive new]
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
  cd [file join $ThisScriptDir ..]
} -body {
  $int eval {
    glob -tails -directory $ThisScriptDir -type d -nocomplain -- * .*
  }
} -cleanup {
  interp delete $int
  cd $startDir
} -result {. .. fixtures}


if {![TestHelpers::makeLibWelcome]} {
  puts stderr "Skipping test load-1 as couldn't build libwelcome"
  skip load-1
}

test load-1 {Ensure can load a library from within tarcel in correct namespace} -setup {
  set int [interp create]
  TestHelpers::loadSourcesInInterp $int
  $int eval {
    set thisDir [file dirname [info script]]
    set files [list [file join $thisDir fixtures libwelcome libwelcome.so]]
    set archive [::tarcel::TarArchive new]
    $archive fetchFiles $files lib
    ::tarcel::tvfs::init
    ::tarcel::tvfs::mount $archive .
  }
} -body {
  $int eval {
    load lib/libwelcome.so
    ::welcome::welcome fred
  }
} -cleanup {
  interp delete $int
} -result {Welcome fred}


cleanupTests
