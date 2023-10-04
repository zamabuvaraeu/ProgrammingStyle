Option Explicit

Const SUBSYSTEM_CONSOLE = 0
Const SUBSYSTEM_WINDOW = 1
Const SUBSYSTEM_NATIVE = 2

Const OUTPUT_FILETYPE_EXE = 0
Const OUTPUT_FILETYPE_DLL = 1
Const OUTPUT_FILETYPE_LIBRARY = 2
Const OUTPUT_FILETYPE_WASM32 = 3
Const OUTPUT_FILETYPE_WASM64 = 4

Const CODE_EMITTER_GCC = 0
Const CODE_EMITTER_GAS = 1
Const CODE_EMITTER_GAS64 = 2
Const CODE_EMITTER_LLVM = 3
Const CODE_EMITTER_WASM32 = 4
Const CODE_EMITTER_WASM64 = 5

Const NOT_FIX_EMITTED_CODE = 0
Const FIX_EMITTED_CODE = 1

Const DEFINE_ANSI = 0
Const DEFINE_UNICODE = 1

Const WINVER_DEFAULT = 0
Const WINVER_XP = 0

' #define WINVER 0x0A00
' #define _WIN32_WINNT 0x0A00

' _WIN32_WINNT version constants

' #define _WIN32_WINNT_NT4                    0x0400 // Windows NT 4.0
' #define _WIN32_WINNT_WIN2K                  0x0500 // Windows 2000
' #define _WIN32_WINNT_WINXP                  0x0501 // Windows XP
' #define _WIN32_WINNT_WS03                   0x0502 // Windows Server 2003
' #define _WIN32_WINNT_WIN6                   0x0600 // Windows Vista
' #define _WIN32_WINNT_VISTA                  0x0600 // Windows Vista
' #define _WIN32_WINNT_WS08                   0x0600 // Windows Server 2008
' #define _WIN32_WINNT_LONGHORN               0x0600 // Windows Vista
' #define _WIN32_WINNT_WIN7                   0x0601 // Windows 7
' #define _WIN32_WINNT_WIN8                   0x0602 // Windows 8
' #define _WIN32_WINNT_WINBLUE                0x0603 // Windows 8.1
' #define _WIN32_WINNT_WINTHRESHOLD           0x0A00 // Windows 10
' #define _WIN32_WINNT_WIN10                  0x0A00 // Windows 10

Const DEFINE_RUNTIME = 0
Const DEFINE_WITHOUT_RUNTIME = 1

Const DEFINE_SINGLETHREADING_RUNTIME = 0
Const DEFINE_MULTITHREADING_RUNTIME = 1

Const LARGE_ADDRESS_UNAWARE = 0
Const LARGE_ADDRESS_AWARE = 1

Const Solidus = "\"
Const ReverseSolidus = "/"
Const MakefilePathSeparator = "$(PATH_SEP)"
Const MakefileMovePathSeparator = "$(MOVE_PATH_SEP)"
Const ReleaseDirPrefix = "$(OBJ_RELEASE_DIR)$(PATH_SEP)"
Const DebugDirPrefix = "$(OBJ_DEBUG_DIR)$(PATH_SEP)"
Const FileSuffix = "$(FILE_SUFFIX)"
Const ObjectFilesRelease = "OBJECTFILES_RELEASE"
Const ObjectFilesDebug = "OBJECTFILES_DEBUG"

Dim colArgs
Set colArgs = WScript.Arguments.Named

Dim MakefileFileName
MakefileFileName = GetMakefileNameParameter()

Dim SourceFolder
SourceFolder = GetSourceFolderParameter()

Dim CompilerPath
CompilerPath = GetCompilerPathParameter()

Dim FbcCompilerName
FbcCompilerName = GetFbcCompilerNameParameter()

Dim OutputFileName
OutputFileName = GetOutputFileNameParameter()

Dim MainModuleName
MainModuleName = GetMainModuleNameParameter()

Dim ExeType
ExeType = GetExeTypeParameter()

Dim FileSubsystem
FileSubsystem = GetFileSubsystemParameter()

Dim Emit
Emit = GetEmitterParameter()

Dim FixEmitted
FixEmitted = GetFixEmittedCodeParameter()

Dim Unicode
Unicode = GetUnicodeParameter()

Dim Runtime
Runtime = GetRuntimeParameter()

Dim AddressAware
AddressAware = GetAddressAwareParameter()

Dim ThreadingMode
ThreadingMode = GetThreadingModeParameter()

Dim UseSuffix
UseSuffix = GetUseFileSuffixParameter()

Dim FSO
Set FSO = CreateObject("Scripting.FileSystemObject")

Dim MakefileFileStream
Set MakefileFileStream = FSO.OpenTextFile(MakefileFileName, 2, True, 0)

WriteTargets MakefileFileStream
WriteCompilerToolChain MakefileFileStream
WriteProcessorArch MakefileFileStream
WriteOutputFilename MakefileFileStream, OutputFileName, ExeType, UseSuffix
WriteUtilsPath MakefileFileStream
WriteArchSpecifiedPath MakefileFileStream

WriteFbcFlags MakefileFileStream, MainModuleName, Emit, Unicode, FileSubsystem
WriteGccFlags MakefileFileStream, Emit
WriteAsmFlags MakefileFileStream
WriteGorcFlags MakefileFileStream
WriteLinkerFlags MakefileFileStream, FileSubsystem, AddressAware, Emit

WriteLinkerLibraryes MakefileFileStream, ThreadingMode, Emit
WriteIncludeFile MakefileFileStream, MainModuleName
WriteReleaseTarget MakefileFileStream
WriteDebugTarget MakefileFileStream
WriteCleanTarget MakefileFileStream
WriteCreateDirsTarget MakefileFileStream

WriteReleaseRule MakefileFileStream
WriteDebugRule MakefileFileStream

WriteAsmRule MakefileFileStream
WriteCRule MakefileFileStream
WriteBasRule MakefileFileStream, FixEmitted
WriteResourceRule MakefileFileStream

Set MakefileFileStream = Nothing
Set FSO = Nothing


Function GetMinimalWindowsVersionParameter()
	If colArgs.Exists("winver") Then
		GetMinimalWindowsVersionParameter = colArgs.Item("winver")
	Else
		GetMinimalWindowsVersionParameter = "Makefile"
	End If
End Function

Function GetMakefileNameParameter()
	If colArgs.Exists("makefile") Then
		GetMakefileNameParameter = colArgs.Item("makefile")
	Else
		GetMakefileNameParameter = "Makefile"
	End If
