#include once "WinMain.bi"
#include once "win\commctrl.bi"
#include once "win\shlobj.bi"
#include once "win\windowsx.bi"
#include once "Resources.RH"

Const C_COLUMNS As UINT = 2

Type InputDialogParam
	hInst As HINSTANCE
End Type

Type ResStringBuffer
	szText(255) As TCHAR
End Type

Type PathBuffer
	szText(MAX_PATH) As TCHAR
End Type

Enum TaskState
	Starting
	Working
	Stopped
End Enum

Enum FormNotify
	TaskStarting
	TaskWorking
	TaskStopped
End Enum

Type BrowseFolderTask
	szText(MAX_PATH) As TCHAR
	State As TaskState
	hWin As HWND
	MainThread As HANDLE
	hFind As HANDLE
	pfnAPC As PAPCFUNC
	ffd As WIN32_FIND_DATA
	NeedWorking As Boolean
End Type

Type MainFormParam
	hWin As HWND
	Action As FormNotify
	pTask As BrowseFolderTask Ptr
	cFileName(MAX_PATH) As TCHAR
End Type

Private Function WorkerThread( _
		ByVal lpParam As LPVOID _
	)As DWORD
	
	Dim pTask As BrowseFolderTask Ptr = lpParam
	
	Select Case pTask->State
		
		Case TaskState.Starting
			If pTask->NeedWorking Then
				Dim pFormParam As MainFormParam Ptr = CoTaskMemAlloc(SizeOf(MainFormParam))
				
				If pFormParam Then
					pFormParam->hWin = pTask->hWin
					pFormParam->Action = FormNotify.TaskStarting
					pFormParam->pTask = pTask
					
					Const AsteriskString = __TEXT("*")
					lstrcat(@pTask->szText(0), @AsteriskString)
					
					pTask->hFind = FindFirstFile( _
						@pTask->szText(0), _
						@pTask->ffd _
					)
					If pTask->hFind = INVALID_HANDLE_VALUE Then
						pFormParam->Action = FormNotify.TaskStopped
						pTask->State = TaskState.Stopped
					Else
						lstrcpyW(@pFormParam->cFileName(0), pTask->ffd.cFileName)
						
						' Notifying the window that the process is starting
						QueueUserAPC( _
							pTask->pfnAPC, _
							pTask->MainThread, _
							Cast(ULONG_PTR, pFormParam) _
						)
						
						pTask->State = TaskState.Working
					End If
				Else
					pTask->State = TaskState.Stopped
				End If
			Else
				pTask->State = TaskState.Stopped
			End If
			
			QueueUserWorkItem( _
				@WorkerThread, _
				pTask, _
				WT_EXECUTEDEFAULT _
			)
			
		Case TaskState.Working
			If pTask->NeedWorking Then
				
				Dim pFormParam As MainFormParam Ptr = CoTaskMemAlloc(SizeOf(MainFormParam))
				
				If pFormParam Then
					pFormParam->hWin = pTask->hWin
					pFormParam->Action = FormNotify.TaskWorking
					pFormParam->pTask = pTask
					
					Sleep_(1000)
					
					Dim resFindNext As BOOL = FindNextFile( _
						pTask->hFind, _
						@pTask->ffd _
					)
					If resFindNext = 0 Then
						/'
						Dim dwError As DWORD = GetLastError()
						If dwError <> ERROR_NO_MORE_FILES Then
							' TOTO Handle error
						End If
						'/
						
						pFormParam->Action = FormNotify.TaskStopped
						pTask->State = TaskState.Stopped
					Else
						lstrcpyW(@pFormParam->cFileName(0), pTask->ffd.cFileName)
						
						' Notifying the window that the process is working
						QueueUserAPC( _
							pTask->pfnAPC, _
							pTask->MainThread, _
							Cast(ULONG_PTR, pFormParam) _
						)
					End If
				Else
					pTask->State = TaskState.Stopped
				End If
			Else
				pTask->State = TaskState.Stopped
			End If
			
			QueueUserWorkItem( _
				@WorkerThread, _
				pTask, _
				WT_EXECUTEDEFAULT _
			)
			
		Case TaskState.Stopped
			FindClose(pTask->hFind)
			
			Dim pFormParam As MainFormParam Ptr = CoTaskMemAlloc(SizeOf(MainFormParam))
			
			If pFormParam Then
				
				pFormParam->hWin = pTask->hWin
				pFormParam->Action = FormNotify.TaskStopped
				pFormParam->pTask = pTask
				
				' Notifying the window that the process is stopped
				QueueUserAPC( _
					pTask->pfnAPC, _
					pTask->MainThread, _
					Cast(ULONG_PTR, pFormParam) _
				)
			End If
			
	End Select
	
	Return 0
	
