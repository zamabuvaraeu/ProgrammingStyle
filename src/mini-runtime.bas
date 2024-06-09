#include once "mini-runtime.bi"
#include once "windows.bi"

#ifdef WITHOUT_RUNTIME

#undef fb_End

Declare Function main Alias "main"(ByVal argc As Long, ByVal argv As ZString Ptr) As Long

Public Sub fb_End Alias "fb_End"(ByVal RetCode As Long)
	#ifdef __FB_WIN32__
		ExitProcess(RetCode)
	#else
		#ifdef __FB_LINUX__
			#ifdef __FB_64BIT__
				Asm
					mov rax, 60        /' 60 - номер системного вызова exit '/
					mov rdi, [RetCode] /' произвольный код возврата - 22    '/
					syscall            /' выполняем системный вызов exit    '/
				End Asm
			#else
				Asm
					mov eax, 1         /' номер системного вызова exit = 1   '/
					mov ebx, [RetCode] /' передать 0 как значение параметра  '/
					int 0x80           /' вызвать exit(0)                    '/
				End Asm
			#endif
		#endif
	#endif
End Sub

Public Function EntryPoint Alias "EntryPoint"()As Integer

	Dim RetCode As Long = main(0, 0)

	fb_End(RetCode)

	Return RetCode

End Function

#endif
