# Стиль кода

Рекомендации по оформлению кода

## Форматирование

### Более двух параметров функции

Если функция принимает больше двух параметров, каждый параметр следует писать на отдельной строке с дополнительным отступом:

```FreeBASIC
Declare Function Foo( _
	ByVal Param1 As Integer, _
	ByVal Param2 As Integer, _
	ByVal Param3 As Integer _
)As Integer

Function Foo( _
		ByVal Param1 As Integer, _
		ByVal Param2 As Integer, _
		ByVal Param3 As Integer _
	)As Integer
	
	Return 0
	
End Function
```

### Выбор чемоданов

Каждый чемодан следует отделять пустой строкой:

```FreeBASIC
Select Case uMsg
	
	Case WM_INITDIALOG
		Dim hMod As HMODULE = GetModuleHandle(0)
		Dim ico As HICON = LoadIcon( _
			hMod, _
			Cast(LPTSTR, IDR_ICON) _
		)
		
		SendMessage(hwndDlg, WM_SETICON, ICON_BIG, Cast(LPARAM, ico))
		SendMessage(hwndDlg, WM_SETICON, ICON_SMALL, Cast(LPARAM, ico))
		
	Case WM_COMMAND
		
		Select Case LOWORD(wParam)
			
			' Case IDC_BTN_RESULT
				' Calculate_Click(hwndDlg)
				
			Case IDCANCEL
				EndDialog(hwndDlg, 1)
				
		End Select
		
	Case WM_CLOSE
		EndDialog(hwndDlg, 1)
		
	Case Else
		Return False
		
End Select
```

## Проверка результата функций

Условный оператор не должен менять состояние программы.

Результат функции следует присваивать переменной, и затем проверять переменную в условии:

```FreeBASIC
Dim x As Integer = Foo()

If x = 1 Then
	'
End If
```

Не следует вызывать функцию внутри условного оператора.

Неправильно:

```FreeBASIC
If Foo() = 1 Then
	'
End If
```
