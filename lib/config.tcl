# Config handler
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#
namespace eval config {
  set ThisScriptDir [file dirname [info script]]
  source [file join $ThisScriptDir base64archive.tcl]

  variable config [dict create init {} archive [Base64Archive new]]
}


proc config::load {filename} {
  variable config

  set exposeCmds {
    if if
    lassign lassign
    list list
    lsort lsort
    regexp regexp
    regsub regsub
    set set
  }
  set slaveCmds {
    config config::Config
    error config::Error
    fetch config::Fetch
    file config::File
    find config::Find
    get config::Get
    import config::Import
    init config::Init
  }

  set fd [open $filename r]
  set scriptIn [read $fd]
  close $fd
  parseConfig -keys {} -exposeCmds $exposeCmds -slaveCmds $slaveCmds $scriptIn

  return $config
}


########################
# Internal commands
########################

proc config::Error {interp msg} {
  error $msg
}

proc config::Config {interp command args} {
  variable config
  switch $command {
    set {
      lassign $args varName value
      dict set config $varName $value
    }
    default {
      return -code error "invalid config command: $command"
    }
  }
}


proc config::Get {interp what args} {
  switch $what {
    packageLoadCommands { GetPackageLoadCommands {*}$args }
    default {
      return -code error "invalid command: get $what $args"
    }
  }
}


proc config::Init {interp script} {
  Config $interp set init $script
}


proc config::Import {interp files importPoint} {
  variable config
  set archive [dict get $config archive]
  $archive importFiles $files $importPoint
}


proc config::Fetch {interp files importPoint} {
  variable config
  set archive [dict get $config archive]
  $archive fetchFiles $files $importPoint
}


proc config::File {interp command args} {
  switch $command {
    join { return [::file join {*}$args] }
    tail { return [::file tail {*}$args] }
    default {
      return -code error "invalid command for file: $command"
    }
  }
}


proc config::Find {interp type args} {
  switch $type {
    module { FindModule {*}$args }
    default {
      return -code error "unknown find type: $type"
    }
  }
}


# TODO: Add version number handling
proc config::FindModule {args} {
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
      lappend foundModules [list $moduleFilename $version]
    }
  }

  if {[llength $foundModules] == 0} {
    return -code error "Module can't be found: $moduleName"
  }
  set latestModule [lindex [lsort -decreasing -index 1 $foundModules] 0]
  lassign $latestModule fullModuleFilename
  return $fullModuleFilename
}


proc config::GetPackageLoadCommands {args} {
  lassign $args packageName
  {*}[package unknown] $packageName
  set versions [package versions $packageName]
  if {[llength $versions] == 0} {
    return {}
  }
  set latestVersion [lindex $versions 0]
  return [list [package ifneeded $packageName $latestVersion] $latestVersion]
}
