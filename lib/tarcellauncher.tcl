# The tarcel launcher
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

namespace eval ::tarcel  {
  proc ::tarcel::init {} {
    variable launcherInt
    set launcherInt [interp create]
  }


  proc ::tarcel::eval {script} {
    variable launcherInt
    $launcherInt eval info script [info script]
    $launcherInt eval $script
  }


  proc ::tarcel::createAliases {} {
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
                 {} ::tarcel::transferChanToMaster
  }


  proc ::tarcel::transferChanToMaster {chan} {
    variable launcherInt
    interp transfer $launcherInt $chan {}
  }


  # TODO: Put this is separate file as not needed except for testing
  proc ::tarcel::finish {} {
    variable launcherInt
    interp alias {} ::open {}
    interp alias {} ::source {}
    interp alias {} ::file {}
    interp alias {} ::glob {}
    interp expose {} open
    interp expose {} source
    interp expose {} file
    interp expose {} glob
    interp delete $launcherInt
  }
}
