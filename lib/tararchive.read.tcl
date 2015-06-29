# Tar archive
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

::oo::class create ::tarcel::TarArchive {
  variable files

  constructor {} {
    set files [dict create]
  }


  method load {tarball} {
    set filenames [::tarcel::tar getFilenames $tarball]

    foreach filename $filenames {
      dict set files $filename [::tarcel::tar getFile $tarball $filename]
    }
  }


  method ls {} {
    lmap filename [dict keys $files] {
      ::tarcel::xplatform::unixToLocalFilename $filename
    }
  }


  method exists {filename} {
    dict exists $files [::tarcel::xplatform::toUnixFilename $filename]
  }


  method read {filename} {
    dict get $files [::tarcel::xplatform::toUnixFilename $filename]
  }

}

