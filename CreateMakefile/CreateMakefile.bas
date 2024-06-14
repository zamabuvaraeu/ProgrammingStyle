#include once "crt.bi"

Const FILEOPEN_READONLY = 1
Const FILEOPEN_WRITEONLY = 2
Const FILEOPEN_APPENDONLY = 8
Const FILEOPEN_CREATENEW = True
Const FILEFORMAT_ASCII = 0
Const FILEFORMAT_UNICODE = 1
Const FILEFORMAT_SYSTEM = 2

Enum Subsystem
	SUBSYSTEM_CONSOLE
	SUBSYSTEM_WINDOW
	SUBSYSTEM_NATIVE
End Enum

Enum ExecutableType
	OUTPUT_FILETYPE_EXE
	OUTPUT_FILETYPE_DLL
	OUTPUT_FILETYPE_LIBRARY
	OUTPUT_FILETYPE_WASM32
	OUTPUT_FILETYPE_WASM64
End Enum

Enum CodeEmitter
	CODE_EMITTER_GCC
	CODE_EMITTER_GAS
	CODE_EMITTER_GAS64
	CODE_EMITTER_LLVM
	CODE_EMITTER_WASM32
	CODE_EMITTER_WASM64
End Enum

Enum FixCode
	NOT_FIX_EMITTED_CODE
	FIX_EMITTED_CODE
End Enum

Enum UseUnicode
	DEFINE_ANSI
	DEFINE_UNICODE
End Enum

Enum UseRuntime
	DEFINE_RUNTIME
	DEFINE_WITHOUT_RUNTIME
End Enum

Enum ProcessAddressSpace
	LARGE_ADDRESS_UNAWARE
	LARGE_ADDRESS_AWARE
End Enum

Enum MultiThreading
	DEFINE_SINGLETHREADING_RUNTIME
	DEFINE_MULTITHREADING_RUNTIME
End Enum

Const WINVER_DEFAULT = 0
Const WINVER_XP = 0

Const vbTab = !"\t"
Const vbCrLf = !"\r\n"
Const Solidus = "\"
Const ReverseSolidus = "/"
Const MakefilePathSeparator = "$(PATH_SEP)"
Const MakefileMovePathSeparator = "$(MOVE_PATH_SEP)"
Const ReleaseDirPrefix = "$(OBJ_RELEASE_DIR)$(PATH_SEP)"
Const DebugDirPrefix = "$(OBJ_DEBUG_DIR)$(PATH_SEP)"
Const FileSuffix = "$(FILE_SUFFIX)"
Const ObjectFilesRelease = "OBJECTFILES_RELEASE"
Const ObjectFilesDebug = "OBJECTFILES_DEBUG"
Const MakefileParametersFile = "setenv.cmd"
Const DefaultCompilerFolder = "C:\Program Files (x86)\FreeBASIC-1.10.1-winlibs-gcc-9.3.0"
Const DefaultCompilerName = "fbc64.exe"
Const FBC_VER = "_FBC1101"
Const GCC_VER = "_GCC0930"

Type Parameter
	MakefileFileName As ZString * MAX_PATH
	SourceFolder As ZString * MAX_PATH
	CompilerPath As ZString * MAX_PATH
	FbcCompilerName As ZString * MAX_PATH
	OutputFileName As ZString * MAX_PATH
	MainModuleName As ZString * MAX_PATH
	ExeType As ExecutableType
	FileSubsystem As Subsystem
	Emitter As CodeEmitter
	FixEmittedCode As FixCode
	Unicode As UseUnicode
	UseRuntimeLibrary As UseRuntime
	AddressAware As ProcessAddressSpace
	ThreadingMode As MultiThreading
	MinimalOSVersion As Integer
	UseFileSuffix As Boolean
	Pedantic As Boolean
End Type

Private Function AppendPathSeparator(ByVal strLine As String) As String

	var Length = Len(strLine)

	var LastChar = Mid(strLine, Length, 1)

	If LastChar = "\" Then
		Return strLine
	Else
		Return strLine & "\"
	End If

End Function

Private Function BuildPath(ByVal Directory As String, ByVal File As String) As String

	Dim DirWithPathSeparator As String = AppendPathSeparator(Directory)

	Dim FirstChar As String = Mid(File, 1, 1)

	If FirstChar = "\" Then
		Return DirWithPathSeparator & Mid(File, 2)
	Else
		Return DirWithPathSeparator & File
	End If

End Function

Private Function Replace(ByVal strFind As String, ByVal strOld As String, ByVal strNew As String) As String

	Dim strLine1 As String = strFind
	Dim FromLength As Integer = Len(strOld)

	Dim Finded As Integer = InStr(strLine1, strOld)

	Do While Finded
		Dim strLeft As String = Mid(strLine1, 1, Finded - 1)
		Dim strRight As String = Mid(strLine1, Finded + FromLength)

		strLine1 = strLeft & strNew & strRight

		Finded = InStr(strLine1, strOld)
	Loop

	Return strLine1

End Function

Private Function ReplaceSolidusToPathSeparator(ByVal strLine As String) As String

	' Replace "\" to "$(PATH_SEP)"

	Dim strLine1 As String = Replace(strLine, Solidus, MakefilePathSeparator)

	Return strLine1

End Function

Private Function ReplaceSolidusToMovePathSeparator(ByVal strLine As String) As String

	' Replace "\" to "$(MOVE_PATH_SEP)"

	Dim strLine1 As String = Replace(strLine, Solidus, MakefileMovePathSeparator)

	Return strLine1

End Function

