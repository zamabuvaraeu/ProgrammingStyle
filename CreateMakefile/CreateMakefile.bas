#ifndef MAX_PATH
#define MAX_PATH (260)
#endif

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

Enum UseSettingsEnvironment
	SETTINGS_ENVIRONMENT_ALWAYS
	DO_NOT_USE_SETTINGS_ENVIRONMENT
End Enum

Enum ParseResult
	PARSE_FAIL
	PARSE_SUCCESS
	PARSE_HELP
End Enum

Const WINVER_XP = 1281
Const WINVER_DEFAULT = WINVER_XP

Const vbTab = !"\t"
Const vbCrLf = !"\r\n"

#ifdef __FB_LINUX__
#define WriteSetenv WriteSetenvLinux
Const PATH_SEPARATOR = "/"
Const MakefileParametersFile = "setenv.sh"
#else
#define WriteSetenv WriteSetenvWin32
Const PATH_SEPARATOR = "\"
Const MakefileParametersFile = "setenv.cmd"
#endif

' Makefile variables
Const MakefilePathSeparator = "$(PATH_SEP)"
Const MakefileMovePathSeparator = "$(MOVE_PATH_SEP)"
Const ReleaseDirPrefix = "$(OBJ_RELEASE_DIR)$(PATH_SEP)"
Const DebugDirPrefix = "$(OBJ_DEBUG_DIR)$(PATH_SEP)"
Const FileSuffix = "$(FILE_SUFFIX)"
Const FBC_VER = "_FBC1101"
Const GCC_VER = "_GCC0930"

Type Parameter
	MakefileFileName As ZString * (MAX_PATH + 1)
	SourceFolder As ZString * (MAX_PATH + 1)
	CompilerPath As ZString * (MAX_PATH + 1)
	IncludePath As ZString * (MAX_PATH + 1)
	FbcCompilerName As ZString * (MAX_PATH + 1)
	OutputFileName As ZString * (MAX_PATH + 1)
	MainModuleName As ZString * (MAX_PATH + 1)
	ExeType As ExecutableType
	FileSubsystem As Subsystem
	Emitter As CodeEmitter
	FixEmittedCode As FixCode
	Unicode As UseUnicode
	UseRuntimeLibrary As UseRuntime
	AddressAware As ProcessAddressSpace
	ThreadingMode As MultiThreading
	UseEnvironmentFile As UseSettingsEnvironment
	MinimalOSVersion As Integer
	UseFileSuffix As Boolean
	Pedantic As Boolean
	CreateDirs As Boolean
End Type

Private Function Join( _
		LinesVector() As String, _
		ByVal Separator As String _
	) As String

	Dim resString As String

	For i As Integer = LBound(LinesVector) To UBound(LinesVector)
		If Len(LinesVector(i)) Then
			resString = resString & Separator & LinesVector(i)
		End If
	Next

	Return Trim(resString)

End Function

Private Function CodeGenerationToString( _
		ByVal p As Parameter Ptr _
	) As String

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

Private Function CreateCompilerParams( _
		ByVal p As Parameter Ptr _
	) As String

	Dim ParamVector(10) As String

	ParamVector(0) = CodeGenerationToString(p)

	Select Case p->Unicode

		Case DEFINE_ANSI
			ParamVector(1) = ""

		Case DEFINE_UNICODE
			ParamVector(1) = "-d UNICODE"

	End Select

	Select Case p->UseRuntimeLibrary

		Case DEFINE_RUNTIME
			ParamVector(2) = ""

		Case DEFINE_WITHOUT_RUNTIME
			ParamVector(2) = "-d WITHOUT_RUNTIME"

	End Select

	If p->MinimalOSVersion Then
		ParamVector(3) = "-d WINVER=" & p->MinimalOSVersion & " -d _WIN32_WINNT=" & p->MinimalOSVersion
	Else
		ParamVector(3) = ""
	End If

	If p->FileSubsystem = SUBSYSTEM_WINDOW Then
		ParamVector(4) = "-s gui"
	Else
		ParamVector(4) = "-s console"
	End If

	ParamVector(5) = "-w error -maxerr 1"

	ParamVector(6) = "-O 0"

	ParamVector(7) = "-r"

	ParamVector(8) = "-showincludes"

	ParamVector(9) = "-m " & p->MainModuleName

	ParamVector(10) = "-i " & p->SourceFolder

	Dim CompilerParam As String = Join(ParamVector(), " ")

	Return CompilerParam

End Function

Private Function Replace( _
		ByVal strFind As String, _
		ByVal strOld As String, _
		ByVal strNew As String _
	) As String

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

Private Function ReplaceOSPathSeparatorToMakePathSeparator( _
		ByVal strLine As String _
	) As String

	' Replace "\" to "$(PATH_SEP)"

	Dim strLine1 As String = Replace( _
		strLine, _
		PATH_SEPARATOR, _
		MakefilePathSeparator _
	)

	Return strLine1

End Function

Private Function ReplaceOSPathSeparatorToMovePathSeparator( _
		ByVal strLine As String _
	) As String

	' Replace "\" to "$(MOVE_PATH_SEP)"

	Dim strLine1 As String = Replace( _
		strLine, _
		PATH_SEPARATOR, _
		MakefileMovePathSeparator _
	)

	Return strLine1

End Function

Private Sub RemoveVerticalLine( _
		LinesVector() As String _
	)

	' Remove all "|"

	Const VSPattern = "|"

	For i As Integer = LBound(LinesVector) To UBound(LinesVector)
		LinesVector(i) = Replace(LinesVector(i), VSPattern, "")
		LinesVector(i) = Trim(LinesVector(i))
	Next

End Sub

Private Sub RemoveOmmittedIncludes( _
		LinesVector() As String _
	)

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

Private Sub ReplaceSolidusToPathSeparatorVector( _
		LinesVector() As String _
	)

	' Replace "\" to "$(PATH_SEP)"

	For i As Integer = LBound(LinesVector) To UBound(LinesVector)
		LinesVector(i) = ReplaceOSPathSeparatorToMakePathSeparator(LinesVector(i))
	Next

End Sub

Private Sub AddSpaces( _
		LinesVector() As String _
	)

	' Append space to all strings
	For i As Integer = LBound(LinesVector) To UBound(LinesVector)
		Dim Length As Integer = Len(LinesVector(i))
		If Length Then
			LinesVector(i) = LinesVector(i) & " "
		End If
	Next

End Sub

Private Function ReadTextStream( _
		ByVal Stream As Long _
	) As String

	' Read file and return strings
	Dim Lines As String

	Do Until EOF(Stream)
		Dim ln As String
		Line Input #Stream, ln
		Lines = Lines & Trim(ln) & vbCrLf
	Loop

	Return Lines

End Function

Private Function AppendPathSeparator( _
		ByVal strLine As String _
	) As String

	var Length = Len(strLine)

	var LastChar = Mid(strLine, Length, 1)

	If LastChar = PATH_SEPARATOR Then
		Return strLine
	End If

	Return strLine & PATH_SEPARATOR

End Function

Private Function GetFileNameWithoutPath( _
		ByVal BasFile As String, _
		ByVal Path As String _
	) As String

	Dim ReplaceFind As String = AppendPathSeparator(Path)

	Return Replace(BasFile, ReplaceFind, "")

End Function

Private Sub RemoveDefaultIncludes( _
		LinesVector() As String, _
		ByVal p As Parameter Ptr _
	)

	' Remove default include files

	For i As Integer = LBound(LinesVector) To UBound(LinesVector)

		Dim Finded As Integer = InStr(LinesVector(i), p->IncludePath)

		If Finded Then
			LinesVector(i) = ""
		End If
	Next

End Sub

