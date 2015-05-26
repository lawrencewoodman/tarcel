# The parcel launcher
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

namespace eval ::parcel  {
  proc ::parcel::init {} {
    variable launcherInt
    set launcherInt [interp create]
  }

  proc ::parcel::getLauncherInterp {} {
    variable launcherInt
    return $launcherInt
  }


  proc ::parcel::eval {script} {
    variable launcherInt
    $launcherInt eval info script [info script]
    $launcherInt eval $script
  }


  proc ::parcel::createAliases {} {
    variable launcherInt
    interp hide {} open
    interp hide {} source
    interp hide {} file
    interp hide {} glob

    interp alias {} ::open $launcherInt ::pvfs::open
    interp alias {} ::source $launcherInt ::pvfs::source
    interp alias {} ::file $launcherInt ::pvfs::file
    interp alias {} ::glob $launcherInt ::pvfs::glob

    interp alias $launcherInt ::parcel::evalInMaster {} interp eval {}
    interp alias $launcherInt ::parcel::invokeHiddenInMaster \
                 {} interp invokehidden {}
    interp alias $launcherInt ::parcel::transferChanToMaster \
                 {} ::parcel::transferChanToMaster
  }


  proc ::parcel::transferChanToMaster {chan} {
    variable launcherInt
    interp transfer $launcherInt $chan {}
  }


  # TODO: Put this is separate file as not needed except for testing
  proc ::parcel::finish {} {
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
