# Commands to handle the tarcel
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#
namespace eval ::tarcel {
  namespace eval commands {
  }


  proc commands::commands {} {
    list commands launch info
  }


  proc commands::info {tarball} {
    set info [dict create]
    dict set info filenames [lsort [::tarcel::tar getFilenames $tarball]]
    set configInfo {}
    if {[::tarcel::tar exists $tarball config/info]} {
      set configInfo [::tarcel::tar getFile $tarball config/info]
    }
    dict merge $info $configInfo
  }


  proc commands::launch {tarball} {
    if {![namespace exists ::tvfs]} {
      uplevel 1 [::tarcel::tar::getFile $tarball lib/parameters.tcl]
      uplevel 1 [::tarcel::tar::getFile $tarball lib/xplatform.tcl]
      uplevel 1 [::tarcel::tar::getFile $tarball lib/embeddedchan.tcl]
      uplevel 1 [::tarcel::tar::getFile $tarball lib/tar.tcl]
      uplevel 1 [::tarcel::tar::getFile $tarball lib/tararchive.tcl]
      uplevel 1 [::tarcel::tar::getFile $tarball lib/tvfs.tcl]
      tvfs::init
    }

    set mainTarball [::tarcel::tar::getFile $tarball main.tar]
    set archive [::tarcel::TarArchive new]
    $archive load $mainTarball
    tvfs::mount $archive .

    if {[::tarcel::tar::exists $tarball config/init.tcl]} {
      uplevel 1 [::tarcel::tar::getFile $tarball config/init.tcl]
    }
  }

  ##########################
  # Internal commands
  ##########################

  proc commands::WriteToFilename {contents filename} {
    file mkdir [file dirname $filename]
    set fd [open $filename w]
    fconfigure $fd -translation binary
    puts -nonewline $fd $contents
    close $fd
  }
}
