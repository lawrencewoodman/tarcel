package require Tcl 8.6
package require tcltest
namespace import tcltest::*

# Add module dir to tm paths
set ThisScriptDir [file dirname [info script]]
set FixturesDir [file join $ThisScriptDir fixtures]

source [file join $ThisScriptDir .. "base64archive.tcl"]


test importFiles-1 {Ensure that files are put in correct location relative to their current location} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files {
    base64archive.test.tcl
    fixtures/greeterExternal-0.1.tm
  }
  set archive [Base64Archive new]
} -body {
  $archive importFiles $files lib
  $archive ls
} -cleanup {
  cd $startDir
} -result {lib/base64archive.test.tcl lib/fixtures/greeterExternal-0.1.tm}


test importFiles-2 {Ensure that any . parts of filename are removed} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files {
    ./base64archive.test.tcl
    ./fixtures/greeterExternal-0.1.tm
  }
  set archive [Base64Archive new]
} -body {
  $archive importFiles $files lib
  $archive ls
} -cleanup {
  cd $startDir
} -result {lib/base64archive.test.tcl lib/fixtures/greeterExternal-0.1.tm}


test importFiles-3 {Ensure that .. in filename raises and error} -setup {
  set startDir [pwd]
  cd $FixturesDir
  set files {
    ../base64archive.test.tcl
  }
  set archive [Base64Archive new]
} -body {
  $archive importFiles $files lib
  $archive ls
} -cleanup {
  cd $startDir
} -result {can't import file: ../base64archive.test.tcl} \
-returnCodes {error}


test fetchFiles-1 {Ensure that files are put in correct location irrespective of original location} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files {
    fixtures/greeterExternal-0.1.tm
  }
  set archive [Base64Archive new]
} -body {
  $archive fetchFiles $files modules
  $archive ls
} -cleanup {
  cd $startDir
} -result {modules/greeterExternal-0.1.tm}


cleanupTests