Private Sub SplitRecursive( _
		LinesVector() As String, _
		ByVal strSource As String, _
		ByVal Separator As String _
	)

	Dim u As Integer = UBound(LinesVector)

	Dim Finded As Integer = InStr(strSource, Separator)

	If Finded Then
		Dim strLeft As String = Mid(strSource, 1, Finded - 1)

		ReDim Preserve LinesVector(u + 1)
		LinesVector(u) = strLeft

		Dim FromLength As Integer = Len(Separator)
		Dim strRight As String = Mid(strSource, Finded + FromLength)

		SplitRecursive(LinesVector(), strRight, Separator)
	Else
		LinesVector(u) = strSource
	End If

End Sub

Private Function BuildPath( _
		ByVal Directory As String, _
		ByVal File As String _
	) As String

	Dim DirLength As Integer = Len(Directory)
	Dim DirWithPathSeparator As String
	If DirLength Then
		DirWithPathSeparator = AppendPathSeparator(Directory)
	End If

	Dim FirstChar As String = Mid(File, 1, 1)

	If FirstChar = PATH_SEPARATOR Then
		Return DirWithPathSeparator & Mid(File, 2)
	End If

	Return DirWithPathSeparator & File

End Function

Private Function GetExtensionName( _
		ByVal filename As String _
	) As String

	Dim DotPosition As Integer = InStrRev(filename, ".")

	If DotPosition Then
		Return Mid(filename, DotPosition + 1)
	End If

	Return ""

End Function

Private Function GetExtensionOutputFile( _
		ByVal p As Parameter Ptr _
	)As String

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

	Return Extension

End Function

Private Function FileExists( _
		ByVal Filepath As String _
	) As Boolean

	var Filenumber = Freefile()
	var resOpen = Open(Filepath, For Input, As Filenumber)
	If resOpen Then
		Return False
	End If

	Close(Filenumber)

	Return True

End Function

Private Function WriteSetenvLinux( _
		ByVal p As Parameter Ptr _
	) As Integer

	var oStream = Freefile()
	var resOpen = Open(MakefileParametersFile, For Output, As oStream)
	If resOpen Then
		Return 1
	End If

	Close(oStream)

	Return 0

End Function

Private Function WriteSetenvWin32( _
		ByVal p As Parameter Ptr _
	) As Integer

	var oStream = Freefile()
	var resOpen = Open(MakefileParametersFile, For Output, As oStream)
	If resOpen Then
		Return 1
	End If

	Print #oStream, "@echo off"
	Print #oStream, "rem Setting up environment parameters for Makefile"
	Print #oStream,

	' PROCESSOR_ARCHITECTURE = AMD64 или x86
	Print #oStream, "rem Get current arch and set BIN and LIB folder"
	Print #oStream, "if %PROCESSOR_ARCHITECTURE% == AMD64 ("
	Print #oStream, "set BinFolder=bin\win64"
	Print #oStream, "set LibFolder=lib\win64"
	Print #oStream, "set MARCH=x86-64"
	Print #oStream, ") else ("
	Print #oStream, "set BinFolder=bin\win32"
	Print #oStream, "set LibFolder=lib\win32"
	Print #oStream, "set MARCH=i686"
	Print #oStream, ")"
	Print #oStream,

	Print #oStream, "rem Add compiler directory to PATH"
	Print #oStream, "set FBC_DIR=" & p->CompilerPath
	Print #oStream, "set PATH=%FBC_DIR%\%BinFolder%;%PATH%"
	Print #oStream, "rem Without quotes:"
	Print #oStream, "set LIB_DIR=%FBC_DIR%\%LibFolder%"
	Print #oStream, "set INC_DIR=%FBC_DIR%\inc"
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

	Print #oStream, "rem Parameters separator for gnu make // or / for mingw32-make"
	Print #oStream, "set PARAM_SEP=/"
	Print #oStream, "set PATH_SEP=/"
	Print #oStream, "set MOVE_PATH_SEP=\\"
	Print #oStream, "set MOVE_COMMAND=%ComSpec% $(PARAM_SEP)c move $(PARAM_SEP)y"
	Print #oStream, "set DELETE_COMMAND=%ComSpec% $(PARAM_SEP)c del $(PARAM_SEP)f $(PARAM_SEP)q"
	Print #oStream, "set MKDIR_COMMAND=%ComSpec% $(PARAM_SEP)c mkdir"
	If p->FixEmittedCode = FIX_EMITTED_CODE Then
		Print #oStream, "set CPREPROCESSOR_COMMAND=cscript.exe fix-emitted-code.vbs"
	Else
		Print #oStream, "set CPREPROCESSOR_COMMAND=%ComSpec% $(PARAM_SEP)c echo cscript.exe fix-emitted-code.vbs"
	End If
	Print #oStream,

	Print #oStream, "rem Source code directory"
	Print #oStream, "set SRC_DIR=" & p->SourceFolder
	Print #oStream,

	Print #oStream, "rem Set TRUE to use runtime libraries"
	If p->UseRuntimeLibrary = DEFINE_WITHOUT_RUNTIME Then
		Print #oStream, "set USE_RUNTIME=FALSE"
	Else
		Print #oStream, "set USE_RUNTIME=TRUE"
	End If

	Print #oStream, "rem Set FALSE to disable c-runtime libraries"
	Print #oStream, "rem set USE_CRUNTIME=TRUE"

	Print #oStream, "rem Set TRUE to use ld linker"
	Print #oStream, "set USE_LD_LINKER=TRUE"

	Print #oStream, "rem WinAPI version"
	Print #oStream, "set WINVER=" & p->MinimalOSVersion
	Print #oStream, "set _WIN32_WINNT=" & p->MinimalOSVersion

	Print #oStream, "rem Use unicode in WinAPI"
	If p->Unicode = DEFINE_UNICODE Then
		Print #oStream, "set USE_UNICODE=TRUE"
	Else
		Print #oStream, "set USE_UNICODE=FALSE"
	End If
	Print #oStream,

	Print #oStream, "rem Set variable FILE_SUFFIX to make the executable name different"
	Print #oStream, "rem for different toolchains, libraries, and compilation flags"
	Print #oStream, "set GCC_VER=" & GCC_VER
	Print #oStream, "set FBC_VER=" & FBC_VER

	If p->UseFileSuffix Then
		Print #oStream, "set FILE_SUFFIX=%GCC_VER%%FBC_VER%%RUNTIME%%WINVER%"
	Else
		Print #oStream, "rem set FILE_SUFFIX=%GCC_VER%%FBC_VER%%RUNTIME%%WINVER%"
	End If
	Dim Extension As String = GetExtensionOutputFile(p)
	Print #oStream, "set OUTPUT_FILE_NAME=" & p->OutputFilename & "%FILE_SUFFIX%" & Extension
	Print #oStream,

	Print #oStream, "rem Add any flags to compiler"
	Print #oStream, "rem set FBCFLAGS="
	Print #oStream, "rem set CFLAGS="
	Print #oStream, "rem set ASFLAGS="
	Print #oStream, "rem set GORCFLAGS="
	Print #oStream, "rem set LDFLAGS="
	Print #oStream,

	Print #oStream, "rem Linker script only for GCC x86, GCC x64 and Clang x86"
	Print #oStream, "rem Without quotes:"
	Print #oStream, "set LD_SCRIPT=%LIB_DIR%\fbextra.x"
	Print #oStream,
	Print #oStream, "rem Only for Clang x86"
	Print #oStream, "rem set TARGET_TRIPLET=i686-pc-windows-gnu"
	Print #oStream,
	Print #oStream, "rem Only for Clang AMD64"
	Print #oStream, "rem set TARGET_TRIPLET=x86_64-w64-pc-windows-msvc"
	Print #oStream,
	Print #oStream, "rem Link Time Optimization for release target"
	Print #oStream, "rem set FLTO=-flto"

	Print #oStream, "rem Only for wasm"
	Print #oStream, "set TARGET_TRIPLET=wasm32"

	Print #oStream,

	Print #oStream, "rem Libraries list"

	Dim crtLib As String
	Dim crtDebug As String

	' TODO Add profile libraries
	Dim Profile As Boolean = False
	If Profile Then
		crtLib = """%LIB_DIR%\gcrt2.o"""
		crtDebug = "-lgcc -lmingw32 -lmingwex -lmoldname -lgcc_eh -lgmon"
	Else
		crtLib = """%LIB_DIR%\crt2.o"""
		crtDebug = "-lgcc -lmingw32 -lmingwex -lmoldname -lgcc_eh"
	End If
	Print #oStream, "set OBJ_CRT_START=" & crtLib & " ""%LIB_DIR%\crtbegin.o"" ""%LIB_DIR%\fbrt0.o"""

	Print #oStream, "set LIBS_WIN95=-ladvapi32 -lcomctl32 -lcomdlg32 -lcrypt32 -lgdi32 -lkernel32 -lole32 -loleaut32 -lshell32 -lshlwapi -lwsock32 -luser32"
	Print #oStream, "set LIBS_WINNT=-lgdiplus -lws2_32 -lmswsock"
	Print #oStream, "set LIBS_GUID=-luuid"
	Print #oStream, "set LIBS_MSVCRT=-lmsvcrt"
	Print #oStream, "rem Add any user libraries"
	Print #oStream, "set LIBS_ANY="
	Print #oStream, "rem Add any FreeBASIC libraries sach as -lfbgfx"
	If p->ThreadingMode = DEFINE_MULTITHREADING_RUNTIME Then
		Print #oStream, "set LIBS_FB=-lfbmt"
	Else
		Print #oStream, "set LIBS_FB=-lfb"
	End If
	Print #oStream, "set LIBS_OS=%LIBS_WIN95% %LIBS_WINNT% %LIBS_GUID% %LIBS_MSVCRT% %LIBS_FB% %LIBS_ANY%"
	Print #oStream, "set LIBS_GCC=" & crtDebug
	Print #oStream, "set OBJ_CRT_END=""%LIB_DIR%\crtend.o"""
	Print #oStream,

	Print #oStream, "rem Create bin obj folders"
	Print #oStream, "rem mingw32-make createdirs"
	Print #oStream,
	Print #oStream, "rem Compile"
	Print #oStream, "rem mingw32-make all"

	Close(oStream)

	Return 0

