# Config handler
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#
namespace eval config {
  set ThisScriptDir [file dirname [info script]]
  source [file join $ThisScriptDir base64archive.tcl]

  variable archive [Base64Archive new]
  variable additionalModulePaths [list]
  variable initScript {}
}


proc config::load {filename} {
  set exposeCmds {
    list list
    set set
  }
  set slaveCmds {
    add config::Add
    fetch config::Fetch
    file config::File
    import config::Import
    init config::Init
  }

  set fd [open $filename r]
  set scriptIn [read $fd]
  close $fd
  parseConfig -keys {} -exposeCmds $exposeCmds -slaveCmds $slaveCmds $scriptIn
}


proc config::getArchive {} {
  variable archive
  return $archive
}


proc config::getAdditionalModulePaths {} {
  variable additionalModulePaths
  return $additionalModulePaths
}


proc config::getInitScript {} {
  variable initScript
  return $initScript
}


########################
# Internal commands
########################

proc config::Init {interp script} {
  variable initScript
  set initScript $script
}


proc config::Import {interp files importPoint} {
  variable archive
  $archive importFiles $files $importPoint
}


proc config::Fetch {interp files importPoint} {
  variable archive
  $archive fetchFiles $files $importPoint
}


proc config::File {interp command args} {
  if {$command eq "join"} {
    return [::file join {*}$args]
  } else {
    return -code error "invalid command for file: $command"
  }
}


proc config::Add {interp type args} {
  switch $type {
    module { AddModule {*}$args }
    modulePath { AddModulePath {*}$args }
    default {
      return -code error "unknown add type: $type"
    }
  }
}


# TODO: Add version number handling
proc config::AddModule {args} {
  variable archive
  lassign $args moduleName destination
  set dirPrefix [regsub {^(.*?)([^:]+)$} $moduleName {\1}]
  set dirPrefix [regsub {::} $dirPrefix [file separator]]
  set tailModuleName [regsub {^(.*?)([^:]+)$} $moduleName {\2}]
  set foundModules [list]

  foreach path [::tcl::tm::path list] {
    set possibleModules [
      glob -nocomplain \
           -directory [file join $path $dirPrefix] \
           "$tailModuleName*.tm"
    ]
    foreach moduleFilename $possibleModules {
      set tailFoundModule [file tail $moduleFilename]
      set version [regsub {^(.*?)-(.*?)\.tm$} $tailFoundModule {\2}]
      lappend foundModules [list $moduleFilename $tailFoundModule $version]
    }
  }

  if {[llength $foundModules] == 0} {
    return -code error "Module can't be found: $moduleName"
  }
  set latestModule [lindex [lsort -decreasing -index 2 $foundModules] 0]
  lassign $latestModule fullModuleFilename tailModuleName
  set importPoint [file join $destination $dirPrefix]
  $archive fetchFiles [list $fullModuleFilename] $importPoint
}


proc config::AddModulePath {args} {
  variable additionalModulePaths

  set additionalModulePaths [list {*}$additionalModulePaths {*}$args]
}