End Function

Private Function ListViewFindItem( _
		ByVal hList As HWND, _
		ByVal Key As Any Ptr _
	)As Long
	
	Dim ItemsCount As Long = ListView_GetItemCount(hList)
	
	For i As Long = 0 To ItemsCount - 1
		Dim Item As LVITEM = Any
		With Item
			.mask = LVIF_PARAM
			.iItem = i
			.iSubItem = 0
		End With
		
		ListView_GetItem(hList, @Item)
		
		If Item.lParam = Cast(LPARAM, Key) Then
			Return i
		End If
	Next
	
	Return -1
	
End Function

Private Sub MainFormAcpCallback( _
		ByVal context As ULONG_PTR _
	)
	
	Dim pFormParam As MainFormParam Ptr = Cast(MainFormParam Ptr, context)
	If pFormParam = NULL Then
		Exit Sub
	End If
	
	Dim this As InputDialogParam Ptr = Cast(InputDialogParam Ptr, GetWindowLongPtr(pFormParam->hWin, GWLP_USERDATA))
	
	Select Case pFormParam->Action
		
		Case FormNotify.TaskStarting
			Dim hList As HWND = GetDlgItem(pFormParam->hWin, IDC_LVW_TASKS)
			Dim index As Long = ListViewFindItem( _
				hList, _
				pFormParam->pTask _
			)
			If index <> -1 Then
				Dim szText As ResStringBuffer = Any
				LoadString( _
					this->hInst, _
					IDS_RUNNING, _
					@szText.szText(0), _
					UBound(szText.szText) - LBound(szText.szText) _
				)
				
				Dim Item As LVITEM = Any
				With Item
					.mask = LVIF_TEXT
					.iItem  = index
					.iSubItem = 1
					.pszText = @szText.szText(0)
				End With
				
				ListView_SetItem(hList, @Item)
			
				Dim hbList As HWND = GetDlgItem(pFormParam->hWin, IDC_LST_RESULT)
				ListBox_AddString(hbList, @pFormParam->cFileName(0))
				
				Dim hButton As HWND = GetDlgItem(pFormParam->hWin, IDC_BTN_CLEAR)
				Button_Enable(hButton, 1)
			End If
			
		Case FormNotify.TaskWorking
			Dim hList As HWND = GetDlgItem(pFormParam->hWin, IDC_LVW_TASKS)
			Dim index As Long = ListViewFindItem( _
				hList, _
				pFormParam->pTask _
			)
			If index <> -1 Then
				Dim szText As ResStringBuffer = Any
				LoadString( _
					this->hInst, _
					IDS_WORKED, _
					@szText.szText(0), _
					UBound(szText.szText) - LBound(szText.szText) _
				)
				Dim Item As LVITEM = Any
				With Item
					.mask = LVIF_TEXT
					.iItem  = index
					.iSubItem = 1
					.pszText = @szText.szText(0)
				End With
				
				ListView_SetItem(hList, @Item)
				
				Dim hbList As HWND = GetDlgItem(pFormParam->hWin, IDC_LST_RESULT)
				ListBox_AddString(hbList, @pFormParam->cFileName(0))
				
				Dim hButton As HWND = GetDlgItem(pFormParam->hWin, IDC_BTN_CLEAR)
				Button_Enable(hButton, 1)
			End If
			
		Case FormNotify.TaskStopped
			Dim hList As HWND = GetDlgItem(pFormParam->hWin, IDC_LVW_TASKS)
			Dim index As Long = ListViewFindItem( _
				hList, _
				pFormParam->pTask _
			)
			If index <> -1 Then
				Dim szText As ResStringBuffer = Any
				LoadString( _
					this->hInst, _
					IDS_STOPPED, _
					@szText.szText(0), _
					UBound(szText.szText) - LBound(szText.szText) _
				)
				Dim Item As LVITEM = Any
				With Item
					.mask = LVIF_TEXT
					.iItem  = index
					.iSubItem = 1
					.pszText = @szText.szText(0)
				End With
				
				ListView_SetItem(hList, @Item)
			End If
			
	End Select
	
	CoTaskMemFree(pFormParam)
	
