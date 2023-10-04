set MINGW_W64_DIR=C:\Program Files\mingw64
set PATH=%MINGW_W64_DIR%\bin;%PATH%

rem set PROCESSOR_ARCHITECTURE=AMD64
set FBC_VER=_FBC1100
set GCC_VER=_GCC1310
set MARCH=native
set FBC_DIR=C:\Program Files (x86)\FreeBASIC-1.10.0-winlibs-gcc-9.3.0
set FBC="C:\Programming\FreeBASIC Projects\fbc-modified\src\compiler\fbc64_icase.exe"
set CC="C:\Program Files\mingw64\bin\gcc.exe"
set AS="C:\Program Files\mingw64\bin\as.exe"
set LD="C:\Program Files\mingw64\bin\ld.exe"
set AR="C:\Program Files\mingw64\bin\ar.exe"
set GORC="%FBC_DIR%\bin\win64\GoRC.exe"
set DLL_TOOL="C:\Program Files\mingw64\bin\dlltool.exe"

rem Without quotes:
set LIB_DIR=%FBC_DIR%\lib\win64
set INC_DIR=%FBC_DIR%\inc
set LD_SCRIPT=%FBC_DIR%\lib\win64\fbextra.x

set USE_RUNTIME=FALSE