End Function

Function GetFbcCompilerNameParameter()
	If colArgs.Exists("fbc") Then
		GetFbcCompilerNameParameter = colArgs.Item("fbc")
	Else
		GetFbcCompilerNameParameter = "fbc64.exe"
	End If
End Function

Function GetCompilerPathParameter()
	If colArgs.Exists("fbc-path") Then
		GetCompilerPathParameter = colArgs.Item("fbc-path")
	Else
		GetCompilerPathParameter = "C:\Program Files (x86)\FreeBASIC-1.10.0-winlibs-gcc-9.3.0"
	End If
End Function

Function GetSourceFolderParameter()
	If colArgs.Exists("src") Then
		GetSourceFolderParameter = colArgs.Item("src")
	Else
		GetSourceFolderParameter = "src"
	End If
End Function

Function GetMainModuleNameParameter()
	If colArgs.Exists("module") Then
		GetMainModuleNameParameter = colArgs.Item("module")
	Else
		GetMainModuleNameParameter = OutputFileName
	End If
End Function

Function GetExeTypeParameter()
	If colArgs.Exists("exetype") Then
		Dim t1
		t1 = colArgs.Item("exetype")
		Select Case t1
			Case "exe"
				GetExeTypeParameter = OUTPUT_FILETYPE_EXE
			Case "dll"
				GetExeTypeParameter = OUTPUT_FILETYPE_DLL
			Case "lib"
				GetExeTypeParameter = OUTPUT_FILETYPE_LIBRARY
			Case "wasm32"
				GetExeTypeParameter = OUTPUT_FILETYPE_WASM32
			Case "wasm64"
				GetExeTypeParameter = OUTPUT_FILETYPE_WASM64
			Case Else
				GetExeTypeParameter = OUTPUT_FILETYPE_EXE
		End Select
	Else
		GetExeTypeParameter = OUTPUT_FILETYPE_EXE
	End If
End Function

Function GetFileSubsystemParameter()
	If colArgs.Exists("subsystem") Then
		Dim t2
		t2 = colArgs.Item("subsystem")
		Select Case t2
			Case "console"
				GetFileSubsystemParameter = SUBSYSTEM_CONSOLE
			Case "windows"
				GetFileSubsystemParameter = SUBSYSTEM_WINDOW
			Case "native"
				GetFileSubsystemParameter = SUBSYSTEM_NATIVE
			Case Else
				GetFileSubsystemParameter = SUBSYSTEM_CONSOLE
		End Select
	Else
		GetFileSubsystemParameter = SUBSYSTEM_CONSOLE
	End If
End Function

Function GetEmitterParameter()
	If colArgs.Exists("emitter") Then
		Dim t3
		t3 = colArgs.Item("emitter")
		Select Case t3
			Case "gcc"
				GetEmitterParameter = CODE_EMITTER_GCC
			Case "gas"
				GetEmitterParameter = CODE_EMITTER_GAS
			Case "gas64"
				GetEmitterParameter = CODE_EMITTER_GAS64
			Case "llvm"
				GetEmitterParameter = CODE_EMITTER_LLVM
			Case "wasm32"
				GetEmitterParameter = CODE_EMITTER_WASM32
			Case "wasm64"
				GetEmitterParameter = CODE_EMITTER_WASM64
			Case Else
				GetEmitterParameter = CODE_EMITTER_GCC
		End Select
	Else
		GetEmitterParameter = CODE_EMITTER_GCC
	End If
End Function

Function GetUnicodeParameter()
	If colArgs.Exists("unicode") Then
		Dim t4
		t4 = colArgs.Item("unicode")
		Select Case t4
			Case "true"
				GetUnicodeParameter = DEFINE_UNICODE
			Case "false"
				GetUnicodeParameter = DEFINE_ANSI
			Case Else
				GetUnicodeParameter = DEFINE_ANSI
		End Select
	Else
		GetUnicodeParameter = DEFINE_ANSI
	End If
End Function

Function GetRuntimeParameter()
	If colArgs.Exists("wrt") Then
		Dim t5
		t5 = colArgs.Item("wrt")
		Select Case t5
			Case "true"
				GetRuntimeParameter = DEFINE_WITHOUT_RUNTIME
			Case "false"
				GetRuntimeParameter = DEFINE_RUNTIME
			Case Else
				GetRuntimeParameter = DEFINE_RUNTIME
		End Select
	Else
		GetRuntimeParameter = DEFINE_RUNTIME
	End If
End Function

Function GetAddressAwareParameter()
	If colArgs.Exists("addressaware") Then
		Dim t6
		t6 = colArgs.Item("addressaware")
		Select Case t6
			Case "true"
				GetAddressAwareParameter = LARGE_ADDRESS_AWARE
			Case "false"
				GetAddressAwareParameter = LARGE_ADDRESS_UNAWARE
			Case Else
				GetAddressAwareParameter = LARGE_ADDRESS_UNAWARE
		End Select
	Else
		GetAddressAwareParameter = LARGE_ADDRESS_UNAWARE
	End If
End Function

Function GetThreadingModeParameter()
	If colArgs.Exists("multithreading") Then
		Dim t7
		t7 = colArgs.Item("multithreading")
		Select Case t7
			Case "true"
				GetThreadingModeParameter = DEFINE_MULTITHREADING_RUNTIME
			Case "false"
				GetThreadingModeParameter = DEFINE_SINGLETHREADING_RUNTIME
			Case Else
				GetThreadingModeParameter = DEFINE_SINGLETHREADING_RUNTIME
		End Select
	Else
		GetThreadingModeParameter = DEFINE_SINGLETHREADING_RUNTIME
	End If
End Function

Function GetUseFileSuffixParameter()
	If colArgs.Exists("usefilesuffix") Then
		Dim t7
		t7 = colArgs.Item("usefilesuffix")
		Select Case t7
			Case "true"
				GetUseFileSuffixParameter = True
			Case "false"
				GetUseFileSuffixParameter = False
			Case Else
				GetUseFileSuffixParameter = True
		End Select
	Else
		GetUseFileSuffixParameter = True
	End If
End Function

Function GetOutputFileNameParameter()
	If colArgs.Exists("out") Then
		GetOutputFileNameParameter = colArgs.Item("out")
	Else
		GetOutputFileNameParameter = "a"
	End If
End Function