End Sub

Private Sub ListViewTaskCreateColumns( _
		ByVal hInst As HINSTANCE, _
		ByVal hList As HWND _
	)
	
	Dim rcList As RECT = Any
	GetClientRect(hList, @rcList)
	
	Dim ColumnWidth As Long = rcList.right \ C_COLUMNS
	
	Dim szText As ResStringBuffer = Any
	
	Dim Column As LVCOLUMN = Any
	With Column
		.mask = LVCF_FMT Or LVCF_WIDTH Or LVCF_TEXT Or LVCF_SUBITEM
		.fmt = LVCFMT_RIGHT
		.cx = ColumnWidth
		.pszText = @szText.szText(0)
	End With
	
	For i As UINT = 0 To C_COLUMNS - 1
		LoadString( _
			hInst, _
			IDS_TASK + i, _
			@szText.szText(0), _
			UBound(szText.szText) - LBound(szText.szText) _
		)
		Column.iSubItem = i
		ListView_InsertColumn(hList, i, @Column)
	Next
	
End Sub

Private Sub ListViewAppendRow( _
		ByVal hList As HWND, _
		ByVal ColumnText1 As LPTSTR, _
		ByVal ColumnText2 As LPTSTR, _
		ByVal pData As Any Ptr _
	)
	
	Dim ItemsCount As Long = ListView_GetItemCount(hList)
	
	Scope
		Dim Item As LVITEM = Any
		With Item
			.mask = LVIF_TEXT Or LVIF_PARAM
			.iItem  = ItemsCount
			.iSubItem = 0
			.pszText = ColumnText1
			.lParam = Cast(LPARAM, pData)
		End With
		
		ListView_InsertItem(hList, @Item)
	End Scope
	
	Scope
		Dim SubItem As LVITEM = Any
		With Item
			.mask = LVIF_TEXT
			.iItem  = ItemsCount
			.iSubItem = 1
			.pszText = ColumnText2
		End With
		
		ListView_SetItem(hList, @SubItem)
	End Scope
	
End Sub

Private Sub ListViewTaskAppendRow( _
		ByVal hInst As HINSTANCE, _
		ByVal hList As HWND, _
		ByVal Column1 As TCHAR Ptr, _
		ByVal pData As Any Ptr _
	)
	
	Dim szText As ResStringBuffer = Any
	
	LoadString( _
		hInst, _
		IDS_STOPPED, _
		@szText.szText(0), _
		UBound(szText.szText) - LBound(szText.szText) _
	)
	
	Dim Column2 As TCHAR Ptr = @szText.szText(0)
	ListViewAppendRow( _
		hList, _
		Column1, _
		Column2, _
		pData _
	)
	
End Sub

Private Sub DialogMain_OnLoad( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)
	
	Dim hList As HWND = GetDlgItem(hWin, IDC_LVW_TASKS)
	Const dwFlasg = LVS_EX_FULLROWSELECT Or LVS_EX_GRIDLINES
	ListView_SetExtendedListViewStyle(hList, dwFlasg)
	
	ListViewTaskCreateColumns(this->hInst, hList)
	
End Sub

