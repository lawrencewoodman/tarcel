package require Tcl 8.6
package require tcltest
namespace import tcltest::*

# Add module dir to tm paths
set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file join $ThisScriptDir fixtures]

source [file join $ThisScriptDir "test_helpers.tcl"]
source [file join $LibDir "tvfs.tcl"]
source [file join $LibDir "tararchive.tcl"]


test importFiles-1 {Ensure that files are put in correct location relative to their current location} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files {
    tararchive.test.tcl
    fixtures/greeterExternal-0.1.tm
  }
  set archive [TarArchive new]
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
  set archive [TarArchive new]
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
  set archive [TarArchive new]
} -body {
  $archive importFiles $files lib
  $archive ls
} -cleanup {
  cd $startDir
} -result {can't import file: ../tararchive.test.tcl} \
-returnCodes {error}


test fetchFiles-1 {Ensure that files are put in correct location irrespective of original location} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files {
    fixtures/greeterExternal-0.1.tm
  }
  set archive [TarArchive new]
} -body {
  $archive fetchFiles $files modules
  $archive ls
} -cleanup {
  cd $startDir
} -result {modules/greeterExternal-0.1.tm}


test export-1 {Ensure that an archive can be exported and loaded again and have the same contents} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files {
    tararchive.test.tcl
    fixtures/greeterExternal-0.1.tm
  }
  set archiveA [TarArchive new]
  set archiveB [TarArchive new]
  $archiveA importFiles $files lib
} -body {
  set tarBinArchive [$archiveA export]
  set exportedArchiveFilename [
    TestHelpers::writeToTempFile "this is some padding\u001a$tarBinArchive"
  ]

  $archiveB load $exportedArchiveFilename
  list [TestHelpers::fileCompare tararchive.test.tcl \
           [$archiveB read [file join lib tararchive.test.tcl]]] \
       [TestHelpers::fileCompare [file join fixtures greeterExternal-0.1.tm] \
           [$archiveB read [file join lib fixtures greeterExternal-0.1.tm]]]
} -cleanup {
  cd $startDir
} -result {0 0}


cleanupTests