End Function

Private Sub WriteHeader( _
		ByVal MakefileStream As Long _
	)

	Print #MakefileStream, ".PHONY: all debug release clean createdirs"
	Print #MakefileStream,
	Print #MakefileStream, "all: release debug"
	Print #MakefileStream,
	Print #MakefileStream, "# Legends:"
	Print #MakefileStream, "# $@ - target name"
	Print #MakefileStream, "# $^ - set of dependent files"
	Print #MakefileStream, "# $< - name of first dependency"
	Print #MakefileStream, "# % - pattern"
	Print #MakefileStream, "# $* - variable pattern"
	Print #MakefileStream,

End Sub

Private Sub WriteCompilerToolChain( _
		ByVal MakefileStream As Long _
	)

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

Private Sub WriteProcessorArch( _
		ByVal MakefileStream As Long _
	)

	Print #MakefileStream, "TARGET_TRIPLET ?="
	Print #MakefileStream,

End Sub

Private Sub WriteOutputFilename( _
		ByVal MakefileStream As Long, _
		ByVal p As Parameter Ptr _
	)

	Dim Extension As String = GetExtensionOutputFile(p)

	Print #MakefileStream, "USE_RUNTIME ?= TRUE"
	Print #MakefileStream, "USE_CRUNTIME ?= TRUE"
	Print #MakefileStream, "USE_LD_LINKER ?= TRUE"
	Print #MakefileStream, "FBC_VER ?= " & FBC_VER
	Print #MakefileStream, "GCC_VER ?= " & GCC_VER

	Print #MakefileStream, "ifeq ($(USE_RUNTIME),TRUE)"
	Print #MakefileStream, "RUNTIME = _RT"
	Print #MakefileStream, "else"
	Print #MakefileStream, "RUNTIME = _WRT"
	Print #MakefileStream, "endif"

	Print #MakefileStream, "OUTPUT_FILE_NAME ?= " & p->OutputFilename & "$(FILE_SUFFIX)" & Extension
	Print #MakefileStream,

End Sub

Private Sub WriteUtilsPathWin32( _
		ByVal MakefileStream As Long _
	)

	Print #MakefileStream, "PARAM_SEP ?= /"
	Print #MakefileStream, "PATH_SEP ?= /"
	Print #MakefileStream, "MOVE_PATH_SEP ?= \\"
	Print #MakefileStream,
	Print #MakefileStream, "MOVE_COMMAND ?= $(ComSpec) $(PARAM_SEP)c move $(PARAM_SEP)y"
	Print #MakefileStream, "DELETE_COMMAND ?= $(ComSpec) $(PARAM_SEP)c del $(PARAM_SEP)f $(PARAM_SEP)q"
	Print #MakefileStream, "MKDIR_COMMAND ?= $(ComSpec) $(PARAM_SEP)c mkdir"
	Print #MakefileStream, "CPREPROCESSOR_COMMAND ?= $(ComSpec) $(PARAM_SEP)c echo no need to fix code"
	Print #MakefileStream,

End Sub

Private Sub WriteArchSpecifiedPath( _
		ByVal MakefileStream As Long _
	)

	Print #MakefileStream, "ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)"
	Print #MakefileStream, "BIN_DEBUG_DIR ?= bin$(PATH_SEP)Debug$(PATH_SEP)x64"
	Print #MakefileStream, "BIN_RELEASE_DIR ?= bin$(PATH_SEP)Release$(PATH_SEP)x64"
	Print #MakefileStream, "OBJ_DEBUG_DIR ?= obj$(PATH_SEP)Debug$(PATH_SEP)x64"
	Print #MakefileStream, "OBJ_RELEASE_DIR ?= obj$(PATH_SEP)Release$(PATH_SEP)x64"
	Print #MakefileStream, "BIN_DEBUG_DIR_MOVE ?= bin$(MOVE_PATH_SEP)Debug$(MOVE_PATH_SEP)x64"
	Print #MakefileStream, "BIN_RELEASE_DIR_MOVE ?= bin$(MOVE_PATH_SEP)Release$(MOVE_PATH_SEP)x64"
	Print #MakefileStream, "OBJ_DEBUG_DIR_MOVE ?= obj$(MOVE_PATH_SEP)Debug$(MOVE_PATH_SEP)x64"
	Print #MakefileStream, "OBJ_RELEASE_DIR_MOVE ?= obj$(MOVE_PATH_SEP)Release$(MOVE_PATH_SEP)x64"
	Print #MakefileStream, "MARCH ?= x86-64"
	Print #MakefileStream, "else"
	Print #MakefileStream, "BIN_DEBUG_DIR ?= bin$(PATH_SEP)Debug$(PATH_SEP)x86"
	Print #MakefileStream, "BIN_RELEASE_DIR ?= bin$(PATH_SEP)Release$(PATH_SEP)x86"
	Print #MakefileStream, "OBJ_DEBUG_DIR ?= obj$(PATH_SEP)Debug$(PATH_SEP)x86"
	Print #MakefileStream, "OBJ_RELEASE_DIR ?= obj$(PATH_SEP)Release$(PATH_SEP)x86"
	Print #MakefileStream, "BIN_DEBUG_DIR_MOVE ?= bin$(MOVE_PATH_SEP)Debug$(MOVE_PATH_SEP)x86"
	Print #MakefileStream, "BIN_RELEASE_DIR_MOVE ?= bin$(MOVE_PATH_SEP)Release$(MOVE_PATH_SEP)x86"
	Print #MakefileStream, "OBJ_DEBUG_DIR_MOVE ?= obj$(MOVE_PATH_SEP)Debug$(MOVE_PATH_SEP)x86"
	Print #MakefileStream, "OBJ_RELEASE_DIR_MOVE ?= obj$(MOVE_PATH_SEP)Release$(MOVE_PATH_SEP)x86"
	Print #MakefileStream, "MARCH ?= i686"
	Print #MakefileStream, "endif"
	Print #MakefileStream,