Function GetFixEmittedCodeParameter()
	If colArgs.Exists("fix") Then
		Dim t7
		t7 = colArgs.Item("fix")
		Select Case t7
			Case "true"
				GetFixEmittedCodeParameter = FIX_EMITTED_CODE
			Case "false"
				GetFixEmittedCodeParameter = NOT_FIX_EMITTED_CODE
			Case Else
				GetFixEmittedCodeParameter = NOT_FIX_EMITTED_CODE
		End Select
	Else
		GetFixEmittedCodeParameter = NOT_FIX_EMITTED_CODE
	End If
End Function

Function CodeGenerationToString(Emitter)
	
	Dim EmitterParam
	
	Select Case Emitter
		Case CODE_EMITTER_GCC
			EmitterParam = "-gen gcc"
		Case CODE_EMITTER_GAS
			EmitterParam = "-gen gas"
		Case CODE_EMITTER_GAS64
			EmitterParam = "-gen gas64"
		Case CODE_EMITTER_LLVM
			EmitterParam = "-gen llvm"
		Case CODE_EMITTER_WASM32
			EmitterParam = "-gen gcc"
		Case CODE_EMITTER_WASM64
			EmitterParam = "-gen gcc"
	End Select
	
	CodeGenerationToString = EmitterParam
	
End Function

Function CreateCompilerParams(Emitter, Unicode, Runtime, SubSystem, MainModule)
	
	Dim EmitterParam
	EmitterParam = CodeGenerationToString(Emitter)
	
	Dim UnicodeFlag
	Select Case Unicode
		Case DEFINE_ANSI
			UnicodeFlag = ""
		Case DEFINE_UNICODE
			UnicodeFlag = "-d UNICODE"
	End Select
	
	Dim RuntimeFlag
	Select Case Runtime
		Case DEFINE_RUNTIME
			RuntimeFlag = ""
		Case DEFINE_WITHOUT_RUNTIME
			RuntimeFlag = "-d WITHOUT_RUNTIME"
	End Select
	
	Dim SubSystemParam
	If SubSystem = SUBSYSTEM_WINDOW Then
		SubSystemParam = "-s gui"
	Else
		SubSystemParam = "-s console"
	End If
	
	Dim CompilerParam
	CompilerParam = EmitterParam & " " & UnicodeFlag & " " & _
		RuntimeFlag & " " & SubSystemParam & " " & _
	"-maxerr 1 -r -O 0 -showincludes -m " & MainModule
	
	CreateCompilerParams = CompilerParam
	
End Function

Sub WriteTargets(MakefileStream)
	MakefileStream.WriteLine ".PHONY: all debug release clean createdirs"
	MakefileStream.WriteLine 
	MakefileStream.WriteLine "all: release debug"
	MakefileStream.WriteLine 
End Sub

Sub WriteCompilerToolChain(MakefileStream)
	MakefileStream.WriteLine "FBC ?= fbc.exe"
	MakefileStream.WriteLine "CC ?= gcc.exe"
	MakefileStream.WriteLine "AS ?= as.exe"
	MakefileStream.WriteLine "AR ?= ar.exe"
	MakefileStream.WriteLine "GORC ?= GoRC.exe"
	MakefileStream.WriteLine "LD ?= ld.exe"
	MakefileStream.WriteLine "DLL_TOOL ?= dlltool.exe"
	MakefileStream.WriteLine "LIB_DIR ?="
	MakefileStream.WriteLine "INC_DIR ?="
	MakefileStream.WriteLine "LD_SCRIPT ?="
	MakefileStream.WriteLine 
End Sub

Sub WriteProcessorArch(MakefileStream)
	MakefileStream.WriteLine "TARGET_TRIPLET ?="
	MakefileStream.WriteLine "MARCH ?= native"
	MakefileStream.WriteLine 
End Sub

Sub WriteOutputFilename(MakefileStream, OutputFilename, FileType, UseFileSuffix)
	
	Dim Extension
	Select Case FileType
		Case OUTPUT_FILETYPE_EXE
			Extension = ".exe"
		Case OUTPUT_FILETYPE_DLL
			Extension = ".dll"
		Case OUTPUT_FILETYPE_LIBRARY
			Extension = ".a"
		Case OUTPUT_FILETYPE_WASM32
			Extension = ".wasm"
		Case OUTPUT_FILETYPE_WASM64
			Extension = ".wasm"
	End Select
	
	' TODO Add UNICODE and _UNICODE to file suffix
	' TODO Add WINVER and _WIN32_WINNT to file suffix
	MakefileStream.WriteLine "USE_RUNTIME ?= TRUE"
	MakefileStream.WriteLine "FBC_VER ?= _FBC1100"
	MakefileStream.WriteLine "GCC_VER ?= _GCC0930"
	MakefileStream.WriteLine "ifeq ($(USE_RUNTIME),TRUE)"
	MakefileStream.WriteLine "RUNTIME = _RT"
	MakefileStream.WriteLine "else"
	MakefileStream.WriteLine "RUNTIME = _WRT"
	MakefileStream.WriteLine "endif"
	
	If UseFileSuffix Then
		MakefileStream.WriteLine "FILE_SUFFIX=$(GCC_VER)$(FBC_VER)$(RUNTIME)"
	End If
	
	MakefileStream.WriteLine "OUTPUT_FILE_NAME=" & OutputFilename & "$(FILE_SUFFIX)" & Extension
	MakefileStream.WriteLine 
End Sub

Sub WriteUtilsPath(MakefileStream)
	MakefileStream.WriteLine "PATH_SEP ?= /"
	MakefileStream.WriteLine "MOVE_PATH_SEP ?= \\"
	MakefileStream.WriteLine 
	MakefileStream.WriteLine "MOVE_COMMAND ?= cmd.exe /c move /y"
	MakefileStream.WriteLine "DELETE_COMMAND ?= cmd.exe /c del /f /q"
	MakefileStream.WriteLine "MKDIR_COMMAND ?= cmd.exe /c mkdir"
	MakefileStream.WriteLine "SCRIPT_COMMAND ?= cscript.exe //nologo fix-emitted-code.vbs"
	MakefileStream.WriteLine 
End Sub

