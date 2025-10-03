#ifndef REGISTRY_BI
#define REGISTRY_BI

#include once "windows.bi"

Const ServerKeyString = __TEXT("Host")
Const ResourceKeyString = __TEXT("Resource")
Const VerbKeyString = __TEXT("Verb")
Const FileKeyString = __TEXT("File")
Const ContentTypeKeyString = __TEXT("Content-Type")
Const UserNameKeyString = __TEXT("UserName")
Const PasswordKeyString = __TEXT("Password")

Type SettingsItem
	Key As TCHAR Ptr
	Value As TCHAR Ptr
	ValueLength As Integer
	ControlId As Integer
End Type

Type SettingsVector
	Vec(0 To 4) As SettingsItem
End Type

Declare Function LoadSettings( _
	ByVal pVec As SettingsVector Ptr _
)As HRESULT

Declare Function SaveSettings( _
	ByVal pVec As SettingsVector Ptr _
)As HRESULT

Declare Function GetContentTypeOfFileExtension( _
	ByVal pBuf As TCHAR Ptr, _
	ByVal pFileExtension As TCHAR Ptr, _
	ByVal Capacity As Integer _
)As HRESULT

#endif