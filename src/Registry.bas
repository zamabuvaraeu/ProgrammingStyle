#include once "Registry.bi"

Const RegistrySection = __TEXT("Software\BatchedFiles\HttpRestClient")

Public Function LoadSettings( _
		ByVal pVec As SettingsVector Ptr _
	)As HRESULT
	
	Dim hRegistryKey As HKEY = Any
	Dim resOpen As LSTATUS = RegOpenKeyEx( _
		HKEY_CURRENT_USER, _
		@RegistrySection, _
		0, _
		KEY_READ, _
		@hRegistryKey _
	)
	
	If resOpen = ERROR_SUCCESS Then
		
		For i As Integer = LBound(pVec->Vec) To UBound(pVec->Vec)
		
			Dim ValueType As DWORD = Any
			Dim cbBytes As DWORD = (MAX_PATH - 1) * SizeOf(TCHAR)
			
			Dim resQuery As LSTATUS = RegQueryValueEx( _
				hRegistryKey, _
				pVec->Vec(i).Key, _
				0, _
				@ValueType, _
				pVec->Vec(i).Value, _
				@cbBytes _
			)
			
			If resQuery = ERROR_SUCCESS Then
				If ValueType = REG_SZ Then
					If cbBytes Then
						Dim ValueLength As Integer = (cbBytes \ SizeOf(TCHAR)) - 1
						
						pVec->Vec(i).Value[ValueLength] = 0
						pVec->Vec(i).ValueLength = ValueLength
					Else
						pVec->Vec(i).Value[0] = 0
						pVec->Vec(i).ValueLength = 0
					End If
				Else
					pVec->Vec(i).Value[0] = 0
					pVec->Vec(i).ValueLength = 0
				End If
			Else
				pVec->Vec(i).Value[0] = 0
				pVec->Vec(i).ValueLength = 0
			End If
		Next
		
		RegCloseKey(hRegistryKey)
		
		Return S_OK
	End If
	
	Return E_FAIL
	
End Function

Public Function SaveSettings( _
		ByVal pVec As SettingsVector Ptr _
	)As HRESULT
	
	Dim hRegistryKey As HKEY = Any
	Dim resOpen As LSTATUS = RegCreateKeyEx( _
		HKEY_CURRENT_USER, _
		@RegistrySection, _
		0, _
		NULL, _
		REG_OPTION_NON_VOLATILE, _
		KEY_WRITE, _
		NULL, _
		@hRegistryKey, _
		NULL _
	)
	
	If resOpen = ERROR_SUCCESS Then
	
		For i As Integer = LBound(pVec->Vec) To UBound(pVec->Vec)
			If pVec->Vec(i).ValueLength Then
				Dim cbBytes As DWORD = (pVec->Vec(i).ValueLength + 1) * SizeOf(TCHAR)
				RegSetValueEx( _
					hRegistryKey, _
					pVec->Vec(i).Key, _
					0, _
					REG_SZ, _
					pVec->Vec(i).Value, _
					cbBytes _
				)
			End If
		Next
		
		RegCloseKey(hRegistryKey)
		
		Return S_OK
	End If
	
	Return E_FAIL
	
End Function

Public Function GetContentTypeOfFileExtension( _
		ByVal pBuf As TCHAR Ptr, _
		ByVal pFileExtension As TCHAR Ptr, _
		ByVal Capacity As Integer _
	)As HRESULT
	
	Dim hRegistryKey As HKEY = Any
	Dim resOpen As LSTATUS = RegOpenKeyEx( _
		HKEY_CLASSES_ROOT, _
		pFileExtension, _
		0, _
		KEY_READ, _
		@hRegistryKey _
	)
	If resOpen <> ERROR_SUCCESS Then
		Return E_FAIL
	End If
	
	Dim ValueType As DWORD = Any
	
	Const ContentTypeString = __TEXT("Content Type")
	Dim cbBytes As DWORD = (Capacity - 1) * SizeOf(TCHAR)
	Dim resQuery As LSTATUS = RegQueryValueEx( _
		hRegistryKey, _
		@ContentTypeString, _
		0, _
		@ValueType, _
		pBuf, _
		@cbBytes _
	)
	
	If resQuery <> ERROR_SUCCESS Then
		RegCloseKey(hRegistryKey)
		Return E_FAIL
	End If
	
	If ValueType <> REG_SZ Then
		RegCloseKey(hRegistryKey)
		Return E_FAIL
	End If
	
	If cbBytes = 0 Then
		RegCloseKey(hRegistryKey)
		Return E_FAIL
	End If
	
	Dim ValueLength As Integer = (cbBytes \ SizeOf(TCHAR)) - 1
	pBuf[ValueLength] = 0
	
	Return S_OK
	
End Function