End Sub

Private Sub WriteFbcFlags( _
		ByVal MakefileStream As Long, _
		ByVal p As Parameter Ptr _
	)

	Dim EmitterParam As String = CodeGenerationToString(p)

	Print #MakefileStream, "FBCFLAGS+=" & EmitterParam

	Print #MakefileStream, "ifeq ($(USE_UNICODE),TRUE)"
	Print #MakefileStream, "FBCFLAGS+=-d UNICODE"
	Print #MakefileStream, "FBCFLAGS+=-d _UNICODE"
	Print #MakefileStream, "endif"

	Print #MakefileStream, "ifneq ($(WINVER),)"
	Print #MakefileStream, "FBCFLAGS+=-d WINVER=$(WINVER)"
	Print #MakefileStream, "endif"
	Print #MakefileStream, "ifneq ($(_WIN32_WINNT),)"
	Print #MakefileStream, "FBCFLAGS+=-d _WIN32_WINNT=$(_WIN32_WINNT)"
	Print #MakefileStream, "endif"

	Print #MakefileStream, "FBCFLAGS+=-m " & p->MainModuleName

	Print #MakefileStream, "ifeq ($(USE_RUNTIME),TRUE)"
	Print #MakefileStream, "else"
	Print #MakefileStream, "FBCFLAGS+=-d WITHOUT_RUNTIME"
	Print #MakefileStream, "endif"

	Print #MakefileStream, "FBCFLAGS+=-w error -maxerr 1"

	Print #MakefileStream, "ifneq ($(INC_DIR),)"
	Print #MakefileStream, "FBCFLAGS+=-i ""$(INC_DIR)"""
	Print #MakefileStream, "endif"
	Print #MakefileStream, "FBCFLAGS+=-i " & p->SourceFolder

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

Private Sub WriteGccFlags( _
		ByVal MakefileStream As Long, _
		ByVal p As Parameter Ptr _
	)

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

	Print #MakefileStream, "ifneq ($(FLTO),)"
	Print #MakefileStream, "release: CFLAGS+=-flto"
	Print #MakefileStream, "endif"

	Print #MakefileStream, "debug: CFLAGS+=$(CFLAGS_DEBUG)"

	Print #MakefileStream,

End Sub

Private Sub WriteAsmFlags( _
		ByVal MakefileStream As Long _
	)

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

Private Sub WriteGorcFlags( _
		ByVal MakefileStream As Long _
	)

	' object output file will be in 64-bit format
	Print #MakefileStream, "ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)"
	Print #MakefileStream, "GORCFLAGS+=$(PARAM_SEP)machine X64"
	Print #MakefileStream, "endif"

	' no information messages
	Print #MakefileStream, "GORCFLAGS+=$(PARAM_SEP)ni"
	' create OBJ file
	Print #MakefileStream, "GORCFLAGS+=$(PARAM_SEP)o"

	' WINVER flag
	Print #MakefileStream, "ifneq ($(WINVER),)"
	Print #MakefileStream, "GORCFLAGS+=$(PARAM_SEP)d WINVER=$(WINVER)"
	Print #MakefileStream, "endif"
	Print #MakefileStream, "ifneq ($(_WIN32_WINNT),)"
	Print #MakefileStream, "GORCFLAGS+=$(PARAM_SEP)d _WIN32_WINNT=$(_WIN32_WINNT)"
	Print #MakefileStream, "endif"

	' DEBUG flag
	Print #MakefileStream, "GORCFLAGS_DEBUG=$(PARAM_SEP)d DEBUG"
	Print #MakefileStream, "debug: GORCFLAGS+=$(GORCFLAGS_DEBUG)"
	Print #MakefileStream,

End Sub

Private Sub WriteLinkerFlags( _
		ByVal MakefileStream As Long, _
		ByVal p As Parameter Ptr _
	)

	Select Case p->Emitter

		Case CODE_EMITTER_WASM32, CODE_EMITTER_WASM64
			' Set maximum stack size to 8MiB
			' -z stack-size=8388608

			' --initial-memory=<value> Initial size of the linear memory
			' --max-memory=<value>     Maximum size of the linear memory
			' --max-memory=8388608

			Print #MakefileStream, "ifeq ($(USE_LD_LINKER),TRUE)"
			Print #MakefileStream, "LDFLAGS+=-m wasm32"
			Print #MakefileStream, "LDFLAGS+=--allow-undefined"
			Print #MakefileStream, "LDFLAGS+=--no-entry"
			Print #MakefileStream, "LDFLAGS+=--export-all"

			Print #MakefileStream, "LDFLAGS+=-L ."
			Print #MakefileStream, "LDFLAGS+=-L ""$(LIB_DIR)"""

			Print #MakefileStream, "release: LDFLAGS+=--lto-O3 --gc-sections"
			Print #MakefileStream, "else"
			Print #MakefileStream, "endif"

		Case Else
			Print #MakefileStream, "ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)"

			Print #MakefileStream, "else"

			Select Case p->AddressAware

				Case LARGE_ADDRESS_UNAWARE

				Case LARGE_ADDRESS_AWARE
					Print #MakefileStream, "ifeq ($(USE_LD_LINKER),TRUE)"
					Print #MakefileStream, "LDFLAGS+=--large-address-aware"
					Print #MakefileStream, "else"
					Print #MakefileStream, "LDFLAGS+=-Wl,--large-address-aware"
					Print #MakefileStream, "endif"

			End Select

			Print #MakefileStream, "endif"

			Select Case p->FileSubsystem

				Case SUBSYSTEM_CONSOLE
					Print #MakefileStream, "ifeq ($(USE_LD_LINKER),TRUE)"
					Print #MakefileStream, "LDFLAGS+=--subsystem console"
					Print #MakefileStream, "else"
					Print #MakefileStream, "LDFLAGS+=-Wl,--subsystem,console"
					Print #MakefileStream, "endif"

				Case SUBSYSTEM_WINDOW
					Print #MakefileStream, "ifeq ($(USE_LD_LINKER),TRUE)"
					Print #MakefileStream, "LDFLAGS+=--subsystem windows"
					Print #MakefileStream, "else"
					Print #MakefileStream, "LDFLAGS+=-Wl,--subsystem,windows"
					Print #MakefileStream, "endif"

				Case SUBSYSTEM_NATIVE
					Print #MakefileStream, "ifeq ($(USE_LD_LINKER),TRUE)"
					Print #MakefileStream, "LDFLAGS+=--subsystem native"
					Print #MakefileStream, "else"
					Print #MakefileStream, "LDFLAGS+=-Wl,--subsystem,native"
					Print #MakefileStream, "endif"

			End Select

			Print #MakefileStream, "ifeq ($(USE_LD_LINKER),TRUE)"
			Print #MakefileStream, "LDFLAGS+=--no-seh --nxcompat"
			Print #MakefileStream, "else"
			Print #MakefileStream, "LDFLAGS+=-Wl,--no-seh -Wl,--nxcompat"
			Print #MakefileStream, "endif"

			Print #MakefileStream, "ifeq ($(USE_RUNTIME),TRUE)"
			Print #MakefileStream, "ifeq ($(USE_LD_LINKER),TRUE)"
			Print #MakefileStream, "LDFLAGS+=--stack 2097152,2097152"
			Print #MakefileStream, "else"
			Print #MakefileStream, "LDFLAGS+=-Wl,--stack 2097152,2097152"
			Print #MakefileStream, "endif"
			Print #MakefileStream, "endif"

			Print #MakefileStream, "ifeq ($(USE_LD_LINKER),TRUE)"
			Print #MakefileStream, "LDFLAGS+=-nostdlib"
			Print #MakefileStream, "else"
			Print #MakefileStream, "LDFLAGS+=-pipe -nostdlib"
			Print #MakefileStream, "endif"

			Print #MakefileStream, "LDFLAGS+=-L ."
			Print #MakefileStream, "LDFLAGS+=-L ""$(LIB_DIR)"""

			Print #MakefileStream, "ifneq ($(LD_SCRIPT),)"
			Print #MakefileStream, "LDFLAGS+=-T ""$(LD_SCRIPT)"""
			Print #MakefileStream, "endif"

			Print #MakefileStream, "ifeq ($(USE_LD_LINKER),TRUE)"
			Print #MakefileStream, "release: LDFLAGS+=-s --gc-sections"
			Print #MakefileStream, "else"
			Print #MakefileStream, "release: LDFLAGS+=-s -Wl,--gc-sections"
			Print #MakefileStream, "endif"
			Print #MakefileStream, "ifneq ($(FLTO),)"
			Print #MakefileStream, "release: LDFLAGS+=-flto"
			Print #MakefileStream, "endif"

			Print #MakefileStream, "debug: LDFLAGS+=$(LDFLAGS_DEBUG)"
			Print #MakefileStream, "debug: LDLIBS+=$(LDLIBS_DEBUG)"
	End Select

	Print #MakefileStream,

