# Генератор Makefile

Этот сценарий генерирует `Makefile` для утилиты `make`. Теперь можно забыть про пакетные файлы и компиляцию из командной строки.

## Достоинства и недостатки

### Достоинства

Типичная компиляция проекта состоит из команды:

```bat
fbc *.bas
```

Это работает, однако это не оптимально. Когда мы изменим хотя бы одну строку кода в файле, то такая команда пересоберёт все файлы. Даже если эти файлы не изменились. Это занимает время, нагружает процессор и изнашивает диск. Кроме того, команда не позволит выполнить хорошую оптимизацию или собрать проект для других операционных систем (например, Windows 95 или драйвер). А если нужно собрать отладочную версию — придётся опять пересобирать проект.

С другой стороны, у нас есть утилита `make`, которая пересобирает только изменившиеся файлы. И мы можем приспособить её для своих нужд. Однако писать вручную конфигурационные файлы `Makefile` для утилиты — неудобно.

Поэтому появился этот генератор для автоматизации процесса. Генератор сам ничего не собирает, генератор только создаёт `Makefile`.

### Недостатки

Не умеет строить зависимости от файла ресурсов. Недостаток компенсируется тем, что известные типы файлов, такие как значки, картинки и манифесты, автоматически добавляются к зависимостям файла ресурсов.

Не добавляет библиотеки в список линковщика. Библиотеки придётся добавлять руками.

Проект должен компилироваться. Если есть ошибки в проекте, генератор создаст неправильный `Makefile`.

## Подготовления

Нам необходимо достать утилиту `make`, собрать генератор и подготовить каталоги проекта.

### Утилита make

