set MINGW_W64_DIR=%ProgramFiles%\mingw64
set PATH=%MINGW_W64_DIR%\bin;%PATH%
set FBC_DIR=C:\Program Files (x86)\FreeBASIC-1.10.0-winlibs-gcc-9.3.0
set PATH=%FBC_DIR%\bin\win32;%PATH%

set PROCESSOR_ARCHITECTURE=x86
set FBC_VER=_FBC1100
set GCC_VER=_GCC1310
set MARCH=atom
rem Patched FBC
set FBC="C:\Programming\FreeBASIC Projects\fbc-modified\src\compiler\fbc32_icase.exe"
rem Original FBC
rem set FBC="%FBC_DIR%\fbc32.exe"
set CC="C:\Program Files (x86)\mingw32\bin\gcc.exe"
set AS="C:\Program Files (x86)\mingw32\bin\as.exe"
set LD="C:\Program Files (x86)\mingw32\bin\ld.exe"
set AR="C:\Program Files (x86)\mingw32\bin\ar.exe"
set GORC="%FBC_DIR%\bin\win32\GoRC.exe"
set DLL_TOOL="C:\Program Files (x86)\mingw32\bin\dlltool.exe"

rem Without quotes:
set LIB_DIR=%FBC_DIR%\lib\win32
set INC_DIR=%FBC_DIR%\inc
set LD_SCRIPT=%FBC_DIR%\lib\win32\fbextra.x

set USE_RUNTIME=FALSE

rem Create "bin" "obj" folders
rem mingw32-make createdirs
rem Compile
rem mingw32-make all