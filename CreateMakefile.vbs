Option Explicit

Const SUBSYSTEM_CONSOLE = 0
Const SUBSYSTEM_WINDOW = 1
Const SUBSYSTEM_NATIVE = 2

Const OUTPUT_FILETYPE_EXE = 0
Const OUTPUT_FILETYPE_DLL = 1
Const OUTPUT_FILETYPE_LIBRARY = 2

Const CODE_EMITTER_GCC = 0
Const CODE_EMITTER_GAS = 1
Const CODE_EMITTER_GAS64 = 2
Const CODE_EMITTER_LLVM = 3

Const DEFINE_ANSI = 0
Const DEFINE_UNICODE = 1

Const DEFINE_RUNTIME = 0
Const DEFINE_WITHOUT_RUNTIME = 1

Const SourceFolder = "src"
Const CompilerPath = "C:\Program Files (x86)\FreeBASIC-1.10.0-winlibs-gcc-9.3.0"
Const FbcCompilerName = "fbc64.exe"

Const Solidus = "\"
Const MakefilePathSeparator = "$(PATH_SEP)"
Const ReleaseDirPrefix = "$(OBJ_RELEASE_DIR)$(PATH_SEP)"
Const DebugDirPrefix = "$(OBJ_DEBUG_DIR)$(PATH_SEP)"
Const FileSuffix = "$(FILE_SUFFIX)"
Const ObjectFilesRelease = "OBJECTFILES_RELEASE"
Const ObjectFilesDebug = "OBJECTFILES_DEBUG"

Const MakefileFileName = "Makefile"


Dim OutputFileName
OutputFileName = "Station922"
Dim ExeType
ExeType = OUTPUT_FILETYPE_EXE
Dim FileSubsystem
FileSubsystem = SUBSYSTEM_CONSOLE


Dim FSO
Set FSO = CreateObject("Scripting.FileSystemObject")

Dim MakefileFileStream
Set MakefileFileStream = FSO.OpenTextFile(MakefileFileName, 2, True, 0)

WriteTargets MakefileFileStream
WriteCompilerToolChain MakefileFileStream
WriteProcessorArch MakefileFileStream
WriteOutputFilename MakefileFileStream, OutputFileName, ExeType
WriteUtilsPath MakefileFileStream
WriteCodeEmitter MakefileFileStream
WriteArchSpecifiedFlags MakefileFileStream
WriteArchSpecifiedPath MakefileFileStream
WriteFbcFlags MakefileFileStream, FileSubsystem
WriteGccFlags MakefileFileStream
WriteAsmFlags MakefileFileStream
WriteGorcFlags MakefileFileStream
WriteLinkerFlags MakefileFileStream, FileSubsystem
WriteLinkerLibraryes MakefileFileStream
WriteIncludeFile MakefileFileStream
WriteReleaseFlags MakefileFileStream
WriteDebugFlags MakefileFileStream
WriteCleanTarget MakefileFileStream
WriteCreateDirsTarget MakefileFileStream
WriteReleaseRule MakefileFileStream
WriteAsmRule MakefileFileStream
WriteCRule MakefileFileStream
WriteBasRule MakefileFileStream
WriteResourceRule MakefileFileStream

Set MakefileFileStream = Nothing
Set FSO = Nothing

Function CreateCompilerParams(Emitter, Unicode, Runtime, SubSystem)
	
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
	End Select
	
	Dim UnicodeParam
	Select Case Unicode
		Case DEFINE_ANSI
			UnicodeParam = ""
		Case DEFINE_UNICODE
			UnicodeParam = "-d UNICODE"
	End Select
	
	Dim RuntimeParam
	Select Case Unicode
		Case DEFINE_RUNTIME
			RuntimeParam = ""
		Case DEFINE_WITHOUT_RUNTIME
			RuntimeParam = "-d WITHOUT_RUNTIME"
	End Select
	
	Dim SubSystemParam
	If SubSystem = SUBSYSTEM_WINDOW Then
		SubSystemParam = "-s gui"
	Else
		SubSystemParam = "-s console"
	End If
	
	Dim CompilerParam
	CompilerParam = EmitterParam & " " & UnicodeParam & " " & _
		RuntimeParam & " " & SubSystemParam & " " & _
	"-maxerr 1 -r -O 0 -showincludes"
	
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

