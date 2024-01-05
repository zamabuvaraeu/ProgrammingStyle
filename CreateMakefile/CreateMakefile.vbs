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

Class Parameter
	Public MakefileFileName
	Public SourceFolder
	Public CompilerPath
	Public FbcCompilerName
	Public OutputFileName
	Public MainModuleName
	Public ExeType
	Public FileSubsystem
	Public Emitter
	Public FixEmittedCode
	Public Unicode
	Public UseRuntimeLibrary
	Public AddressAware
	Public ThreadingMode
	Public MinimalWindowsVersion
	Public UseFileSuffix
	Public Pedantic
End Class

Dim Params
Set Params = GetParameters()

Dim FSO
Set FSO = CreateObject("Scripting.FileSystemObject")

Dim MakefileFileStream
Set MakefileFileStream = FSO.OpenTextFile(Params.MakefileFileName, 2, True, 0)

WriteTargets MakefileFileStream
WriteCompilerToolChain MakefileFileStream
WriteProcessorArch MakefileFileStream
WriteOutputFilename MakefileFileStream, Params
WriteUtilsPath MakefileFileStream
WriteArchSpecifiedPath MakefileFileStream

WriteFbcFlags MakefileFileStream, Params
WriteGccFlags MakefileFileStream, Params
WriteAsmFlags MakefileFileStream
WriteGorcFlags MakefileFileStream
WriteLinkerFlags MakefileFileStream, Params

WriteLinkerLibraryes MakefileFileStream, Params
WriteIncludeFile MakefileFileStream, Params
WriteReleaseTarget MakefileFileStream
WriteDebugTarget MakefileFileStream
WriteCleanTarget MakefileFileStream
WriteCreateDirsTarget MakefileFileStream

WriteReleaseRule MakefileFileStream
WriteDebugRule MakefileFileStream

WriteAsmRule MakefileFileStream
WriteCRule MakefileFileStream
WriteBasRule MakefileFileStream, Params
WriteResourceRule MakefileFileStream

Set MakefileFileStream = Nothing
Set FSO = Nothing
Set Params = Nothing

