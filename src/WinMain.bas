#include once "WinMain.bi"
#include once "win\commctrl.bi"
#include once "Resources.RH"

Type InputDialogParam
	hInst As HINSTANCE
	hWin As HWND
End Type

Private Sub IDOK_OnClick( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)


End Sub

Private Sub IDCANCEL_OnClick( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)

	PostQuitMessage(0)

End Sub

Private Sub DialogMain_OnLoad( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)

End Sub

Private Sub DialogMain_OnUnload( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)

End Sub

Private Function InputDataDialogProc( _
		ByVal hWin As HWND, _
		ByVal uMsg As UINT, _
		ByVal wParam As WPARAM, _
		ByVal lParam As LPARAM _
	)As INT_PTR

	Dim pContext As InputDialogParam Ptr = Any

	If uMsg = WM_INITDIALOG Then
		pContext = Cast(InputDialogParam Ptr, lParam)
		SetWindowLongPtr(hWin, GWLP_USERDATA, Cast(LONG_PTR, pContext))
		DialogMain_OnLoad(pContext, hWin)
		Return TRUE
	End If

	pContext = Cast(Any Ptr, GetWindowLongPtr(hWin, GWLP_USERDATA))

	Select Case uMsg

		Case WM_COMMAND
			Select Case LOWORD(wParam)

				Case IDOK
					IDOK_OnClick(pContext, hWin)

				Case IDCANCEL
					IDCANCEL_OnClick(pContext, hWin)

			End Select

		Case WM_CLOSE
			DialogMain_OnUnload(pContext, hWin)
			PostQuitMessage(0)

		Case Else
			Return FALSE

	End Select

	Return TRUE

End Function

Private Function EnableVisualStyles()As HRESULT

	Dim icc As INITCOMMONCONTROLSEX = Any
	icc.dwSize = SizeOf(INITCOMMONCONTROLSEX)
	icc.dwICC = ICC_ANIMATE_CLASS Or _
		ICC_BAR_CLASSES Or _
		ICC_COOL_CLASSES Or _
		ICC_DATE_CLASSES Or _
		ICC_HOTKEY_CLASS Or _
		ICC_INTERNET_CLASSES Or _
		ICC_LINK_CLASS Or _
		ICC_LISTVIEW_CLASSES Or _
		ICC_NATIVEFNTCTL_CLASS Or _
		ICC_PAGESCROLLER_CLASS Or _
		ICC_PROGRESS_CLASS Or _
		ICC_STANDARD_CLASSES Or _
		ICC_TAB_CLASSES Or _
		ICC_TREEVIEW_CLASSES Or _
		ICC_UPDOWN_CLASS Or _
		ICC_USEREX_CLASSES Or _
	ICC_WIN95_CLASSES

	Dim res As BOOL = InitCommonControlsEx(@icc)
	If res = 0 Then
		Dim dwError As DWORD = GetLastError()
		Return HRESULT_FROM_WIN32(dwError)
	End If

	Return S_OK

End Function

Private Function CreateMainWindow( _
		Byval hInst As HINSTANCE, _
		ByVal param As InputDialogParam Ptr _
	)As HWND

	Dim hWin As HWND = CreateDialogParam( _
		hInst, _
		MAKEINTRESOURCE(IDD_DLG_TASKS), _
		NULL, _
		@InputDataDialogProc, _
		Cast(LPARAM, param) _
	)

	Return hWin

End Function

Private Function MessageLoop( _
		ByVal hWin As HWND, _
		ByVal hEvent As HANDLE _
	)As Integer

	Do
		Const EventVectorLength = 1
		Dim dwWaitResult As DWORD = MsgWaitForMultipleObjectsEx( _
			EventVectorLength, _
			@hEvent, _
			INFINITE, _
			QS_ALLEVENTS Or QS_ALLINPUT Or QS_ALLPOSTMESSAGE, _
			MWMO_INPUTAVAILABLE Or MWMO_ALERTABLE _
		)

		Select Case dwWaitResult

			Case WAIT_OBJECT_0
				' The event became a signal, exit from loop
				Return 0

			Case WAIT_OBJECT_0 + 1
				' Messages have been added to the message queue
				' they need to be processed

			Case WAIT_IO_COMPLETION
				' The asynchronous procedure has ended
				' we continue to wait

			Case Else ' WAIT_ABANDONED, WAIT_TIMEOUT, WAIT_FAILED
				Return 1

		End Select

		Do
			Dim wMsg As MSG = Any
			Dim resGetMessage As BOOL = PeekMessage( _
				@wMsg, _
				NULL, _
				0, _
				0, _
				PM_REMOVE _
			)
			If resGetMessage =  0 Then
				Exit Do
			End If

			If wMsg.message = WM_QUIT Then
				Return wMsg.wParam
			Else
				Dim resDialogMessage As BOOL = IsDialogMessage( _
					hWin, _
					@wMsg _
				)
				If resDialogMessage = 0 Then
					TranslateMessage(@wMsg)
					DispatchMessage(@wMsg)
				End If
			End If
		Loop
	Loop

	Return 0

End Function

Private Function tWinMain( _
		Byval hInst As HINSTANCE, _
		ByVal hPrevInstance As HINSTANCE, _
		ByVal lpCmdLine As LPTSTR, _
		ByVal iCmdShow As Long _
	)As Integer

	Scope
		Dim hrVisualStyles As Integer = EnableVisualStyles()
		If FAILED(hrVisualStyles) Then
			Return 1
		End If
	End Scope

	Dim param As InputDialogParam = Any
	param.hInst = hInst

	Scope
		Dim hEvent As HANDLE = CreateEvent( _
			NULL, _
			TRUE, _
			FALSE, _
			NULL _
		)
		If hEvent = NULL Then
			Return 1
		End If

		Dim hWin As HWND = CreateMainWindow( _
			hInst, _
			@param _
		)
		If hWin = NULL Then
			CloseHandle(hEvent)
			Return 1
		End If

		Dim resMessageLoop As Integer = MessageLoop( _
			hWin, _
			hEvent _
		)

		DestroyWindow(hWin)
		CloseHandle(hEvent)

		Return resMessageLoop
	End Scope

End Function

#ifndef WITHOUT_RUNTIME
Private Function EntryPoint()As Integer
#else
Public Function EntryPoint Alias "EntryPoint"()As Integer
#endif

	Dim hInst As HMODULE = GetModuleHandle(NULL)

	' The program does not process command line parameters
	Dim Arguments As LPTSTR = NULL
	Dim RetCode As Integer = tWinMain( _
		hInst, _
		NULL, _
		Arguments, _
		SW_SHOW _
	)

	#ifdef WITHOUT_RUNTIME
		ExitProcess(RetCode)
	#endif

	Return RetCode

End Function

#ifndef WITHOUT_RUNTIME
Dim RetCode As Long = CLng(EntryPoint())
End(RetCode)
#endif
