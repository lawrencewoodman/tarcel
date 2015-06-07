# Parameter handling
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

namespace eval ::tarcel {
  namespace eval parameters {
  }

  proc parameters::getSwitches {switchesWithValue switchesWithoutValue args} {
    set switches [dict create]
    set numArgs [llength $args]

    for {set argNum 0} {$argNum < $numArgs} {incr argNum} {
      set arg [lindex $args $argNum]
      if {![string match {-*} $arg]} {
        break
      }

      if {$arg in $switchesWithValue && ($argNum + 1 < $numArgs)} {
        set nextArg [lindex $args [expr {$argNum + 1}]]
        dict set switches $arg $nextArg
        incr argNum
      } elseif {$arg in $switchesWithoutValue} {
        dict set switches $arg 1
      } else {
        return -code error "invalid switch"
      }
    }

    set argsLeft [lrange $args $argNum end]
    return [list $switches $argsLeft]
  }

}