Private Function ParseCommandLine(ByVal p As Parameter Ptr) As Integer

	p->MakefileFileName = "Makefile"
	p->SourceFolder = "src"
	p->CompilerPath = DefaultCompilerFolder
	p->FbcCompilerName = DefaultCompilerName
	p->OutputFileName = "a"
	p->MainModuleName = "a"
	p->ExeType = OUTPUT_FILETYPE_EXE
	p->FileSubsystem = SUBSYSTEM_CONSOLE
	p->Emitter = CODE_EMITTER_GCC
	p->FixEmittedCode = NOT_FIX_EMITTED_CODE
	p->Unicode = DEFINE_ANSI
	p->UseRuntimeLibrary = DEFINE_RUNTIME
	p->AddressAware = LARGE_ADDRESS_UNAWARE
	p->ThreadingMode = DEFINE_SINGLETHREADING_RUNTIME
	' p->MinimalOSVersion = 1024
	p->MinimalOSVersion = 0
	p->UseFileSuffix = False
	p->Pedantic = False

	Dim i As Integer = 1
	Dim sKey As String = Command(i)
	Do While Len(sKey)
		i += 1
		Dim sValue As String = Command(i)

		Select Case sKey

			Case "-makefile"
				p->MakefileFileName = sValue

			Case "-src"
				p->SourceFolder = sValue

			Case "-fbc-path"
				p->CompilerPath = sValue

			Case "-fbc"
				p->FbcCompilerName = sValue

			Case "-out"
				p->OutputFileName = sValue

			Case "-module"
				p->MainModuleName = sValue

			Case "-exetype"

				Select Case sValue

					Case "exe"
						p->ExeType = OUTPUT_FILETYPE_EXE

					Case "dll"
						p->ExeType = OUTPUT_FILETYPE_DLL

					Case "lib"
						p->ExeType = OUTPUT_FILETYPE_LIBRARY

					Case "wasm32"
						p->ExeType = OUTPUT_FILETYPE_WASM32

					Case "wasm64"
						p->ExeType = OUTPUT_FILETYPE_WASM64

					Case Else
						p->ExeType = OUTPUT_FILETYPE_EXE

				End Select

			Case "-subsystem"

				Select Case sValue

					Case "console"
						p->FileSubsystem = SUBSYSTEM_CONSOLE

					Case "windows"
						p->FileSubsystem = SUBSYSTEM_WINDOW

					Case "native"
						p->FileSubsystem = SUBSYSTEM_NATIVE

					Case Else
						p->FileSubsystem = SUBSYSTEM_CONSOLE

				End Select

			Case "-emitter"

				Select Case sValue

					Case "gcc"
						p->Emitter = CODE_EMITTER_GCC

					Case "gas"
						p->Emitter = CODE_EMITTER_GAS

					Case "gas64"
						p->Emitter = CODE_EMITTER_GAS64

					Case "llvm"
						p->Emitter = CODE_EMITTER_LLVM

					Case "wasm32"
						p->Emitter = CODE_EMITTER_WASM32

					Case "wasm64"
						p->Emitter = CODE_EMITTER_WASM64

					Case Else
						p->Emitter = CODE_EMITTER_GCC

				End Select

			Case "-fix"

				Select Case sValue

					Case "true"
						p->FixEmittedCode = FIX_EMITTED_CODE

					Case "false"
						p->FixEmittedCode = NOT_FIX_EMITTED_CODE

					Case Else
						p->FixEmittedCode = NOT_FIX_EMITTED_CODE

				End Select

			Case "-unicode"

				Select Case sValue

					Case "true"
						p->Unicode = DEFINE_UNICODE

					Case "false"
						p->Unicode = DEFINE_ANSI

					Case Else
						p->Unicode = DEFINE_ANSI

				End Select

			Case "-wrt"

				Select Case sValue

					Case "true"
						p->UseRuntimeLibrary = DEFINE_WITHOUT_RUNTIME

					Case "false"
						p->UseRuntimeLibrary = DEFINE_RUNTIME

					Case Else
						p->UseRuntimeLibrary = DEFINE_RUNTIME

				End Select

			Case "-addressaware"

				Select Case sValue

					Case "true"
						p->AddressAware = LARGE_ADDRESS_AWARE

					Case "false"
						p->AddressAware = LARGE_ADDRESS_UNAWARE

					Case Else
						p->AddressAware = LARGE_ADDRESS_UNAWARE

				End Select

			Case "-multithreading"

				Select Case sValue

					Case "true"
						p->ThreadingMode = DEFINE_MULTITHREADING_RUNTIME

					Case "false"
						p->ThreadingMode = DEFINE_SINGLETHREADING_RUNTIME

					Case Else
						p->ThreadingMode = DEFINE_SINGLETHREADING_RUNTIME

				End Select

			Case "-usefilesuffix"

				Select Case sValue

					Case "true"
						p->UseFileSuffix = True

					Case "false"
						p->UseFileSuffix = False

					Case Else
						p->UseFileSuffix = True

				End Select

			Case "-pedantic"

				Select Case sValue

					Case "true"
						p->Pedantic = True

					Case "false"
						p->Pedantic = False

					Case Else
						p->Pedantic = False

				End Select

			Case "-winver"
				' 	p.MinimalWindowsVersion = colArgs.Item("winver")
				' Else
				' 	p.MinimalWindowsVersion = "1024"
				' End If

		End Select

		i += 1
		sKey = Command(i)
	Loop

	Return 0

End Function

