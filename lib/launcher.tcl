# The tarcel launcher
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

namespace eval ::tarcel {
  namespace eval launcher  {
    variable launcherInt
  }


  proc launcher::init {} {
    variable launcherInt
    set launcherInt [interp create]
  }


  proc launcher::eval {script} {
    variable launcherInt
    $launcherInt eval info script [info script]
    $launcherInt eval $script
  }


  proc launcher::createAliases {} {
    variable launcherInt
    interp hide {} open
    interp hide {} source
    interp hide {} file
    interp hide {} glob

    interp alias {} ::open $launcherInt ::tvfs::open
    interp alias {} ::source $launcherInt ::tvfs::source
    interp alias {} ::file $launcherInt ::tvfs::file
    interp alias {} ::glob $launcherInt ::tvfs::glob

    interp alias $launcherInt ::tarcel::evalInMaster {} interp eval {}
    interp alias $launcherInt ::tarcel::invokeHiddenInMaster \
                 {} interp invokehidden {}
    interp alias $launcherInt ::tarcel::transferChanToMaster \
                 {} ::tarcel::launcher::transferChanToMaster
  }


  proc launcher::transferChanToMaster {chan} {
    variable launcherInt
    interp transfer $launcherInt $chan {}
  }
}
