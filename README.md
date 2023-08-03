# Стиль кода

Рекомендации по оформлению кода.

## Форматирование

### Пробелы

Операторы следует отбивать пробелами:

```FreeBASIC
X = A + B
```

После запятых следует ставить пробелы:

```FreeBASIC
Foo(Param1, Param2, Param3)
```

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

### Возвращаемое значение

Последнюю строку функции с оператором возврата следует отбивать пустыми строками:

```FreeBASIC
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

Операторы тоже являются функциями, не следует использовать их в условиях:

```FreeBASIC
If a + b = 2 Then
	'
End If
```


## Условный оператор

Однострочный условный оператор не используется:

```FreeBASIC
If Variable = 1 Then Foo()
```

Используется только многострочный условный оператор:

```FreeBASIC
If Variable = 1 Then
	'
End If
```

## Передача параметров в функцию

Во избежание неоднозначности нельзя опускать ключевые слова `ByVal` или `ByRef` при объявлении функции.

В функцию не следует передавать функции:

```FreeBASIC
Bar(Foo())
```

Результат функции следует присвоить переменной, и только затем передать эту переменную в функцию:

```FreeBASIC
Dim x As Integer = Foo()
Bar(x)
```

## Объявление переменных

Объявлять переменные следует сразу же с присваиванием в одной строке:

```FreeBASIC
Dim x As Integer = 265
Dim y As Integer = Foo()
```

Переменные, которые в дальнейшем будут использованы для получения значения по указателю (retval), следует объявлять без инициализации:

```FreeBASIC
Dim Buffer As ZString * 512 = Any
FillBuffer(@Buffer)
```

Не следует объявлять переменные в строчку:

```FreeBASIC
Dim As Integer a, b, c, d, e
```
