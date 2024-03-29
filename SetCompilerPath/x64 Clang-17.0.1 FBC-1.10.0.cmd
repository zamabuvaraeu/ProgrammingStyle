set MINGW_W64_DIR=C:\Program Files\mingw64
set PATH=%MINGW_W64_DIR%\bin;%PATH%
set FBC_DIR=C:\Program Files (x86)\FreeBASIC-1.10.0-winlibs-gcc-9.3.0
set PATH=%FBC_DIR%\bin\win64;%PATH%

rem set PROCESSOR_ARCHITECTURE=AMD64
set FBC_VER=_FBC1100
set GCC_VER=_Clang1701
set MARCH=native
rem Patched FBC
set FBC="C:\Programming\FreeBASIC Projects\fbc-modified\src\compiler\fbc64_icase.exe"
rem Original FBC
rem set FBC="%FBC_DIR%\fbc64.exe"
set CC="C:\Program Files\LLVM\bin\clang.exe"
set AS="C:\LLVM\bin\as.exe"
rem for wasm
rem set LD="C:\Program Files\LLVM\bin\wasm-ld.exe"
set LD="C:\Program Files\LLVM\bin\ld.lld.exe"
set AR="C:\LLVM\bin\ar.exe"
set GORC="%FBC_DIR%\bin\win64\GoRC.exe"
set DLL_TOOL="C:\LLVM\bin\dlltool.exe"

rem Without quotes:
set LIB_DIR=%FBC_DIR%\lib\win64
set INC_DIR=%FBC_DIR%\inc

set USE_RUNTIME=FALSE

rem Only for Clang
rem for wasm
rem set TARGET_TRIPLET=wasm32
set TARGET_TRIPLET=x86_64-w64-pc-windows-msvc
set FLTO=-flto

rem Create "bin" "obj" folders
rem mingw32-make createdirs
rem Compile
rem mingw32-make all