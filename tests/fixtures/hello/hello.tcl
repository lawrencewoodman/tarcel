set LibDir [file join [file dirname [info script]] lib]
source [file join $LibDir sayhello.tcl]
sayHello bob