Private Function WriteSetenv(ByVal p As Parameter Ptr) As Integer

	var oStream = Freefile()
	var resOpen = Open(MakefileParametersFile, For Output, As oStream)
	If resOpen Then
		Return 1
	End If

	' PROCESSOR_ARCHITECTURE = AMD64 или x86
	Print #oStream, "if %PROCESSOR_ARCHITECTURE% == AMD64 ("
	Print #oStream, "set BinFolder=bin\win64"
	Print #oStream, "set LibFolder=lib\win64"
	Print #oStream, "set FBC_FILENAME=fbc64.exe"
	Print #oStream, ") else ("
	Print #oStream, "set BinFolder=bin\win32"
	Print #oStream, "set LibFolder=lib\win32"
	Print #oStream, "set FBC_FILENAME=fbc32.exe"
	Print #oStream, ")"
	Print #oStream,

	Print #oStream, "rem Add mingw64 directory to PATH"
	Print #oStream, "set MINGW_W64_DIR=C:\Program Files\mingw64"
	Print #oStream, "set PATH=%MINGW_W64_DIR%\bin;%PATH%"
	Print #oStream,
	Print #oStream, "rem Add compiler directory to PATH"
	Print #oStream, "set FBC_DIR=" & p->CompilerPath
	Print #oStream, "set PATH=%FBC_DIR%\%BinFolder%;%PATH%"
	Print #oStream,

	Print #oStream, "rem Source code directory"
	Print #oStream, "set SRC_DIR=" & p->SourceFolder
	Print #oStream,

	Print #oStream, "rem Set to TRUE for use runtime libraries"
	If p->UseRuntimeLibrary = DEFINE_WITHOUT_RUNTIME Then
		Print #oStream, "set USE_RUNTIME=FALSE"
	Else
		Print #oStream, "set USE_RUNTIME=TRUE"
	End If

	Print #oStream, "rem WinAPI version"
	Print #oStream, "set WINVER=" & p->MinimalOSVersion
	Print #oStream, "set _WIN32_WINNT=" & p->MinimalOSVersion
	Print #oStream,

	Print #oStream, "rem Use unicode in WinAPI"
	If p->Unicode = DEFINE_UNICODE Then
		Print #oStream, "set USE_UNICODE=TRUE"
	Else
		Print #oStream, "set USE_UNICODE=FALSE"
	End If

	Print #oStream, "rem Set variable FILE_SUFFIX to make the executable name different"
	Print #oStream, "rem for different toolchains, libraries, and compilation flags"
	Print #oStream, "set GCC_VER=" & GCC_VER
	Print #oStream, "set FBC_VER=" & FBC_VER
	Print #oStream,

	If p->UseFileSuffix Then
		Print #oStream, "set FILE_SUFFIX=%GCC_VER%%FBC_VER%%RUNTIME%"
	Else
		Print #oStream, "set FILE_SUFFIX="
	End If

	Print #oStream,

	Print #oStream, "rem Toolchain"
	Print #oStream, "set FBC=""%FBC_DIR%\" & p->FbcCompilerName & """"
	Print #oStream, "set CC=""%FBC_DIR%\%BinFolder%\gcc.exe"""
	Print #oStream, "set AS=""%FBC_DIR%\%BinFolder%\as.exe"""
	Print #oStream, "set AR=""%FBC_DIR%\%BinFolder%\ar.exe"""
	Print #oStream, "set GORC=""%FBC_DIR%\%BinFolder%\GoRC.exe"""
	Print #oStream, "set LD=""%FBC_DIR%\%BinFolder%\ld.exe"""
	Print #oStream, "set DLL_TOOL=""%FBC_DIR%\%BinFolder%\dlltool.exe"""
	Print #oStream,

	Print #oStream, "rem Without quotes:"
	Print #oStream, "set LIB_DIR==%FBC_DIR%\%LibFolder%"
	Print #oStream, "set INC_DIR=%FBC_DIR%\inc"
	Print #oStream,

	Select Case p->Emitter

		Case CODE_EMITTER_GCC, CODE_EMITTER_GAS, CODE_EMITTER_GAS64, CODE_EMITTER_LLVM
			Print #oStream, "rem Linker script only for GCC x86, GCC x64 and Clang x86"
			Print #oStream, "rem Without quotes:"
			Print #oStream, "set LD_SCRIPT=%FBC_DIR%\%LibFolder%\fbextra.x"
			Print #oStream,
			Print #oStream, "rem Set processor architecture"
			Print #oStream, "set MARCH=native"
			Print #oStream,
			Print #oStream, "rem Only for Clang x86"
			Print #oStream, "rem set TARGET_TRIPLET=i686-pc-windows-gnu"
			Print #oStream,
			Print #oStream, "rem Only for Clang AMD64"
			Print #oStream, "rem set TARGET_TRIPLET=x86_64-w64-pc-windows-msvc"
			Print #oStream, "rem set FLTO=-flto"

		Case CODE_EMITTER_WASM32, CODE_EMITTER_WASM64
			Print #oStream, "rem Only for wasm"
			Print #oStream, "set TARGET_TRIPLET=wasm32"

	End Select

	Print #oStream,

	Print #oStream, "rem Create bin obj folders"
	Print #oStream, "rem mingw32-make createdirs"
	Print #oStream,
	Print #oStream, "rem Compile"
	Print #oStream, "rem mingw32-make all"

	Close(oStream)

	Return 0

End Function

Private Sub WriteTargets(ByVal MakefileStream As Long)
	Print #MakefileStream, ".PHONY: all debug release clean createdirs"
	Print #MakefileStream,
	Print #MakefileStream, "all: release debug"
	Print #MakefileStream,
End Sub

Private Sub WriteCompilerToolChain(ByVal MakefileStream As Long)
	Print #MakefileStream, "FBC ?= fbc.exe"
	Print #MakefileStream, "CC ?= gcc.exe"
	Print #MakefileStream, "AS ?= as.exe"
	Print #MakefileStream, "AR ?= ar.exe"
	Print #MakefileStream, "GORC ?= GoRC.exe"
	Print #MakefileStream, "LD ?= ld.exe"
	Print #MakefileStream, "DLL_TOOL ?= dlltool.exe"
	Print #MakefileStream, "LIB_DIR ?="
	Print #MakefileStream, "INC_DIR ?="
	Print #MakefileStream, "LD_SCRIPT ?="
	Print #MakefileStream,
End Sub

Private Sub WriteProcessorArch(ByVal MakefileStream As Long)
	Print #MakefileStream, "TARGET_TRIPLET ?="
	Print #MakefileStream, "MARCH ?= native"
	Print #MakefileStream,
End Sub

Private Sub WriteOutputFilename(ByVal MakefileStream As Long, ByVal p As Parameter Ptr)

	Dim Extension As String
	Select Case p->ExeType

		Case OUTPUT_FILETYPE_EXE
			Extension = ".exe"

		Case OUTPUT_FILETYPE_DLL
			Extension = ".dll"

		Case OUTPUT_FILETYPE_LIBRARY
			Extension = ".a"

		Case OUTPUT_FILETYPE_WASM32
			Extension = ".wasm"

		Case Else ' OUTPUT_FILETYPE_WASM64
			Extension = ".wasm"

	End Select

	' TODO Add UNICODE and _UNICODE to file suffix
	' TODO Add WINVER and _WIN32_WINNT to file suffix

	Print #MakefileStream, "USE_RUNTIME ?= TRUE"
	Print #MakefileStream, "FBC_VER ?= " & FBC_VER
	Print #MakefileStream, "GCC_VER ?= " & GCC_VER

	Print #MakefileStream, "ifeq ($(USE_RUNTIME),TRUE)"
	Print #MakefileStream, "RUNTIME = _RT"
	Print #MakefileStream, "else"
	Print #MakefileStream, "RUNTIME = _WRT"
	Print #MakefileStream, "endif"

	Print #MakefileStream, "OUTPUT_FILE_NAME=" & p->OutputFilename & "$(FILE_SUFFIX)" & Extension
	Print #MakefileStream,

End Sub

Private Sub WriteUtilsPath(ByVal MakefileStream As Long)

	Print #MakefileStream, "PATH_SEP ?= /"
	Print #MakefileStream, "MOVE_PATH_SEP ?= \\"
	Print #MakefileStream,
	Print #MakefileStream, "MOVE_COMMAND ?= cmd.exe /c move /y"
	Print #MakefileStream, "DELETE_COMMAND ?= cmd.exe /c del /f /q"
	Print #MakefileStream, "MKDIR_COMMAND ?= cmd.exe /c mkdir"
	Print #MakefileStream, "SCRIPT_COMMAND ?= cscript.exe //nologo fix-emitted-code.vbs"
	Print #MakefileStream,

End Sub

