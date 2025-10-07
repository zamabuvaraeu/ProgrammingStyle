#include once "Registry.bi"

Const RegistrySection = __TEXT("Software\BatchedFiles\HttpRestClient")

Private Function LoadSettings( _
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

			Dim pByte As BYTE Ptr = CPtr(BYTE Ptr, pVec->Vec(i).Value)
			Dim resQuery As LSTATUS = RegQueryValueEx( _
				hRegistryKey, _
				pVec->Vec(i).Key, _
				0, _
				@ValueType, _
				pByte, _
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

Private Function SaveSettings( _
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
				Dim pByte As BYTE Ptr = CPtr(BYTE Ptr, pVec->Vec(i).Value)
				RegSetValueEx( _
					hRegistryKey, _
					pVec->Vec(i).Key, _
					0, _
					REG_SZ, _
					pByte, _
					cbBytes _
				)
			End If
		Next

		RegCloseKey(hRegistryKey)

		Return S_OK
	End If

	Return E_FAIL

End Function
