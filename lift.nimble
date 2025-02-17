# Package

version       = "0.1.0"
author        = "Mark Leyva"
description   = "WinRT bindings generator"
license       = "MIT"
srcDir        = "src"
bin           = @["lift"]


# Dependencies

requires "nim >= 2.0.2"
requires "argparse >= 4.0.2"
requires "json_serialization"

# Testing
task generate, "Generate":
    exec "nim c --out:lift src/lift.nim"
    exec "./lift win32json/api generated"
