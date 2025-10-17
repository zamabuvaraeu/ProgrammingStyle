#include once "WinMain.bi"
#include once "win\commctrl.bi"
#include once "win\windowsx.bi"
#include once "Resources.RH"

Type InputDialogParam
	hInst As HINSTANCE
	hWin As HWND
End Type

Private Sub AppendLengthText( _
		ByVal hwndControl As HWND, _
		ByVal lptszText As LPTSTR _
	)

	Dim OldTextLength As Long = GetWindowTextLength(hwndControl)

	Edit_SetSel(hwndControl, OldTextLength, OldTextLength)
	Edit_ReplaceSel(hwndControl, lptszText)
	Edit_ScrollCaret(hwndControl)

End Sub

Private Sub DisableDialogItem( _
		ByVal hWin As HWND, _
		ByVal Id As UINT _
	)

	SendMessage(hWin, WM_NEXTDLGCTL, 0, 0)

	Dim hwndOk As HWND = GetDlgItem(hWin, Id)
	EnableWindow(hwndOk, False)

End Sub

Private Sub EnableDialogItem( _
		ByVal hWin As HWND, _
		ByVal Id As UINT _
	)

	Dim hwndOk As HWND = GetDlgItem(hWin, Id)
	EnableWindow(hwndOk, True)

End Sub

Private Sub IDOK_Click( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)


End Sub

Private Sub ModelessIDCANCEL_Click( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)

	PostQuitMessage(0)

End Sub

Private Sub ModalIDCANCEL_Click( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)

	EndDialog(hWin, 0)

End Sub

Private Sub DialogMain_Load( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)

End Sub

Private Sub DialogMain_Unload( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)

End Sub

Private Sub DialogMain_Closing( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)

	DestroyWindow(hWin)

End Sub

Private Function ModelessDialogProc( _
		ByVal hWin As HWND, _
		ByVal uMsg As UINT, _
		ByVal wParam As WPARAM, _
		ByVal lParam As LPARAM _
	)As INT_PTR

	Dim pContext As InputDialogParam Ptr = Any

	If uMsg = WM_INITDIALOG Then
		pContext = Cast(InputDialogParam Ptr, lParam)
		SetWindowLongPtr(hWin, GWLP_USERDATA, Cast(LONG_PTR, pContext))
		DialogMain_Load(pContext, hWin)
		Return TRUE
	End If

	pContext = Cast(Any Ptr, GetWindowLongPtr(hWin, GWLP_USERDATA))

	Select Case uMsg

		Case WM_COMMAND
			Select Case LOWORD(wParam)

				Case IDOK
					IDOK_Click(pContext, hWin)

				Case IDCANCEL
					ModelessIDCANCEL_Click(pContext, hWin)

			End Select

		Case WM_CLOSE
			DialogMain_Closing(pContext, hWin)

		Case WM_DESTROY
			DialogMain_Unload(pContext, hWin)
			PostQuitMessage(0)

		Case Else
			Return FALSE

	End Select

	Return TRUE

End Function

Private Function ModalDialogProc( _
		ByVal hWin As HWND, _
		ByVal uMsg As UINT, _
		ByVal wParam As WPARAM, _
		ByVal lParam As LPARAM _
	)As INT_PTR

	Dim pContext As InputDialogParam Ptr = Any

	If uMsg = WM_INITDIALOG Then
		pContext = Cast(InputDialogParam Ptr, lParam)
		SetWindowLongPtr(hWin, GWLP_USERDATA, Cast(LONG_PTR, pContext))
		DialogMain_Load(pContext, hWin)
		Return TRUE
	End If

	pContext = Cast(Any Ptr, GetWindowLongPtr(hWin, GWLP_USERDATA))

	Select Case uMsg

		Case WM_COMMAND
			Select Case LOWORD(wParam)

				Case IDOK
					IDOK_Click(pContext, hWin)

				Case IDCANCEL
					ModalIDCANCEL_Click(pContext, hWin)

			End Select

		Case WM_CLOSE
			EndDialog(hWin, 0)

		Case WM_DESTROY
			DialogMain_Unload(pContext, hWin)

		Case Else
			Return FALSE

	End Select

	Return TRUE

End Function

Private Function EnableVisualStyles( _
	)As HRESULT

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
		@ModelessDialogProc, _
		Cast(LPARAM, param) _
	)

	Return hWin

End Function

Private Function CreateModalWindow( _
		Byval hInst As HINSTANCE, _
		ByVal param As InputDialogParam Ptr _
	)As INT_PTR

	Dim res As INT_PTR = DialogBoxParam( _
		hInst, _
		MAKEINTRESOURCE(IDD_DLG_TASKS), _
		NULL, _
		@ModalDialogProc, _
		Cast(LPARAM, param) _
	)

	Return res

End Function

Private Function AlertableMessageLoop( _
		ByVal hWin As HWND _
	)As Integer

	Dim hEvent As HANDLE = CreateEvent( _
		NULL, _
		TRUE, _
		FALSE, _
		NULL _
	)
	If hEvent = NULL Then
		Return 1
	End If

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
				CloseHandle(hEvent)
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

	CloseHandle(hEvent)

	Return 0

End Function

Private Function tWinMain( _
		Byval hInst As HINSTANCE, _
		ByVal hPrevInstance As HINSTANCE, _
		ByVal lpCmdLine As LPTSTR, _
		ByVal iCmdShow As Long _
	)As Long

	Scope
		Dim hrVisualStyles As Integer = EnableVisualStyles()
		If FAILED(hrVisualStyles) Then
			Return 1
		End If
	End Scope

	Dim param As InputDialogParam = Any
	param.hInst = hInst

	' Scope
	' 	Dim hWin As HWND = CreateMainWindow( _
	' 		hInst, _
	' 		@param _
	' 	)
	' 	If hWin = NULL Then
	' 		Return 1
	' 	End If

	' 	param.hWin = hWin

	' 	Dim resMessageLoop As Integer = AlertableMessageLoop(hWin)

	' 	DestroyWindow(hWin)

	' 	Return resMessageLoop
	' End Scope

	Scope
		CreateModalWindow( _
			hInst, _
			@param _
		)

		Return 0
	End Scope

End Function

Type IntegerVector
	vec(265) As Integer
End Type

Dim hInst As HMODULE = GetModuleHandle(NULL)
Dim hPrevInstance As HINSTANCE = NULL

' The program does not process command line parameters
Dim Arguments As LPTSTR = NULL

Dim RetCode As Long = tWinMain( _
	hInst, _
	hPrevInstance, _
	Arguments, _
	SW_SHOW _
)

End(RetCode)

Dim Vector As IntegerVector = Any
For i As Integer = LBound(Vector.vec) To UBound(Vector.vec)
	Vector.vec(i) = i
Next
