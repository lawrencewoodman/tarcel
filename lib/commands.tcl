# Commands to handle the tarcel
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#
namespace eval ::tarcel {
  namespace eval commands {
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

    if {[::tarcel::tar::exists $tarball init.tcl]} {
      uplevel 1 [::tarcel::tar::getFile $tarball init.tcl]
    }
  }
}