Sub WriteArchSpecifiedPath(MakefileStream)
	MakefileStream.WriteLine "ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)"
	MakefileStream.WriteLine "BIN_DEBUG_DIR ?= bin$(PATH_SEP)Debug$(PATH_SEP)x64"
	MakefileStream.WriteLine "BIN_RELEASE_DIR ?= bin$(PATH_SEP)Release$(PATH_SEP)x64"
	MakefileStream.WriteLine "OBJ_DEBUG_DIR ?= obj$(PATH_SEP)Debug$(PATH_SEP)x64"
	MakefileStream.WriteLine "OBJ_RELEASE_DIR ?= obj$(PATH_SEP)Release$(PATH_SEP)x64"
	MakefileStream.WriteLine "BIN_DEBUG_DIR_MOVE ?= bin$(MOVE_PATH_SEP)Debug$(MOVE_PATH_SEP)x64"
	MakefileStream.WriteLine "BIN_RELEASE_DIR_MOVE ?= bin$(MOVE_PATH_SEP)Release$(MOVE_PATH_SEP)x64"
	MakefileStream.WriteLine "OBJ_DEBUG_DIR_MOVE ?= obj$(MOVE_PATH_SEP)Debug$(MOVE_PATH_SEP)x64"
	MakefileStream.WriteLine "OBJ_RELEASE_DIR_MOVE ?= obj$(MOVE_PATH_SEP)Release$(MOVE_PATH_SEP)x64"
	MakefileStream.WriteLine "else"
	MakefileStream.WriteLine "BIN_DEBUG_DIR ?= bin$(PATH_SEP)Debug$(PATH_SEP)x86"
	MakefileStream.WriteLine "BIN_RELEASE_DIR ?= bin$(PATH_SEP)Release$(PATH_SEP)x86"
	MakefileStream.WriteLine "OBJ_DEBUG_DIR ?= obj$(PATH_SEP)Debug$(PATH_SEP)x86"
	MakefileStream.WriteLine "OBJ_RELEASE_DIR ?= obj$(PATH_SEP)Release$(PATH_SEP)x86"
	MakefileStream.WriteLine "BIN_DEBUG_DIR_MOVE ?= bin$(MOVE_PATH_SEP)Debug$(MOVE_PATH_SEP)x86"
	MakefileStream.WriteLine "BIN_RELEASE_DIR_MOVE ?= bin$(MOVE_PATH_SEP)Release$(MOVE_PATH_SEP)x86"
	MakefileStream.WriteLine "OBJ_DEBUG_DIR_MOVE ?= obj$(MOVE_PATH_SEP)Debug$(MOVE_PATH_SEP)x86"
	MakefileStream.WriteLine "OBJ_RELEASE_DIR_MOVE ?= obj$(MOVE_PATH_SEP)Release$(MOVE_PATH_SEP)x86"
	MakefileStream.WriteLine "endif"
	MakefileStream.WriteLine 
End Sub

Sub WriteFbcFlags(MakefileStream, MainModule, Emitter, Unicode, SubSystem)
	
	Dim EmitterParam
	EmitterParam = CodeGenerationToString(Emitter)
	
	Dim UnicodeFlag
	Select Case Unicode
		Case DEFINE_ANSI
			UnicodeFlag = ""
		Case DEFINE_UNICODE
			UnicodeFlag = "FBCFLAGS+=-d UNICODE"
	End Select
	
	Dim SubSystemParam
	If SubSystem = SUBSYSTEM_WINDOW Then
		SubSystemParam = "-s gui"
	Else
		SubSystemParam = "-s console"
	End If
	
	MakefileStream.WriteLine "FBCFLAGS+=" & EmitterParam
	MakefileStream.WriteLine UnicodeFlag
	MakefileStream.WriteLine "ifeq ($(USE_RUNTIME),TRUE)"
	MakefileStream.WriteLine "FBCFLAGS+=-m " & MainModule
	MakefileStream.WriteLine "else"
	MakefileStream.WriteLine "FBCFLAGS+=-d WITHOUT_RUNTIME"
	MakefileStream.WriteLine "endif"
	MakefileStream.WriteLine "FBCFLAGS+=-w error -maxerr 1"
	MakefileStream.WriteLine "FBCFLAGS+=-i " & SourceFolder
	MakefileStream.WriteLine "ifneq ($(INC_DIR),)"
	MakefileStream.WriteLine "FBCFLAGS+=-i ""$(INC_DIR)"""
	MakefileStream.WriteLine "endif"
	MakefileStream.WriteLine "FBCFLAGS+=-r"
	MakefileStream.WriteLine "FBCFLAGS+=" & SubSystemParam
	MakefileStream.WriteLine "FBCFLAGS+=-O 0"
	MakefileStream.WriteLine "FBCFLAGS_DEBUG+=-g"
	MakefileStream.WriteLine "debug: FBCFLAGS+=$(FBCFLAGS_DEBUG)"
	MakefileStream.WriteLine 
End Sub

Sub WriteGccFlags(MakefileStream, Emitter)
	
	Select Case Emitter
		Case CODE_EMITTER_WASM32, CODE_EMITTER_WASM64
			' MakefileStream.WriteLine "CFLAGS+=-emit-llvm"
		Case Else
			MakefileStream.WriteLine "ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)"
			MakefileStream.WriteLine "CFLAGS+=-m64"
			MakefileStream.WriteLine "else"
			MakefileStream.WriteLine "CFLAGS+=-m32"
			MakefileStream.WriteLine "endif"
			
			MakefileStream.WriteLine "CFLAGS+=-march=$(MARCH)"
			
	End Select
	
	Select Case Emitter
		
		Case CODE_EMITTER_WASM32
			MakefileStream.WriteLine "CFLAGS+=--target=wasm32"
			
		Case CODE_EMITTER_WASM64
			MakefileStream.WriteLine "CFLAGS+=--target=wasm64"
			
		Case Else
		
	End Select
	
	MakefileStream.WriteLine "CFLAGS+=-pipe"
	MakefileStream.WriteLine "CFLAGS+=-Wall -Werror -Wextra -pedantic"
	MakefileStream.WriteLine "CFLAGS+=-Wno-unused-label -Wno-unused-function"
	MakefileStream.WriteLine "CFLAGS+=-Wno-unused-parameter -Wno-unused-variable"
	MakefileStream.WriteLine "CFLAGS+=-Wno-dollar-in-identifier-extension"
	MakefileStream.WriteLine "CFLAGS+=-Wno-language-extension-token"
	MakefileStream.WriteLine "CFLAGS+=-Wno-parentheses-equality"
	
	MakefileStream.WriteLine "CFLAGS_DEBUG+=-g -O0"
	
	MakefileStream.WriteLine "FLTO ?="
	
	MakefileStream.WriteLine "release: CFLAGS+=$(CFLAGS_RELEASE)"
	MakefileStream.WriteLine "release: CFLAGS+=-fno-math-errno -fno-exceptions"
	MakefileStream.WriteLine "release: CFLAGS+=-fno-unwind-tables -fno-asynchronous-unwind-tables"
	MakefileStream.WriteLine "release: CFLAGS+=-O3 -fno-ident -fdata-sections -ffunction-sections"
	
	MakefileStream.WriteLine "ifneq ($(FLTO),)"
	MakefileStream.WriteLine "release: CFLAGS+=$(FLTO)"
	MakefileStream.WriteLine "endif"
	
	MakefileStream.WriteLine "debug: CFLAGS+=$(CFLAGS_DEBUG)"
	
	MakefileStream.WriteLine 