Function GetParameters()
	Dim p
	Set p = New Parameter
	
	Dim colArgs
	Set colArgs = WScript.Arguments.Named
	
	If colArgs.Exists("makefile") Then
		p.MakefileFileName = colArgs.Item("makefile")
	Else
		p.MakefileFileName = "Makefile"
	End If
	
	If colArgs.Exists("src") Then
		p.SourceFolder = colArgs.Item("src")
	Else
		p.SourceFolder = "src"
	End If
	
	If colArgs.Exists("fbc-path") Then
		p.CompilerPath = colArgs.Item("fbc-path")
	Else
		p.CompilerPath = "C:\Program Files (x86)\FreeBASIC-1.10.1-winlibs-gcc-9.3.0"
	End If
	
	If colArgs.Exists("fbc") Then
		p.FbcCompilerName = colArgs.Item("fbc")
	Else
		p.FbcCompilerName = "fbc64.exe"
	End If
	
	If colArgs.Exists("out") Then
		p.OutputFileName = colArgs.Item("out")
	Else
		p.OutputFileName = "a"
	End If
	
	If colArgs.Exists("module") Then
		p.MainModuleName = colArgs.Item("module")
	Else
		p.MainModuleName = p.OutputFileName
	End If
	
	If colArgs.Exists("exetype") Then
		Dim t1
		t1 = colArgs.Item("exetype")
		Select Case t1
			Case "exe"
				p.ExeType = OUTPUT_FILETYPE_EXE
			Case "dll"
				p.ExeType = OUTPUT_FILETYPE_DLL
			Case "lib"
				p.ExeType = OUTPUT_FILETYPE_LIBRARY
			Case "wasm32"
				p.ExeType = OUTPUT_FILETYPE_WASM32
			Case "wasm64"
				p.ExeType = OUTPUT_FILETYPE_WASM64
			Case Else
				p.ExeType = OUTPUT_FILETYPE_EXE
		End Select
	Else
		p.ExeType = OUTPUT_FILETYPE_EXE
	End If
	
	If colArgs.Exists("subsystem") Then
		Dim t2
		t2 = colArgs.Item("subsystem")
		Select Case t2
			Case "console"
				p.FileSubsystem = SUBSYSTEM_CONSOLE
			Case "windows"
				p.FileSubsystem = SUBSYSTEM_WINDOW
			Case "native"
				p.FileSubsystem = SUBSYSTEM_NATIVE
			Case Else
				p.FileSubsystem = SUBSYSTEM_CONSOLE
		End Select
	Else
		p.FileSubsystem = SUBSYSTEM_CONSOLE
	End If
	
	If colArgs.Exists("emitter") Then
		Dim t3
		t3 = colArgs.Item("emitter")
		Select Case t3
			Case "gcc"
				p.Emitter = CODE_EMITTER_GCC
			Case "gas"
				p.Emitter = CODE_EMITTER_GAS
			Case "gas64"
				p.Emitter = CODE_EMITTER_GAS64
			Case "llvm"
				p.Emitter = CODE_EMITTER_LLVM
			Case "wasm32"
				p.Emitter = CODE_EMITTER_WASM32
			Case "wasm64"
				p.Emitter = CODE_EMITTER_WASM64
			Case Else
				p.Emitter = CODE_EMITTER_GCC
		End Select
	Else
		p.Emitter = CODE_EMITTER_GCC
	End If
	
	If colArgs.Exists("fix") Then
		Dim t9
		t9 = colArgs.Item("fix")
		Select Case t9
			Case "true"
				p.FixEmittedCode = FIX_EMITTED_CODE
			Case "false"
				p.FixEmittedCode = NOT_FIX_EMITTED_CODE
			Case Else
				p.FixEmittedCode = NOT_FIX_EMITTED_CODE
		End Select
	Else
		p.FixEmittedCode = NOT_FIX_EMITTED_CODE
	End If
	
	If colArgs.Exists("unicode") Then
		Dim t4
		t4 = colArgs.Item("unicode")
		Select Case t4
			Case "true"
				p.Unicode = DEFINE_UNICODE
			Case "false"
				p.Unicode = DEFINE_ANSI
			Case Else
				p.Unicode = DEFINE_ANSI
		End Select
	Else
		p.Unicode = DEFINE_ANSI
	End If
	
	If colArgs.Exists("wrt") Then
		Dim t5
		t5 = colArgs.Item("wrt")
		Select Case t5
			Case "true"
				p.UseRuntimeLibrary = DEFINE_WITHOUT_RUNTIME
			Case "false"
				p.UseRuntimeLibrary = DEFINE_RUNTIME
			Case Else
				p.UseRuntimeLibrary = DEFINE_RUNTIME
		End Select
	Else
		p.UseRuntimeLibrary = DEFINE_RUNTIME
	End If
	
	If colArgs.Exists("addressaware") Then
		Dim t6
		t6 = colArgs.Item("addressaware")
		Select Case t6
			Case "true"
				p.AddressAware = LARGE_ADDRESS_AWARE
			Case "false"
				p.AddressAware = LARGE_ADDRESS_UNAWARE
			Case Else
				p.AddressAware = LARGE_ADDRESS_UNAWARE
		End Select
	Else
		p.AddressAware = LARGE_ADDRESS_UNAWARE
	End If
	
	If colArgs.Exists("multithreading") Then
		Dim t7
		t7 = colArgs.Item("multithreading")
		Select Case t7
			Case "true"
				p.ThreadingMode = DEFINE_MULTITHREADING_RUNTIME
			Case "false"
				p.ThreadingMode = DEFINE_SINGLETHREADING_RUNTIME
			Case Else
				p.ThreadingMode = DEFINE_SINGLETHREADING_RUNTIME
		End Select
	Else
		p.ThreadingMode = DEFINE_SINGLETHREADING_RUNTIME
	End If
	
	If colArgs.Exists("usefilesuffix") Then
		Dim t8
		t8 = colArgs.Item("usefilesuffix")
		Select Case t8
			Case "true"
				p.UseFileSuffix = True
			Case "false"
				p.UseFileSuffix = False
			Case Else
				p.UseFileSuffix = True
		End Select
	Else
		p.UseFileSuffix = True
	End If
	
	If colArgs.Exists("pedantic") Then
		Dim t10
		t10 = colArgs.Item("pedantic")
		Select Case t10
			Case "true"
				p.Pedantic = True
			Case "false"
				p.Pedantic = False
			Case Else
				p.Pedantic = False
		End Select
	Else
		p.Pedantic = False
	End If
	
	If colArgs.Exists("winver") Then
		p.MinimalWindowsVersion = colArgs.Item("winver")
	Else
		' #define WINVER 0x0A00
		' #define _WIN32_WINNT 0x0A00

		' _WIN32_WINNT version constants

		' #define _WIN32_WINNT_NT4            0x0400 // Windows NT 4.0
		' #define _WIN32_WINNT_WIN2K          0x0500 // Windows 2000
		' #define _WIN32_WINNT_WINXP          0x0501 // Windows XP
		' #define _WIN32_WINNT_WS03           0x0502 // Windows Server 2003
		' #define _WIN32_WINNT_WIN6           0x0600 // Windows Vista
		' #define _WIN32_WINNT_VISTA          0x0600 // Windows Vista
		' #define _WIN32_WINNT_WS08           0x0600 // Windows Server 2008
		' #define _WIN32_WINNT_LONGHORN       0x0600 // Windows Vista
		' #define _WIN32_WINNT_WIN7           0x0601 // Windows 7
		' #define _WIN32_WINNT_WIN8           0x0602 // Windows 8
		' #define _WIN32_WINNT_WINBLUE        0x0603 // Windows 8.1
		' #define _WIN32_WINNT_WINTHRESHOLD   0x0A00 // Windows 10
		' #define _WIN32_WINNT_WIN10          0x0A00 // Windows 10
		
		p.MinimalWindowsVersion = "0x0400"
	End If
	
	Set GetParameters = p
	