End Sub

Private Sub WriteLinkerLibraries( _
		ByVal MakefileStream As Long, _
		ByVal p As Parameter Ptr _
	)

	Select Case p->Emitter

		Case CODE_EMITTER_WASM32, CODE_EMITTER_WASM64
			' do Nothing

		Case Else
			' mainCRTStartup libraries
			Scope
				Print #MakefileStream, "ifeq ($(USE_RUNTIME),TRUE)"

				Print #MakefileStream, "ifeq ($(OBJ_CRT_START),)"

				' TODO For profile
				' Print #MakefileStream, "LDLIBSBEGIN+=gcrt2.o"

				Print #MakefileStream, "LDLIBSBEGIN+=""$(LIB_DIR)\crt2.o"""
				Print #MakefileStream, "LDLIBSBEGIN+=""$(LIB_DIR)\crtbegin.o"""
				Print #MakefileStream, "LDLIBSBEGIN+=""$(LIB_DIR)\fbrt0.o"""

				Print #MakefileStream, "else"
				Print #MakefileStream, "LDLIBSBEGIN+=$(OBJ_CRT_START)"
				Print #MakefileStream, "endif"

				Print #MakefileStream, "else"

				Print #MakefileStream, "ifeq ($(USE_CRUNTIME),TRUE)"
				Print #MakefileStream, "LDLIBSBEGIN+=""$(LIB_DIR)\crt2.o"""
				Print #MakefileStream, "LDLIBSBEGIN+=""$(LIB_DIR)\crtbegin.o"""
				Print #MakefileStream, "LDLIBSBEGIN+=""$(LIB_DIR)\fbrt0.o"""
				Print #MakefileStream, "else"
				Print #MakefileStream, "endif"

				Print #MakefileStream, "endif"
			End Scope

			Print #MakefileStream,

			Print #MakefileStream, "ifeq ($(USE_LD_LINKER),TRUE)"
			Print #MakefileStream, "LDLIBS+=--start-group"
			Print #MakefileStream, "else"
			Print #MakefileStream, "LDLIBS+=-Wl,--start-group"
			Print #MakefileStream, "endif"

			' OS libraries
			Scope
				Print #MakefileStream, "ifeq ($(LIBS_OS),)"

				' Windows API libraries
				Print #MakefileStream, "LDLIBS+=-ladvapi32 -lcomctl32 -lcomdlg32 -lcrypt32"
				Print #MakefileStream, "LDLIBS+=-lgdi32 -lgdiplus -lkernel32 -lmswsock"
				Print #MakefileStream, "LDLIBS+=-lole32 -loleaut32 -lshell32 -lshlwapi"
				Print #MakefileStream, "LDLIBS+=-lwsock32 -lws2_32 -luser32 -luuid"
				Print #MakefileStream, "LDLIBS+=-lmsvcrt"
				Print #MakefileStream, "else"
				Print #MakefileStream, "LDLIBS+=$(LIBS_OS)"
				Print #MakefileStream, "endif"
			End Scope

			' Runtime libraries
			Scope
				Print #MakefileStream, "ifeq ($(USE_RUNTIME),TRUE)"
				Select Case p->ThreadingMode

					Case DEFINE_SINGLETHREADING_RUNTIME
						Print #MakefileStream, "LDLIBS+=-lfb"

					Case DEFINE_MULTITHREADING_RUNTIME
						Print #MakefileStream, "LDLIBS+=-lfbmt"

				End Select

				Print #MakefileStream, "LDLIBS+=-lgcc -lmingw32 -lmingwex -lmoldname -lgcc_eh"
				Print #MakefileStream, "endif"
			End Scope

			Print #MakefileStream, "ifeq ($(USE_LD_LINKER),TRUE)"
			Print #MakefileStream, "LDLIBS+=--end-group"
			Print #MakefileStream, "else"
			Print #MakefileStream, "LDLIBS+=-Wl,--end-group"
			Print #MakefileStream, "endif"

			Print #MakefileStream,

			' Debug libraries
			Scope
				Print #MakefileStream, "ifeq ($(LIBS_GCC),)"
				' TODO For profile
				' Print #MakefileStream, "LDLIBS_DEBUG+=-lgmon"

				Print #MakefileStream, "LDLIBS_DEBUG+=-lgcc -lmingw32 -lmingwex -lmoldname -lgcc_eh"
				Print #MakefileStream, "else"
				Print #MakefileStream, "LDLIBS_DEBUG+=$(LIBS_GCC)"
				Print #MakefileStream, "endif"
			End Scope

			Print #MakefileStream,

			' Crtend libraries
			Scope
				Print #MakefileStream, "ifeq ($(USE_RUNTIME),TRUE)"
				Print #MakefileStream, "ifeq ($(OBJ_CRT_END),)"
				Print #MakefileStream, "LDLIBSEND+=""$(LIB_DIR)\crtend.o"""
				Print #MakefileStream, "else"
				Print #MakefileStream, "LDLIBSEND+=$(OBJ_CRT_END)"
				Print #MakefileStream, "endif"
				Print #MakefileStream, "else"
				Print #MakefileStream, "ifeq ($(USE_CRUNTIME),TRUE)"
				Print #MakefileStream, "LDLIBSEND+=""$(LIB_DIR)\crtend.o"""
				Print #MakefileStream, "else"
				Print #MakefileStream, "endif"
				Print #MakefileStream, "endif"
			End Scope

	End Select

	Print #MakefileStream,

End Sub

