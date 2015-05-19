package require Tcl 8.6
package require tcltest
namespace import tcltest::*

# Add module dir to tm paths
set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]


source [file join $LibDir "base64archive.tcl"]
source [file join $LibDir "pvfs.tcl"]


test ls-1 {Ensure that you can mount multiple archives at same mount point} -setup {
  set startDir [pwd]
  cd $FixturesDir

  set textA {This is some text in textA}
  set textB {This is some text in textA}
  set archiveA [Base64Archive new]
  set archiveB [Base64Archive new]
  $archiveA importContents $textA [file join text texta.txt]
  $archiveB importContents $textB [file join text textb.txt]
  pvfs::mount $archiveA .
  pvfs::mount $archiveB .
} -body {
  list [pvfs::exists [file join text texta.txt]] \
       [pvfs::exists [file join text textb.txt]]
} -cleanup {
  cd $startDir
} -result {1 1}


cleanupTests
