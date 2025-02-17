import std/options
import std/strutils
import std/strformat
import std/streams

import types

import json_serialization

type
    MetadataMarshallingError = object of CatchableError

proc nimFfiType(name: string): string =
    case name:
        of "Byte":
            result = "byte"
        of "UInt16":
            result = "uint16"
        of "UInt32":
            result = "uint32"
        of "UInt64":
            result = "uint64"
        of "Int32": 
            result = "int32"
        of "Int64":
            result = "int64"
        of "String":
            result = "cstring"
        of "Guid":
            result = "todo"
        of "Single":
            result = "cfloat"
        of "Double":
            result = "cdouble"
        else:
            raise newException(MetadataMarshallingError, "Unknown FFI type " & $name)

proc toNimType(winrtType: ConstantType): string =
    result = ""
    case winrtType.Kind:
        of Native:
            return nimFfiType(winrtType.Name)
        of Array:
            if winrtType.Shape.isSome():
                let shape = winrtType.Shape.get()
                result = shape.toJson()
            else:
                raise newException(MetadataMarshallingError, "Type is `Array` but is missing `Shape` field")
        of ApiRef:
            # Refers to some type in another winrt file
            discard
        of PointerTo:
            # Pointer type
            discard
        of LPArray:
            discard

proc generateConstants(info: Metadata; file: FileStream): void =
    for constant in info.Constants:
        let constantType = toNimType(constant.Type)
        if constantType.len > 0:
            file.writeLine &"const {constant.Name}*: {constantType} ="

func getNimArch(arch: Architecture): string =
    ## Get the `hostCpu` equivalent.
    ## 
    case arch:
        of X86:
            result = "i386"
        of X64:
            result = "amd64"
        of Arm64:
            result = "arm64"

proc generateTypes(info: Metadata; file: FileStream): void =
    ## Check for architectures
    for taipe in info.Types:
        for arch in taipe.Architectures:
            file.writeLine &"when defined({getNimArch(arch)}):"
            file.write &"\t"
        file.writeLine &"type {taipe.Name} =  {taipe.Kind}"

proc pragmaBuilder(lib: Option[string] = none(string)): string =
    ## Generates the appropriate pragma for the function.
    ## 
    var builder = newStringStream()
    builder.write("{.")
    builder.write("importc")
    if lib.isSome():
        builder.write(", dynlib: \"")
        builder.write(lib.get())
        builder.write(".dll")
        builder.write("\"")
    builder.write(".}")
    builder.setPosition(0)
    result = builder.readAll()
    builder.close()

proc functionReturnType(ret: JsonValueRef[string]): string =
    result = "<TYPE(todo)>"

proc functionParameters(params: seq[Parameter]): string =
    var args = newSeq[string]()
    for param in params:
        args.add(&"{param.Name}: <TYPE(todo)>")
    result = args.join(", ")

proc generateFunctions(info: Metadata; file: FileStream): void =
    ## Generate Nim FFI bindings.
    ## 
    for function in info.Functions:
        for arch in function.Architectures:
            file.writeLine &"when defined({arch}):"
            file.write &"\t"
        file.write("proc ")
        file.write(function.Name)
        file.write("(")
        file.write(functionParameters(function.Params))
        file.write("): ")
        file.write(functionReturnType(function.ReturnType))
        file.write(pragmaBuilder(function.DllImport))

const generatedHeader = "# This file was automatically generated. DO NOT MODIFY"

proc genBindings*(info: Metadata; file: File): void =
    var file = newFileStream(file)
    defer: file.close()
    file.writeLine(generatedHeader)
    info.generateConstants(file)
    file.writeLine("")
    info.generateTypes(file)
    file.writeLine("")
    info.generateFunctions(file)