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
    set configInfo [::tarcel::tar getFile $tarball config/info]
    dict merge $info $configInfo
  }


  proc commands::launch {} {
    set tarball ${::tarcel::tarball}
    if {![namespace exists ::tarcel::launcher]} {
      eval [::tarcel::tar::getFile $tarball lib/launcher.tcl]
      ::tarcel::launcher::init
      ::tarcel::launcher::eval [::tarcel::tar::getFile $tarball lib/embeddedchan.tcl]
      ::tarcel::launcher::eval [::tarcel::tar::getFile $tarball lib/tar.tcl]
      ::tarcel::launcher::eval [::tarcel::tar::getFile $tarball lib/tararchive.tcl]
      ::tarcel::launcher::eval [::tarcel::tar::getFile $tarball lib/tvfs.tcl]
      ::tarcel::launcher::eval {
        tvfs::init ::tarcel::evalInMaster \
                   ::tarcel::invokeHiddenInMaster \
                   ::tarcel::transferChanToMaster
      }
      ::tarcel::launcher::createAliases
    }

    ::tarcel::launcher::eval {
      set tarball [::tarcel::evalInMaster "uplevel 1 set ::tarcel::tarball"]
      set mainTarball [::tarcel::tar::getFile $tarball main.tar]
      set archive [TarArchive new]
      $archive load $mainTarball
      tvfs::mount $archive .
    }

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
