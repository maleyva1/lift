import std/strutils
import std/os
import std/dirs
import std/paths

# todo: remove
import std/strformat

import internal/types
import internal/generate

import json_serialization

iterator jsonOnly(dir: Path): tuple[kind: PathComponent, file: Path] =
    ## Iterate over all files in `dir` that are JSON.
    ## 
    for kind, file in walkDir(dir):
        let (_, _, ext) = file.splitFile()
        if kind == pcFile and ext == ".json":
            yield (kind, file)

proc generate(input, output: Path) =
    for kind, file in jsonOnly(input):
        let (_, name, _) = file.splitFile()
        let apiDir = name.string.replace(".", "/").Path
        let dest = output / apiDir
        # discard existsOrCreateDir(dest)
        genBindings marshal(string(file)), dest, name.string

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