End Sub

Sub WriteAsmFlags(MakefileStream)
	MakefileStream.WriteLine "ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)"
	MakefileStream.WriteLine "ASFLAGS+=--64"
	MakefileStream.WriteLine "else"
	MakefileStream.WriteLine "ASFLAGS+=--32"
	MakefileStream.WriteLine "endif"
	MakefileStream.WriteLine "ASFLAGS_DEBUG+="
	MakefileStream.WriteLine "release: ASFLAGS+=--strip-local-absolute"
	MakefileStream.WriteLine "debug: ASFLAGS+=$(ASFLAGS_DEBUG)"
	MakefileStream.WriteLine 
End Sub

Sub WriteGorcFlags(MakefileStream)
	MakefileStream.WriteLine "ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)"
	MakefileStream.WriteLine "GORCFLAGS+=/machine X64"
	MakefileStream.WriteLine "endif"
	MakefileStream.WriteLine "GORCFLAGS+=/ni /o /d FROM_MAKEFILE"
	MakefileStream.WriteLine "GORCFLAGS_DEBUG=/d DEBUG"
	MakefileStream.WriteLine "debug: GORCFLAGS+=$(GORCFLAGS_DEBUG)"
	MakefileStream.WriteLine 
End Sub

Sub WriteLinkerFlags(MakefileStream, SubSystem, LargeAddress, Emitter)
	
	Select Case Emitter
		Case CODE_EMITTER_WASM32, CODE_EMITTER_WASM64
			' Set maximum stack size to 8MiB
			' -z stack-size=8388608
			
			' --initial-memory=<value> Initial size of the linear memory
			' --max-memory=<value>     Maximum size of the linear memory
			' --max-memory=8388608
			
			MakefileStream.WriteLine "LDFLAGS+=-m wasm32"
			MakefileStream.WriteLine "LDFLAGS+=--allow-undefined"
			MakefileStream.WriteLine "LDFLAGS+=--no-entry"
			MakefileStream.WriteLine "LDFLAGS+=--export-all"
			
			MakefileStream.WriteLine "LDFLAGS+=-L ."
			MakefileStream.WriteLine "LDFLAGS+=-L ""$(LIB_DIR)"""
			
			MakefileStream.WriteLine "release: LDFLAGS+=--lto-O3 --gc-sections"
		Case Else
			MakefileStream.WriteLine "ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)"
			MakefileStream.WriteLine "ifeq ($(USE_RUNTIME),FALSE)"
			MakefileStream.WriteLine "LDFLAGS+=-e EntryPoint"
			MakefileStream.WriteLine "endif"
			MakefileStream.WriteLine "LDFLAGS+=-m i386pep"
			MakefileStream.WriteLine "else"
			MakefileStream.WriteLine "ifeq ($(USE_RUNTIME),FALSE)"
			MakefileStream.WriteLine "LDFLAGS+=-e _EntryPoint@0"
			MakefileStream.WriteLine "endif"
			MakefileStream.WriteLine "LDFLAGS+=-m i386pe"
			
			Select Case LargeAddress
				Case LARGE_ADDRESS_UNAWARE
				Case LARGE_ADDRESS_AWARE
					MakefileStream.WriteLine "LDFLAGS+=--large-address-aware"
			End Select
			
			MakefileStream.WriteLine "endif"
			
			Select Case SubSystem
				Case SUBSYSTEM_CONSOLE
					MakefileStream.WriteLine "LDFLAGS+=-subsystem console"
				Case SUBSYSTEM_WINDOW
					MakefileStream.WriteLine "LDFLAGS+=-subsystem windows"
				Case SUBSYSTEM_NATIVE
					MakefileStream.WriteLine "LDFLAGS+=-subsystem native"
			End Select
			
			MakefileStream.WriteLine "LDFLAGS+=--no-seh --nxcompat"
			
			MakefileStream.WriteLine "LDFLAGS+=-L ."
			MakefileStream.WriteLine "LDFLAGS+=-L ""$(LIB_DIR)"""
			
			MakefileStream.WriteLine "ifneq ($(LD_SCRIPT),)"
			MakefileStream.WriteLine "LDFLAGS+=-T ""$(LD_SCRIPT)"""
			MakefileStream.WriteLine "endif"
			
			MakefileStream.WriteLine "release: LDFLAGS+=-s --gc-sections"
			
			MakefileStream.WriteLine "debug: LDFLAGS+=$(LDFLAGS_DEBUG)"
			MakefileStream.WriteLine "debug: LDLIBS+=$(LDLIBS_DEBUG)"
	End Select
	
	MakefileStream.WriteLine 
	
End Sub

Sub WriteLinkerLibraryes(MakefileStream, Multithreading, Emitter)
	
	Select Case Emitter
		Case CODE_EMITTER_WASM32, CODE_EMITTER_WASM64
			
		Case Else
			MakefileStream.WriteLine "ifeq ($(USE_RUNTIME),TRUE)"
			' For profile
			' MakefileStream.WriteLine "LDLIBSBEGIN+=gcrt2.o"
			MakefileStream.WriteLine "LDLIBSBEGIN+=""$(LIB_DIR)\crt2.o"""
			MakefileStream.WriteLine "LDLIBSBEGIN+=""$(LIB_DIR)\crtbegin.o"""
			MakefileStream.WriteLine "LDLIBSBEGIN+=""$(LIB_DIR)\fbrt0.o"""
			MakefileStream.WriteLine "endif"
			
			
			MakefileStream.WriteLine "LDLIBS+=--start-group"
			MakefileStream.WriteLine "LDLIBS+=-ladvapi32 -lcrypt32 -lkernel32 -lmsvcrt"
			MakefileStream.WriteLine "LDLIBS+=-lole32 -loleaut32"
			MakefileStream.WriteLine "LDLIBS+=-lmswsock -lws2_32"
			MakefileStream.WriteLine "LDLIBS+=-lshell32 -lshlwapi -lgdi32 -luser32 -lcomctl32"
			
			MakefileStream.WriteLine "ifeq ($(USE_RUNTIME),TRUE)"
			
			' For Multithreading
			Select Case Multithreading
				Case DEFINE_SINGLETHREADING_RUNTIME
					MakefileStream.WriteLine "LDLIBS+=-lfb"
				Case DEFINE_MULTITHREADING_RUNTIME
					MakefileStream.WriteLine "LDLIBS+=-lfbmt"
			End Select
			
			MakefileStream.WriteLine "LDLIBS+=-luuid"
			
			MakefileStream.WriteLine "endif"
			
			' For profile
			' MakefileStream.WriteLine "LDLIBS_DEBUG+=-lgmon"
			MakefileStream.WriteLine "LDLIBS_DEBUG+=-lgcc -lmingw32 -lmingwex -lmoldname -lgcc_eh"
			
			MakefileStream.WriteLine "ifeq ($(USE_RUNTIME),TRUE)"
			MakefileStream.WriteLine "LDLIBS+=-lgcc -lmingw32 -lmingwex -lmoldname -lgcc_eh"
			MakefileStream.WriteLine "endif"

			MakefileStream.WriteLine "LDLIBS+=--end-group"
			
			MakefileStream.WriteLine "ifeq ($(USE_RUNTIME),TRUE)"
			MakefileStream.WriteLine "LDLIBSEND+=""$(LIB_DIR)\crtend.o"""
			MakefileStream.WriteLine "endif"
	End Select
	
	MakefileStream.WriteLine
	
