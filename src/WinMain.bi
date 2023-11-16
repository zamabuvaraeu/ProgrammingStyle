#ifndef WINMAIN_BI
#define WINMAIN_BI

#include once "windows.bi"

Declare Function WinMain Alias "WinMain"( _
	Byval hInst As HINSTANCE, _
	ByVal hPrevInstance As HINSTANCE, _
	ByVal lpCmdLine As LPSTR, _
	ByVal iCmdShow As Long _
)As Integer

#ifndef UNICODE
Declare Function tWinMain Alias "WinMain"( _
	Byval hInst As HINSTANCE, _
	ByVal hPrevInstance As HINSTANCE, _
	ByVal lpCmdLine As LPSTR, _
	ByVal iCmdShow As Long _
)As Integer
#endif

Declare Function wWinMain Alias "wWinMain"( _
	Byval hInst As HINSTANCE, _
	ByVal hPrevInstance As HINSTANCE, _
	ByVal lpCmdLine As LPWSTR, _
	ByVal iCmdShow As Long _
)As Integer

#ifdef UNICODE
Declare Function tWinMain Alias "wWinMain"( _
	Byval hInst As HINSTANCE, _
	ByVal hPrevInstance As HINSTANCE, _
	ByVal lpCmdLine As LPWSTR, _
	ByVal iCmdShow As Long _
)As Integer
#endif

#endif
