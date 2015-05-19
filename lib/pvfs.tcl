# Parcel Virtual File System
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

namespace eval pvfs {
  set mounts [list]
}


proc pvfs::mount {archive mountPoint} {
  variable mounts
# TODO: Need to make mount relative to something, perhaps pwd or perhaps script file
  lappend mounts [list $mountPoint $archive]
}


proc pvfs::ls {} {
  variable mounts
  set result [list]

  foreach mount $mounts {
    lassign $mount mountPoint archive
    foreach filename [$archive ls] {
      if {$mountPoint eq "."} {
        lappend result $filename
      } else {
        lappend result [file join $mountPoint $filename]
      }
    }
  }

  return $result
}


proc pvfs::read {filename} {
  lassign [FilenameToArchiveFilename $filename] archive archiveFilename
  if {$archive eq {}} {return {}}
  $archive read $archiveFilename
}


proc pvfs::exists {name} {
  foreach filename [ls] {
    if {[DoCommonNamePartsMatch $name $filename]} {
      return 1
    }
  }
  return 0
}



#######################
# Internal commands
#######################

proc pvfs::DoCommonNamePartsMatch {name1 name2} {
  set normalizedName1 [file split [file normalize $name1]]
  set normalizedName2 [file split [file normalize $name2]]
  set lastIndexName1 [expr {[llength $normalizedName1] - 1}]
  set lastIndexName2 [expr {[llength $normalizedName2] - 1}]
  set lastCommonIndex [expr {min($lastIndexName1, $lastIndexName2)}]
  set commonName1 [lrange $normalizedName1 0 $lastCommonIndex]
  set commonName2 [lrange $normalizedName2 0 $lastCommonIndex]
  expr {$commonName1 == $commonName2}
}


proc pvfs::FilenameToArchiveFilename {filename} {
  variable mounts

  foreach mount $mounts {
    lassign $mount mountPoint archive
    if {[DoCommonNamePartsMatch $mountPoint $filename]} {
      set normalizedFilename [file split [file normalize $filename]]
      set normalizedMountPoint [file split [file normalize $mountPoint]]
      set archiveFilename [
        file join {*}[lrange $normalizedFilename \
                             [llength $normalizedMountPoint] \
                             end]
      ]

      if {[$archive exists $archiveFilename]} {
        return [list $archive $archiveFilename]
      }
    }
  }

  return {}
}