Private Sub WriteArchSpecifiedPath(ByVal MakefileStream As Long)

	Print #MakefileStream, "ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)"
	Print #MakefileStream, "BIN_DEBUG_DIR ?= bin$(PATH_SEP)Debug$(PATH_SEP)x64"
	Print #MakefileStream, "BIN_RELEASE_DIR ?= bin$(PATH_SEP)Release$(PATH_SEP)x64"
	Print #MakefileStream, "OBJ_DEBUG_DIR ?= obj$(PATH_SEP)Debug$(PATH_SEP)x64"
	Print #MakefileStream, "OBJ_RELEASE_DIR ?= obj$(PATH_SEP)Release$(PATH_SEP)x64"
	Print #MakefileStream, "BIN_DEBUG_DIR_MOVE ?= bin$(MOVE_PATH_SEP)Debug$(MOVE_PATH_SEP)x64"
	Print #MakefileStream, "BIN_RELEASE_DIR_MOVE ?= bin$(MOVE_PATH_SEP)Release$(MOVE_PATH_SEP)x64"
	Print #MakefileStream, "OBJ_DEBUG_DIR_MOVE ?= obj$(MOVE_PATH_SEP)Debug$(MOVE_PATH_SEP)x64"
	Print #MakefileStream, "OBJ_RELEASE_DIR_MOVE ?= obj$(MOVE_PATH_SEP)Release$(MOVE_PATH_SEP)x64"
	Print #MakefileStream, "else"
	Print #MakefileStream, "BIN_DEBUG_DIR ?= bin$(PATH_SEP)Debug$(PATH_SEP)x86"
	Print #MakefileStream, "BIN_RELEASE_DIR ?= bin$(PATH_SEP)Release$(PATH_SEP)x86"
	Print #MakefileStream, "OBJ_DEBUG_DIR ?= obj$(PATH_SEP)Debug$(PATH_SEP)x86"
	Print #MakefileStream, "OBJ_RELEASE_DIR ?= obj$(PATH_SEP)Release$(PATH_SEP)x86"
	Print #MakefileStream, "BIN_DEBUG_DIR_MOVE ?= bin$(MOVE_PATH_SEP)Debug$(MOVE_PATH_SEP)x86"
	Print #MakefileStream, "BIN_RELEASE_DIR_MOVE ?= bin$(MOVE_PATH_SEP)Release$(MOVE_PATH_SEP)x86"
	Print #MakefileStream, "OBJ_DEBUG_DIR_MOVE ?= obj$(MOVE_PATH_SEP)Debug$(MOVE_PATH_SEP)x86"
	Print #MakefileStream, "OBJ_RELEASE_DIR_MOVE ?= obj$(MOVE_PATH_SEP)Release$(MOVE_PATH_SEP)x86"
	Print #MakefileStream, "endif"
	Print #MakefileStream,

End Sub

Private Function CodeGenerationToString(ByVal p As Parameter Ptr) As String

	Dim ep As String

	Select Case p->Emitter

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

		Case Else ' CODE_EMITTER_WASM64
			ep = "-gen gcc"

	End Select

	Return ep

End Function

Private Sub WriteFbcFlags(ByVal MakefileStream As Long, ByVal p As Parameter Ptr)

	Dim EmitterParam As String = CodeGenerationToString(p)

	Print #MakefileStream, "FBCFLAGS+=" & EmitterParam

	Print #MakefileStream, "ifeq ($(USE_UNICODE),TRUE)"
	Print #MakefileStream, "FBCFLAGS+=-d UNICODE"
	Print #MakefileStream, "FBCFLAGS+=-d _UNICODE"
	Print #MakefileStream, "endif"

	Print #MakefileStream, "FBCFLAGS+=-d WINVER=$(WINVER)"
	Print #MakefileStream, "FBCFLAGS+=-d _WIN32_WINNT=$(_WIN32_WINNT)"

	Print #MakefileStream, "FBCFLAGS+=-m " & p->MainModuleName

	Print #MakefileStream, "ifeq ($(USE_RUNTIME),TRUE)"
	Print #MakefileStream, "else"
	Print #MakefileStream, "FBCFLAGS+=-d WITHOUT_RUNTIME"
	Print #MakefileStream, "endif"

	Print #MakefileStream, "FBCFLAGS+=-w error -maxerr 1"
	Print #MakefileStream, "FBCFLAGS+=-i " & p->SourceFolder

	Print #MakefileStream, "ifneq ($(INC_DIR),)"
	Print #MakefileStream, "FBCFLAGS+=-i ""$(INC_DIR)"""
	Print #MakefileStream, "endif"

	Print #MakefileStream, "FBCFLAGS+=-r"

	Dim SubSystemParam As String
	If p->FileSubsystem = SUBSYSTEM_WINDOW Then
		SubSystemParam = "-s gui"
	Else
		SubSystemParam = "-s console"
	End If

	Print #MakefileStream, "FBCFLAGS+=" & SubSystemParam

	Print #MakefileStream, "FBCFLAGS+=-O 0"
	Print #MakefileStream, "FBCFLAGS_DEBUG+=-g"
	Print #MakefileStream, "debug: FBCFLAGS+=$(FBCFLAGS_DEBUG)"
	Print #MakefileStream,

End Sub

Private Sub WriteGccFlags(ByVal MakefileStream As Long, ByVal p As Parameter Ptr)

	Select Case p->Emitter

		Case CODE_EMITTER_WASM32, CODE_EMITTER_WASM64
			' MakefileStream.WriteLine "CFLAGS+=-emit-llvm"

		Case Else
			Print #MakefileStream, "ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)"
			Print #MakefileStream, "CFLAGS+=-m64"
			Print #MakefileStream, "else"
			Print #MakefileStream, "CFLAGS+=-m32"
			Print #MakefileStream, "endif"

			Print #MakefileStream, "CFLAGS+=-march=$(MARCH)"

	End Select

	Select Case p->Emitter

		Case CODE_EMITTER_WASM32
			Print #MakefileStream, "CFLAGS+=--target=wasm32"

		Case CODE_EMITTER_WASM64
			Print #MakefileStream, "CFLAGS+=--target=wasm64"

		Case Else

	End Select

	Print #MakefileStream, "CFLAGS+=-pipe"

	If p->Pedantic Then
		Print #MakefileStream, "CFLAGS+=-Wall -Werror -Wextra -pedantic"
	Else
		Print #MakefileStream, "CFLAGS+=-Wall -Werror -Wextra"
	End If

	Print #MakefileStream, "CFLAGS+=-Wno-unused-label -Wno-unused-function"
	Print #MakefileStream, "CFLAGS+=-Wno-unused-parameter -Wno-unused-variable"
	Print #MakefileStream, "CFLAGS+=-Wno-dollar-in-identifier-extension"
	Print #MakefileStream, "CFLAGS+=-Wno-language-extension-token"
	Print #MakefileStream, "CFLAGS+=-Wno-parentheses-equality"

	Print #MakefileStream, "CFLAGS_DEBUG+=-g -O0"

	Print #MakefileStream, "release: CFLAGS+=$(CFLAGS_RELEASE)"
	Print #MakefileStream, "release: CFLAGS+=-fno-math-errno -fno-exceptions"
	Print #MakefileStream, "release: CFLAGS+=-fno-unwind-tables -fno-asynchronous-unwind-tables"
	Print #MakefileStream, "release: CFLAGS+=-O3 -fno-ident -fdata-sections -ffunction-sections"
	Print #MakefileStream, "release: CFLAGS+=-flto"

	Print #MakefileStream, "debug: CFLAGS+=$(CFLAGS_DEBUG)"

	Print #MakefileStream,

