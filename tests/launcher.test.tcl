package require Tcl 8.6
package require tcltest
namespace import tcltest::*

# Add module dir to tm paths
set ThisScriptDir [file dirname [info script]]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]

source [file join $ThisScriptDir .. "embeddedchan.tcl"]
source [file join $ThisScriptDir .. "base64archive.tcl"]
source [file join $ThisScriptDir .. "pvfs.tcl"]
source [file join $ThisScriptDir .. "launcher.tcl"]


test source-1 {Ensure that info script returns correct location when an encoded file sourced} -setup {
  set infoScriptScript {
    info script
  }

  set archive [Base64Archive new]
  $archive importContents $infoScriptScript [file join lib app info_script.tcl]
  pvfs::mount $archive .
  launcher::init
} -body {
  source [file join lib app info_script.tcl]
} -cleanup {
  launcher::finish
} -result [file join lib app info_script.tcl]


test source-2 {Ensure that package require for a module outside of the parcel works in the correct namespace} -setup {
  set mainScript {
    package require greeterExternal
    namespace import greeterExternal::*
    hello fred
  }
  ::tcl::tm::path add $FixturesDir
  set archive [Base64Archive new]
  $archive importContents $mainScript [file join lib app main.tcl]
  pvfs::mount $archive .
  launcher::init
} -body {
  source [file join lib app main.tcl]
} -cleanup {
  launcher::finish
  namespace forget greeterExternal::*
  ::tcl::tm::path remove $FixturesDir
} -result {hello fred (from external greeter)}


test source-3 {Ensure that package require for a module inside the parcel works in the correct namespace} -setup {
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

  ::tcl::tm::path add [file join lib modules]
  set archive [Base64Archive new]
  $archive importContents $mainScript [file join lib app main.tcl]
  $archive importContents $greeterInternalScript \
                          [file join lib modules greeterInternal-0.1.tm]
  pvfs::mount $archive .
  launcher::init
} -body {
  source [file join lib app main.tcl]
} -cleanup {
  launcher::finish
  namespace forget greeterInternal::*
  ::tcl::tm::path remove [file join lib modules]
} -result {hello fred (from internal greeter)}


test open-1 {Ensure that read works correctly for files when no count given} -setup {
  set niceDayText {
    This is a very nice day
    oh yes it is
  }
  set archive [Base64Archive new]
  $archive importContents $niceDayText [file join text nice_day.txt]
  pvfs::mount $archive .
  launcher::init
} -body {
  set fd [open [file join text nice_day.txt] r]
  set result [read $fd]
  close $fd
  set result
} -cleanup {
  launcher::finish
} -result {
    This is a very nice day
    oh yes it is
  }


test open-2 {Ensure that read works correct for files when count given} -setup {
  set niceDayText {This is a very nice day}
  set result [list]
  set archive [Base64Archive new]
  $archive importContents $niceDayText [file join text nice_day.txt]
  pvfs::mount $archive .
  launcher::init
} -body {
  set fd [open [file join text nice_day.txt] r]
  lappend result [read $fd 7]
  lappend result [read $fd 6]
  lappend result [read $fd 20]
  lappend result [read $fd 20]
  close $fd
  set result
} -cleanup {
  launcher::finish
} -result {{This is} { a ver} {y nice day} {}}


test open-3 {Ensure that gets works correctly for files} -setup {
  set niceDayText {This is a very nice day
    and so is this}
  set result [list]
  set archive [Base64Archive new]
  $archive importContents $niceDayText [file join text nice_day.txt]
  pvfs::mount $archive .
  launcher::init
} -body {
  set fd [open [file join text nice_day.txt] r]
  lappend result [gets $fd]
  lappend result [gets $fd]
  lappend result [gets $fd]
  close $fd
  set result
} -cleanup {
  launcher::finish
} -result {{This is a very nice day} {    and so is this} {}}


test file-exists-1 {Ensure that 'file exists' finds directories within directory paths} -setup {
  set mainScript {
    hello
  }
  set greeterInternalScript {
    proc hello {} {
      return "hello"
    }
  }
  set archive [Base64Archive new]
  $archive importContents $mainScript [file join lib app main.tcl]
  $archive importContents $greeterInternalScript \
                          [file join lib modules greeterInternal-0.1.tm]
  pvfs::mount $archive .
  launcher::init
} -body {
  file exists [file join lib modules]
} -cleanup {
  launcher::finish
} -result {1}


test file-exists-2 {Ensure that 'file exists' returns when files aren't found} -setup {
  set mainScript {
    hello
  }
  set greeterInternalScript {
    proc hello {} {
      return "hello"
    }
  }
  set archive [Base64Archive new]
  $archive importContents $mainScript [file join lib app main.tcl]
  $archive importContents $greeterInternalScript \
                          [file join lib modules greeterInternal-0.1.tm]
  pvfs::mount $archive .
  launcher::init
} -body {
  file exists [file join lib modules bob]
} -cleanup {
  launcher::finish
} -result {0}


test glob-1 {Ensure that glob -directory works on encoded files} -setup {
  set mainScript {
    hello
  }
  set greeterInternalScript {
    proc hello {} {
      return "hello"
    }
  }
  set archive [Base64Archive new]
  $archive importContents $mainScript [file join lib app main.tcl]
  $archive importContents $greeterInternalScript \
                          [file join lib modules greeterInternal-0.1.tm]
  pvfs::mount $archive .
  launcher::init
} -body {
  glob -directory [file join lib modules] *.tm
} -cleanup {
  launcher::finish
} -result [list [file join lib modules greeterInternal-0.1.tm]]


test glob-2 {Ensure that glob -directory works with -nocomplain} -setup {
  set mainScript {
    hello
  }
  set greeterInternalScript {
    proc hello {} {
      return "hello"
    }
  }
  set archive [Base64Archive new]
  $archive importContents $mainScript [file join lib app main.tcl]
  $archive importContents $greeterInternalScript \
                          [file join lib modules greeterInternal-0.1.tm]
  pvfs::mount $archive .
  launcher::init
} -body {
  glob -nocomplain -directory [file join lib modules] *.fred
} -cleanup {
  launcher::finish
} -result {}


test glob-3 {Ensure that glob -directory complains if nothing found and -nocomplain not passed} -setup {
  set mainScript {
    hello
  }
  set greeterInternalScript {
    proc hello {} {
      return "hello"
    }
  }
  set archive [Base64Archive new]
  $archive importContents $mainScript [file join lib app main.tcl]
  $archive importContents $greeterInternalScript \
                          [file join lib modules greeterInternal-0.1.tm]
  pvfs::mount $archive .
  launcher::init
} -body {
  glob -directory [file join lib modules] *.fred
} -cleanup {
  launcher::finish
} -result {no files matched glob pattern "*.fred"} -returnCodes {error}


cleanupTests
