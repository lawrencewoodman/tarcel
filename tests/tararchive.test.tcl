package require Tcl 8.6
package require tcltest
namespace import tcltest::*

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file join $ThisScriptDir fixtures]

source [file join $ThisScriptDir "test_helpers.tcl"]
source [file join $LibDir "xplatform.tcl"]
source [file join $LibDir "tvfs.tcl"]
source [file join $LibDir "tar.tcl"]
source [file join $LibDir "tararchive.tcl"]


test importFiles-1 {Ensure that files are put in correct location relative to their current location} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files {
    tararchive.test.tcl
    fixtures/greeterExternal-0.1.tm
  }
  set archive [::tarcel::TarArchive new]
} -body {
  $archive importFiles $files lib
  $archive ls
} -cleanup {
  cd $startDir
} -result {lib/tararchive.test.tcl lib/fixtures/greeterExternal-0.1.tm}


test importFiles-2 {Ensure that any . parts of filename are removed} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files {
    ./tararchive.test.tcl
    ./fixtures/greeterExternal-0.1.tm
  }
  set archive [::tarcel::TarArchive new]
} -body {
  $archive importFiles $files lib
  $archive ls
} -cleanup {
  cd $startDir
} -result {lib/tararchive.test.tcl lib/fixtures/greeterExternal-0.1.tm}


test importFiles-3 {Ensure that .. in filename raises and error} -setup {
  set startDir [pwd]
  cd $FixturesDir
  set files {
    ../tararchive.test.tcl
  }
  set archive [::tarcel::TarArchive new]
} -body {
  $archive importFiles $files lib
  $archive ls
} -cleanup {
  cd $startDir
} -result {can't import file: ../tararchive.test.tcl} \
-returnCodes {error}


test importFiles-4 {Ensure that files are stored as binary files} -setup {
  set startDir [pwd]
  set all256Nums [list]
  for {set i 0} {$i < 256} {incr i} {
    lappend all256Nums $i
  }
  set fd [file tempfile allBinaryFilename]
  fconfigure $fd -translation binary
  puts -nonewline $fd [binary format c* $all256Nums]
  close $fd
  cd [file dirname $allBinaryFilename]
  set files [list [file tail $allBinaryFilename]]
  set archive [::tarcel::TarArchive new]
} -body {
  $archive importFiles $files .
  set readAllBinaryContents [$archive read [file tail $allBinaryFilename]]
  binary scan $readAllBinaryContents c* readNums
  set unsignedReadNums [lmap num $readNums {expr {$num & 0xff}}]
  expr {$unsignedReadNums == $all256Nums}
} -cleanup {
  cd $startDir
} -result 1


test fetchFiles-1 {Ensure that files are put in correct location irrespective of original location} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files {
    fixtures/greeterExternal-0.1.tm
  }
  set archive [::tarcel::TarArchive new]
} -body {
  $archive fetchFiles $files modules
  $archive ls
} -cleanup {
  cd $startDir
} -result {modules/greeterExternal-0.1.tm}


test fetchFiles-2 {Ensure that files are stored as binary files} -setup {
  set startDir [pwd]
  set all256Nums [list]
  for {set i 0} {$i < 256} {incr i} {
    lappend all256Nums $i
  }
  set fd [file tempfile allBinaryFilename]
  fconfigure $fd -translation binary
  puts -nonewline $fd [binary format c* $all256Nums]
  close $fd
  set files [list $allBinaryFilename]
  set archive [::tarcel::TarArchive new]
} -body {
  $archive fetchFiles $files .
  set readAllBinaryContents [$archive read [file tail $allBinaryFilename]]
  binary scan $readAllBinaryContents c* readNums
  set unsignedReadNums [lmap num $readNums {expr {$num & 0xff}}]
  expr {$unsignedReadNums == $all256Nums}
} -cleanup {
  cd $startDir
} -result 1


test export-1 {Ensure that an archive can be exported and loaded again and have the same contents} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files {
    tararchive.test.tcl
    fixtures/greeterExternal-0.1.tm
  }
  set archiveA [::tarcel::TarArchive new]
  set archiveB [::tarcel::TarArchive new]
  $archiveA importFiles $files lib
} -body {
  set tarball [$archiveA export]

  $archiveB load $tarball
  list [TestHelpers::fileCompare tararchive.test.tcl \
           [$archiveB read [file join lib tararchive.test.tcl]]] \
       [TestHelpers::fileCompare [file join fixtures greeterExternal-0.1.tm] \
           [$archiveB read [file join lib fixtures greeterExternal-0.1.tm]]]
} -cleanup {
  cd $startDir
} -result {0 0}


test ls-1 {Ensure that if run under windows that the files are returned with windows' file separators} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files [list \
    tararchive.test.tcl \
    {fixtures/greeterExternal-0.1.tm} \
  ]
  set archive [::tarcel::TarArchive new]
  $archive importFiles $files lib
} -body {
  TestHelpers::changeFileSeparator windows
  $archive ls
} -cleanup {
  TestHelpers::resetFileSeparator
  cd $startDir
} -result [list {lib\tararchive.test.tcl} {lib\fixtures\greeterExternal-0.1.tm}]


test ls-2 {Ensure that if run under unix that the files are returned with unix file separators} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files [list \
    tararchive.test.tcl \
    fixtures/greeterExternal-0.1.tm \
  ]
  set archive [::tarcel::TarArchive new]
  $archive importFiles $files lib
} -body {
  TestHelpers::changeFileSeparator unix
  $archive ls
} -cleanup {
  TestHelpers::resetFileSeparator
  cd $startDir
} -result {lib/tararchive.test.tcl lib/fixtures/greeterExternal-0.1.tm}


test exists-1 {Ensure that if run under windows that the filename uses windows' file separators} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files [list \
    tararchive.test.tcl \
    fixtures/greeterExternal-0.1.tm \
  ]
  set archive [::tarcel::TarArchive new]
  $archive importFiles $files lib
} -body {
  TestHelpers::changeFileSeparator windows
  $archive exists {lib\fixtures\greeterExternal-0.1.tm}
} -cleanup {
  TestHelpers::resetFileSeparator
  cd $startDir
} -result 1


test exists-2 {Ensure that if run under unix that the filename uses unix file separators} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files [list \
    tararchive.test.tcl \
    fixtures/greeterExternal-0.1.tm \
  ]
  set archive [::tarcel::TarArchive new]
  $archive importFiles $files lib
} -body {
  TestHelpers::changeFileSeparator unix
  $archive exists {lib/fixtures/greeterExternal-0.1.tm}
} -cleanup {
  TestHelpers::resetFileSeparator
  cd $startDir
} -result 1


test read-1 {Ensure that if run under windows that the filename uses windows' file separators} -setup {
  set archive [::tarcel::TarArchive new]
  $archive importContents {hello how are you from fred} {text/fred.txt}
  $archive importContents {hello how are you from bert} {text/bert.txt}
} -body {
  TestHelpers::changeFileSeparator windows
  $archive read {text\bert.txt}
} -cleanup {
  TestHelpers::resetFileSeparator
} -result {hello how are you from bert}


test exists-2 {Ensure that if run under unix that the filename uses unix file separators} -setup {
  set archive [::tarcel::TarArchive new]
  $archive importContents {hello how are you from fred} {text/fred.txt}
  $archive importContents {hello how are you from bert} {text/bert.txt}
} -body {
  TestHelpers::changeFileSeparator unix
  $archive read {text/bert.txt}
} -cleanup {
  TestHelpers::resetFileSeparator
} -result {hello how are you from bert}


cleanupTests