End Sub

Sub WriteIncludeFile(MakefileStream, MainModule)
	Dim SrcFolder
	Set SrcFolder = FSO.GetFolder(SourceFolder)
	
	Dim File
	For Each File In SrcFolder.Files
		Dim ext
		ext = FSO.GetExtensionName(File.Path)
		CreateDependencies MakefileStream, File, ext, File.Path, MainModule
	Next
	
	Set SrcFolder = Nothing
	
	MakefileStream.WriteLine 
End Sub

Sub WriteReleaseTarget(MakefileStream)
	' MakefileStream.WriteLine 
	' MakefileStream.WriteLine "# $@ - target name"
	' MakefileStream.WriteLine "# $^ - set of dependent files"
	' MakefileStream.WriteLine "# $< - name of first dependency"
	' MakefileStream.WriteLine "# % - pattern"
	' MakefileStream.WriteLine "# $* - variable pattern"
	' MakefileStream.WriteLine 
	MakefileStream.WriteLine "release: $(BIN_RELEASE_DIR)$(PATH_SEP)$(OUTPUT_FILE_NAME)"
	MakefileStream.WriteLine 
End Sub

Sub WriteDebugTarget(MakefileStream)
	MakefileStream.WriteLine "debug: $(BIN_DEBUG_DIR)$(PATH_SEP)$(OUTPUT_FILE_NAME)"
	MakefileStream.WriteLine 
End Sub

Sub WriteCleanTarget(MakefileStream)
	MakefileStream.WriteLine "clean:"
	MakefileStream.WriteLine "	$(DELETE_COMMAND) $(OBJ_RELEASE_DIR_MOVE)$(MOVE_PATH_SEP)*$(FILE_SUFFIX).c"
	MakefileStream.WriteLine "	$(DELETE_COMMAND) $(OBJ_DEBUG_DIR_MOVE)$(MOVE_PATH_SEP)*$(FILE_SUFFIX).c"
	MakefileStream.WriteLine "	$(DELETE_COMMAND) $(OBJ_RELEASE_DIR_MOVE)$(MOVE_PATH_SEP)*$(FILE_SUFFIX).asm"
	MakefileStream.WriteLine "	$(DELETE_COMMAND) $(OBJ_DEBUG_DIR_MOVE)$(MOVE_PATH_SEP)*$(FILE_SUFFIX).asm"
	MakefileStream.WriteLine "	$(DELETE_COMMAND) $(OBJ_RELEASE_DIR_MOVE)$(MOVE_PATH_SEP)*$(FILE_SUFFIX).o"
	MakefileStream.WriteLine "	$(DELETE_COMMAND) $(OBJ_DEBUG_DIR_MOVE)$(MOVE_PATH_SEP)*$(FILE_SUFFIX).o"
	MakefileStream.WriteLine "	$(DELETE_COMMAND) $(OBJ_RELEASE_DIR_MOVE)$(MOVE_PATH_SEP)*$(FILE_SUFFIX).obj"
	MakefileStream.WriteLine "	$(DELETE_COMMAND) $(OBJ_DEBUG_DIR_MOVE)$(MOVE_PATH_SEP)*$(FILE_SUFFIX).obj"
	MakefileStream.WriteLine "	$(DELETE_COMMAND) $(BIN_RELEASE_DIR_MOVE)$(MOVE_PATH_SEP)$(OUTPUT_FILE_NAME)"
	MakefileStream.WriteLine "	$(DELETE_COMMAND) $(BIN_DEBUG_DIR_MOVE)$(MOVE_PATH_SEP)$(OUTPUT_FILE_NAME)"
	MakefileStream.WriteLine 
End Sub

Sub WriteCreateDirsTarget(MakefileStream)
	MakefileStream.WriteLine "createdirs:"
	MakefileStream.WriteLine "	$(MKDIR_COMMAND) $(BIN_DEBUG_DIR_MOVE)"
	MakefileStream.WriteLine "	$(MKDIR_COMMAND) $(BIN_RELEASE_DIR_MOVE)"
	MakefileStream.WriteLine "	$(MKDIR_COMMAND) $(OBJ_DEBUG_DIR_MOVE)"
	MakefileStream.WriteLine "	$(MKDIR_COMMAND) $(OBJ_RELEASE_DIR_MOVE)"
	MakefileStream.WriteLine 
End Sub

Sub WriteReleaseRule(MakefileStream)
	MakefileStream.WriteLine "$(BIN_RELEASE_DIR)$(PATH_SEP)$(OUTPUT_FILE_NAME): $(OBJECTFILES_RELEASE)"
	MakefileStream.WriteLine "	$(LD) $(LDFLAGS) $(LDLIBSBEGIN) $^ $(LDLIBS) $(LDLIBSEND) -o $@"
	MakefileStream.WriteLine 
End Sub

Sub WriteDebugRule(MakefileStream)
	MakefileStream.WriteLine "$(BIN_DEBUG_DIR)$(PATH_SEP)$(OUTPUT_FILE_NAME): $(OBJECTFILES_DEBUG)"
	MakefileStream.WriteLine "	$(LD) $(LDFLAGS) $(LDLIBSBEGIN) $^ $(LDLIBS) $(LDLIBSEND) -o $@"
	MakefileStream.WriteLine 