Sub WriteOutputFilename(MakefileStream, OutputFilename, FileType)
	Dim Extension
	Select Case FileType
		Case OUTPUT_FILETYPE_EXE
			Extension = ".exe"
		Case OUTPUT_FILETYPE_DLL
			Extension = ".dll"
		Case OUTPUT_FILETYPE_LIBRARY
			Extension = ".a"
	End Select
	
	MakefileStream.WriteLine "FBC_VER ?= FBC1100"
	MakefileStream.WriteLine "GCC_VER ?= GCC0930"
	MakefileStream.WriteLine "FILE_SUFFIX=_$(GCC_VER)_$(FBC_VER)"
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
	MakefileStream.WriteLine "SCRIPT_COMMAND ?= cscript.exe //nologo replace.vbs"
	MakefileStream.WriteLine 
End Sub

Sub WriteCodeEmitter(MakefileStream)
	MakefileStream.WriteLine "ifeq ($(CODE_EMITTER),gcc)"
	MakefileStream.WriteLine "FBCFLAGS+=-gen gcc"
	MakefileStream.WriteLine "else"
	MakefileStream.WriteLine "FBCFLAGS+=-gen gcc"
	MakefileStream.WriteLine "endif"
	MakefileStream.WriteLine 
End Sub

Sub WriteArchSpecifiedFlags(MakefileStream)
	MakefileStream.WriteLine "ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)"
	MakefileStream.WriteLine "CFLAGS+=-m64"
	MakefileStream.WriteLine "ASFLAGS+=--64"
	MakefileStream.WriteLine "ENTRY_POINT=EntryPoint"
	MakefileStream.WriteLine "LDFLAGS+=-m i386pep"
	MakefileStream.WriteLine "GORCFLAGS+=/machine X64"
	MakefileStream.WriteLine "else"
	MakefileStream.WriteLine "CFLAGS+=-m32"
	MakefileStream.WriteLine "ASFLAGS+=--32"
	MakefileStream.WriteLine "ENTRY_POINT=_EntryPoint@0"
	MakefileStream.WriteLine "LDFLAGS+=-m i386pe --large-address-aware"
	MakefileStream.WriteLine "GORCFLAGS+="
	MakefileStream.WriteLine "endif"
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

Sub WriteFbcFlags(MakefileStream, SubSystem)
	MakefileStream.WriteLine "FBCFLAGS+=-d UNICODE -d WITHOUT_RUNTIME"
	MakefileStream.WriteLine "FBCFLAGS+=-w error -maxerr 1"
	MakefileStream.WriteLine "FBCFLAGS+=-i src"
	MakefileStream.WriteLine "ifneq ($(INC_DIR),)"
	MakefileStream.WriteLine "FBCFLAGS+=-i ""$(INC_DIR)"""
	MakefileStream.WriteLine "endif"
	MakefileStream.WriteLine "FBCFLAGS+=-r"
	If SubSystem = SUBSYSTEM_WINDOW Then
		MakefileStream.WriteLine "FBCFLAGS+=-s gui"
	Else
		MakefileStream.WriteLine "FBCFLAGS+=-s console"
	End If
	MakefileStream.WriteLine "FBCFLAGS+=-O 0"
	MakefileStream.WriteLine "FBCFLAGS_DEBUG+=-g"
	MakefileStream.WriteLine 
End Sub