End Function

Function CodeGenerationToString(p)
	
	Dim ep
	
	Select Case p.Emitter
		
		Case CODE_EMITTER_GCC
			ep = "-gen gcc"
			
		Case CODE_EMITTER_GAS
			ep = "-gen gas"
			
		Case CODE_EMITTER_GAS64
			ep = "-gen gas64"
			
		Case CODE_EMITTER_LLVM
			ep = "-gen llvm"
			
		Case CODE_EMITTER_WASM32
			ep = "-gen gcc"
			
		Case CODE_EMITTER_WASM64
			ep = "-gen gcc"
			
	End Select
	
	CodeGenerationToString = ep
	
End Function

Function CreateCompilerParams(p)
	
	Dim EmitterFlag
	EmitterFlag = CodeGenerationToString(p)
	
	Dim UnicodeFlag
	Select Case p.Unicode
		Case DEFINE_ANSI
			UnicodeFlag = ""
		Case DEFINE_UNICODE
			UnicodeFlag = "-d UNICODE"
	End Select
	
	Dim RuntimeFlag
	Select Case p.UseRuntimeLibrary
		Case DEFINE_RUNTIME
			RuntimeFlag = ""
		Case DEFINE_WITHOUT_RUNTIME
			RuntimeFlag = "-d WITHOUT_RUNTIME"
	End Select
	
	Dim WinverFlag
	WinverFlag = "-d WINVER=" & p.MinimalWindowsVersion & " -d _WIN32_WINNT=" & p.MinimalWindowsVersion
	
	Dim SubSystemFlag
	If p.FileSubsystem = SUBSYSTEM_WINDOW Then
		SubSystemFlag = "-s gui"
	Else
		SubSystemFlag = "-s console"
	End If
	
	Dim MaxErrorFlag
	MaxErrorFlag = "-maxerr 1"
	
	Dim OptimizationFlag
	OptimizationFlag = "-O 0"
	
	Dim OnlyAssemblyFlag
	OnlyAssemblyFlag = "-r"
	
	Dim ShowIncludesFlag
	ShowIncludesFlag = "-showincludes"
	
	Dim MainModuleFlag
	MainModuleFlag = "-m " & p.MainModuleName
	
	Dim CompilerParam
	CompilerParam = _
		EmitterFlag      & " " & _
		UnicodeFlag      & " " & _
		RuntimeFlag      & " " & _
		WinverFlag       & " " & _
		SubSystemFlag    & " " & _
		MaxErrorFlag     & " " & _
		OptimizationFlag & " " & _
		OnlyAssemblyFlag & " " & _
		ShowIncludesFlag & " " & _
	MainModuleFlag
	
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
	MakefileStream.WriteLine "FLTO ?="
	MakefileStream.WriteLine 
End Sub

Sub WriteProcessorArch(MakefileStream)
	MakefileStream.WriteLine "TARGET_TRIPLET ?="
	MakefileStream.WriteLine "MARCH ?= native"
	MakefileStream.WriteLine 
End Sub

Sub WriteOutputFilename(MakefileStream, p)
	
	Dim Extension
	Select Case p.ExeType
		
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
	
	If p.UseFileSuffix Then
		MakefileStream.WriteLine "FILE_SUFFIX=$(GCC_VER)$(FBC_VER)$(RUNTIME)"
	End If
	
	MakefileStream.WriteLine "OUTPUT_FILE_NAME=" & p.OutputFilename & "$(FILE_SUFFIX)" & Extension
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