Private Sub ButtonAdd_OnClick( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)
	
	Dim bi As BROWSEINFO = Any
	With bi
		.hwndOwner = hWin
		.pidlRoot = NULL
		.pszDisplayName = NULL
		.lpszTitle = NULL
		.ulFlags = BIF_RETURNONLYFSDIRS
		.lpfn = NULL
		.lParam = NULL
		.iImage = 0
	End With
	
	Dim plst As PIDLIST_ABSOLUTE = SHBrowseForFolder(@bi)
	If plst Then
		' Create Task
		Dim pTask As BrowseFolderTask Ptr = CoTaskMemAlloc(SizeOf(BrowseFolderTask))
		
		If pTask Then
			pTask->State = TaskState.Stopped
			pTask->hWin = hWin
			pTask->pfnAPC = @MainFormAcpCallback
			pTask->NeedWorking = True
			
			Dim dwThreadId As DWORD = GetCurrentThreadId()
			pTask->MainThread = OpenThread( _
				THREAD_ALL_ACCESS, _
				FALSE, _
				dwThreadId _
			)
			If pTask->MainThread = NULL Then
				CoTaskMemFree(pTask)
				Exit Sub
			End If
			
			SHGetPathFromIDList(plst, @pTask->szText(0))
			
			Dim Length As Integer = lstrlen(@pTask->szText(0))
			If Length Then
				Const ReverseSolidusCharacter = &h005C
				Const NullCharacter = &h0000
				If pTask->szText(Length - 1) <> ReverseSolidusCharacter Then
					pTask->szText(Length) = ReverseSolidusCharacter
					pTask->szText(Length + 1) = NullCharacter
				End If
			End If
			
			Dim hList As HWND = GetDlgItem(hWin, IDC_LVW_TASKS)
			ListViewTaskAppendRow( _
				this->hInst, _
				hList, _
				@pTask->szText(0), _
				pTask _
			)
		End If
		
		CoTaskMemFree(plst)
	End If
	
End Sub

Private Sub ButtonStart_OnClick( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)
	
	Dim hList As HWND = GetDlgItem(hWin, IDC_LVW_TASKS)
	Dim index As Long = ListView_GetNextItem(hList, -1, LVNI_SELECTED)
	If index <> -1 Then
		Dim Item As LV_ITEM = Any
		With Item
			.mask = LVIF_PARAM
			.iItem = index
			.iSubItem = 0
		End With
		
		ListView_GetItem(hList, @Item)
		
		Dim pTask As BrowseFolderTask Ptr = Cast(BrowseFolderTask Ptr, Item.lParam)
		
		If pTask->State = TaskState.Stopped Then
			pTask->NeedWorking = True
			pTask->State = TaskState.Starting
			
			' Run Task in ThreadPool
			QueueUserWorkItem( _
				@WorkerThread, _
				pTask, _
				WT_EXECUTEDEFAULT _
			)
		End If
	End If
	
End Sub

Private Sub ButtonStop_OnClick( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)
	
	Dim hList As HWND = GetDlgItem(hWin, IDC_LVW_TASKS)
	Dim index As Long = ListView_GetNextItem(hList, -1, LVNI_SELECTED)
	If index <> -1 Then
		Dim Item As LV_ITEM = Any
		With Item
			.mask = LVIF_PARAM
			.iItem = index
			.iSubItem = 0
		End With
		
		ListView_GetItem(hList, @Item)
		
		Dim pTask As BrowseFolderTask Ptr = Cast(BrowseFolderTask Ptr, Item.lParam)
		pTask->NeedWorking = False
	End If
	
End Sub

Private Sub ButtonRemove_OnClick( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)
	
	Dim hList As HWND = GetDlgItem(hWin, IDC_LVW_TASKS)
	Dim index As Long = ListView_GetNextItem(hList, -1, LVNI_SELECTED)
	If index <> -1 Then
		Dim Item As LV_ITEM = Any
		With Item
			.mask = LVIF_PARAM
			.iItem = index
			.iSubItem = 0
		End With
		
		ListView_GetItem(hList, @Item)
		
		Dim pTask As BrowseFolderTask Ptr = Cast(BrowseFolderTask Ptr, Item.lParam)
		pTask->NeedWorking = False
		
		ListView_DeleteItem(hList, index)
		
		Dim hButtonStart As HWND = GetDlgItem(hWin, IDC_BTN_START)
		Dim hButtonStop As HWND = GetDlgItem(hWin, IDC_BTN_STOP)
		Dim hButtonRemove As HWND = GetDlgItem(hWin, IDC_BTN_REMOVE)
		
		Dim bEnabled As Long = 0
		
		Button_Enable(hButtonStart, bEnabled)
		Button_Enable(hButtonStop, bEnabled)
		Button_Enable(hButtonRemove, bEnabled)
	End If
	
End Sub