Sub WriteGccFlags(MakefileStream)
	MakefileStream.WriteLine "CFLAGS+=-march=$(MARCH)"
	MakefileStream.WriteLine "ifneq ($(TARGET_TRIPLET),)"
	MakefileStream.WriteLine "CFLAGS+=--target=$(TARGET_TRIPLET)"
	MakefileStream.WriteLine "endif"
	MakefileStream.WriteLine "CFLAGS+=-pipe"
	MakefileStream.WriteLine "CFLAGS+=-Wall -Werror -Wextra -pedantic"
	MakefileStream.WriteLine "CFLAGS+=-Wno-unused-label -Wno-unused-function -Wno-unused-parameter -Wno-unused-variable"
	MakefileStream.WriteLine "CFLAGS+=-Wno-dollar-in-identifier-extension -Wno-language-extension-token"
	MakefileStream.WriteLine "CFLAGS+=-Wno-parentheses-equality"
	MakefileStream.WriteLine "CFLAGS_DEBUG+=-g -O0"
	MakefileStream.WriteLine "FLTO ?="
	MakefileStream.WriteLine 
End Sub

Sub WriteAsmFlags(MakefileStream)
	MakefileStream.WriteLine "ASFLAGS+="
	MakefileStream.WriteLine "ASFLAGS_DEBUG+="
	MakefileStream.WriteLine 
End Sub

Sub WriteGorcFlags(MakefileStream)
	MakefileStream.WriteLine "GORCFLAGS+=/ni /o /d FROM_MAKEFILE"
	MakefileStream.WriteLine "GORCFLAGS_DEBUG=/d DEBUG"
	MakefileStream.WriteLine 
End Sub

Sub WriteLinkerFlags(MakefileStream, SubSystem)
	Select Case SubSystem
		Case SUBSYSTEM_CONSOLE
			MakefileStream.WriteLine "LDFLAGS+=-subsystem console"
		Case SUBSYSTEM_WINDOW
			MakefileStream.WriteLine "LDFLAGS+=-subsystem windows"
		Case SUBSYSTEM_NATIVE
			MakefileStream.WriteLine "LDFLAGS+=-subsystem native"
	End Select
	MakefileStream.WriteLine "LDFLAGS+=--no-seh --nxcompat"
	MakefileStream.WriteLine "LDFLAGS+=-e $(ENTRY_POINT)"
	MakefileStream.WriteLine "LDFLAGS+=-L ""$(LIB_DIR)"""
	MakefileStream.WriteLine "ifneq ($(LD_SCRIPT),)"
	MakefileStream.WriteLine "LDFLAGS+=-T ""$(LD_SCRIPT)"""
	MakefileStream.WriteLine "endif"
	MakefileStream.WriteLine 
End Sub

Sub WriteLinkerLibraryes(MakefileStream)
	MakefileStream.WriteLine "LDLIBS+=-ladvapi32 -lkernel32 -lmsvcrt -lmswsock -lcrypt32 -loleaut32"
	MakefileStream.WriteLine "LDLIBS+=-lole32 -lshell32 -lshlwapi -lws2_32 -luser32"
	MakefileStream.WriteLine "LDLIBS_DEBUG+=-lgcc -lmingw32 -lmingwex -lmoldname -lgcc_eh -lucrt -lucrtbase"
	MakefileStream.WriteLine 
End Sub

Sub WriteIncludeFile(MakefileStream)
	' MakefileStream.WriteLine "# Object files are loaded from a file ""dependencies.mk"""
	' MakefileStream.WriteLine "include dependencies.mk"
	
	Dim SrcFolder
	Set SrcFolder = FSO.GetFolder(SourceFolder)
	
	Dim File
	For Each File In SrcFolder.Files
		Dim ext
		ext = FSO.GetExtensionName(File.Path)
		CreateDependencies MakefileStream, File, ext, File.Path
	Next
	
	Set SrcFolder = Nothing
	
	MakefileStream.WriteLine 
End Sub

