;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;|	proc StrLib_Get_StrLen SrcStr: DWORD											 						 |
;|																										 |
;|  This function returns the length of a null-terminated string.									 	 |
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
proc StrLib_Get_StrLen SrcStr: DWORD

	;1. Calculate the length of the end-result string (escaped '\' and the null-terminator)
		;Preserve value of esi (whatever it may be)
			push esi

			;Set value of esi to address of SrcStr
				mov esi, [SrcStr]
				
				push ecx

					xor ecx, ecx

				Util_Get_StrLen_CountLoop:
						lodsb
						cmp al, 0
						je Util_Get_StrLen_Done
						
						add ecx, 1
						jmp Util_Get_StrLen_CountLoop
	
					Util_Get_StrLen_Done:
	
				mov eax, ecx

		;Restore value of esi (whatever it may be)
		;	pop esi
		;Restore value of eax (whatever it may be)
		;	pop eax
		
		pop ecx

	;Preserve edi register from previously entering this procedure -- incase it's needed.
		pop edi

;return
ret
endp




;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;|	proc StrLib_Determine_EscapeBackslash_StrLen SrcStr: DWORD											 |
;|																										 |
;|  This function takes in an unescaped string and will return out the length the escaped version would	 |
;|	take. This is useful for finding out how many bytes will be needed to manually allocate on the heap	 |
;|	for a string that will be escaped.																	 |
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
proc StrLib_Determine_EscapeBackslash_StrLen SrcStr: DWORD

local DestString:DWORD

local SrcString_Length:DWORD
local New_EscapedString_Length:DWORD

mov [SrcString_Length], 0

	;This is the optimized verison of string length, but because we need to capture the byte being read in so we can add one extra
	;character for each \, we have to use the slower version of lodsb and stosb
		;First, get the length of the string
			;From: http://www.int80h.org/strlen/
	;			mov edi, [Filename]
			
				;Set ecx to 0
	;				sub	ecx, ecx
				;Set the terminator match for null termination (0x00)
	;				sub	al, al
				;Inverse the bits so get either maximum value of a unsigned int, or a -1. In this
				;case we are looking for -1
	;				not	ecx
				;clear the direction flag
	;				cld
				;scan the string until while it has not seen the terminator, and decrease ecx (from -1) as each character
				;is scanned.
	;				repne scasb
				;inverse the bits again so that we go positive
	;				not	ecx
				;subtract 1 from the length for the terminator
	;			;	dec	ecx

	;Preserve edi register from previously entering this procedure -- incase it's needed.
		push edi

	xor edi, edi

	;1. Calculate the length of the end-result string (escaped '\' and the null-terminator)
		;Preserve value of eax (whatever it may be)
			push eax
		;Preserve value of esi (whatever it may be)
			push esi
	
			;Set value of esi to address of SrcStr
				mov esi, [SrcStr]
				
				;mov edi, [New_FileOpen_Slot.lpFilePath]
				;mov edi, New_FileOpen_Slot.lpFilePath
				
				push ecx
				
					;mov ecx, New_FileOpen_Slot.lpFilePath
					;mov edi, [ecx]		;lpFilePath is the first member in
										;New_FileOpen_Slot (FileInfo_Struct)
										;so in the disassembler it will look like
										;JUST MOV EDI, New_FileOpen_Slot

					;Rem'ed out temporary to check something...
						;mov ecx, [SrcString_Length]
					;mov ecx, dword ptr SrcString_Length
					xor ecx, ecx

				Util_Escape_BS_CountLoop:
						lodsb
						
						cmp al, 0x5C								; 0x5C = '\'
						;add [SrcString_Length], 1
						add ecx, 1
						je Util_Escape_BS_Add_One_To_Length
						
						cmp al, 0
						je Util_Escape_BS_Done
						
						jmp Util_Escape_BS_CountLoop
	
						Util_Escape_BS_Add_One_To_Length:
							;add [SrcString_Length], 1
							add ecx, 1
							jmp Util_Escape_BS_CountLoop
	
					Util_Escape_BS_Done:
						;Add one for the null-terminator
						;add [SrcString_Length], 1
						add ecx, 1
				;pop ecx
	
		;Restore value of esi (whatever it may be)
		;	pop esi
		;Restore value of eax (whatever it may be)
		;	pop eax


		mov eax, ecx
		
		pop ecx

	;Preserve edi register from previously entering this procedure -- incase it's needed.
		pop edi
		
;mov eax, [SrcString_Length]
;mov eax, ecx

;return
ret
endp



;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;|	proc StrLib_Generate_Escape_Backslash SrcStr: DWORD													 |
;|																										 |
;|  This function takes in a string and unescaped string and will return out the string with the		 |
;|	each backslash causing an extra backslash. This is useful for strings that are file paths.	 		 |
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
proc StrLib_Generate_Escape_Backslash SrcStr: DWORD, bAdd_ZeroTerminator: DWORD

local DestString:DWORD

local SrcString_Length:DWORD
local New_EscapedString:DWORD

mov [SrcString_Length], 0

	;This is the optimized verison of string length, but because we need to capture the byte being read in so we can add one extra
	;character for each \, we have to use the slower version of lodsb and stosb
		;First, get the length of the string
			;From: http://www.int80h.org/strlen/
	;			mov edi, [Filename]
			
				;Set ecx to 0
	;				sub	ecx, ecx
				;Set the terminator match for null termination (0x00)
	;				sub	al, al
				;Inverse the bits so get either maximum value of a unsigned int, or a -1. In this
				;case we are looking for -1
	;				not	ecx
				;clear the direction flag
	;				cld
				;scan the string until while it has not seen the terminator, and decrease ecx (from -1) as each character
				;is scanned.
	;				repne scasb
				;inverse the bits again so that we go positive
	;				not	ecx
				;subtract 1 from the length for the terminator
	;			;	dec	ecx

	;Preserve edi register from previously entering this procedure -- incase it's needed.
		push edi

	xor edi, edi

	;1. Calculate the length of the end-result string (escaped '\' and the null-terminator)
		;Preserve value of eax (whatever it may be)
			push eax
		;Preserve value of esi (whatever it may be)
			push esi
	
			;Set value of esi to address of SrcStr
				mov esi, [SrcStr]
				
				;mov edi, [New_FileOpen_Slot.lpFilePath]
				;mov edi, New_FileOpen_Slot.lpFilePath
				
				push ecx
				
					;mov ecx, New_FileOpen_Slot.lpFilePath
					;mov edi, [ecx]		;lpFilePath is the first member in
										;New_FileOpen_Slot (FileInfo_Struct)
										;so in the disassembler it will look like
										;JUST MOV EDI, New_FileOpen_Slot

					;Rem'ed out temporary to check something...
						;mov ecx, [SrcString_Length]
					;mov ecx, dword ptr SrcString_Length
					xor ecx, ecx

				Util_Generate_Escape_BS_CountLoop:
						lodsb
						
						cmp al, 0x5C								; 0x5C = '\'
						;add [SrcString_Length], 1
						je Util_Generate_Escape_BS_Add_One_To_Length
						add ecx, 1
						
						cmp al, 0
						je Util_Generate_Escape_BS_Done
						
						jmp Util_Generate_Escape_BS_CountLoop
	
						Util_Generate_Escape_BS_Add_One_To_Length:
							add ecx, 1
							;add [SrcString_Length], 1
							add ecx, 1
							jmp Util_Generate_Escape_BS_CountLoop
	
					Util_Generate_Escape_BS_Done:
						;Add one for the null-terminator
						;add [SrcString_Length], 1
						cmp [bAdd_ZeroTerminator], 1
						jne Util_Generate_Escape_BS_Done_2
						add ecx, 1

						Util_Generate_Escape_BS_Done_2:
				;pop ecx
	
		;Restore value of esi (whatever it may be)
		;	pop esi
		;Restore value of eax (whatever it may be)
		;	pop eax





	;2. Now allocate the new string
		push ecx
		;	push ebx
		;		mov ebx, [SrcString_Length]
		;		mov ecx, [ebx]
				sub ecx, 1
				
				;invoke HeapAlloc, [ProcessHeap], HEAP_GENERATE_EXCEPTIONS + HEAP_ZERO_MEMORY, [SrcString_Length]
				;HeapAlloc seems to trampls the ecx register, so it had to be preserved a few lines above!
					invoke HeapAlloc, [ProcessHeap], HEAP_GENERATE_EXCEPTIONS + HEAP_ZERO_MEMORY, ecx
				mov [New_EscapedString], eax
		;	pop ebx
		pop ecx



		;Restore value of esi (whatever it may be)
			pop esi
		;Restore value of eax (whatever it may be)
			pop eax


	;3. Now fill the dest string with the escaped-version of the original string
		;Preserve value of eax (whatever it may be)
			push eax
		;Preserve value of esi (whatever it may be)
			push esi
	
			;Set value of esi to address of SrcStr
				mov esi, [SrcStr]
				mov edi, [New_EscapedString]
				
				;;push ecx
				
					;mov ecx, New_FileOpen_Slot.lpFilePath
					;mov edi, [ecx]		;lpFilePath is the first member in
										;New_FileOpen_Slot (FileInfo_Struct)
										;so in the disassembler it will look like
										;JUST MOV EDI, New_FileOpen_Slot
				Util_CreateEscaped_DestStr_Loop:
						lodsb
						
						cmp al, 0x5C								; 0x5C = '\'
						je Util_CreateEscaped_DestStr_AddDouble_BS
						
						stosb
						
						cmp al, 0
						je Util_CreateEscaped_DestStr_Loop_Done
						
						;stosb
						jmp Util_CreateEscaped_DestStr_Loop
	
						Util_CreateEscaped_DestStr_AddDouble_BS:
							mov [edi], byte 0x5C
							add edi, dword 1
							mov [edi], byte 0x5C
							add edi, 1
							;jmp Util_Escape_BS_CountLoop
							jmp Util_CreateEscaped_DestStr_Loop
	
					Util_CreateEscaped_DestStr_Loop_Done:
						;Add one for the null-terminator
						add [SrcString_Length], 1
	
				;;pop ecx
	
		;Restore value of esi (whatever it may be)
			pop esi
		;Restore value of eax (whatever it may be)
			pop eax

		;mov eax, ecx
		mov eax, [New_EscapedString]
		
		pop ecx

	;Preserve edi register from previously entering this procedure -- incase it's needed.
		pop edi
		
;mov eax, [SrcString_Length]
;mov eax, ecx

;return
ret
endp