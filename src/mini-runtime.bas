#ifdef WITHOUT_RUNTIME

#include once "mini-runtime.bi"

#ifdef __FB_WIN32__
#include once "windows.bi"
#endif

#undef fb_End
#undef fb_Init

Declare Function main cdecl Alias "main"(ByVal argc As Long, ByVal argv As ZString Ptr Ptr) As Long

Public Sub __main cdecl Alias "__main"()

End Sub

Public Sub fb_Init Alias "fb_Init"(ByVal argc As Long, ByVal argv As ZString Ptr Ptr, ByVal lang As Long)

End Sub

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

Public Function mainCRTStartup Alias "mainCRTStartup"()As Integer

	Dim RetCode As Long = main(0, 0)

	fb_End(RetCode)

	Return RetCode

End Function

#endif