Sub WriteFbcFlags(MakefileStream, p)
	
	Dim EmitterParam
	EmitterParam = CodeGenerationToString(p)
	
	Dim UnicodeFlag
	Select Case p.Unicode
		
		Case DEFINE_ANSI
			UnicodeFlag = ""
			
		Case DEFINE_UNICODE
			UnicodeFlag = "FBCFLAGS+=-d UNICODE"
			
	End Select
	
	Dim SubSystemParam
	If p.FileSubsystem = SUBSYSTEM_WINDOW Then
		SubSystemParam = "-s gui"
	Else
		SubSystemParam = "-s console"
	End If
	
	MakefileStream.WriteLine "FBCFLAGS+=" & EmitterParam
	MakefileStream.WriteLine UnicodeFlag
	
	MakefileStream.WriteLine "ifeq ($(USE_RUNTIME),TRUE)"
	MakefileStream.WriteLine "FBCFLAGS+=-m " & p.MainModuleName
	MakefileStream.WriteLine "else"
	MakefileStream.WriteLine "FBCFLAGS+=-d WITHOUT_RUNTIME"
	MakefileStream.WriteLine "endif"
	
	MakefileStream.WriteLine "FBCFLAGS+=-w error -maxerr 1"
	MakefileStream.WriteLine "FBCFLAGS+=-i " & p.SourceFolder
	
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

Sub WriteGccFlags(MakefileStream, p)
	
	Select Case p.Emitter
		
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
	
	Select Case p.Emitter
		
		Case CODE_EMITTER_WASM32
			MakefileStream.WriteLine "CFLAGS+=--target=wasm32"
			
		Case CODE_EMITTER_WASM64
			MakefileStream.WriteLine "CFLAGS+=--target=wasm64"
			
		Case Else
		
	End Select
	
	MakefileStream.WriteLine "CFLAGS+=-pipe"
	
	If p.Pedantic Then
		MakefileStream.WriteLine "CFLAGS+=-Wall -Werror -Wextra -pedantic"
	Else
		MakefileStream.WriteLine "CFLAGS+=-Wall -Werror -Wextra"
	End If
	
	MakefileStream.WriteLine "CFLAGS+=-Wno-unused-label -Wno-unused-function"
	MakefileStream.WriteLine "CFLAGS+=-Wno-unused-parameter -Wno-unused-variable"
	MakefileStream.WriteLine "CFLAGS+=-Wno-dollar-in-identifier-extension"
	MakefileStream.WriteLine "CFLAGS+=-Wno-language-extension-token"
	MakefileStream.WriteLine "CFLAGS+=-Wno-parentheses-equality"
	
	MakefileStream.WriteLine "CFLAGS_DEBUG+=-g -O0"
	
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

Sub WriteLinkerFlags(MakefileStream, p)
	
	Select Case p.Emitter
		
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
			
			Select Case p.AddressAware
				Case LARGE_ADDRESS_UNAWARE
				Case LARGE_ADDRESS_AWARE
					MakefileStream.WriteLine "LDFLAGS+=--large-address-aware"
			End Select
			
			MakefileStream.WriteLine "endif"
			
			Select Case p.FileSubsystem
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

Sub WriteLinkerLibraryes(MakefileStream, p)
	
	Select Case p.Emitter
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
			' Windows API
			MakefileStream.WriteLine "LDLIBS+=-ladvapi32 -lcomctl32 -lcomdlg32 -lcrypt32"
			MakefileStream.WriteLine "LDLIBS+=-lgdi32 -lgdiplus -lkernel32 -lmswsock"
			MakefileStream.WriteLine "LDLIBS+=-lole32 -loleaut32 -lshell32 -lshlwapi"
			MakefileStream.WriteLine "LDLIBS+=-lwsock32 -lws2_32 -luser32"
			' C Runtime
			MakefileStream.WriteLine "LDLIBS+=-lmsvcrt"
			
			MakefileStream.WriteLine "ifeq ($(USE_RUNTIME),TRUE)"
			
			' For Multithreading
			Select Case p.ThreadingMode
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

Sub WriteIncludeFile(MakefileStream, p)
	Dim SrcFolder
	Set SrcFolder = FSO.GetFolder(p.SourceFolder)
	
	Dim File
	For Each File In SrcFolder.Files
		Dim ext
		ext = FSO.GetExtensionName(File.Path)
		CreateDependencies MakefileStream, File, ext, p
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

