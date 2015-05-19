set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir lib]

source [file join $LibDir foodplurals.tcl]

proc eat {what} {
  return "I like eating [$what]"
}