End Sub

Private Sub WriteAsmFlags(ByVal MakefileStream As Long)

	Print #MakefileStream, "ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)"
	Print #MakefileStream, "ASFLAGS+=--64"
	Print #MakefileStream, "else"
	Print #MakefileStream, "ASFLAGS+=--32"
	Print #MakefileStream, "endif"

	Print #MakefileStream, "ASFLAGS_DEBUG+="
	Print #MakefileStream, "release: ASFLAGS+=--strip-local-absolute"
	Print #MakefileStream, "debug: ASFLAGS+=$(ASFLAGS_DEBUG)"
	Print #MakefileStream,

End Sub

Private Sub WriteGorcFlags(ByVal MakefileStream As Long)

	Print #MakefileStream, "ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)"
	Print #MakefileStream, "GORCFLAGS+=/machine X64"
	Print #MakefileStream, "endif"

	Print #MakefileStream, "GORCFLAGS+=/ni /o /d FROM_MAKEFILE"
	Print #MakefileStream, "GORCFLAGS_DEBUG=/d DEBUG"
	Print #MakefileStream, "debug: GORCFLAGS+=$(GORCFLAGS_DEBUG)"
	Print #MakefileStream,

End Sub

Private Sub WriteLinkerFlags(ByVal MakefileStream As Long, ByVal p As Parameter Ptr)

	Select Case p->Emitter

		Case CODE_EMITTER_WASM32, CODE_EMITTER_WASM64
			' Set maximum stack size to 8MiB
			' -z stack-size=8388608

			' --initial-memory=<value> Initial size of the linear memory
			' --max-memory=<value>     Maximum size of the linear memory
			' --max-memory=8388608

			Print #MakefileStream, "LDFLAGS+=-m wasm32"
			Print #MakefileStream, "LDFLAGS+=--allow-undefined"
			Print #MakefileStream, "LDFLAGS+=--no-entry"
			Print #MakefileStream, "LDFLAGS+=--export-all"

			Print #MakefileStream, "LDFLAGS+=-L ."
			Print #MakefileStream, "LDFLAGS+=-L ""$(LIB_DIR)"""

			Print #MakefileStream, "release: LDFLAGS+=--lto-O3 --gc-sections"

		Case Else
			Print #MakefileStream, "ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)"

			' WinMainCRTStartup or mainCRTStartup
			Print #MakefileStream, "ifeq ($(USE_RUNTIME),FALSE)"
			Print #MakefileStream, "LDFLAGS+=-Wl,-e EntryPoint"
			Print #MakefileStream, "endif"

			' MakefileStream.WriteLine "LDFLAGS+=-m i386pep"

			Print #MakefileStream, "else"

			Print #MakefileStream, "ifeq ($(USE_RUNTIME),FALSE)"
			Print #MakefileStream, "LDFLAGS+=-Wl,-e _EntryPoint@0"
			Print #MakefileStream, "endif"

			' MakefileStream.WriteLine "LDFLAGS+=-m i386pe"

			Select Case p->AddressAware

				Case LARGE_ADDRESS_UNAWARE

				Case LARGE_ADDRESS_AWARE
					Print #MakefileStream, "LDFLAGS+=-Wl,--large-address-aware"

			End Select

			Print #MakefileStream, "endif"

			Select Case p->FileSubsystem

				Case SUBSYSTEM_CONSOLE
					Print #MakefileStream, "LDFLAGS+=-Wl,--subsystem console"

				Case SUBSYSTEM_WINDOW
					Print #MakefileStream, "LDFLAGS+=-Wl,--subsystem windows"

				Case SUBSYSTEM_NATIVE
					Print #MakefileStream, "LDFLAGS+=-Wl,--subsystem native"

			End Select

			Print #MakefileStream, "LDFLAGS+=-Wl,--no-seh -Wl,--nxcompat"
			Print #MakefileStream, "LDFLAGS+=-Wl,--disable-dynamicbase"

			Print #MakefileStream, "LDFLAGS+=-pipe -nostdlib"

			Print #MakefileStream, "LDFLAGS+=-L ."
			Print #MakefileStream, "LDFLAGS+=-L ""$(LIB_DIR)"""

			Print #MakefileStream, "ifneq ($(LD_SCRIPT),)"
			Print #MakefileStream, "LDFLAGS+=-T ""$(LD_SCRIPT)"""
			Print #MakefileStream, "endif"

			Print #MakefileStream, "release: LDFLAGS+=-flto -s -Wl,--gc-sections"

			Print #MakefileStream, "debug: LDFLAGS+=$(LDFLAGS_DEBUG)"
			Print #MakefileStream, "debug: LDLIBS+=$(LDLIBS_DEBUG)"
	End Select

	Print #MakefileStream,

End Sub

Private Sub WriteLinkerLibraryes(ByVal MakefileStream As Long, ByVal p As Parameter Ptr)

	Select Case p->Emitter

		Case CODE_EMITTER_WASM32, CODE_EMITTER_WASM64

		Case Else
			Print #MakefileStream, "ifeq ($(USE_RUNTIME),TRUE)"

			' For profile
			' Print #MakefileStream, "LDLIBSBEGIN+=gcrt2.o"

			Print #MakefileStream, "LDLIBSBEGIN+=""$(LIB_DIR)\crt2.o"""
			Print #MakefileStream, "LDLIBSBEGIN+=""$(LIB_DIR)\crtbegin.o"""
			Print #MakefileStream, "LDLIBSBEGIN+=""$(LIB_DIR)\fbrt0.o"""
			Print #MakefileStream, "endif"

			Print #MakefileStream, "LDLIBS+=-Wl,--start-group"

			' Windows API
			Print #MakefileStream, "LDLIBS+=-ladvapi32 -lcomctl32 -lcomdlg32 -lcrypt32"
			Print #MakefileStream, "LDLIBS+=-lgdi32 -lgdiplus -lkernel32 -lmswsock"
			Print #MakefileStream, "LDLIBS+=-lole32 -loleaut32 -lshell32 -lshlwapi"
			Print #MakefileStream, "LDLIBS+=-lwsock32 -lws2_32 -luser32"
			Print #MakefileStream, "LDLIBS+=-lmsvcrt"

			Print #MakefileStream, "ifeq ($(USE_RUNTIME),TRUE)"

			' For Multithreading
			Select Case p->ThreadingMode

				Case DEFINE_SINGLETHREADING_RUNTIME
					Print #MakefileStream, "LDLIBS+=-lfb"

				Case DEFINE_MULTITHREADING_RUNTIME
					Print #MakefileStream, "LDLIBS+=-lfbmt"

			End Select

			Print #MakefileStream, "LDLIBS+=-luuid"

			Print #MakefileStream, "endif"

			' For profile
			' Print #MakefileStream, "LDLIBS_DEBUG+=-lgmon"

			Print #MakefileStream, "LDLIBS_DEBUG+=-lgcc -lmingw32 -lmingwex -lmoldname -lgcc_eh"

			Print #MakefileStream, "ifeq ($(USE_RUNTIME),TRUE)"
			Print #MakefileStream, "LDLIBS+=-lgcc -lmingw32 -lmingwex -lmoldname -lgcc_eh"
			Print #MakefileStream, "endif"

			Print #MakefileStream, "LDLIBS+=-Wl,--end-group"

			Print #MakefileStream, "ifeq ($(USE_RUNTIME),TRUE)"
			Print #MakefileStream, "LDLIBSEND+=""$(LIB_DIR)\crtend.o"""
			Print #MakefileStream, "endif"

	End Select

	Print #MakefileStream,

