# Tarcel Virtual File System
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#
# This allows you to mount archives at certain points and then takes
# over the functionality of open, source, file and glob to access them.
#

namespace eval tvfs {
  variable mounts [list]
  variable masterEvalCmd
  variable masterHiddenCmd
  variable masterTransferChanCmd
  namespace export open source file glob
}


proc tvfs::init {_masterEvalCmd _masterHiddenCmd _masterTransferChanCmd} {
  variable mounts
  variable masterEvalCmd
  variable masterHiddenCmd
  variable masterTransferChanCmd
  set mounts [list]
  set masterEvalCmd $_masterEvalCmd
  set masterHiddenCmd $_masterHiddenCmd
  set masterTransferChanCmd $_masterTransferChanCmd
}


proc tvfs::glob {args} {
  set switchesWithValue {-directory -path -types}
  set switchesWithoutValue {-join -nocomplain -tails}
  set result [list]

  lassign [::tarcel::parameters::getSwitches $switchesWithValue \
                                             $switchesWithoutValue \
                                             {*}$args] \
          switches \
          patterns

  if {[dict exists $switches -directory]} {
    set directory [dict get $switches -directory]
    set result [GlobInDir $switches $directory $patterns]
  }

  try {
    set result [
      list {*}$result {*}[MasterHidden glob {*}$args]
    ]
  } on error {errorMsg options} {
    if {[string match {no files matched glob pattern*} $errorMsg] &&
        [llength $result] == 0 &&
        ![dict exists $switches -nocomplain]} {
      dict unset options -level
      return -options $options $errorMsg
    }
  }

  return [lsort -unique $result]
}


proc tvfs::load {args} {
  set switchesWithoutValue {-global -lazy --}
  set result [list]

  lassign [::tarcel::parameters::getSwitches {} \
                                             $switchesWithoutValue \
                                             {*}$args] \
          switches \
          argsLeft

  if {[llength $argsLeft] < 1 || [llength $argsLeft] > 3} {
    MasterHidden load {*}$args
  }

  lassign $argsLeft filename
  set argsLeft [lrange $argsLeft 1 end]
  if {[exists $filename]} {
    set libFileContents [read $filename]
    set tempDir [MakeTempDir]
    set tempLibFilename [::file join $tempDir [::file tail $filename]]
    set fd [::open $tempLibFilename w]
    fconfigure $fd -translation binary
    puts -nonewline $fd $libFileContents
    close $fd
    MasterHidden load $tempLibFilename {*}$argsLeft
  } else {
    MasterHidden load $filename {*}$argsLeft
  }
}


proc tvfs::file {args} {
  lassign $args command

  switch $command {
    exists {
      if {[llength $args] == 2 && [exists [lindex $args 1]]} {
        return 1
      }
    }
    isfile {
      if {[llength $args] == 2 && [isfile [lindex $args 1]]} {
        return 1
      }
    }
  }
  ::file {*}$args
}


proc tvfs::source {args} {
  set switchesWithValue {-encoding}
  lassign [::tarcel::parameters::getSwitches $switchesWithValue \
                                             {} \
                                             {*}$args] \
          switches \
          argsLeft

  if {[llength $argsLeft] != 1} {
    MasterHidden source {*}$args
  }

  set filename $argsLeft
  set contents [ReadTclFile $filename]
  if {$contents ne {}} {
    set callingScript [MasterEval info script]
    MasterEval info script $filename
    if {[dict exist $switches -encoding]} {
      set contents [
        encoding convertfrom [dict get $switches -encoding] $contents
      ]
    }
    set res [MasterEval $contents]
    MasterEval info script $callingScript
  } else {
    set res [MasterHidden source {*}$args]
  }

  return $res
}


proc tvfs::open {args} {
  lassign $args filename
  if {[exists $filename]} {
    set contents [read $filename]
    set fd [embeddedChan::open $contents]
    MasterTransferChan $fd
    return $fd
  } else {
    MasterHidden open {*}$args
  }
}


proc tvfs::mount {archive mountPoint} {
  variable mounts
  lappend mounts [list [file normalize $mountPoint] $archive]
}


proc tvfs::read {filename} {
  lassign [FilenameToArchiveFilename $filename] archive archiveFilename
  if {$archive eq {}} {return {}}
  $archive read $archiveFilename
}


proc tvfs::exists {name} {
  foreach filename [Ls] {
    if {[DoCommonNamePartsMatch $name $filename]} {
      return 1
    }
  }
  return 0
}


proc tvfs::isfile {name} {
  foreach filename [Ls] {
    if {[::file normalize $name] eq [::file normalize $filename]} {
      return 1
    }
  }
  return 0
}

#######################
# Internal commands
#######################