Sub WriteReleaseFlags(MakefileStream)
	MakefileStream.WriteLine "release: CFLAGS+=$(CFLAGS_RELEASE)"
	MakefileStream.WriteLine "release: CFLAGS+=-fno-math-errno -fno-exceptions"
	MakefileStream.WriteLine "release: CFLAGS+=-fno-unwind-tables -fno-asynchronous-unwind-tables"
	MakefileStream.WriteLine "release: CFLAGS+=-O3 -fno-ident -fdata-sections -ffunction-sections"
	MakefileStream.WriteLine "ifneq ($(FLTO),)"
	MakefileStream.WriteLine "release: CFLAGS+=$(FLTO)"
	MakefileStream.WriteLine "endif"
	MakefileStream.WriteLine "release: ASFLAGS+=--strip-local-absolute"
	MakefileStream.WriteLine "release: LDFLAGS+=-s --gc-sections"
	MakefileStream.WriteLine "release: $(BIN_RELEASE_DIR)$(PATH_SEP)$(OUTPUT_FILE_NAME)"
	MakefileStream.WriteLine 
End Sub

Sub WriteDebugFlags(MakefileStream)
	MakefileStream.WriteLine "debug: FBCFLAGS+=$(FBCFLAGS_DEBUG)"
	MakefileStream.WriteLine "debug: CFLAGS+=$(CFLAGS_DEBUG)"
	MakefileStream.WriteLine "debug: ASFLAGS+=$(ASFLAGS_DEBUG)"
	MakefileStream.WriteLine "debug: GORCFLAGS+=$(GORCFLAGS_DEBUG)"
	MakefileStream.WriteLine "debug: LDFLAGS+=$(LDFLAGS_DEBUG)"
	MakefileStream.WriteLine "debug: LDLIBS+=$(LDLIBS_DEBUG)"
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
	MakefileStream.WriteLine "	$(LD) $(LDFLAGS) $^ $(LDLIBS) -o $@"
	MakefileStream.WriteLine 
	MakefileStream.WriteLine "$(BIN_DEBUG_DIR)$(PATH_SEP)$(OUTPUT_FILE_NAME):   $(OBJECTFILES_DEBUG)"
	MakefileStream.WriteLine "	$(LD) $(LDFLAGS) $^ $(LDLIBS) -o $@"
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

Sub WriteBasRule(MakefileStream)
	MakefileStream.WriteLine "$(OBJ_RELEASE_DIR)$(PATH_SEP)%$(FILE_SUFFIX).c: src$(PATH_SEP)%.bas"
	MakefileStream.WriteLine "	$(FBC) $(FBCFLAGS) $<"
	MakefileStream.WriteLine "	$(SCRIPT_COMMAND) /release src$(MOVE_PATH_SEP)$*.c"
	MakefileStream.WriteLine "	$(MOVE_COMMAND) src$(MOVE_PATH_SEP)$*.c $(OBJ_RELEASE_DIR_MOVE)$(MOVE_PATH_SEP)$*$(FILE_SUFFIX).c"
	MakefileStream.WriteLine
	MakefileStream.WriteLine "$(OBJ_DEBUG_DIR)$(PATH_SEP)%$(FILE_SUFFIX).c: src$(PATH_SEP)%.bas"
	MakefileStream.WriteLine "	$(FBC) $(FBCFLAGS) $<"
	MakefileStream.WriteLine "	$(SCRIPT_COMMAND) /debug src$(MOVE_PATH_SEP)$*.c"
	MakefileStream.WriteLine "	$(MOVE_COMMAND) src$(MOVE_PATH_SEP)$*.c $(OBJ_DEBUG_DIR_MOVE)$(MOVE_PATH_SEP)$*$(FILE_SUFFIX).c"
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
	' ������ ��� ��������� "|"
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
	' ���� ������ � ������ � ���� "(filename.bi)"
	' �� � ��������
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
	' ������������ ����� � ��������� �������� ��������
	Dim i
	For i = LBound(LinesArray) To UBound(LinesArray)
		Dim Finded
		Finded = InStr(LinesArray(i), CompilerPath & Solidus & "inc")
		If Finded Then
			LinesArray(i) = ""
		End If
	Next