End Sub

Private Sub WriteLegend(ByVal MakefileStream As Long)

	Print #MakefileStream, "# Legends:"
	Print #MakefileStream, "# $@ - target name"
	Print #MakefileStream, "# $^ - set of dependent files"
	Print #MakefileStream, "# $< - name of first dependency"
	Print #MakefileStream, "# % - pattern"
	Print #MakefileStream, "# $* - variable pattern"
	Print #MakefileStream,

End Sub

Private Sub WriteReleaseTarget(ByVal MakefileStream As Long)

	Print #MakefileStream, "release: $(BIN_RELEASE_DIR)$(PATH_SEP)$(OUTPUT_FILE_NAME)"
	Print #MakefileStream,

End Sub

Private Sub WriteDebugTarget(ByVal MakefileStream As Long)

	Print #MakefileStream, "debug: $(BIN_DEBUG_DIR)$(PATH_SEP)$(OUTPUT_FILE_NAME)"
	Print #MakefileStream,

End Sub

Private Sub WriteCleanTarget(ByVal MakefileStream As Long)

	Print #MakefileStream, "clean:"
	Print #MakefileStream, vbTab & "$(DELETE_COMMAND) $(OBJ_RELEASE_DIR_MOVE)$(MOVE_PATH_SEP)*$(FILE_SUFFIX).c"
	Print #MakefileStream, vbTab & "$(DELETE_COMMAND) $(OBJ_DEBUG_DIR_MOVE)$(MOVE_PATH_SEP)*$(FILE_SUFFIX).c"
	Print #MakefileStream, vbTab & "$(DELETE_COMMAND) $(OBJ_RELEASE_DIR_MOVE)$(MOVE_PATH_SEP)*$(FILE_SUFFIX).asm"
	Print #MakefileStream, vbTab & "$(DELETE_COMMAND) $(OBJ_DEBUG_DIR_MOVE)$(MOVE_PATH_SEP)*$(FILE_SUFFIX).asm"
	Print #MakefileStream, vbTab & "$(DELETE_COMMAND) $(OBJ_RELEASE_DIR_MOVE)$(MOVE_PATH_SEP)*$(FILE_SUFFIX).o"
	Print #MakefileStream, vbTab & "$(DELETE_COMMAND) $(OBJ_DEBUG_DIR_MOVE)$(MOVE_PATH_SEP)*$(FILE_SUFFIX).o"
	Print #MakefileStream, vbTab & "$(DELETE_COMMAND) $(OBJ_RELEASE_DIR_MOVE)$(MOVE_PATH_SEP)*$(FILE_SUFFIX).obj"
	Print #MakefileStream, vbTab & "$(DELETE_COMMAND) $(OBJ_DEBUG_DIR_MOVE)$(MOVE_PATH_SEP)*$(FILE_SUFFIX).obj"
	Print #MakefileStream, vbTab & "$(DELETE_COMMAND) $(BIN_RELEASE_DIR_MOVE)$(MOVE_PATH_SEP)$(OUTPUT_FILE_NAME)"
	Print #MakefileStream, vbTab & "$(DELETE_COMMAND) $(BIN_DEBUG_DIR_MOVE)$(MOVE_PATH_SEP)$(OUTPUT_FILE_NAME)"
	Print #MakefileStream,

End Sub

Private Sub WriteCreateDirsTarget(ByVal MakefileStream As Long)

	Print #MakefileStream, "createdirs:"
	Print #MakefileStream, vbTab & "$(MKDIR_COMMAND) $(BIN_DEBUG_DIR_MOVE)"
	Print #MakefileStream, vbTab & "$(MKDIR_COMMAND) $(BIN_RELEASE_DIR_MOVE)"
	Print #MakefileStream, vbTab & "$(MKDIR_COMMAND) $(OBJ_DEBUG_DIR_MOVE)"
	Print #MakefileStream, vbTab & "$(MKDIR_COMMAND) $(OBJ_RELEASE_DIR_MOVE)"
	Print #MakefileStream,

End Sub

Private Sub WriteReleaseRule(ByVal MakefileStream As Long)

	Print #MakefileStream, "$(BIN_RELEASE_DIR)$(PATH_SEP)$(OUTPUT_FILE_NAME): $(OBJECTFILES_RELEASE)"
	' Print #MakefileStream, vbTab & "$(LD) $(LDFLAGS) $(LDLIBSBEGIN) $^ $(LDLIBS) $(LDLIBSEND) -o $@"
	Print #MakefileStream, vbTab & "$(CC) $(LDFLAGS) $(LDLIBSBEGIN) $^ $(LDLIBS) $(LDLIBSEND) -o $@"
	Print #MakefileStream,

End Sub

Private Sub WriteDebugRule(ByVal MakefileStream As Long)

	Print #MakefileStream, "$(BIN_DEBUG_DIR)$(PATH_SEP)$(OUTPUT_FILE_NAME): $(OBJECTFILES_DEBUG)"
	' Print #MakefileStream, vbTab & "$(LD) $(LDFLAGS) $(LDLIBSBEGIN) $^ $(LDLIBS) $(LDLIBSEND) -o $@"
	Print #MakefileStream, vbTab & "$(CC) $(LDFLAGS) $(LDLIBSBEGIN) $^ $(LDLIBS) $(LDLIBSEND) -o $@"
	Print #MakefileStream,