End Sub

Sub WriteAsmRule(MakefileStream)
	MakefileStream.WriteLine "$(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).o: $(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).asm"
	MakefileStream.WriteLine "	$(AS) $(ASFLAGS) -o $@ $<"
	MakefileStream.WriteLine
	MakefileStream.WriteLine "$(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).o: $(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).asm"
	MakefileStream.WriteLine "	$(AS) $(ASFLAGS) -o $@ $<"
	MakefileStream.WriteLine 
End Sub

Sub WriteCRule(MakefileStream)
	MakefileStream.WriteLine "$(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).asm: $(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).c"
	MakefileStream.WriteLine "	$(CC) $(EXTRA_CFLAGS) $(CFLAGS) -o $@ $<"
	MakefileStream.WriteLine
	MakefileStream.WriteLine "$(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).asm: $(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).c"
	MakefileStream.WriteLine "	$(CC) $(EXTRA_CFLAGS) $(CFLAGS) -o $@ $<"
	MakefileStream.WriteLine 
End Sub

Function GetSourceFolderWithPathSep(strLine)
	Dim Length
	Length = Len(strLine)
	
	Dim LastChar
	LastChar = Mid(strLine, Length, 1)
	
	If LastChar = "\" Then
		GetSourceFolderWithPathSep = strLine
	Else
		GetSourceFolderWithPathSep = strLine & "\"
	End If
End Function

Sub WriteBasRule(MakefileStream, NeedFixEmittedCode)
	Dim SourceFolderWithPathSep
	SourceFolderWithPathSep = GetSourceFolderWithPathSep(SourceFolder)
	
	Dim AnyBasFile
	AnyBasFile = ReplaceSolidusToPathSeparator(SourceFolderWithPathSep) & "%.bas"
	
	Dim AnyCFile
	AnyCFile = ReplaceSolidusToMovePathSeparator(SourceFolderWithPathSep) & "$*.c"
	
	MakefileStream.WriteLine "$(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).c: " & AnyBasFile
	MakefileStream.WriteLine "	$(FBC) $(FBCFLAGS) $<"
	If NeedFixEmittedCode = FIX_EMITTED_CODE Then
		MakefileStream.WriteLine "	$(SCRIPT_COMMAND) /release " & AnyCFile
	End If
	MakefileStream.WriteLine "	$(MOVE_COMMAND) " & AnyCFile & " $(OBJ_RELEASE_DIR_MOVE)$(MOVE_PATH_SEP)$*$(FILE_SUFFIX).c"
	MakefileStream.WriteLine
	
	MakefileStream.WriteLine "$(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).c: " & AnyBasFile
	MakefileStream.WriteLine "	$(FBC) $(FBCFLAGS) $<"
	If NeedFixEmittedCode = FIX_EMITTED_CODE Then
		MakefileStream.WriteLine "	$(SCRIPT_COMMAND) /debug " & AnyCFile
	End If
	MakefileStream.WriteLine "	$(MOVE_COMMAND) " & AnyCFile & " $(OBJ_DEBUG_DIR_MOVE)$(MOVE_PATH_SEP)$*$(FILE_SUFFIX).c"
	MakefileStream.WriteLine 
End Sub

Sub WriteResourceRule(MakefileStream)
	MakefileStream.WriteLine "$(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).obj: src$(PATH_SEP)%.RC"
	MakefileStream.WriteLine "	$(GORC) $(GORCFLAGS) /fo $@ $<"
	MakefileStream.WriteLine
	MakefileStream.WriteLine "$(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).obj: src$(PATH_SEP)%.RC"
	MakefileStream.WriteLine "	$(GORC) $(GORCFLAGS) /fo $@ $<"
	MakefileStream.WriteLine 
End Sub

Sub RemoveVerticalLine(LinesArray)
	Const VSPattern = "|"
	' Удалим все вхождения "|"
	Dim i
	For i = LBound(LinesArray) To UBound(LinesArray)
		Dim Finded
		Finded = InStr(LinesArray(i), VSPattern)
		Do While Finded
			LinesArray(i) = Replace(LinesArray(i), VSPattern, "")
			Finded = InStr(LinesArray(i), VSPattern)
		Loop
		LinesArray(i) = Trim(LinesArray(i))
	Next
End Sub

Sub RemoveOmmittedIncludes(LinesArray)
	' Если строка в списке в виде "(filename.bi)"
	' мы её обнуляем
	Dim i
	For i = LBound(LinesArray) To UBound(LinesArray)
		Dim First
		First = Mid(LinesArray(i), 1, 1)
		If First = "(" Then
			Dim Length
			Length = Len(LinesArray(i))
			Dim Last
			Last = Mid(LinesArray(i), Length, 1)
			If Last = ")" Then
				LinesArray(i) = ""
			End If
		End If
	Next
End Sub

Sub RemoveDefaultIncludes(LinesArray)
	' заголовочные файлы в системном каталоге обнуляем
	Dim i
	For i = LBound(LinesArray) To UBound(LinesArray)
		Dim Finded
		Finded = InStr(LinesArray(i), CompilerPath & Solidus & "inc")
		If Finded Then
			LinesArray(i) = ""
		End If
	Next
End Sub

Function ReplaceSolidusToPathSeparator(strLine)
	' заменяем "\" на "$(PATH_SEP)"
	Dim strLine1
	strLine1 = strLine
	
	Dim Finded
	Finded = InStr(strLine1, Solidus)
	Do While Finded
		strLine1 = Replace(strLine1, Solidus, MakefilePathSeparator)
		Finded = InStr(strLine1, Solidus)
	Loop
	
	ReplaceSolidusToPathSeparator = strLine1
	
End Function

Function ReplaceSolidusToMovePathSeparator(strLine)
	' заменяем "\" на "$(MOVE_PATH_SEP)"
	Dim strLine1
	strLine1 = strLine
	
	Dim Finded
	Finded = InStr(strLine1, Solidus)
	Do While Finded
		strLine1 = Replace(strLine1, Solidus, MakefileMovePathSeparator)
		Finded = InStr(strLine1, Solidus)
	Loop
	
	ReplaceSolidusToMovePathSeparator = strLine1
	
End Function

Sub ReplaceSolidusToPathSeparatorVector(LinesArray)
	' заменяем "\" на "$(PATH_SEP)"
	Dim i
	For i = LBound(LinesArray) To UBound(LinesArray)
		Dim strLine
		strLine = LinesArray(i)
		LinesArray(i) = ReplaceSolidusToPathSeparator(strLine)
	Next
