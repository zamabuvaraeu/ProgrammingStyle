# Генератор Makefile

Этот сценарий генерирует `Makefile` для утилиты `make`. Теперь можно забыть про пакетные файлы и компиляцию из командной строки.

## Почему утилита make

Утилита `make` используется для сборки чего‐нибудь по рецепту. Сама по себе утилита ничего не собирает, она читает «файл рецепта» и вызывает команды, чтобы «приготовить блюдо». Чаще всего `make` используют для компиляции программ, но это совсем необязательно.

Так почему нам следует использовать `make` и усложнять сборку программы, когда достаточно выполнить одну простую команду `fbc *.bas`? Да, иногда можно и вовсе обойтись компиляцией через перетаскивание мышью значка файла на значок компилятора.

Утилита `make` имеет неоспоримое преимущество: нет нужды пересобирать то, что уже собрано. Когда мы изменяем одну строку кода в файле, то команда `fbc *.bas` требует перекомпиляции всех файлов. Утилита `make` пересобирает только изменившиеся файлы.

## Подготовления

Чтобы создать зависимости, все файлы проекта следует располагать в одном каталоге.

## Параметры

Параметры для сценария указываются в именованном виде: `/параметр:значение`.

### Имя исполняемого файла

(без расширения .exe или .dll)

Function GetOutputFileName()
	If colArgs.Exists("out") Then
		GetOutputFileName = colArgs.Item("out") 
	Else
		GetOutputFileName = "Station922"
	End If
End Function

"command": "cscript.exe",
"args": [
	"//nologo",
	"CreateMakefile.vbs",
	"/out:TestGui",
	"/subsystem:windows",
	"/unicode:true",
	"/wrt:true",
	"/addressaware:true"
],


Имя фала компилятора

	If colArgs.Exists("fbc") Then
		GetFbcCompilerName = colArgs.Item("fbc")
	Else
		GetFbcCompilerName = "fbc64.exe"
	End If
End Function

Путь к компилятору

Function GetCompilerPath()
	If colArgs.Exists("fbc-path") Then
		GetCompilerPath = colArgs.Item("fbc-path")
	Else
		GetCompilerPath = "C:\Program Files (x86)\FreeBASIC-1.10.0-winlibs-gcc-9.3.0"
	End If
End Function

Путь к каталогу src

Function GetSourceFolder()
	If colArgs.Exists("src") Then
		GetSourceFolder = colArgs.Item("src")
	Else
		GetSourceFolder = "src"
	End If
End Function

Имя главного модуля программы (без расширения .bas)

Function GetMainModuleName()
	If colArgs.Exists("module") Then
		GetMainModuleName = colArgs.Item("module")
	Else
		GetMainModuleName = OutputFileName
	End If
End Function

Тип исполняемого файла

Function GetExeType()
	If colArgs.Exists("exetype") Then
		Dim t1
		t1 = colArgs.Item("exetype")
		Select Case t1
			Case "exe"
				GetExeType = OUTPUT_FILETYPE_EXE
			Case "dll"
				GetExeType = OUTPUT_FILETYPE_DLL
			Case "lib"
				GetExeType = OUTPUT_FILETYPE_LIBRARY
			Case Else
				GetExeType = OUTPUT_FILETYPE_EXE
		End Select
	Else
		GetExeType = OUTPUT_FILETYPE_EXE
	End If
End Function

Подсистема

Function GetFileSubsystem()
	If colArgs.Exists("subsystem") Then
		Dim t2
		t2 = colArgs.Item("subsystem")
		Select Case t2
			Case "console"
				GetFileSubsystem = SUBSYSTEM_CONSOLE
			Case "windows"
				GetFileSubsystem = SUBSYSTEM_WINDOW
			Case "native"
				GetFileSubsystem = SUBSYSTEM_NATIVE
			Case Else
				GetFileSubsystem = SUBSYSTEM_CONSOLE
		End Select
	Else
		GetFileSubsystem = SUBSYSTEM_CONSOLE
	End If
End Function

Кодогенератор

Function GetEmitter()
	If colArgs.Exists("emitter") Then
		Dim t3
		t3 = colArgs.Item("emitter")
		Select Case t3
			Case "gcc"
				GetEmitter = CODE_EMITTER_GCC
			Case "gas"
				GetEmitter = CODE_EMITTER_GAS
			Case "gas64"
				GetEmitter = CODE_EMITTER_GAS64
			Case "llvm"
				GetEmitter = CODE_EMITTER_LLVM
			Case Else
				GetEmitter = CODE_EMITTER_GCC
		End Select
	Else
		GetEmitter = CODE_EMITTER_GCC
	End If
End Function

Юникод (для винапи)

Function GetUnicode()
	If colArgs.Exists("unicode") Then
		Dim t4
		t4 = colArgs.Item("unicode")
		Select Case t4
			Case "true"
				GetUnicode = DEFINE_UNICODE
			Case "false"
				GetUnicode = DEFINE_ANSI
			Case Else
				GetUnicode = DEFINE_ANSI
		End Select
	Else
		GetUnicode = DEFINE_ANSI
	End If
End Function

Рантайм

Function GetRuntime()
	If colArgs.Exists("wrt") Then
		Dim t5
		t5 = colArgs.Item("wrt")
		Select Case t5
			Case "true"
				GetRuntime = DEFINE_WITHOUT_RUNTIME
			Case "false"
				GetRuntime = DEFINE_RUNTIME
			Case Else
				GetRuntime = DEFINE_RUNTIME
		End Select
	Else
		GetRuntime = DEFINE_RUNTIME
	End If
End Function

Большие адреса (на x86)

Function GetAddressAware()
	If colArgs.Exists("addressaware") Then
		Dim t6
		t6 = colArgs.Item("addressaware")
		Select Case t6
			Case "true"
				GetAddressAware = LARGE_ADDRESS_AWARE
			Case "false"
				GetAddressAware = LARGE_ADDRESS_UNAWARE
			Case Else
				GetAddressAware = LARGE_ADDRESS_UNAWARE
		End Select
	Else
		GetAddressAware = LARGE_ADDRESS_UNAWARE
	End If
End Function

Многопоточная или однопоточная модель

Function GetThreadingMode()
	If colArgs.Exists("multithreading") Then
		Dim t7
		t7 = colArgs.Item("multithreading")
		Select Case t7
			Case "true"
				GetThreadingMode = DEFINE_MULTITHREADING_RUNTIME
			Case "false"
				GetThreadingMode = DEFINE_SINGLETHREADING_RUNTIME
			Case Else
				GetThreadingMode = DEFINE_SINGLETHREADING_RUNTIME
		End Select
	Else
		GetThreadingMode = DEFINE_SINGLETHREADING_RUNTIME
	End If
End Function

