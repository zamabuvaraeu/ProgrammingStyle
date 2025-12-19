set BIN_DEBUG_DIR=bin\Debug\x64
set OBJ_DEBUG_DIR=obj\Debug\x64

"C:\Program Files (x86)\FreeBASIC-1.10.1-winlibs-gcc-9.3.0\fbc64_mod.exe" -i "C:\Program Files (x86)\FreeBASIC-1.10.1-winlibs-gcc-9.3.0\inc" -m CreateMakefile -gen gcc -O 0 -g -v -r -w error -maxerr 1 CreateMakefile\CreateMakefile.bas
IF %ERRORLEVEL% GEQ 1 goto lastline
move CreateMakefile\CreateMakefile.c %OBJ_DEBUG_DIR%\CreateMakefile.c
rem cscript.exe fix-emitted-code.vbs -debug "CreateMakefile\CreateMakefile.c"
"C:\Program Files (x86)\FreeBASIC-1.10.1-winlibs-gcc-9.3.0\bin\win64\gcc.exe" -m64 -march=x86-64 -S -nostdlib -nostdinc -Wall -Wno-unused -Wno-main -Werror-implicit-function-declaration -O0 -fno-strict-aliasing -fno-ident -frounding-math -fno-math-errno -fwrapv -fno-exceptions -fno-asynchronous-unwind-tables -funwind-tables -Wno-format -g -masm=intel %OBJ_DEBUG_DIR%\CreateMakefile.c -o %OBJ_DEBUG_DIR%\CreateMakefile.asm
"C:\Program Files (x86)\FreeBASIC-1.10.1-winlibs-gcc-9.3.0\bin\win64\as.exe" --64 %OBJ_DEBUG_DIR%\CreateMakefile.asm -o %OBJ_DEBUG_DIR%\CreateMakefile.o
"C:\Program Files (x86)\FreeBASIC-1.10.1-winlibs-gcc-9.3.0\bin\win64\ld.exe" -m i386pep -o %BIN_DEBUG_DIR%\CreateMakefile.exe -subsystem console -T "C:\Program Files (x86)\FreeBASIC-1.10.1-winlibs-gcc-9.3.0\lib\win64\fbextra.x" --stack 2097152,2097152 -L "C:\Program Files (x86)\FreeBASIC-1.10.1-winlibs-gcc-9.3.0\lib\win64" -L "." "C:\Program Files (x86)\FreeBASIC-1.10.1-winlibs-gcc-9.3.0\lib\win64\crt2.o" "C:\Program Files (x86)\FreeBASIC-1.10.1-winlibs-gcc-9.3.0\lib\win64\crtbegin.o" "C:\Program Files (x86)\FreeBASIC-1.10.1-winlibs-gcc-9.3.0\lib\win64\fbrt0.o" %OBJ_DEBUG_DIR%\CreateMakefile.o "-(" -lfb -lgcc -lmsvcrt -lkernel32 -luser32 -lmingw32 -lmingwex -lmoldname -lgcc_eh "-)" "C:\Program Files (x86)\FreeBASIC-1.10.1-winlibs-gcc-9.3.0\lib\win64\crtend.o"
:lastline