Sub WriteBasRule(MakefileStream, p)
	Dim SourceFolderWithPathSep
	SourceFolderWithPathSep = GetSourceFolderWithPathSep(p.SourceFolder)
	
	Dim AnyBasFile
	AnyBasFile = ReplaceSolidusToPathSeparator(SourceFolderWithPathSep) & "%.bas"
	
	Dim AnyCFile
	AnyCFile = ReplaceSolidusToMovePathSeparator(SourceFolderWithPathSep) & "$*.c"
	
	MakefileStream.WriteLine "$(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).c: " & AnyBasFile
	MakefileStream.WriteLine "	$(FBC) $(FBCFLAGS) $<"
	
	If p.FixEmittedCode = FIX_EMITTED_CODE Then
		MakefileStream.WriteLine "	$(SCRIPT_COMMAND) /release " & AnyCFile
	End If
	
	MakefileStream.WriteLine "	$(MOVE_COMMAND) " & AnyCFile & " $(OBJ_RELEASE_DIR_MOVE)$(MOVE_PATH_SEP)$*$(FILE_SUFFIX).c"
	MakefileStream.WriteLine
	
	MakefileStream.WriteLine "$(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).c: " & AnyBasFile
	MakefileStream.WriteLine "	$(FBC) $(FBCFLAGS) $<"
	
	If p.FixEmittedCode = FIX_EMITTED_CODE Then
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

Sub RemoveDefaultIncludes(LinesArray, p)
	' заголовочные файлы в системном каталоге обнуляем
	Dim i
	For i = LBound(LinesArray) To UBound(LinesArray)
		Dim Finded
		Finded = InStr(LinesArray(i), p.CompilerPath & Solidus & "inc")
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

Function GetBasFileWithoutPath(BasFile, p)
	Dim ReplaceFind
	ReplaceFind = GetSourceFolderWithPathSep(p.SourceFolder)
	
	GetBasFileWithoutPath = Replace(BasFile, ReplaceFind, "")
	
End Function

Sub WriteTextFile(MakefileStream, BasFile, DependenciesLine, p)
	
	Dim BasFileWithoutPath
	BasFileWithoutPath = GetBasFileWithoutPath(BasFile, p)
	
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

Function GetIncludesFromBasFile(Filepath, p)
	Dim FbcParam
	FbcParam = CreateCompilerParams(p)
	
	Dim ProgramName
	ProgramName = """" & p.CompilerPath & Solidus & p.FbcCompilerName & """" & " " & _
		FbcParam & _
		" -i " & p.SourceFolder & _
		" -i " & """" & p.CompilerPath & Solidus & "inc" & """" & " """ & Filepath & """"
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
	WScript.Echo FileC
	FSO.DeleteFile FileC
	
	GetIncludesFromBasFile = Lines
End Function

Function GetIncludesFromResFile(Filepath, p)
	' TODO Get real dependencies from resource file
	GetIncludesFromResFile = "src\Resources.RC"
	
	Dim SrcFolder
	Set SrcFolder = FSO.GetFolder(p.SourceFolder)
	
	Dim File
	For Each File In SrcFolder.Files
		Dim ext
		ext = FSO.GetExtensionName(File.Path)
		Dim FileNameWithParentDir
		FileNameWithParentDir = SrcFolder.Name & "\" & File.Name
		
		Select Case UCase(ext)
			
			Case "RH"
				GetIncludesFromResFile = GetIncludesFromResFile & vbCrLf & FileNameWithParentDir
				
		End Select
		
		Select Case UCase(File.Name)
			
			Case "MANIFEST.XML"
				GetIncludesFromResFile = GetIncludesFromResFile & vbCrLf & FileNameWithParentDir
				
			Case "RESOURCES.RC"
				GetIncludesFromResFile = GetIncludesFromResFile & vbCrLf & FileNameWithParentDir
				
			Case "APP.ICO"
				GetIncludesFromResFile = GetIncludesFromResFile & vbCrLf & FileNameWithParentDir
				
		End Select
	Next
	
	Set SrcFolder = Nothing
	
End Function

Function CreateDependencies(MakefileStream, oFile, FileExtension, p)
	
	Dim LinesArray
	Dim LinesArrayCreated
	
	Select Case UCase(FileExtension)
		Case "RC"
			LinesArray = Split(GetIncludesFromResFile(oFile.Path, p), vbCrLf)
			LinesArrayCreated = True
		Case "BAS"
			LinesArray = Split(GetIncludesFromBasFile(oFile.Path, p), vbCrLf)
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
		RemoveDefaultIncludes LinesArray, p
		ReplaceSolidusToPathSeparatorVector LinesArray
		AddSpaces LinesArray
		
		' Весь массив в одну линию
		Dim OneLine
		OneLine = Join(LinesArray, "")
		
		WriteTextFile MakefileStream, Original, RTrim(OneLine), p
	End If
End Function
