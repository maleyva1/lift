import std/strutils
import std/os
import std/dirs
import std/paths

# todo: remove
import std/strformat
import std/tables
import std/sets

import internal/types

import json_serialization

proc generate(input, output: Path) =
    var items = initTable[string, HashSet[JsonValueKind]]()
    var names = initHashSet[string]()
    for component, file in walkDir(input):
        let (_, name, _) = file.splitFile()
        let nameStr = string(name)
        let apiDir = nameStr.replace(".", "/").Path
        let dest = output / apiDir
        # discard existsOrCreateDir(dest)
        discard marshal(string(file))
    for name in names:
        echo name
    for k,v in items.pairs:
            echo &"{k} = {v}"

when isMainModule:
    import argparse

    var p = newParser:
        help("CLI tool to generate Nim bindings for WinRT")
        arg("metadata")
        arg("output")
        run:
            let input = opts.metadata.Path
            if dirExists(input):
                generate(input, opts.output.Path)
            else:
                stderr.writeLine("The directory " & string(input) & " does not appear to exists")
                quit(1)
    if paramCount() > 0:
        try:
            p.run(commandLineParams())
        except UsageError:
            stderr.writeLine getCurrentExceptionMsg()
            quit(1)
        except ShortCircuit as err:
            if err.flag == "argparse_help":
                stdout.writeLine(err.help)
            quit(1)
    else:
        stderr.writeLine(p.help())
        quit(1)