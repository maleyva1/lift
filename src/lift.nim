import std/json
import std/streams
import std/strutils
import std/os
import std/options
import std/dirs
import std/paths

type
    TypeKind = enum
        Native
        ApiRef
        PointerTo
        LPArray
    Type = object
        `Kind`: Option[TypeKind]
        `Name`: Option[string]
        `TargetKind`: Option[string]
        `Api`: Option[string]
        `Parents`: Option[seq[JsonNode]] # No idea what this is
        `Child`: Option[JsonNode]
        `Attrs`: Option[Attributes]
    ValueTypeKind = enum
      Int32
      UInt32
      UInt64
      Byte
      UInt16
      PropertyKey
      Single
      Double
      Int64
      String
    Constant = object
        `Name`: string
        `Type`: Type
        `ValueType`: ValueTypeKind
        `Value`: JsonNode # Polymorphic type
        `Attrs`: seq[JsonNode] # Don't know what these are
    Fields = object
        `Name`: string
        `Type`: JsonNode
    Value = object
      `Name`: string
      `Value`: uint
    Types = object
        `Name`: string
        `Architectures`: seq[Architecture]
        `Platform`: Option[string]
        `Kind`: string
        `Guid`: Option[string]
        `Size`: Option[int]
        `PackingSize`: Option[int]
        `Fields`: Option[seq[Fields]]
        `IntegerBase`: Option[string]
        `AlsoUsableFor`: Option[string]
        `NestedType`: JsonNode # Don't know what this is
        `Interface`: Type
        `Params`: Parameter
        `FreeFunc`: Option[string]
        `Scoped`: bool
        `Values`: seq[Value] 
        `Def`: JsonNode # todo: comback
        `InvalidHandleValue`: Option[int]
        `Flags`: bool
        `Comment`: string
        `Methods`: seq[Function]
        `ReturnAttrs`: seq[Attributes]
        `ReturnType`: Type
    Attributes = enum
      PreserveSig
      DoesNotReturn
      Optional
      In
      Out
      ComOutPtr
      Const
      SpecialName
    Parameter = object
      `Name`: string 
      `Type`: Type
      `Attrs`: seq[JsonNode] # TODO: fix
    Architecture = enum
      X86
      X64
      Arm64
    Platform = enum # todo fix
      `windows6.1`
    Function = object
        `Name`: string
        `SetLastError`: bool
        `DllImport`: Option[string]
        `ReturnType`: Type
        `Architectures`: seq[Architecture]
        `Platform`: Option[Platform]
        `Attrs`: seq[Attributes]
        `Params`: seq[Parameter]
        `ReturnAttrs`: seq[Attributes]
    Metadata = object
        `Constants`: seq[Constant]
        `Types`: seq[Types]
        `Functions`: seq[Function]
        `UnicodeAliases`: seq[string]


when isMainModule:
    import std/strformat
    import std/sets
    import std/tables
    var c = initTable[string, HashSet[JsonNodeKind]]()
    for component, file in walkDir("win32json/api"):
        let (_, name, _) = file.splitFile()
        let apiDir = name.replace(".", "/").Path
        let dest = Path("generated") / apiDir
        # discard existsOrCreateDir(dest)
        var f = openFileStream(file)
        defer:
            # echo "Closing " & file
            f.close()
        let jsonNode = parseJson(f.readAll())
        for item in jsonNode["Constants"]:
            if item.hasKey("Attrs"):
                echo item["Attrs"]
            else:
              discard