End Sub

Sub AddSpaces(LinesArray)
	' Добавляем пробел в конце каждой строки
	Dim i
	For i = LBound(LinesArray) To UBound(LinesArray)
		Dim Length
		Length = Len(LinesArray(i))
		If Length > 0 Then
			LinesArray(i) = LinesArray(i) & " "
		End If
	Next
End Sub

Function ReadTextFile(FileName)
	' читаем текстовый файл и возвращаем строку
	Dim TextStream
	Set TextStream = FSO.OpenTextFile(FileName, 1)
	
	Dim strLines
	strLines = TextStream.ReadAll

	TextStream.Close
	Set TextStream = Nothing
	
	ReadTextFile = strLines
End Function

Function ReadTextStream(Stream)
	' Читаем текстовый поток и возвращаем строку
	Dim Lines
	Lines = ""
	Do While Not Stream.AtEndOfStream
		Lines = Lines & Trim(Stream.ReadLine()) & vbCrLf
	Loop
	ReadTextStream = Lines
End Function

Function GetBasFileWithoutPath(BasFile)
	Dim ReplaceFind
	ReplaceFind = GetSourceFolderWithPathSep(SourceFolder)
	
	GetBasFileWithoutPath = Replace(BasFile, ReplaceFind, "")
	
End Function

Sub WriteTextFile(MakefileStream, BasFile, DependenciesLine)
	
	Dim BasFileWithoutPath
	BasFileWithoutPath = GetBasFileWithoutPath(BasFile)
	
	Dim FileNameCExtenstionWitthSuffix
	Dim ObjectFileName
	
	Dim Finded
	Finded = InStr(BasFile, ".bas")
	If Finded Then
		FileNameCExtenstionWitthSuffix = Replace(BasFileWithoutPath, ".bas", FileSuffix & ".c")
		ObjectFileName = Replace(BasFileWithoutPath, ".bas", FileSuffix & ".o")
	Else
		FileNameCExtenstionWitthSuffix = Replace(BasFileWithoutPath, ".RC", FileSuffix & ".obj")
		ObjectFileName = Replace(BasFileWithoutPath, ".RC", FileSuffix & ".obj")
	End If
	
	Dim FileNameWithPathSep
	Dim ObjectFileNameWithPathSep
	FileNameWithPathSep = Replace(FileNameCExtenstionWitthSuffix, Solidus, MakefilePathSeparator)
	ObjectFileNameWithPathSep = Replace(ObjectFileName, Solidus, MakefilePathSeparator)
	
	Dim FileNameWithDebug
	FileNameWithDebug = DebugDirPrefix & FileNameWithPathSep
	Dim FileNameWithRelease
	FileNameWithRelease = ReleaseDirPrefix & FileNameWithPathSep
	
	Dim ObjectFileNameWithDebug
	ObjectFileNameWithDebug = ObjectFilesDebug & "+=" & DebugDirPrefix & ObjectFileNameWithPathSep
	Dim ObjectFileNameRelease
	ObjectFileNameRelease = ObjectFilesRelease & "+=" & ReleaseDirPrefix & ObjectFileNameWithPathSep
	
	Dim ResultDebugString
	ResultDebugString = FileNameWithDebug & ": " & DependenciesLine
	Dim ResultReleaseString
	ResultReleaseString = FileNameWithRelease & ": " & DependenciesLine
	
	' записываем строку в текстовый файл
	MakefileStream.WriteLine ObjectFileNameWithDebug
	MakefileStream.WriteLine ObjectFileNameRelease
	MakefileStream.WriteLine
	MakefileStream.WriteLine ResultDebugString
	MakefileStream.WriteLine ResultReleaseString
	MakefileStream.WriteLine
	
End Sub

Function GetIncludesFromBasFile(Filepath, MainModule)
	Dim FbcParam
	FbcParam = CreateCompilerParams( _
		CODE_EMITTER_GCC, _
		DEFINE_UNICODE, _
		DEFINE_WITHOUT_RUNTIME, _
		SUBSYSTEM_CONSOLE, _
		MainModule _
	)
	
	Dim ProgramName
	ProgramName = """" & CompilerPath & Solidus & FbcCompilerName & """" & " " & _
		FbcParam & _
		" -i " & SourceFolder & _
		" -i " & """" & CompilerPath & Solidus & "inc" & """" & " """ & Filepath & """"
	WScript.Echo ProgramName
	
	Dim WshShell
	Set WshShell = CreateObject("WScript.Shell")
	Dim WshExec
	Set WshExec = WshShell.Exec(ProgramName)
	
	Dim Stream
	Set Stream = WshExec.StdOut
	Dim Lines
	Lines = ReadTextStream(Stream)
	
	Set Stream = Nothing
	Set WshExec = Nothing
	Set WshShell = Nothing
	
	' Remove temporary "c" file
	Dim FileC
	FileC = Replace(Filepath, ".bas", ".c")
	FSO.DeleteFile FileC
	
	GetIncludesFromBasFile = Lines
End Function

Function GetIncludesFromResFile(Filepath)
	' TODO Get real dependencies from resource file
	GetIncludesFromResFile = "src\Resources.RC" & vbCrLf & "src\Resources.RH" & vbCrLf & "src\app.exe.manifest"
End Function

Function CreateDependencies(MakefileStream, oFile, FileExtension, Filepath, MainModule)
	
	Dim LinesArray
	Dim LinesArrayCreated
	
	Select Case UCase(FileExtension)
		Case "RC"
			LinesArray = Split(GetIncludesFromResFile(oFile.Path, MainModule), vbCrLf)
			LinesArrayCreated = True
		Case "BAS"
			LinesArray = Split(GetIncludesFromBasFile(oFile.Path, MainModule), vbCrLf)
			LinesArrayCreated = True
		Case Else
			LinesArray = Split("", vbCrLf)
			LinesArrayCreated = False
	End Select
	
	If LinesArrayCreated Then
		Dim Original
		Original = LinesArray(0)
		
		' Первая строка не нужна — там имя самого файла
		LinesArray(0) = ""
		
		RemoveVerticalLine LinesArray
		RemoveOmmittedIncludes LinesArray
		RemoveDefaultIncludes LinesArray
		ReplaceSolidusToPathSeparatorVector LinesArray
		AddSpaces LinesArray
		
		' Весь массив в одну линию
		Dim OneLine
		OneLine = Join(LinesArray, "")
		
		WriteTextFile MakefileStream, Original, RTrim(OneLine)
	End If
End Function