Private Sub WriteObjectFiles( _
		ByVal MakefileStream As Long, _
		ByVal BasFile As String, _
		ByVal DependenciesLine As String, _
		ByVal p As Parameter Ptr, _
		ByVal DependenciesNumber As Integer _
	)

	Dim BasFileWithoutPath As String = GetFileNameWithoutPath(BasFile, p->SourceFolder)

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

	Dim FileNameWithPathSep As String = ReplaceOSPathSeparatorToMakePathSeparator( _
		FileNameCExtenstionWitthSuffix _
	)
	Dim ObjectFileNameWithPathSep As String = ReplaceOSPathSeparatorToMakePathSeparator( _
		ObjectFileName _
	)

	Dim FileNameWithDebug As String = DebugDirPrefix & FileNameWithPathSep
	Dim FileNameWithRelease As String = ReleaseDirPrefix & FileNameWithPathSep

	Dim ObjectFileNameWithDebug As String = "OBJECTFILES_DEBUG+=" & DebugDirPrefix & ObjectFileNameWithPathSep
	Dim ObjectFileNameRelease As String = "OBJECTFILES_RELEASE+=" & ReleaseDirPrefix & ObjectFileNameWithPathSep

	Dim DepsVariable As String = "DEPENDENCIES" & "_" & Str(DependenciesNumber) & "=" & DependenciesLine

	Print #MakefileStream, ObjectFileNameWithDebug
	Print #MakefileStream, ObjectFileNameRelease
	Print #MakefileStream,
	Print #MakefileStream, DepsVariable
	Print #MakefileStream,
	Print #MakefileStream, FileNameWithDebug & ": " & "$(" & "DEPENDENCIES" & "_" & Str(DependenciesNumber) & ")"
	Print #MakefileStream, FileNameWithRelease & ": " & "$(" & "DEPENDENCIES" & "_" & Str(DependenciesNumber) & ")"
	Print #MakefileStream,

End Sub

Private Sub WriteApplicationTargets( _
		ByVal MakefileStream As Long _
	)

	Print #MakefileStream, "release: $(BIN_RELEASE_DIR)$(PATH_SEP)$(OUTPUT_FILE_NAME)"
	Print #MakefileStream,
	Print #MakefileStream, "debug: $(BIN_DEBUG_DIR)$(PATH_SEP)$(OUTPUT_FILE_NAME)"
	Print #MakefileStream,

End Sub

Private Sub WriteCleanTarget( _
		ByVal MakefileStream As Long _
	)

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

Private Sub WriteCreateDirsTarget( _
		ByVal MakefileStream As Long _
	)

	Print #MakefileStream, "createdirs:"
	Print #MakefileStream, vbTab & "$(MKDIR_COMMAND) $(BIN_DEBUG_DIR_MOVE)"
	Print #MakefileStream, vbTab & "$(MKDIR_COMMAND) $(BIN_RELEASE_DIR_MOVE)"
	Print #MakefileStream, vbTab & "$(MKDIR_COMMAND) $(OBJ_DEBUG_DIR_MOVE)"
	Print #MakefileStream, vbTab & "$(MKDIR_COMMAND) $(OBJ_RELEASE_DIR_MOVE)"
	Print #MakefileStream,

End Sub

Private Sub WriteApplicationRules( _
		ByVal MakefileStream As Long _
	)

	Print #MakefileStream, "$(BIN_RELEASE_DIR)$(PATH_SEP)$(OUTPUT_FILE_NAME): $(OBJECTFILES_RELEASE)"
	Print #MakefileStream, vbTab & "$(LD) $(LDFLAGS) $(LDLIBSBEGIN) $^ $(LDLIBS) $(LDLIBSEND) -o $@"
	Print #MakefileStream,
	Print #MakefileStream, "$(BIN_DEBUG_DIR)$(PATH_SEP)$(OUTPUT_FILE_NAME): $(OBJECTFILES_DEBUG)"
	Print #MakefileStream, vbTab & "$(LD) $(LDFLAGS) $(LDLIBSBEGIN) $^ $(LDLIBS) $(LDLIBSEND) -o $@"
	Print #MakefileStream,

End Sub

Private Sub WriteAsmRule( _
		ByVal MakefileStream As Long _
	)

	Print #MakefileStream, "$(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).o: $(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).asm"
	Print #MakefileStream, vbTab & "$(AS) $(ASFLAGS) -o $@ $<"
	Print #MakefileStream,

	Print #MakefileStream, "$(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).o: $(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).asm"
	Print #MakefileStream, vbTab & "$(AS) $(ASFLAGS) -o $@ $<"
	Print #MakefileStream,

End Sub

Private Sub WriteCRule( _
		ByVal MakefileStream As Long _
	)

	Print #MakefileStream, "$(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).asm: $(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).c"
	Print #MakefileStream, vbTab & "$(CC) $(EXTRA_CFLAGS) $(CFLAGS) -o $@ $<"
	Print #MakefileStream,

	Print #MakefileStream, "$(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).asm: $(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).c"
	Print #MakefileStream, vbTab & "$(CC) $(EXTRA_CFLAGS) $(CFLAGS) -o $@ $<"
	Print #MakefileStream,

End Sub

Private Sub WriteResourceRule( _
		ByVal MakefileStream As Long _
	)

	Print #MakefileStream, "$(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).obj: src$(PATH_SEP)%.RC"
	Print #MakefileStream, vbTab & "$(GORC) $(GORCFLAGS) $(PARAM_SEP)fo $@ $<"
	Print #MakefileStream,

	Print #MakefileStream, "$(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).obj: src$(PATH_SEP)%.RC"
	Print #MakefileStream, vbTab & "$(GORC) $(GORCFLAGS) $(PARAM_SEP)fo $@ $<"
	Print #MakefileStream,

End Sub

Private Sub WriteBasRule( _
		ByVal MakefileStream As Long, _
		ByVal p As Parameter Ptr _
	)

	Dim SourceFolderWithPathSep As String = AppendPathSeparator(p->SourceFolder)

	Dim AnyBasFile As String = ReplaceOSPathSeparatorToMakePathSeparator(SourceFolderWithPathSep) & "%.bas"

	Scope
		Print #MakefileStream, "$(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).c: " & AnyBasFile
		Print #MakefileStream, vbTab & "$(FBC) $(FBCFLAGS) $< -o $(OBJ_RELEASE_DIR)$(PATH_SEP)$*$(FILE_SUFFIX).c"
		Print #MakefileStream, vbTab & "$(CPREPROCESSOR_COMMAND) -release $(OBJ_RELEASE_DIR)$(PATH_SEP)$*$(FILE_SUFFIX).c"

		Print #MakefileStream,
	End Scope

	Scope
		Print #MakefileStream, "$(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).c: " & AnyBasFile
		Print #MakefileStream, vbTab & "$(FBC) $(FBCFLAGS) $< -o $(OBJ_DEBUG_DIR)$(PATH_SEP)$*$(FILE_SUFFIX).c"
		Print #MakefileStream, vbTab & "$(CPREPROCESSOR_COMMAND) -debug $(OBJ_DEBUG_DIR)$(PATH_SEP)$*$(FILE_SUFFIX).c"

		Print #MakefileStream,
	End Scope

End Sub

Private Sub GetLibraries( _
		ByVal file As String _
	)

	'static const char __attribute__((used, section(".fbctinf"))) __fbctinf[] = "-l\0kernel32\0-l\0gdi32\0-l\0msimg32\0-l\0user32\0-l\0version\0-l\0advapi32\0-l\0imm32\0-l\0comctl32";
	' Read c-file
	' Parse string
	' Get Libraries list

End sub

Private Function GetIncludesFromBasFile( _
		ByVal Filepath As String, _
		ByVal p As Parameter Ptr _
	) As String

	Dim FbcParam As String = CreateCompilerParams(p)

	Dim CompilerFullName As String = BuildPath( _
		p->CompilerPath, _
		p->FbcCompilerName _
	)

	Dim bExists As Boolean = FileExists(CompilerFullName)
	If bExists = False Then
		Print "FreeBASIC not exists in path " & CompilerFullName
		End(1)
	End If

	' TODO Find a way to use parameters with spaces

	Dim ProgramName As String = _
		"""" & CompilerFullName & """" & " " & _
		FbcParam & " " & _
		Filepath
	Print ProgramName

	Dim FileNumber As Long = Freefile()
	Dim resOpen As Long = Open Pipe(ProgramName, For Input, As FileNumber)
	If resOpen Then
		Print "Can not create process"
		End(1)
	End If

	Dim Lines As String = ReadTextStream(FileNumber)

	Close(FileNumber)

	Dim FileC As String = Replace(Filepath, ".bas", ".c")

	GetLibraries(FileC)

	' Remove temporary "c" file
	Kill(FileC)

	' TODO Get error code from child process
	' If code > 0 Then
	' 	Call Err.Raise(vbObjectError + 10, "FreeBASIC compiler error", Lines)
	' End If

	Return Lines

