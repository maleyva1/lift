import std/strformat

import json_serialization
import json_serialization/std/options

type
    TypeKind* = enum
        Array
        Native
        ApiRef
        PointerTo
        LPArray
    Attribute* = enum
        PreserveSig
        DoesNotReturn
        Optional
        In
        Out
        ComOutPtr
        Const
        SpecialName
        LPArray
        Agile
        NotNullTerminated
        NullNullTerminated
        Obselete
    ValueTypeKind* = enum
        Int32
        Int64
        UInt16
        UInt32
        UInt64
        Byte
        SByte
        Single
        Double
        String
        PropertyKey
    ShapeType* = object
        `Size`*: int
    ConstantType* = object
        `Kind`*: TypeKind
        `Name`*: string
        `TargetKind`*: Option[string]
        `Api`*: Option[string]
        `Parents`*: Option[seq[JsonValueRef[string]]] # No idea what this is yet
        `Child`*: Option[JsonValueRef[string]]
        `Shape`*: Option[ShapeType]
        `NullNullTerm`*: Option[bool]
        `CountConst`*: Option[int]
        `CountParamIndex`*: Option[int]
    Constant* = object
        `Name`*: string
        `Type`*: ConstantType
        `ValueType`*: ValueTypeKind
        `Value`*: JsonValueRef[string]      # Polymorphic type
        `Attrs`*: seq[Attribute] # Don't know what these are. Assuming same type as other `Attrs`
    Field* = object
        `Name`*: string
        `Type`*: ConstantType
        `Attrs`*: seq[Attribute]
    Value = object
        `Name`*: string
        `Value`*: JsonNumber[uint64]
    TypeDefinition* = object
        `Name`*: string
        `Kind`*: TypeKind
        `Child`*: JsonValueRef[string]
    InterfaceDefinition* = object
        `Name`*: string
        `Kind`*: TypeKind
        `Parents`*: seq[JsonValueRef[string]]
        `TargetKind`*: TypeKindKind
        `Api`*: string
    TypeKindKind = enum
        Com
        ComClassID
        Enum
        Struct
        FunctionPointer
        Union
        NativeTypedef
    Type* = object
        `Name`*: string
        `Architectures`*: seq[Architecture]
        `Platform`*: Option[string]
        `Kind`*: TypeKindKind
        `Guid`*: Option[string]
        `SetLastError`*: bool
        `Size`*: int
        `Attrs`*: seq[Attribute]
        `PackingSize`*: int
        `Fields`*: seq[Field]
        `IntegerBase`*: Option[ValueTypeKind]
        `AlsoUsableFor`*: Option[string]
        `NestedTypes`*: JsonValueRef[string] # Don't know what this is
        `Interface`*: Option[InterfaceDefinition]
        `Params`*: seq[Parameter]
        `FreeFunc`*: Option[string]
        `Scoped`*: bool
        `Values`*: seq[Value]
        `Def`*: Option[TypeDefinition]
        `InvalidHandleValue`*: Option[int]
        `Flags`*: bool
        `Comment`*: string
        `Methods`*: seq[Function]
        `ReturnAttrs`*: seq[Attribute]
        `ReturnType`*: JsonValueRef[string]
    Parameter* = object
        `Name`*: string
        `Type`*: JsonValueRef[string] 
        `Attrs`*: seq[JsonValueRef[string]] # an array of many types
    Architecture* = enum
        `X86`
        `X64`
        Arm64
    Platform = enum
        `windows5.0` = "windows5.0"
        `windows5.1.2600` = "windows5.1.2600"
        `windows6.0.6000` = "windows6.0.6000"
        `windows6.1` = "windows6.1"
        `windows8.0` = "windows8.0"
        `windows8.1` = "windows8.1"
        `windows10.0.10240` = "windows10.0.10240"
        `windows10.0.10586` = "windows10.0.10586"
        `windows10.0.14393` = "windows10.0.14393"
        `windows10.0.15063` = "windows10.0.15063"
        `windows10.0.16299` = "windows10.0.16299"
        `windows10.0.17134` = "windows10.0.17134"
        `windows10.0.17763` = "windows10.0.17763"
        `windows10.0.19041` = "windows10.0.19041"
        `windowsServer2000` = "windowsServer2000"
        `windowsServer2003` = "windowsServer2003"
        `windowsServer2008` = "windowsServer2008"
        `windowsServer2012` = "windowsServer2012"
        `windowsServer2016` = "windowsServer2016"
    Function* = object
        `Attrs`*: seq[Attribute] # Don't know what this is. Assume same as others
        `Name`*: string
        `SetLastError`*: bool
        `DllImport`*: Option[string]
        `ReturnType`*: JsonValueRef[string] # Polymorphic apparently
        `Architectures`*: seq[Architecture]
        `Platform`*: Option[Platform]
        `Params`*: seq[Parameter]
        `ReturnAttrs`*: seq[Attribute]
    Metadata* = object
        `Constants`*: seq[Constant]
        `Types`*: seq[Type]
        `Functions`*: seq[Function]
        `UnicodeAliases`*: seq[string]

type
    MarshallingError* = object of CatchableError

proc marshal*(file: string): Metadata = 
    try:
        return Json.loadFile(file, Metadata)
    except UnexpectedValueError as e:
        raise newException(MarshallingError, &"Unepxected value in {file}:{e.line}|{e.col}")
    except UnexpectedField as e:
        raise newException(MarshallingError, &"Deserialized {e.deserializedType} for {e.encounteredField} in {file}:{e.line}|{e.col}")
    except UnexpectedTokenError as e:
        raise newException(MarshallingError, &"Encountered {e.encountedToken} but expected {e.expectedToken} in {file}:{e.line}|{e.col}")
    except IntOverflowError as e:
        raise newException(MarshallingError, &"Couldn't fit number as `int` {file}:{e.line}|{e.col}")