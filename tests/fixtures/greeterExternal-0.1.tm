namespace eval greeterExternal {
  namespace export {[a-z]*}
}


proc greeterExternal::hello {who} {
  return "hello $who (from external greeter)"
}
