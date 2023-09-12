set MINGW_W64_DIR=C:\Program Files\mingw64
set PATH=%MINGW_W64_DIR%\bin;%PATH%

rem set PROCESSOR_ARCHITECTURE=AMD64
set FBC_VER=_FBC1100
set GCC_VER=_Clang1600
set MARCH=native
set FBC="C:\Programming\FreeBASIC Projects\fbc\src\compiler\fbc64_icase.exe"
set CC="C:\Program Files\LLVM\bin\clang.exe"
set AS="C:\LLVM\bin\as.exe"
set LD="C:\Program Files\LLVM\bin\ld.lld.exe"
set AR="C:\LLVM\bin\ar.exe"
set GORC="C:\Program Files (x86)\FreeBASIC-1.10.0-winlibs-gcc-9.3.0\bin\win64\GoRC.exe"
set DLL_TOOL="C:\LLVM\bin\dlltool.exe"

rem Without quotes:
set LIB_DIR=C:\Program Files (x86)\FreeBASIC-1.10.0-winlibs-gcc-9.3.0\lib\win64
set INC_DIR=C:\Program Files (x86)\FreeBASIC-1.10.0-winlibs-gcc-9.3.0\inc

set TARGET_TRIPLET=x86_64-w64-pc-windows-msvc
set FLTO=-flto
set USE_RUNTIME=FALSE