End Sub

Sub ReplaceSolidusToPathSeparator(LinesArray)
	' �������� "\" �� "$(PATH_SEP)"
	Dim i
	For i = LBound(LinesArray) To UBound(LinesArray)
		Dim Finded
		Finded = InStr(LinesArray(i), Solidus)
		Do While Finded
			LinesArray(i) = Replace(LinesArray(i), Solidus, MakefilePathSeparator)
			Finded = InStr(LinesArray(i), Solidus)
		Loop
	Next
End Sub

Sub AddSpaces(LinesArray)
	' ��������� ������ � ����� ������ ������
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
	' ������ ��������� ���� � ���������� ������
	Dim TextStream
	Set TextStream = FSO.OpenTextFile(FileName, 1)
	
	Dim strLines
	strLines = TextStream.ReadAll

	TextStream.Close
	Set TextStream = Nothing
	
	ReadTextFile = strLines
End Function

Function ReadTextStream(Stream)
	' ������ ��������� ����� � ���������� ������
	Dim Lines
	Lines = ""
	Do While Not Stream.AtEndOfStream
		Lines = Lines & Trim(Stream.ReadLine()) & vbCrLf
	Loop
	ReadTextStream = Lines
End Function

Sub WriteTextFile(MakefileStream, BasFile, DependenciesLine)
	
	Dim BasFileWithoutPath
	BasFileWithoutPath = Replace(BasFile, SourceFolder & "\", "")
	
	Dim FileNameCExtenstionWitthSuffix
	Dim ObjectFileName
	Dim Finded
	Finded = InStr(BasFile, ".bas")
	If Finded Then
		FileNameCExtenstionWitthSuffix = Replace(BasFileWithoutPath, ".bas", FileSuffix & ".c")
		ObjectFileName = Replace(BasFileWithoutPath, ".bas", FileSuffix & ".o")
	Else
		Finded = InStr(BasFile, ".RC")
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
	
	' ���������� ������ � ��������� ����
	MakefileStream.WriteLine ObjectFileNameWithDebug
	MakefileStream.WriteLine ObjectFileNameRelease
	MakefileStream.WriteLine ResultDebugString
	MakefileStream.WriteLine ResultReleaseString
	
End Sub

Function GetIncludesFromBasFile(Filepath)
	Dim ProgramName
	ProgramName = """" & CompilerPath & Solidus & FbcCompilerName & """" & " " & _
		CreateCompilerParams(CODE_EMITTER_GCC, DEFINE_UNICODE, DEFINE_WITHOUT_RUNTIME, SUBSYSTEM_CONSOLE) & _
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

Function CreateDependencies(MakefileStream, oFile, FileExtension, Filepath)
	
	Dim LinesArray
	Dim LinesArrayCreated
	
	Select Case UCase(FileExtension)
		Case "RC"
			LinesArray = Split(GetIncludesFromResFile(oFile.Path), vbCrLf)
			LinesArrayCreated = True
		Case "BAS"
			LinesArray = Split(GetIncludesFromBasFile(oFile.Path), vbCrLf)
			LinesArrayCreated = True
		Case Else
			LinesArray = Split("", vbCrLf)
			LinesArrayCreated = False
	End Select
	
	If LinesArrayCreated Then
		Dim Original
		Original = LinesArray(0)
		
		' ������ ������ �� ����� � ��� ��� ������ �����
		LinesArray(0) = ""
		
		RemoveVerticalLine LinesArray
		RemoveOmmittedIncludes LinesArray
		RemoveDefaultIncludes LinesArray
		ReplaceSolidusToPathSeparator LinesArray
		AddSpaces LinesArray
		
		' ���� ������ � ���� �����
		Dim OneLine
		OneLine = Join(LinesArray, "")
		
		WriteTextFile MakefileStream, Original, RTrim(OneLine)
	End If
End Function
