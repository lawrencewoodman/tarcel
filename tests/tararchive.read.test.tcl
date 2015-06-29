package require Tcl 8.6
package require tcltest
namespace import tcltest::*

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file join $ThisScriptDir fixtures]

source [file join $ThisScriptDir "test_helpers.tcl"]
source [file join $LibDir "xplatform.tcl"]
source [file join $LibDir "tvfs.tcl"]
source [file join $LibDir "tar.read.tcl"]
source [file join $LibDir "tar.write.tcl"]
source [file join $LibDir "tararchive.read.tcl"]
source [file join $LibDir "tararchive.write.tcl"]


test ls-1 {Ensure that if run under windows that the files are returned with windows' file separators} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files [list \
    tararchive.read.test.tcl \
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
} -result [list {lib\tararchive.read.test.tcl} \
                {lib\fixtures\greeterExternal-0.1.tm}]


test ls-2 {Ensure that if run under unix that the files are returned with unix file separators} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files [list \
    tararchive.read.test.tcl \
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
} -result {lib/tararchive.read.test.tcl lib/fixtures/greeterExternal-0.1.tm}


test exists-1 {Ensure that if run under windows that the filename uses windows' file separators} -setup {
  set startDir [pwd]
  cd $ThisScriptDir
  set files [list \
    tararchive.read.test.tcl \
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
    tararchive.read.test.tcl \
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