End Function

Private Function GetIncludesFromResFile( _
		ByVal Filepath As String, _
		ByVal p As Parameter Ptr _
	) As String

	' TODO Get real dependencies from resource file
	Dim ResourceIncludes As String = Filepath

	Dim ExtensionList(0 To ...) As String = { _
		"*.bmp", _
		"*.ico", _
		"*.dib", _
		"*.cur", _
		"*.rh", _
		"*.xml" _
	}

	For i As Integer = LBound(ExtensionList) To UBound(ExtensionList)
		Dim filespec As String = BuildPath(p->SourceFolder, ExtensionList(i))

		Dim filename As String = Dir(filespec)

		If Len(filename) Then
			Dim ext As String = GetExtensionName(filename)
			Dim FullFileName As String = BuildPath(p->SourceFolder, filename)

			If FileExists(FullFileName) Then
				ResourceIncludes = ResourceIncludes & vbCrLf & FullFileName
			End If
		End If
	Next

	Return ResourceIncludes

End Function

Private Sub CreateDependencies( _
		ByVal MakefileStream As Long, _
		ByVal oFile As String, _
		ByVal FileExtension As String, _
		ByVal p As Parameter Ptr, _
		ByVal DependenciesNumber As Integer _
	)

	ReDim LinesArray(0) As String
	Dim LinesArrayCreated As Boolean = Any

	Select Case UCase(FileExtension)

		Case "RC"
			SplitRecursive( _
				LinesArray(), _
				GetIncludesFromResFile(oFile, p), _
				vbCrLf _
			)
			LinesArrayCreated = True

		Case "BAS"
			SplitRecursive( _
				LinesArray(), _
				GetIncludesFromBasFile(oFile, p), _
				vbCrLf _
			)
			LinesArrayCreated = True

		Case Else
			LinesArrayCreated = False

	End Select

	If LinesArrayCreated Then
		Dim Original As String = LinesArray(0)

		RemoveVerticalLine(LinesArray())
		RemoveOmmittedIncludes(LinesArray())
		RemoveDefaultIncludes(LinesArray(), p)
		ReplaceSolidusToPathSeparatorVector(LinesArray())
		AddSpaces(LinesArray())

		Dim OneLine As String = Join(LinesArray(), "")

		WriteObjectFiles(MakefileStream, Original, RTrim(OneLine), p, DependenciesNumber)
	End If

End Sub

Private Sub GetFiles( _
		FilesVector() As String, _
		ByVal filespec As String _
	)

	Dim filename As String = Dir(filespec)

	Do While Len(filename)
		Dim u As Integer = UBound(FilesVector)
		ReDim Preserve FilesVector(u + 1)
		FilesVector(u) = filename
		filename = Dir()
	Loop

End Sub

Private Sub WriteDependencies( _
		FilesVector() As String, _
		ByVal MakefileStream As Long, _
		ByVal p As Parameter Ptr _
	)

	For i As Integer = LBound(FilesVector) To UBound(FilesVector)
		If Len(FilesVector(i)) Then
			Dim ext As String = GetExtensionName(FilesVector(i))
			Dim FullFileName As String = BuildPath(p->SourceFolder, FilesVector(i))
			CreateDependencies(MakefileStream, FullFileName, ext, p, i)
		End If
	Next

	Print #MakefileStream,

End Sub

Private Function ParseCommandLine( _
		ByVal p As Parameter Ptr _
	) As ParseResult

	p->MakefileFileName = "Makefile"
	p->SourceFolder = "src"
	p->CompilerPath = ""
	p->IncludePath = ""
	p->FbcCompilerName = ""
	p->OutputFileName = "a"
	p->MainModuleName = ""
	p->ExeType = OUTPUT_FILETYPE_EXE
	p->FileSubsystem = SUBSYSTEM_CONSOLE
	p->Emitter = CODE_EMITTER_GCC
	p->FixEmittedCode = NOT_FIX_EMITTED_CODE
	p->Unicode = DEFINE_ANSI
	p->UseRuntimeLibrary = DEFINE_RUNTIME
	p->AddressAware = LARGE_ADDRESS_UNAWARE
	p->ThreadingMode = DEFINE_SINGLETHREADING_RUNTIME
	p->UseEnvironmentFile = SETTINGS_ENVIRONMENT_ALWAYS
	p->MinimalOSVersion = WINVER_DEFAULT
	p->UseFileSuffix = False
	p->Pedantic = False
	p->CreateDirs = False

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

			Case "-i"
				p->IncludePath = sValue

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

				End Select

			Case "-subsystem"

				Select Case sValue

					Case "console"
						p->FileSubsystem = SUBSYSTEM_CONSOLE

					Case "windows"
						p->FileSubsystem = SUBSYSTEM_WINDOW

					Case "native"
						p->FileSubsystem = SUBSYSTEM_NATIVE

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

				End Select

			Case "-fix"
				If sValue = "true" Then
					p->FixEmittedCode = FIX_EMITTED_CODE
				End If

			Case "-unicode"
				If sValue = "true" Then
					p->Unicode = DEFINE_UNICODE
				End If

			Case "-wrt"
				If sValue = "true" Then
					p->UseRuntimeLibrary = DEFINE_WITHOUT_RUNTIME
				End If

			Case "-addressaware"
				If sValue = "true" Then
					p->AddressAware = LARGE_ADDRESS_AWARE
				End If

			Case "-multithreading"
				If sValue = "true" Then
					p->ThreadingMode = DEFINE_MULTITHREADING_RUNTIME
				End If

			Case "-usefilesuffix"
				If sValue = "true" Then
					p->UseFileSuffix = True
				End If

			Case "-pedantic"
				If sValue = "true" Then
					p->Pedantic = True
				End If

			Case "-create-environment-file"
				If sValue = "false" Then
					p->UseEnvironmentFile = DO_NOT_USE_SETTINGS_ENVIRONMENT
				End If

			Case "-winver"
				p->MinimalOSVersion = CInt(sValue)

			Case "-createdirs"
				If sValue = "true" Then
					p->CreateDirs = True
				End If

		End Select

		i += 1
		sKey = Command(i)
	Loop

	If Len(p->CompilerPath) = 0 Then
		Print "Path to compiler is not specified"
		Return PARSE_FAIL
	End If

	If Len(p->FbcCompilerName) = 0 Then
		Print "Compiler name is not specified"
		Return PARSE_FAIL
	End If

	If Len(p->IncludePath) = 0 Then
		p->IncludePath = BuildPath(p->CompilerPath, "inc")
	End If

	If Len(p->MainModuleName) = 0 Then
		p->MainModuleName = p->OutputFileName
	End If

	Return PARSE_SUCCESS

End Function

