# Package

version       = "0.1.0"
author        = "Mark Leyva"
description   = "WinRT bindings generator"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.2"

# Testing
task generate, "Generate":
    exec "nim c --out:gen src/lift.nim"
