# Cross platform functions
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

namespace eval ::tarcel {

  namespace eval xplatform {
    namespace export {[a-z]*}
  }


  # Used instead of file join/split because 'file split' doesn't split in
  # some circumstances such as where a ~ is in a filename
  proc xplatform::toUnixFilename {filename} {
    join [split $filename [file separator]] /
  }


  proc xplatform::unixToLocalFilename {filename} {
    file join {*}[split $filename /]
  }

}
