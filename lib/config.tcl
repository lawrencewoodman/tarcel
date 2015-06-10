# Config handler
#
# Copyright (C) 2015 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

package require configurator
namespace import configurator::*


::oo::class create ::tarcel::Config {
  variable config

  constructor {} {
    set config [dict create init {} archive [::tarcel::TarArchive new]]
  }

  method parse {script} {
    set selfObject [self object]
    set exposeCmds {
      foreach foreach
      glob glob
      if if
      lassign lassign
      list list
      llength llength
      lsort lsort
      regexp regexp
      regsub regsub
      set set
      string string
    }
    set slaveCmds [dict create \
      config [list ${selfObject}::my Config] \
      error [list ${selfObject}::my Error] \
      fetch [list ${selfObject}::my Fetch] \
      file [list ${selfObject}::my File] \
      find [list ${selfObject}::my Find] \
      get [list ${selfObject}::my Get] \
      import [list ${selfObject}::my Import] \
      tarcel [list ${selfObject}::my Tarcel]
    ]

    parseConfig -keys {} -exposeCmds $exposeCmds -slaveCmds $slaveCmds $script

    return $config
  }


  method load {filename} {
    set fd [open $filename r]
    set scriptIn [read $fd]
    set config [my parse $scriptIn]
    close $fd
    return $config
  }


  ########################
  # Private methods
  ########################

  method Tarcel {interp tarcelManifestFilename destination} {
    set startDir [pwd]
    set fd [open $tarcelManifestFilename r]
    set tarcelManifest [read $fd]
    close $fd

    set childConfig [::tarcel::Config new]
    cd [file dirname $tarcelManifestFilename]

    try {
      set childConfigSettings [$childConfig parse $tarcelManifest]
    } finally {
      cd $startDir
    }

    lassign [compiler::compile -nostartupcode $childConfigSettings] \
            startScript \
            tarball
    set tarcel [string cat $startScript $tarball]
    set archive [dict get $config archive]
    set childOutputFilename [
      file join $destination [dict get $childConfigSettings outputFilename]
    ]
    $archive importContents $tarcel $childOutputFilename
  }


  method Error {interp msg} {
    error $msg
  }

  method Config {interp command args} {
    set invalidVarnames {archive}
    switch $command {
      set {
        if {[llength $args] != 2} {
          return -code error \
                 "wrong # of arguments, should be: config set varName value"
        }
        lassign $args varName value
        if {$varName in $invalidVarnames} {
          return -code error "invalid variable for config set: $varName"
        }
        dict set config $varName $value
      }

      default {
        return -code error "invalid config command: $command"
      }
    }
  }


  method Get {interp what args} {
    switch $what {
      packageLoadCommands { my GetPackageLoadCommands {*}$args }
      default {
        return -code error "invalid command: get $what $args"
      }
    }
  }


  method Import {interp files importPoint} {
    set archive [dict get $config archive]
    $archive importFiles $files $importPoint
  }


  method Fetch {interp files importPoint} {
    set archive [dict get $config archive]
    $archive fetchFiles $files $importPoint
  }


  method File {interp command args} {
    switch $command {
      dirname { return [::file dirname {*}$args] }
      join { return [::file join {*}$args] }
      tail { return [::file tail {*}$args] }
      default {
        return -code error "invalid command for file: $command"
      }
    }
  }


  method Find {interp type args} {
    switch $type {
      module { my FindModule {*}$args }
      default {
        return -code error "unknown find type: $type"
      }
    }
  }


# TODO: Add version number handling
  method FindModule {args} {
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


  method GetPackageLoadCommands {args} {
    lassign $args packageName
    {*}[package unknown] $packageName
    set versions [package versions $packageName]
    if {[llength $versions] == 0} {
      return {}
    }
    set latestVersion [lindex $versions 0]
    return [list [package ifneeded $packageName $latestVersion] $latestVersion]
  }

}