End Sub

Private Sub WriteAsmRule(ByVal MakefileStream As Long)

	Print #MakefileStream, "$(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).o: $(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).asm"
	Print #MakefileStream, vbTab & "$(AS) $(ASFLAGS) -o $@ $<"
	Print #MakefileStream,
	Print #MakefileStream, "$(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).o: $(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).asm"
	Print #MakefileStream, vbTab & "$(AS) $(ASFLAGS) -o $@ $<"
	Print #MakefileStream,

End Sub

Private Sub WriteCRule(ByVal MakefileStream As Long)

	Print #MakefileStream, "$(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).asm: $(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).c"
	Print #MakefileStream, vbTab & "$(CC) $(EXTRA_CFLAGS) $(CFLAGS) -o $@ $<"
	Print #MakefileStream,
	Print #MakefileStream, "$(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).asm: $(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).c"
	Print #MakefileStream, vbTab & "$(CC) $(EXTRA_CFLAGS) $(CFLAGS) -o $@ $<"
	Print #MakefileStream,

End Sub

Private Sub WriteResourceRule(ByVal MakefileStream As Long)

	Print #MakefileStream, "$(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).obj: src$(PATH_SEP)%.RC"
	Print #MakefileStream, vbTab & "$(GORC) $(GORCFLAGS) /fo $@ $<"
	Print #MakefileStream,
	Print #MakefileStream, "$(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).obj: src$(PATH_SEP)%.RC"
	Print #MakefileStream, vbTab & "$(GORC) $(GORCFLAGS) /fo $@ $<"
	Print #MakefileStream,

End Sub

Private Sub WriteBasRule(ByVal MakefileStream As Long, ByVal p As Parameter Ptr)

	Dim SourceFolderWithPathSep As String = AppendPathSeparator(p->SourceFolder)

	Dim AnyBasFile As String = ReplaceSolidusToPathSeparator(SourceFolderWithPathSep) & "%.bas"

	Dim AnyCFile As String = ReplaceSolidusToMovePathSeparator(SourceFolderWithPathSep) & "$*.c"

	Print #MakefileStream, "$(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).c: " & AnyBasFile
	Print #MakefileStream, vbTab & "$(FBC) $(FBCFLAGS) $<"

	If p->FixEmittedCode = FIX_EMITTED_CODE Then
		Print #MakefileStream, vbTab & "$(SCRIPT_COMMAND) /release " & AnyCFile
	End If

	Print #MakefileStream, vbTab & "$(MOVE_COMMAND) " & AnyCFile & " $(OBJ_RELEASE_DIR_MOVE)$(MOVE_PATH_SEP)$*$(FILE_SUFFIX).c"
	Print #MakefileStream,

	Print #MakefileStream, "$(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).c: " & AnyBasFile
	Print #MakefileStream, vbTab & "$(FBC) $(FBCFLAGS) $<"

	If p->FixEmittedCode = FIX_EMITTED_CODE Then
		Print #MakefileStream, vbTab & "$(SCRIPT_COMMAND) /debug " & AnyCFile
	End If

	Print #MakefileStream, vbTab & "$(MOVE_COMMAND) " & AnyCFile & " $(OBJ_DEBUG_DIR_MOVE)$(MOVE_PATH_SEP)$*$(FILE_SUFFIX).c"
	Print #MakefileStream,

End Sub

Private Function CreateCompilerParams(ByVal p As Parameter Ptr) As String

	Dim EmitterFlag As String = CodeGenerationToString(p)

	Dim UnicodeFlag As String
	Select Case p->Unicode

		Case DEFINE_ANSI
			UnicodeFlag = ""

		Case DEFINE_UNICODE
			UnicodeFlag = "-d UNICODE"

	End Select

	Dim RuntimeFlag As String
	Select Case p->UseRuntimeLibrary

		Case DEFINE_RUNTIME
			RuntimeFlag = ""

		Case DEFINE_WITHOUT_RUNTIME
			RuntimeFlag = "-d WITHOUT_RUNTIME"

	End Select

	Dim WinverFlag As String
	If p->MinimalOSVersion Then
		WinverFlag = "-d WINVER=" & p->MinimalOSVersion & " -d _WIN32_WINNT=" & p->MinimalOSVersion
	Else
		WinverFlag = ""
	End If

	Dim SubSystemFlag As String
	If p->FileSubsystem = SUBSYSTEM_WINDOW Then
		SubSystemFlag = "-s gui"
	Else
		SubSystemFlag = "-s console"
	End If

	Dim MaxErrorFlag As String = "-w error -maxerr 1"

	Dim OptimizationFlag As String = "-O 0"

	Dim OnlyAssemblyFlag As String = "-r"

	Dim ShowIncludesFlag As String = "-showincludes"

	Dim MainModuleFlag As String = "-m " & p->MainModuleName

	Dim CompilerParam As String = _
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

	Return CompilerParam

End Function

Private Sub RemoveVerticalLine(LinesVector() As String)

	' Remove all "|"

	Const VSPattern = "|"

	For i As Integer = LBound(LinesVector) To UBound(LinesVector)
		LinesVector(i) = Replace(LinesVector(i), VSPattern, "")
		LinesVector(i) = Trim(LinesVector(i))
	Next

End Sub

Private Sub RemoveOmmittedIncludes(LinesVector() As String)

	' Remove all strings "(filename.bi)"

	For i As Integer = LBound(LinesVector) To UBound(LinesVector)

		Dim First As String = Mid(LinesVector(i), 1, 1)

		If First = "(" Then
			Dim Length As Integer = Len(LinesVector(i))
			Dim Last As String = Mid(LinesVector(i), Length, 1)

			If Last = ")" Then
				LinesVector(i) = ""
			End If
		End If
	Next
End Sub

Private Sub ReplaceSolidusToPathSeparatorVector(LinesVector() As String)

	' Replace "\" to "$(PATH_SEP)"

	For i As Integer = LBound(LinesVector) To UBound(LinesVector)
		LinesVector(i) = ReplaceSolidusToPathSeparator(LinesVector(i))
	Next

End Sub

Private Sub AddSpaces(LinesVector() As String)

	' Append space to all strings
	For i As Integer = LBound(LinesVector) To UBound(LinesVector)
		Dim Length As Integer = Len(LinesVector(i))
		If Length Then
			LinesVector(i) = LinesVector(i) & " "
		End If
	Next

End Sub

Private Function ReadTextStream(ByVal Stream As Long) As String

	' Read file and return strings
	Dim Lines As String

	Do Until EOF(Stream)
		Dim ln As String
		Line Input #Stream, ln
		Lines = Lines & Trim(ln) & vbCrLf
	Loop

	Return Lines

End Function

