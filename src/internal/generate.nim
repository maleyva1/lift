import std/paths

import std/strformat

import types

# "const" & constant.Name & ": " & toNimType(constant.Type) & " = " & 

proc generateConstants(): void = discard

proc generateTypes(): void = discard

proc generateFunctions(): void = discard

proc genBindings*(info: Metadata; dest: Path, namespace: string): void =
    for constant in info.Constants:
        echo &"const {constant.Name}* = "