Private Sub PrintAllParameters( _
			ByVal p As Parameter Ptr _
	)

	Print "Makefile generator version 1.1"
	Print "Source folder", p->SourceFolder
	Dim FbcName As String = BuildPath(p->CompilerPath, p->FbcCompilerName)
	Print "Compiler name", FbcName
	Print "Makefile name", p->MakefileFileName
	Print "Include path", p->IncludePath
	Print "Output file name", p->OutputFileName
	Print "Main module name", p->MainModuleName

	Scope
		Dim sExeType As String
		Select Case p->ExeType
			Case OUTPUT_FILETYPE_EXE
				sExeType = "exe"
			Case OUTPUT_FILETYPE_DLL
				sExeType = "dll"
			Case OUTPUT_FILETYPE_LIBRARY
				sExeType = "static library"
			Case OUTPUT_FILETYPE_WASM32
				sExeType = "wasm32"
			Case OUTPUT_FILETYPE_WASM64
				sExeType = "wasm64"
		End Select
		Print "Exe type", sExeType
	End Scope

	Scope
		Dim sSys As String
		Select Case p->FileSubsystem
			Case SUBSYSTEM_CONSOLE
				sSys = "Console"
			Case SUBSYSTEM_WINDOW
				sSys = "Windows"
			Case SUBSYSTEM_NATIVE
				sSys = "Native"
		End Select
		Print "File subsystem", sSys
	End Scope

	Scope
		Dim sEmitter As String
		Select Case p->Emitter
			Case CODE_EMITTER_GCC
				sEmitter = "gcc"
			Case CODE_EMITTER_GAS
				sEmitter = "gas"
			Case CODE_EMITTER_GAS64
				sEmitter = "gas64"
			Case CODE_EMITTER_LLVM
				sEmitter = "llvm"
			Case CODE_EMITTER_WASM32
				sEmitter = "wasm"
			Case CODE_EMITTER_WASM64
				sEmitter = "wasm64"
		End Select
		Print "Code emitter", sEmitter
	End Scope

	Scope
		Dim sFix As String
		Select Case p->FixEmittedCode
			Case NOT_FIX_EMITTED_CODE
				sFix = "false"
			Case FIX_EMITTED_CODE
				sFix = "true"
		End Select
		Print "Fix emitted code", sFix
	End Scope

	Scope
		Dim sUnicode As String
		Select Case p->Unicode
			Case DEFINE_ANSI
				sUnicode = "false"
			Case DEFINE_UNICODE
				sUnicode = "true"
		End Select
		Print "Unicode", sUnicode
	End Scope

	Scope
		Dim sRuntime As String
		Select Case p->UseRuntimeLibrary
			Case DEFINE_RUNTIME
				sRuntime = "true"
			Case DEFINE_WITHOUT_RUNTIME
				sRuntime = "false"
		End Select
		Print "Use runtime libraries", sRuntime
	End Scope

	Scope
		Dim sAware As String
		Select Case p->AddressAware
			Case ProcessAddressSpace.LARGE_ADDRESS_UNAWARE
				sAware = "unaware"
			Case ProcessAddressSpace.LARGE_ADDRESS_AWARE
				sAware = "aware"
		End Select
		Print "Address aware", sAware
	End Scope

	Scope
		Dim sMode As String
		Select Case p->ThreadingMode
			Case DEFINE_SINGLETHREADING_RUNTIME
				sMode = "single threading"
			Case DEFINE_MULTITHREADING_RUNTIME
				sMode = "multithreading"
		End Select
		Print "Threading mode", sMode
	End Scope

	Scope
		Dim sEnviron As String
		Select Case p->UseEnvironmentFile
			Case SETTINGS_ENVIRONMENT_ALWAYS
				sEnviron = "true"
			Case DO_NOT_USE_SETTINGS_ENVIRONMENT
				sEnviron = "false"
		End Select
		Print "Create environment file", sEnviron
	End Scope

	Scope
		Print "Minimal OS version", p->MinimalOSVersion
	End Scope

	Scope
		Dim sSuffix As String
		If p->UseFileSuffix Then
			sSuffix = "true"
		Else
			sSuffix = "false"
		End If
		Print "Use file suffix", sSuffix
	End Scope

	Scope
		Dim sPedantic As String
		If p->Pedantic Then
			sPedantic = "true"
		Else
			sPedantic = "false"
		End If
		Print "Pedantic", sPedantic
	End Scope

	Scope
		Dim sCreateDirs As String
		If p->CreateDirs Then
			sCreateDirs = "true"
		Else
			sCreateDirs = "false"
		End If
		Print "Create bin obj directories", sCreateDirs
	End Scope

	Print ""

End Sub

Dim pParams As Parameter Ptr = Allocate(SizeOf(Parameter))
If pParams = 0 Then
	Print "Out of memory"
	End(1)
End If

Scope
	var resParse = ParseCommandLine(pParams)

	Select Case resParse

		Case PARSE_FAIL
			Print "Can not parse command line"
			End(1)

		Case PARSE_SUCCESS
			PrintAllParameters(pParams)

		Case PARSE_HELP
			' Just print help and exit
			End(0)

	End Select
End Scope

If pParams->CreateDirs Then
	Print "Create bin obj directories..."
	MkDir("bin")
	MkDir("bin" & PATH_SEPARATOR & "Debug")
	MkDir("bin" & PATH_SEPARATOR & "Debug" & PATH_SEPARATOR  & "x64")
	MkDir("bin" & PATH_SEPARATOR & "Debug" & PATH_SEPARATOR  & "x86")

	MkDir("bin" & PATH_SEPARATOR & "Release")
	MkDir("bin" & PATH_SEPARATOR & "Release" & PATH_SEPARATOR  & "x64")
	MkDir("bin" & PATH_SEPARATOR & "Release" & PATH_SEPARATOR  & "x86")

	MkDir("obj")
	MkDir("obj" & PATH_SEPARATOR & "Debug")
	MkDir("obj" & PATH_SEPARATOR & "Debug" & PATH_SEPARATOR  & "x64")
	MkDir("obj" & PATH_SEPARATOR & "Debug" & PATH_SEPARATOR  & "x86")

	MkDir("obj" & PATH_SEPARATOR & "Release")
	MkDir("obj" & PATH_SEPARATOR & "Release" & PATH_SEPARATOR  & "x64")
	MkDir("obj" & PATH_SEPARATOR & "Release" & PATH_SEPARATOR  & "x86")
End If

If pParams->UseEnvironmentFile = SETTINGS_ENVIRONMENT_ALWAYS Then
	Print "Create environment file..."
	var resSetenv = WriteSetenv(pParams)
	If resSetenv Then
		Print "Can not create environment file"
		End(2)
	End If
End If

ReDim FilesVector(0) As String
Scope
	Print "Find source files in folder", pParams->SourceFolder
	Dim filespec As String = BuildPath(pParams->SourceFolder, "*.*")
	GetFiles(FilesVector(), filespec)

	For i As Integer = LBound(FilesVector) To UBound(FilesVector)
		Print FilesVector(i)
	Next
End Scope

Print "Create Makefile..."
var MakefileNumber = Freefile()
var resOpen = Open(pParams->MakefileFileName, For Output, As MakefileNumber)
If resOpen Then
	Print "Can not create Makefile file"
	End(3)
End If

WriteHeader(MakefileNumber)

WriteCompilerToolChain(MakefileNumber)
WriteProcessorArch(MakefileNumber)
WriteOutputFilename(MakefileNumber, pParams)
WriteUtilsPathWin32(MakefileNumber)
WriteArchSpecifiedPath(MakefileNumber)

WriteFbcFlags(MakefileNumber, pParams)
WriteGccFlags(MakefileNumber, pParams)
WriteAsmFlags(MakefileNumber)
WriteGorcFlags(MakefileNumber)
WriteLinkerFlags(MakefileNumber, pParams)
WriteLinkerLibraries(MakefileNumber, pParams)

Print "Get Dependencies..."
WriteDependencies(FilesVector(), MakefileNumber, pParams)

WriteApplicationTargets(MakefileNumber)
WriteCleanTarget(MakefileNumber)
WriteCreateDirsTarget(MakefileNumber)

' bas -> c -> asm -> o + obj -> exe
' rc -> obj -> exe
WriteApplicationRules(MakefileNumber)
WriteAsmRule(MakefileNumber)
WriteCRule(MakefileNumber)
WriteBasRule(MakefileNumber, pParams)
WriteResourceRule(MakefileNumber)

Close(MakefileNumber)
Deallocate(pParams)

Print "Done"