Private Function GetBasFileWithoutPath(ByVal BasFile As String, ByVal p As Parameter Ptr) As String

	Dim ReplaceFind As String = AppendPathSeparator(p->SourceFolder)

	Return Replace(BasFile, ReplaceFind, "")

End Function

Private Sub WriteTextFile(ByVal MakefileStream As Long, ByVal BasFile As String, ByVal DependenciesLine As String, ByVal p As Parameter Ptr)

	Dim BasFileWithoutPath As String = GetBasFileWithoutPath(BasFile, p)

	Dim FileNameCExtenstionWitthSuffix As String
	Dim ObjectFileName As String

	Dim Finded As Integer = InStr(BasFile, ".bas")
	If Finded Then
		FileNameCExtenstionWitthSuffix = Replace(BasFileWithoutPath, ".bas", FileSuffix & ".c")
		ObjectFileName = Replace(BasFileWithoutPath, ".bas", FileSuffix & ".o")
	Else
		FileNameCExtenstionWitthSuffix = Replace(BasFileWithoutPath, ".RC", FileSuffix & ".obj")
		ObjectFileName = Replace(BasFileWithoutPath, ".RC", FileSuffix & ".obj")
	End If

	Dim FileNameWithPathSep As String = Replace(FileNameCExtenstionWitthSuffix, Solidus, MakefilePathSeparator)
	Dim ObjectFileNameWithPathSep As String = Replace(ObjectFileName, Solidus, MakefilePathSeparator)

	Dim FileNameWithDebug As String = DebugDirPrefix & FileNameWithPathSep
	Dim FileNameWithRelease As String = ReleaseDirPrefix & FileNameWithPathSep

	Dim ObjectFileNameWithDebug As String = ObjectFilesDebug & "+=" & DebugDirPrefix & ObjectFileNameWithPathSep
	Dim ObjectFileNameRelease As String = ObjectFilesRelease & "+=" & ReleaseDirPrefix & ObjectFileNameWithPathSep

	Dim ResultDebugString As String = FileNameWithDebug & ": " & DependenciesLine
	Dim ResultReleaseString As String = FileNameWithRelease & ": " & DependenciesLine

	Print #MakefileStream, ObjectFileNameWithDebug
	Print #MakefileStream, ObjectFileNameRelease
	Print #MakefileStream,
	Print #MakefileStream, ResultDebugString
	Print #MakefileStream, ResultReleaseString
	Print #MakefileStream,

End Sub

Dim Params As Parameter = Any
var resParse = ParseCommandLine(@Params)
If resParse Then
	Print "Can not parse command line"
	End(1)
End If

var resSetenv = WriteSetenv(@Params)
If resSetenv Then
	Print "Can not create environment file"
	End(2)
End If

var MakefileNumber = Freefile()
var resOpen = Open(Params.MakefileFileName, For Output, As MakefileNumber)
If resOpen Then
	Print "Can not create Makefile file"
	End(3)
End If

WriteTargets(MakefileNumber)
WriteCompilerToolChain(MakefileNumber)
WriteProcessorArch(MakefileNumber)
WriteOutputFilename(MakefileNumber, @Params)
WriteUtilsPath(MakefileNumber)
WriteArchSpecifiedPath(MakefileNumber)

WriteFbcFlags(MakefileNumber, @Params)
WriteGccFlags(MakefileNumber, @Params)
WriteAsmFlags(MakefileNumber)
WriteGorcFlags(MakefileNumber)
WriteLinkerFlags(MakefileNumber, @Params)

WriteLinkerLibraryes(MakefileNumber, @Params)

WriteReleaseTarget(MakefileNumber)
WriteDebugTarget(MakefileNumber)
WriteCleanTarget(MakefileNumber)
WriteCreateDirsTarget(MakefileNumber)

WriteReleaseRule(MakefileNumber)
WriteDebugRule(MakefileNumber)

WriteAsmRule(MakefileNumber)
WriteCRule(MakefileNumber)
WriteBasRule(MakefileNumber, @Params)
WriteResourceRule(MakefileNumber)

' WriteIncludeFile MakefileFileStream, Params

Close(MakefileNumber)

/'

#ifdef __FB_UNIX__
Const TEST_COMMAND = "fbc"
#else
Const TEST_COMMAND = """C:\Program Files (x86)\FreeBASIC-1.10.1-winlibs-gcc-9.3.0\fbc64.exe"""
#endif

Dim FileNumber As Long = Freefile()
Dim resOpen As Long = Open Pipe(TEST_COMMAND, For Input, As FileNumber)
If resOpen Then
	Print "Can not create process"
	End(1)
End If

Dim As String ln
Do Until EOF(FileNumber)
    Line Input #FileNumber, ln
    Print ln
Loop

Close(FileNumber)
'/

/'

Sub RemoveDefaultIncludes(LinesArray, p)
	' заголовочные файлы в системном каталоге обнуляем
	Dim i
	For i = LBound(LinesArray) To UBound(LinesArray)
		Dim IncludeFullName
		IncludeFullName = FSO.BuildPath(p.CompilerPath, "inc")

		Dim Finded
		Finded = InStr(LinesArray(i), IncludeFullName)

		If Finded Then
			LinesArray(i) = ""
		End If
	Next
End Sub

Function GetIncludesFromBasFile(Filepath, p)
	Dim FbcParam
	FbcParam = CreateCompilerParams(p)

	Dim CompilerFullName
	CompilerFullName = FSO.BuildPath(p.CompilerPath, p.FbcCompilerName)

	Dim IncludeFullName
	IncludeFullName = FSO.BuildPath(p.CompilerPath, "inc")

	Dim ProgramName
	ProgramName = """" & CompilerFullName & """" & " " & _
		FbcParam & _
		" -i " & p.SourceFolder & _
		" -i " & """" & IncludeFullName & """" & " """ & Filepath & """"
	WScript.Echo ProgramName

	Dim WshShell
	Set WshShell = CreateObject("WScript.Shell")
	Dim WshExec
	Set WshExec = WshShell.Exec(ProgramName)

	Dim Stream
	Set Stream = WshExec.StdOut
	Dim Lines
	Lines = ReadTextStream(Stream)

	Dim code
	code = WshExec.ExitCode

	Set Stream = Nothing
	Set WshExec = Nothing
	Set WshShell = Nothing

	' Remove temporary "c" file
	Dim FileC
	FileC = Replace(Filepath, ".bas", ".c")
	WScript.Echo FileC
	FSO.DeleteFile FileC

	If code > 0 Then
		Call Err.Raise(vbObjectError + 10, "FreeBASIC compiler error", Lines)
	End If

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
		FileNameWithParentDir = FSO.BuildPath(SrcFolder.Name, File.Name)

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

'/