proc tvfs::Ls {} {
  variable mounts
  set result [list]

  foreach mount $mounts {
    lassign $mount mountPoint archive
    foreach filename [$archive ls] {
      if {$mountPoint eq "."} {
        lappend result $filename
      } else {
        lappend result [::file join $mountPoint $filename]
      }
    }
  }

  return $result
}


proc tvfs::GetCommonNameParts {name1 name2} {
  set normalizedName1 [::file split [::file normalize $name1]]
  set normalizedName2 [::file split [::file normalize $name2]]
  set lastIndexName1 [expr {[llength $normalizedName1] - 1}]
  set lastIndexName2 [expr {[llength $normalizedName2] - 1}]
  set lastCommonIndex [expr {min($lastIndexName1, $lastIndexName2)}]
  set commonName1 [lrange $normalizedName1 0 $lastCommonIndex]
  set commonName2 [lrange $normalizedName2 0 $lastCommonIndex]
  if {$commonName1 == $commonName2} {
    return $commonName1
  }
  return {}
}


proc tvfs::DoCommonNamePartsMatch {name1 name2} {
  set commonNameParts [GetCommonNameParts $name1 $name2]
  expr {$commonNameParts != {}}
}


proc tvfs::ReadTclFile {filename} {
  try {
    set contents [read $filename]
    if {$contents eq {}} {
      set fd [::open $filename r]
      set contents [::read $fd]
      close $fd
    }
  } on error {} {
    return {}
  }

  set contentsUpToControlZ [regsub "^(.*?)(\u001a.*)$" $contents {\1}]
  if {$contentsUpToControlZ eq {}} {
    return $contents
  }
  return $contentsUpToControlZ
}


proc tvfs::MasterTransferChan {chan} {
  variable masterTransferChanCmd
  {*}$masterTransferChanCmd $chan
}


proc tvfs::MasterEval {args} {
  variable masterEvalCmd
  {*}$masterEvalCmd {*}$args
}


proc tvfs::MasterHidden {args} {
  variable masterHiddenCmd
  {*}$masterHiddenCmd {*}$args
}


proc tvfs::GlobInDir {switches directory patterns} {
  set normalizedDirectory [::file normalize $directory]
  set result [list]
  set vFilenames [Ls]

  # Files
  foreach vFilename $vFilenames {
    set vFilename [::file normalize $vFilename]
    if {[::file dirname $vFilename] eq $normalizedDirectory} {
      foreach pattern $patterns {
        if {[string match $pattern [::file tail $vFilename]]} {
          lappend result [file join $directory [::file tail $vFilename]]
        }
      }
    }
  }

  # Directories
  foreach vFilename $vFilenames {
    set vFilename [::file normalize $vFilename]
    set commonParts [GetCommonNameParts $vFilename $normalizedDirectory]
    set nextPartVFilenameIndex [llength $commonParts]
    set nextPartVFilename [
      lindex [::file split $vFilename] $nextPartVFilenameIndex
    ]
    set vFilenameSplit [::file split $vFilename]
    set isDirectory [
      expr {$nextPartVFilenameIndex < [llength $vFilenameSplit] - 1}
    ]
    set dirName [::file join $directory $nextPartVFilename]
    if {[lsearch $result $dirName] == -1 &&
        $isDirectory &&
        [llength $commonParts] >= 1} {
      if {[::file join {*}$commonParts] eq $normalizedDirectory} {
        foreach pattern $patterns {
          if {[string match $pattern $nextPartVFilename]} {
            lappend result $dirName
          }
        }
      }
    }
  }

  return $result
}


proc tvfs::FilenameToArchiveFilename {filename} {
  variable mounts

  set normalizedFilename [::file normalize $filename]
  set splitNormalizedFilename [::file split $normalizedFilename]
  foreach mount $mounts {
    lassign $mount mountPoint archive
    if {[DoCommonNamePartsMatch $mountPoint $normalizedFilename]} {
      set splitNormalizedMountPoint [
        ::file split [::file normalize $mountPoint]
      ]
      set archiveFilename [
        ::file join {*}[lrange $splitNormalizedFilename \
                               [llength $splitNormalizedMountPoint] \
                               end]
      ]
      if {[$archive exists $archiveFilename]} {
        return [list $archive $archiveFilename]
      }
    }
  }

  return {}
}


proc tvfs::MakeTempDir {} {
  set fd [::file tempfile mainTempFile]
  close $fd
  set mainTempDir [::file dirname $mainTempFile]
  while {1} {
    try {
      set tempDir [::file join $mainTempDir tarcel_tests_[clock milliseconds]]
      ::file mkdir $tempDir
      break
    } on error {} {}
  }

  return $tempDir
}