Необходимо где‐то достать утилиту `make`. Например, для Windows в одной из (сборок mingw от Brecht Sanders)[https://github.com/brechtsanders/winlibs_mingw/releases]. В этой сборке для операционной системы Windows утилита называется `mingw32-make`.

### Сборка генератора

Собрать генератор можно такой командой:

```
fbc64.exe CreateMakefile.bas
```

### Структура проекта

Генератор требует, чтобы проект был организован определённым образом:

```
My Cool Project

	bin\          — каталог для исполняемых файлов

		Debug\    — отладочная версия
			x64\  — для 64 бит
			x86\  — для 32 бит

		Release   — окончательная версия
			x64\
			x86\

	obj\          — каталог для объектных файлов
		Debug\
			x64\
			x86\
		Release
			x64\
			x86\

	src\          — каталог для файлов исходного кода
		main.bas  — все файлы исходного кода
		main.bi

	CreateMakefile.exe   — Генератор makefile

	Makefile             — сгенерированный файл

	setenv.cmd           — настройки переменных среды

	fix-emitted-code.vbs — сценарий для исправления промежуточного си‐кода (неообязательно)
```

К счастью, каталоги `bin` и `obj` вручную создавать не нужно, их можно создать командой `createdirs`.

### Определение зависимостей

Генератор строит зависимости для каждого `*.bas` файла в каталоге проекта. Зависимостями считаются любые включаемые файлы. Если файл ссылается на стандартные заголовочники в директории компилятора, то они пропускаются.

Любые изменения зависимостей (добавили или удалили заголовочники) требуют обновления `Makefile` и перезапуска генератора.

## Краткое руководство

### Запуск

Нажимаем Пуск → Выполнить, запускаем консоль и заходим в каталог проекта:

```bat
cd c:\FreeBASIC Projects\My Cool Project
```

Далее запускаем генератор одним из описанных в будущем способов. В каталоге проекта появятся два файла: `Makefile` и `setenv.cmd`. `Makefile` нужен для утилиты `make`, в файле `setenv.cmd` лежат настройки переменных среды.

Устанавливаем переменные среды:

```bat
setenv.cmd
```

Создаём каталоги `bin` и `obj` если они ещё не созданы:

```bat
mingw32-make createdirs
```

Запускаем одну или несколько целей сборки:

```bat
mingw32-make all
```

### Цели сборки

| Тип        | Описание                          |
|------------|-----------------------------------|
| debug      | Собирает отладочную версию |
| release    | Собирает окончательную версию |
| all        | Собирает обе версии |
| clean      | Очищает каталоги от промежуточных и объектных файлов |
| createdirs | Создаёт каталоги `obj` и `bin` с подкаталогами |

### GUI Программа

Создадим `Makefile` для оконной программы:

```bat
"c:\FreeBASIC Projects\CreateMakefile.exe" -out HelloWorld -subsystem windows -fbc-path "C:\Program Files (x86)\FreeBASIC-1.10.0-winlibs-gcc-9.3.0" -fbc fbc64.exe
```

### Консольная программа

Создадим `Makefile` для консольной программы с поддержкой юникода и адресного пространства больше 2 гигабайт:

```bat
"c:\FreeBASIC Projects\CreateMakefile.exe" -out HelloWorld -unicode true -addressaware true -fbc-path "C:\Program Files (x86)\FreeBASIC-1.10.0-winlibs-gcc-9.3.0" -fbc fbc64.exe
```

### WebAssembly

```bat
"c:\FreeBASIC Projects\CreateMakefile.exe" -out HelloWorld -fix true -emitter wasm32 -exetype wasm32 -fbc-path "C:\Program Files (x86)\FreeBASIC-1.10.0-winlibs-gcc-9.3.0" -fbc fbc64.exe
```

### Все параметры

```bat
"c:\FreeBASIC Projects\CreateMakefile.exe" -makefile Makefile -src src -fbc-path "C:\Program Files (x86)\FreeBASIC-1.10.0-winlibs-gcc-9.3.0" -fbc fbc64.exe -out HelloWorld -module WinMain -exetype exe -subsystem console -emitter gcc -fix false -unicode true -wrt false -wcrt false -addressaware true -multithreading false -usefilesuffix true -pedantic true -winver 1281 -create-environment-file true -createdirs false
```

## Параметры генератора Makefile

Параметры для утилиты указываются в виде пары: `-параметр значение`.

### makefile

Имя генерируемого файла для утилиты `make`.

По умолчанию равно `Makefile`.

### src

Каталог с исходными кодами.

По умолчанию равен `src`.

### fbc-path

Путь к файлу компилятора.

По умолчанию равно `C:\Program Files (x86)\FreeBASIC-1.10.1-winlibs-gcc-9.3.0`.

### fbc

Имя файла компилятора.

По умолчанию равно `fbc64.exe`.

### out

Имя исполняемого файла.

Имя файла указывается без расширения. Например, скомпилированная программа должна иметь имя `HelloWorld.exe`, указываем здесь `HelloWorld`.

По умолчанию равно `a`.

### module

Главный модуль программы. Указываем имя файла без расширения.

По умолчанию равен названию программы (без расширения): то, что указано в параметре `-out`.

### exetype

Тип генерируемого исполняемого файла.

Может принимать следующий значения:

| Тип | Описание                          |
|-----|-----------------------------------|
| exe | Исполняемый файл |
| dll | Динамически загружаемая библиотека |
| lib | Статически загружаемая библиотека |
| wasm32 | WebAssembly |
| wasm64 | WebAssembly 64 бита |

По умолчанию равен `exe`.

Примечание: поддержка wasm64 в браузерах находится в экспериментальном режиме, и может не работать корректно.

### subsystem

Подсистема исполняемого файла. Применимо только к файлам типа `exe`.

| Подсистема | Описание                          |
|-----|-----------------------------------|
| console | Консольная программа для WinAPI |
| windows | Оконная программа для WinAPI |
| native | Программа для NT API |

По умолчанию равен `console`.

### emitter

Задаёт генератор промежуточного кода для цепочки инструментов.

| Генератор | Описание                          |
|-----|-----------------------------------|
| gcc | Кодогенератор для компилятора Си. |
| gas | Кодогенератор для ассемблера |
| gas64 | 64‐битный ассемблер |
| llvm | Низкоуровневая виртуальная машина |
| wasm32 | WebAssembly 32 бит |
| wasm64 | WebAssembly 64 бит |

По умолчанию равен `gcc`.

Примечание: поддержка wasm64 в браузерах находится в экспериментальном режиме, и может не работать корректно.

### fix

Добавляет сценарий исправления сгенерированного промежуточного кода.

Пояснение: компилятор фрибейсика генерирует промежуточный код для GCC и использует расширения GCC. Некоторые конструкции не будут работать для другого компилятора, например, для шланга.

По умолчанию `false`.

### unicode

Задаёт константу `UNICODE` для WinAPI.

| Юникод | Описание                          |
|-----|-----------------------------------|
| true | Включает `UNICODE` |
| false | Выключает `UNICODE` |

По умолчанию равен `false`.

### wrt

Выключает библиотеки времени выполнения. Чтобы выключить библиотеки, установите этот параметр в `true`.

По умолчанию равен `false`.

### wcrt

Выключает библиотеки языка си. Чтобы выключить библиотеки, установите этот параметр в `true`.

По умолчанию равен `false`.

### addressaware

Включает использование адресного пространства больше 2 гигабайт.

Чтобы использовать адресное пространство больше двух гигабайт, исполняемый файл должен быть отмечен этим флагом. Установите это значение в `true`. Применимо только для 32‐битных программ.

По умолчанию равен `false`.

### multithreading

Включает многопоточные библиотеки времени выполнения.

По умолчанию равен `false`.

### usefilesuffix

Включает использование файлового суффикса.

По умолчанию равен `true`.

### pedantic

Включает строгое следование стандарту языка Си для промежуточного представления.

По умолчанию равен `false`.

### winver

Задаёт версию Windows: константы `WINVER` и `_WIN32_WINNT`. В десятичном формате. Допустимые значения:

| Десятичный | 16‐ричный | Именованная константа     | Описание |
|------------|-----------|---------------------------|----------|
| 1024       | 0x0400    | _WIN32_WINNT_NT4          | Windows NT 4.0 и Windows 95 |
| 1280       | 0x0500    | _WIN32_WINNT_WIN2K        | Windows 2000 |
| 1281       | 0x0501    | _WIN32_WINNT_WINXP        | Windows XP |
| 1282       | 0x0502    | _WIN32_WINNT_WS03         | Windows Server 2003 |
| 1536       | 0x0600    | _WIN32_WINNT_WIN6         | Windows Vista |
| 1536       | 0x0600    | _WIN32_WINNT_VISTA        | Windows Vista |
| 1536       | 0x0600    | _WIN32_WINNT_WS08         | Windows Server 2008 |
| 1536       | 0x0600    | _WIN32_WINNT_LONGHORN     | Windows Vista |
| 1537       | 0x0601    | _WIN32_WINNT_WIN7         | Windows 7 |
| 1538       | 0x0602    | _WIN32_WINNT_WIN8         | Windows 8 |
| 1539       | 0x0603    | _WIN32_WINNT_WINBLUE      | Windows 8.1 |
| 2560       | 0x0A00    | _WIN32_WINNT_WINTHRESHOLD | Windows 10 |
| 2560       | 0x0A00    | _WIN32_WINNT_WIN10        | Windows 10 |

По умолчанию `1281` (Windows XP).

### create-environment-file

Включает генерацию файла настроек среды выполнения для утилиты `make`.

По умолчанию `true`.

### createdirs

Создаёт подкаталоги `bin` и `obj`.

По умолчанию `false`.

## Параметры для утилиты make

Генератор создаёт файл `setenv.cmd` с переменными среды, которые нужны для запуска. Заглянем в него и отредактируем как нам надо. Самое главное — это пути к цепочке инструментов и библиотеки.

### Битность процессора

Здесь устанавливаются каталоги Bin, Lib и имя файла компилятора для 32‐битной и 64‐битной версий:

```bat
if %PROCESSOR_ARCHITECTURE% == AMD64 (
set BinFolder=bin\win64
set LibFolder=lib\win64
set FBC_FILENAME=fbc64.exe
) else (
set BinFolder=bin\win32
set LibFolder=lib\win32
set FBC_FILENAME=fbc32.exe
)
```

### Пути к компилятору и заголовочным файлам

Путь к компилятору, указываем без кавычек.

```bat
rem Add compiler directory to PATH
rem Without quotes:
set FBC_DIR=C:\Program Files (x86)\FreeBASIC-1.10.1-winlibs-gcc-9.3.0
set PATH=%FBC_DIR%\%BinFolder%;%PATH%
set LIB_DIR=%FBC_DIR%\%LibFolder%
set INC_DIR=%FBC_DIR%\inc
```

### Цепочки инструментов

По умолчанию пути к файлам цепочки инструментов настроены на каталог компилятора.

```bat
rem Toolchain
set FBC="%FBC_DIR%\fbc64"
set CC="%FBC_DIR%\%BinFolder%\gcc.exe"
set AS="%FBC_DIR%\%BinFolder%\as.exe"
set AR="%FBC_DIR%\%BinFolder%\ar.exe"
set GORC="%FBC_DIR%\%BinFolder%\GoRC.exe"
set LD="%FBC_DIR%\%BinFolder%\ld.exe"
set DLL_TOOL="%FBC_DIR%\%BinFolder%\dlltool.exe"
```

### Вспомогательные переменные

Разделители путей и команды, которые используются утилитой `make` для сборки проекта.

```bat
rem Разделитель параметров для mingw32-make
rem set PARAM_SEP=/
rem Разделитель параметров для mingw32-make
set PARAM_SEP=//

rem Разделитель путей
set PATH_SEP=/
set MOVE_PATH_SEP=\\
set MOVE_COMMAND=cmd.exe /c move /y
set DELETE_COMMAND=cmd.exe /c del /f /q
set MKDIR_COMMAND=cmd.exe /c mkdir
set CPREPROCESSOR_COMMAND=cmd.exe /c echo cscript.exe //nologo fix-emitted-code.vbs
```

### Путь к каталогу исходных кодов

Если исходные коды лежат в другом месте, это нужно указать.

```bat
rem Source code directory
set SRC_DIR=src
```

### Использование рантайма

Когда проект не будет использовать библиотеки времени выполнения, устанавливаем в `FALSE`.

```bat
rem Set to TRUE for use runtime libraries
set USE_RUNTIME=FALSE

rem Set to TRUE for use runtime libraries
set USE_CRUNTIME=FALSE
```

### Юникод и версия операционной системы

Указываем минимально поддерживаемую версию ОС и юникод.

```bat
rem WinAPI version
set WINVER=1280
set _WIN32_WINNT=1280
rem Use unicode in WinAPI
set USE_UNICODE=TRUE
```

### Флаги компилятора и цепочки инструментов

Добавляем особые флаги к компилятору и цепочке инструментов.

```bat
set FBCFLAGS=
set CFLAGS=
set ASFLAGS=
set GORCFLAGS=
set LDFLAGS=
```

### Суффикс файла

Если мы компилируем файл с разными флагами компиляции или компиляторами, можно добавить специальные суффиксы к имени файла, чтобы имена файлов различались.

```bat
set GCC_VER=_GCC0930
set FBC_VER=_FBC1101
set FILE_SUFFIX=%GCC_VER%_%FBC_VER%_%RUNTIME%_%WINVER%
set OUTPUT_FILE_NAME=HelloWorld%FILE_SUFFIX%.exe
```

### Сценарий компоновщика

Указываем без кавычек.

```bat
rem Linker script only for GCC x86, GCC x64 and Clang x86
rem Without quotes:
set LD_SCRIPT=%LIB_DIR%\fbextra.x
```

### Модель процессора

Можно указать конкретную модель процессора.

```bat
rem Set processor architecture
set MARCH=native
```

Для шланга:

```bat
rem Only for Clang x86
rem set TARGET_TRIPLET=i686-pc-windows-gnu
rem Only for Clang AMD64
rem set TARGET_TRIPLET=x86_64-w64-pc-windows-msvc
```

### Межмодульная оптимизация

Указываем `-flto` для межмодульной оптимизации.

```bat
rem Link Time Optimization for release target
rem set FLTO=-flto
```

### Подключаемые библиотеки

Нам необходимо добавить библиотеки в список или убрать лишние.

| Переменная    | Описание                          |
|---------------|-----------------------------------|
| OBJ_CRT_START | Стартовые библиотеки языка Си |
| OBJ_CRT_END   | Заключительные библиотеки языка Си |
| LIBS_WIN95    | Библиотеки для Win95 |
| LIBS_WINNT    | Библиотеки для Windows NT |
| LIBS_GUID     | Библиотека с GUID |
| LIBS_MSVCRT   | Динамическая библиотека языка Си |
| LIBS_FB       | Библиотеки языка FreeBASIC, например `-lfbgfx` |
| LIBS_GCC      | Библиотеки языка Си и отладчика |
| LIBS_ANY      | Любые дополнительные библиотеки, например `lcards` |
| LIBS_OS       | Комбинация всех библиотеки операционной системы |

```bat
rem Libraries list
set OBJ_CRT_START="%LIB_DIR%\crt2.o" "%LIB_DIR%\crtbegin.o" "%LIB_DIR%\fbrt0.o"
set LIBS_WIN95=-ladvapi32 -lcomctl32 -lcomdlg32 -lcrypt32 -lgdi32 -lkernel32 -lole32 -loleaut32 -lshell32 -lshlwapi -lwsock32 -luser32
set LIBS_WINNT=-lgdiplus -lws2_32 -lmswsock
set LIBS_GUID=-luuid
set LIBS_MSVCRT=-lmsvcrt
set LIBS_ANY=
set LIBS_FB=-lfb
set LIBS_OS=%LIBS_WIN95% %LIBS_WINNT% %LIBS_GUID% %LIBS_MSVCRT% %LIBS_FB% %LIBS_ANY%
set LIBS_GCC=-lgcc -lmingw32 -lmingwex -lmoldname -lgcc_eh
set OBJ_CRT_END="%LIB_DIR%\crtend.o"
```