Private Sub IDCANCEL_OnClick( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)
	
	PostQuitMessage(0)
	
End Sub

Private Sub ButtonClear_OnClick( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)
	
	Dim hButton As HWND = GetDlgItem(hWin, IDC_BTN_CLEAR)
	Button_Enable(hButton, 0)
	
	Dim hList As HWND = GetDlgItem(hWin, IDC_LST_RESULT)
	ListBox_ResetContent(hList)
	
End Sub

Private Sub DialogMain_OnUnload( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND _
	)
	
	' CoTaskMemFree(pTask)
	
End Sub

Private Sub ListView_OnClick( _
		ByVal this As InputDialogParam Ptr, _
		ByVal hWin As HWND, _
		ByVal hList As HWND, _
		ByVal lpnmitem As NMITEMACTIVATE Ptr _
	)
	
	Dim hButtonStart As HWND = GetDlgItem(hWin, IDC_BTN_START)
	Dim hButtonStop As HWND = GetDlgItem(hWin, IDC_BTN_STOP)
	Dim hButtonRemove As HWND = GetDlgItem(hWin, IDC_BTN_REMOVE)
	
	Dim bEnabled As Long = Any
	Dim index As Long = ListView_GetNextItem(hList, -1, LVNI_SELECTED)
	If index = -1 Then
		bEnabled = 0
	Else
		bEnabled = 1
	End If
	
	Button_Enable(hButtonStart, bEnabled)
	Button_Enable(hButtonStop, bEnabled)
	Button_Enable(hButtonRemove, bEnabled)
	
End Sub

Private Function InputDataDialogProc( _
		ByVal hWin As HWND, _
		ByVal uMsg As UINT, _
		ByVal wParam As WPARAM, _
		ByVal lParam As LPARAM _
	)As INT_PTR
	
	Select Case uMsg
		
		Case WM_INITDIALOG
			Dim pParam As InputDialogParam Ptr = Cast(InputDialogParam Ptr, lParam)
			DialogMain_OnLoad(pParam, hWin)
			SetWindowLongPtr(hWin, GWLP_USERDATA, Cast(LONG_PTR, pParam))
			
		Case WM_COMMAND
			Dim pParam As InputDialogParam Ptr = Cast(InputDialogParam Ptr, GetWindowLongPtr(hWin, GWLP_USERDATA))
			
			Select Case LOWORD(wParam)
				
				Case IDC_BTN_ADD
					ButtonAdd_OnClick(pParam, hWin)
					
				Case IDC_BTN_START
					ButtonStart_OnClick(pParam, hWin)
					
				Case IDC_BTN_STOP
					ButtonStop_OnClick(pParam, hWin)
					
				Case IDC_BTN_REMOVE
					ButtonRemove_OnClick(pParam, hWin)
					
				Case IDC_BTN_CLEAR
					ButtonClear_OnClick(pParam, hWin)
					
				Case IDCANCEL
					IDCANCEL_OnClick(pParam, hWin)
					
			End Select
			
		Case WM_NOTIFY
			Dim pParam As InputDialogParam Ptr = Cast(InputDialogParam Ptr, GetWindowLongPtr(hWin, GWLP_USERDATA))
			Dim pHdr As NMHDR Ptr = Cast(NMHDR Ptr, lParam)
			
			Select Case pHdr->code
				
				Case NM_CLICK
					Dim lpnmitem As NMITEMACTIVATE Ptr = Cast(NMITEMACTIVATE Ptr, lParam)
					ListView_OnClick(pParam, hWin, pHdr->hwndFrom, lpnmitem)
					
			End Select
			
		Case WM_CLOSE
			Dim pParam As InputDialogParam Ptr = Cast(InputDialogParam Ptr, GetWindowLongPtr(hWin, GWLP_USERDATA))
			DialogMain_OnUnload(pParam, hWin)
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
			MWMO_ALERTABLE Or MWMO_INPUTAVAILABLE _
		)
		Select Case dwWaitResult
			
			Case WAIT_OBJECT_0
				' The event became a signal
				' exit from loop
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
	
	Scope
		' Need for function SHBrowseForFolder
		Dim hrComInit As HRESULT = CoInitialize(NULL)
		If FAILED(hrComInit) Then
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
