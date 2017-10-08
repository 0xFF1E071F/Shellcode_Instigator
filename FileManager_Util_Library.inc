;Errors
	ERROR_GET_FILEOPEN_INDEX_INDEX_NOT_FOUND			equ -1
	ERROR_GET_FILEOPEN_INDEX_NO_ELEMENTS_ALLOCATED		equ -2

FileManager_Create_Add_UniqueNameTableSlot_Label:

;Start of proc FileManager_Create_Add_UniqueNameTableSlot UseGlobal, lpTable:DWORD
;Params:
;			UseGlobal: boolean
;								Values:
;										TRUE		- lpTable parameter is ignored
;										FALSE		- lpTable parameter is used as the table to create the additional slot 
;			lpTable: DWORD
;								Values:
;										<pointer>	- Pointer to the table that will be used to create the additional slot in
proc FileManager_Create_Add_UniqueNameTableSlot UseGlobal, lpNameTable:DWORD
local Temp_NameTable: DWORD
local RetVal: DWORD

	mov [RetVal], -1

	cmp [UseGlobal], FALSE
	;jne UniqueNameTable_Global_CreateSlot	;jmp to UniqueNameTable_Global_CreateSlot if UseGlobal is TRUE
	jne UniqueNameTable_Global_IsSlotNeededChk

	;cmp lpNameTable, -1
	;jmp error?			;Use Global is false but the lpTable parameter is a value that makes no sense?

	;TODO: If a lpTable param is permitted then there needs to be a way to determine how many elements
	;there are in that array since it's not tied to the global lpFileManager object!


	UniqueNameTable_Global_IsSlotNeededChk:
		;Because Create_FileOpen_Slot is typically called before this, OpenFileCount is >0, so offset it by -1
		push ecx
			xor ecx, ecx
			mov cl, [lpFileManager.OpenFileCount]
			sub ecx, 1
			cmp ecx, 0
		;pop ecx
		jg UniqueNameTable_Global_CreateSlot

		;else	just create the slot no need to deal with temporary name table and the "shell game"

		push ecx
			xor ecx, ecx
			mov ecx, sizeof.FileManager_NameIndex
			;Allocate space for the temporary name table
				invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ecx
				mov [lpFileManager.lpUniqueNameTable], eax
		pop ecx

		mov al, [lpFileManager.OpenFileCount]


		;jmp UniqueNameTable_Global_CreateSlot_Exit
	
	UniqueNameTable_Global_CreateSlot:
		pop ecx
	;	;Since an initial element is created upon initialization of the FileManager,
	;	;the comparison is done against whether OpenFileCount is greater than 1 (NOT 0)!

	;		push ecx
	;			xor ecx, ecx
	;			;mov ecx, [lpFileManager.OpenFileCount]
	;			mov cl, [lpFileManager.OpenFileCount]
	;			;sub ecx, 1
	;			cmp ecx, 0
	;			jg UniqueNameTable_Global_AllocateSlot
	;		pop ecx

	;		;Only initial slot exists, no need to create an additional slot since both the FilesOpened and lpUniqueNameTable
	;		;should be in synch!

	;		xor eax, eax
	;		mov al, [lpFileManager.OpenFileCount]
	;		jmp UniqueNameTable_Global_CreateSlot_Exit

	UniqueNameTable_Global_AllocateSlot:
		push ecx
			xor ecx, ecx
			mov ecx, sizeof.FileManager_NameIndex
			push edx
				xor edx, edx
				mov dl, [lpFileManager.OpenFileCount]
				imul ecx, edx
			pop edx

			;Allocate space for the temporary name table
				invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ecx
				mov [Temp_NameTable], eax
		pop ecx



		;Now copy over all of the elements from the original name table to the temporary name table
			push ecx
				xor ecx, ecx
				mov ecx, -1
				UniqueNameTable_Global_AllocateSlot_CopyToTemp:
					add ecx, 1
					cmp cl, [lpFileManager.OpenFileCount]
					jge UniqueNameTable_Global_AllocateSlot_CopyToTemp_Done

					;else...

					push [lpFileManager.lpUniqueNameTable]
					push [Temp_NameTable]
					call FileManager_Copy_NameTable_Slot
					jmp UniqueNameTable_Global_AllocateSlot_CopyToTemp

				UniqueNameTable_Global_AllocateSlot_CopyToTemp_Done:
			pop ecx

		;Next, free the original NameTable
			;TODO: [POTENTIAL_BUG]: This may not be a "deep"-free! But that's ok because we're just going to re-use the already allocated existing memory???
				invoke HeapFree,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,lpFileManager.lpUniqueNameTable


		;Now, re-allocate the size of the name table plus one additional slot
			push ecx
				xor ecx, ecx
				mov ecx, sizeof.FileManager_NameIndex

				push edx
					mov dl, [lpFileManager.OpenFileCount]
					add edx, 1	;+1 for the additional slot

				imul ecx, edx

				pop edx

				;Allocate space for the original name table
					invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ecx
					mov [lpFileManager.lpUniqueNameTable], eax
			pop ecx



		;Then, copy all the elements from the temporary name table back over to [lpFileManager.lpUniqueNameTable]
			push ecx
				xor ecx, ecx
				mov ecx, -1

				UniqueNameTable_Global_AllocateSlot_CopyFromTemp:
					add ecx, 1
					cmp cl, [lpFileManager.OpenFileCount]
					jge UniqueNameTable_Global_AllocateSlot_CopyFromTemp_Done

					;else...

					push [Temp_NameTable]
					push [lpFileManager.lpUniqueNameTable]
					call FileManager_Copy_NameTable_Slot
					jmp UniqueNameTable_Global_AllocateSlot_CopyFromTemp

				UniqueNameTable_Global_AllocateSlot_CopyFromTemp_Done:
			pop ecx



		;Finally, free the temporary name table
			;TODO: [POTENTIAL_BUG]: This may not be a "deep"-free! But that's ok because we're just going to re-use the already allocated existing memory???
				invoke HeapFree,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,[Temp_NameTable]

		xor eax, eax
		mov al, [lpFileManager.OpenFileCount]


	UniqueNameTable_Global_CreateSlot_Exit:
		ret
endp
;End of proc FileManager_Create_Add_UniqueNameTableSlot UseGlobal, lpTable:DWORD





FileManager_Get_FileOpenIndex_ByFilename_Label:

proc FileManager_Get_FileOpenIndex_ByFilename Filename

		;First check if any elements are even allocated -- no sense in checking filename element values if there's not filenames
		;to work with!
			cmp [lpFileManager.OpenFileCount], 0
			jle GetFOI_BF_Index_NoElementsUsed		;First iteration through this jumps

		push ecx
		push edx

			xor ecx, ecx
			xor edx, edx
			xor eax, eax

		GetFOI_BF_Check_Name:
			push edx
				xor edx, edx
				mov edx, sizeof.FileInfo_Struct		;0x9A = 154 in dec. which is correct size of FileInfo_Struct
				;imul edx, ecx						;Initially ecx is 0, every iteration it gets incremented by 1 down blow
				imul edx, ecx

				push ecx
					;mov ebx, [lpFileManager.FilesOpened]
					mov ecx, lpFileManager.FilesOpened

					mov ebx, [ecx]
					add ebx, edx
					add ebx, 4	;0 is the path; 4 is the filename, and 8 is the path + filename
				pop ecx

;[0040115A]:
			;add ebx, 4	;0 is the path; 4 is the filename, and 8 is the path + filename
			;push edx
			;	mov edx, [ebx]
			;	mov ebx, edx
			;pop edx
			
			;For whatever reason, lstrcmp seems to LOOOOVE trampling the ecx register. Bad dog microsoft, very fucking bad!
				push ecx
						invoke lstrcmp, ebx, dword ptr Filename
				pop ecx
			
			cmp eax, 0
			je GetFOI_BF_Index_Found


			Continue_GetFOI_BF_Check_Name:
				add ecx, 1
				;cmp ecx, [lpFileManager.OpenFileCount]
				;mov eax, byte lpFileManager.OpenFileCount
				xor eax, eax
				mov al, [lpFileManager.OpenFileCount]
				cmp ecx, eax
				jge	GetFOI_BF_Index_NotFound
				jmp GetFOI_BF_Check_Name

		GetFOI_BF_Index_NotFound:
			;mov eax, -1
			mov eax, ERROR_GET_FILEOPEN_INDEX_INDEX_NOT_FOUND

			jmp GetFOI_BF_Exit

		GetFOI_BF_Index_NoElementsUsed:
			;mov eax, -2
			mov eax, ERROR_GET_FILEOPEN_INDEX_NO_ELEMENTS_ALLOCATED		;First iteration through, this is jumped to

			jmp GetFOI_BF_Exit2

		GetFOI_BF_Index_Found:
			mov eax, ecx

	GetFOI_BF_Exit:
		pop edx
		pop ecx
	GetFOI_BF_Exit2:
ret
endp







FileManager_OpenFile_Split_Label:

;Split refers to the fact that filename with path is split and passed in as two parameters (One as path and one as a filename)
proc FileManager_OpenFile_Split Path, Filename

local PathAndFile_Temp:DWORD


local Filename_Length:DWORD

local Path_Escaped_Length:DWORD

local Path_Escaped:DWORD
local PathAndFile_Escaped_Length:DWORD

	;First ensure the file isn't already opened
		;TODO: This should be checking based on Path+Filename since multiple files of the same name can
		;be opened at once just at different paths.
			;invoke Get_FileOpenIndex_ByFilename,dword ptr Filename
			push dword ptr Filename
				call FileManager_Get_FileOpenIndex_ByFilename

		;Possible error returns
		;>= 0	Element
		;  -1 	Element not found
		;  -2 	No elements used
		cmp eax, 0
		jl OpenFile_OpenFile
		jmp OpenFile_FileAlreadyOpen

		OpenFile_OpenFile:
			;Attempt to open the file
				push ecx
				xor ecx, ecx

				;First concat the Path and FileName together
					;First get the total length needed to hold both string names
						xor eax, eax			;Ensure eax is zero'ed out.

					;CRITICAL!!!!
					;As per: http://stackoverflow.com/questions/27230459/issue-in-rewriting-strlen-from-c-to-assembly
					;The cdecl calling conventions determines that arguments are passed on the stack and
					;the caller must clear the stack. You correctly pushed the argument but don't clear
					;the stack. Add a add esp, 4 after call strlen.
					;UPDATE: This could be bad information, as per minwindef.h WINAPI macro is defined as __stdcall
					;		 only WINAPIV is defined as __cdecl !!!!
						;TODO: [Possible Bug]: strlen most likely uses the rep style assembly opcodes, as a result, because rep utilizes ecx, and the nature of this function is iterative, that could VERY WELL be why ecx is trampled!!!!!
						;It also seems to trample edx!!!!!
					;	push ecx
					;		;invoke strlen,dword ptr Path
					;		invoke strlen,[Path]
					;	pop ecx

					;	;Rebalance the stack from a cdecl function call
					;		add esp, 4

					;	mov ecx, eax

 		push ebx

		;ebx is the running character count of path + filename as each character of both are parsed.
		;When complete, ebx should contain the length of path + filename.
			xor ebx, ebx

						;push '\'
						push EscapeCharacter
						push dword ptr Path_Escaped
						push dword ptr Path
					call Util_Str_Escaped
					;mov [Path_Escaped], eax

						push dword ptr Path_Escaped
					call Util_Get_StrLen
					mov [Path_Escaped_Length], eax
						
						push dword ptr Filename
					call Util_Get_StrLen
					mov [Filename_Length], eax
					
					
					

					push ecx
					jmp DebugPoint1
						DebugPoint1:
						;Preserve the length of the escaped path
							push eax
								invoke HeapAlloc, [ProcessHeap], HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY, eax		;Problematic call; OllyDbg traces to here for an Access Violation!!!! 
								mov [New_FileOpen_Slot.lpFilePath], eax
	
						;Restore the length of the escaped path		
							pop eax
					pop ecx


					;Preserve the length of the escaped path + filename length
						push eax

					;Preserve value of esi (whatever it may be)
						push esi
					;Preserve value of edi (whatever it may be)
						push edi

						;Store a copy of the Filename in the New_FileOpen_Slot.lpFilename member
							mov esi, [Path]


							;push ecx
								mov ecx, New_FileOpen_Slot.lpFilePath
								mov edi, [ecx]		;lpFilePath is the first member in
													;New_FileOpen_Slot (FileInfo_Struct)
													;so in the disassembler it will look like
													;JUST MOV EDI, New_FileOpen_Slot
	
								OpenFile_Split_StoreFilePath:
									lodsb
									cmp al, 0
									je OpenFile_Split_StoreFilePath_Done
									stosb
									jmp OpenFile_Split_StoreFilePath
			
								OpenFile_Split_StoreFilePath_Done:
									mov [edi], byte 0
									;mov [edi], byte 63
							;pop ecx

					;Restore value of edi (whatever it may be)
						pop edi
					;Restore value of esi (whatever it may be)
						pop esi

					;Restore the length of the escaped path + filename length
						pop eax


					push ecx
							push [Filename]
						call Util_Get_StrLen
						mov ecx, eax
						push eax
							push ecx
								invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY, ecx
								mov [New_FileOpen_Slot.lpFilename], eax
							pop ecx
						pop eax
					pop ecx

					;Preserve value of eax (whatever it may be)
						push eax
					;Preserve value of esi (whatever it may be)
						push esi
					;Preserve value of edi (whatever it may be)
						push edi

						;Store a copy of the Filename in the New_FileOpen_Slot.lpFilename member
							mov esi, [Filename]
							push ecx
								;mov edi, [New_FileOpen_Slot.lpFilename]
								;mov ecx, [New_FileOpen_Slot.lpFilename]
								mov ecx, New_FileOpen_Slot.lpFilename
								mov edi, [ecx]
								OpenFile_Split_StoreFilename:
									lodsb
									cmp al, 0
									je OpenFile_Split_StoreFilename_Done
									stosb
									jmp OpenFile_Split_StoreFilename

								OpenFile_Split_StoreFilename_Done:
									mov [edi], byte 0
							pop ecx

					pop edi
					pop esi
					pop eax

			;Allocate memory for the amount of characters that Path and Filename take up
			;and store that address (returned back from HeapAlloc) in the PathAndFile_Temp
			;variable. NOTE: This is only a temporary variable used to hold both the
			;path and filename so that the more long-term permanent storage in the
			;FileManager array can be created a little later.
				push ecx
					;mov ecx, [Path_Escaped_Length]	;Path_Escaped_Length	- SS:[LOCAL.3]
					add ecx, [Filename_Length]		;Filename_Length 		- SS:[LOCAL.4]
						push ecx
					invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ecx
					mov [PathAndFile_Temp], eax		;PathAndFile_Temp 		- SS:[LOCAL.5]
				pop ecx		;Restore the ecx register after having been trampled by HeapAlloc

			;Concat the Path and Filename together in PathAndFile_Temp
				;First, copy the Path value and store it into the value at the memory
				;address that PathAndFile_Temp variable points to.
						push ecx	;lstrcat likely tramples the ecx, so preserve that register
						;Path					- SS:[ARG.1]
						;Filename 				- SS:[ARG.2]
						;Path_Escaped			- SS:[LOCAL.2]
						;Path_Escaped_Length	- SS:[LOCAL.3]
						;PathAndFile_Temp		- SS:[LOCAL.5]
							;invoke lstrcat, dword ptr PathAndFile_Temp, dword ptr Path
					invoke lstrcat, dword ptr PathAndFile_Temp, dword ptr Path_Escaped
							;add esp, 4	;Rebalance the stack after a cdecl function call
						pop ecx		;Restore the ecx register after having been trampled by lstrcat

				;Next, copy the Filename value onto the end of the value at the memory
				;address that PathAndFile_Temp variable points to.
							;invoke lstrcat, dword ptr PathAndFile_Temp, dword ptr Filename
							add edx, [Path_Escaped_Length]
							push edx
								;mov edx, dword ptr PathAndFile_Temp
								;add edx, [Path_Escaped_Length]
								
								;mov edx, dword ptr PathAndFile_Temp
								;lea edx, [edx+Path_Escaped_Length]
								
								;mov edx, dword ptr PathAndFile_Temp
								
						invoke lstrcat, dword ptr PathAndFile_Temp, dword ptr Filename
							pop edx
							;add esp, 4	;Rebalance the stack after a cdecl function call
					;pop ecx


					;pop edx



;Problem line, returns an ERROR_INVALID_PARAMETER resulting in an Access Violation!!!!
				;Now store BOTH the path AND filename TOGETHER in New_FileOpen_Slot.lpFile_PathAndName
					;push ecx
					;	mov ecx, edx
					;	invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ecx
					;	mov [New_FileOpen_Slot.lpFile_PathAndName], eax
					;pop ecx
					
						push ProcessHeap
						push edx
						push New_FileOpen_Slot.lpFile_PathAndName
					call Allocate_Memory
 
 
					;Preserve value of eax (whatever it may be)
						push eax
					;Preserve value of esi (whatever it may be)
						push esi
					;Preserve value of edi (whatever it may be)
						push edi
					
					;Store a copy of the Filename in the New_FileOpen_Slot.lpFilename member
						mov esi, [PathAndFile_Temp]
						mov edi, [New_FileOpen_Slot.lpFile_PathAndName]
						OpenFile_Split_StoreFileAndPath:
							lodsb
							cmp al, 0
							je OpenFile_Split_StoreFileAndPath_Done
							stosb
							jmp OpenFile_Split_StoreFileAndPath
	
						OpenFile_Split_StoreFileAndPath_Done:
							mov [edi], byte 0

					;Restore value of edi (whatever it may be)
						pop edi
					;Restore value of esi (whatever it may be)
						pop esi
					;Restore value of eax (whatever it may be)
						pop eax


				;Create the FileOpen_Slot so that pointers to memory addresses can be filled in.
					;This call here succeeds: 11/21/2016 12:04 PM EST
						;Create a new slot at the end of the FileManager_Struct (lpFileManager) . dd (FilesOpened) array
							call FileManager_Create_FileOpen_Slot

						;eax points to the next [lpFileManager.FilesOpened] element and FilesOpened is an
						;array of FileInfo_Struct -- line: 779
							mov edx, eax

				;Preserve EDX register
					push edx
	
					;If successful, add an entry to the name table
							push lpFileManager.lpUniqueNameTable
							push TRUE
						call FileManager_Create_Add_UniqueNameTableSlot
	
						;Store the requisite elements in the name table
							;...
							;push [New_FileOpen_Slot.lpFile_PathAndName]
							;push FILE_ALL_ACCESS
							;push FILE_SHARE_WRITE
							;push NULL
							
							;TODO: Add in ability to specify the file's open disposition (create always, create_new, truncate_existing, etc.) -- for now, just go with TRUNCATE_EXISTING
							;	push TRUNCATE_EXISTING
							
							;TODO: Add in ability to specify the file's attributes -- for now, just go with whatever they currently are (if the file exists), or default (if it doesn't existr).
							;	push FILE_ATTRIBUTE_NORMAL
							
							;push NULL
							;call CreateFile

							;invoke CreateFile, [New_FileOpen_Slot.lpFile_PathAndName], FILE_ALL_ACCESS, FILE_SHARE_WRITE, NULL, TRUNCATE_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
							;invoke CreateFile, [New_FileOpen_Slot.lpFile_PathAndName], STANDARD_RIGHTS_REQUIRED OR SYNCHRONIZE OR 1FFh, FILE_SHARE_WRITE, NULL, TRUNCATE_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
							invoke CreateFile, [New_FileOpen_Slot.lpFile_PathAndName], GENERIC_WRITE, FILE_SHARE_WRITE, NULL, TRUNCATE_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL

							;From: https://msdn.microsoft.com/en-us/library/aa363858(VS.85).aspx
								;Return value
								;	If the function succeeds, the return value is an open handle to the specified file, device, named pipe, or mail slot.
								;	If the function fails, the return value is INVALID_HANDLE_VALUE. To get extended error information, call GetLastError.
							;Other resources used as reference:
							;	https://board.flatassembler.net/topic.php?t=11801
							;	https://msdn.microsoft.com/en-us/library/gg258116(v=vs.85).aspx
							;	https://msdn.microsoft.com/en-us/library/aa379560(v=vs.85).aspx
							
							cmp eax, INVALID_HANDLE_VALUE
							jne FileManager_OpenFile_SUCCESS
							call ShowLastError
							
							;TODO: There was an error trying to open the file, so unallocate slot created!!!!
							
							jmp OpenFile_Exit

							FileManager_OpenFile_SUCCESS:
								mov [New_FileOpen_Slot.FileHandle], eax
	
	
					;Only copy over all of the elements from New_FileOpen_Slot to the new lpFileManager.FilesOpened (?) slot if there are elements
					;to copy over!!!!
						cmp [lpFileManager.OpenFileCount], 1

						jl OpenFile_Split_SkipCopy
						;jl OpenFile_Split_Copy_New_FileOpen_Slot

						;OpenFile_Split_Copy_New_FileOpen_Slot:
							push edx
								push ecx

									;Calculate the offset into FileManager_Struct (lpFileManager) . FileManager_NameIndex (lpUniqueNameTable)
										;mov ecx, [lpFileManager.OpenFileCount]
										xor ecx, ecx
										mov cl, [lpFileManager.OpenFileCount]
										;mov edx, sizeof.FileManager_NameIndex
										mov edx, sizeof.FileInfo_Struct

										;edx, after the next line, will now contain the number of bytes offset from the start of the address of where
										;lpFileManager.lpUniqueNameTable is pointed at
											imul edx, ecx

													;mov ecx, [lpFileManager.lpUniqueNameTable]
													mov ecx, [lpFileManager.FilesOpened]

												;ecx, after the next line, should now point to the proper location offset from the address of the start of
												;where lpFileManager.lpUniqueNameTable is pointed at
													add ecx, edx

									OpenFile_Split_Copy_New_FileOpen_Slot:
										;New_FileOpen_Slot = FileInfo_Struct
										;As of 04/13/2017 1:23PM:
										;members of FileInfo_Struct (for quick reference)
											;lpFilePath			dd				?
											;lpFilename			dd				?
											;lpFile_PathAndName	dd				?
											;FileHandle			dd				?
											;lpReOpenBuff		OFSTRUCT_struct	?
											;uStyle				dw				?
										mov edx, [New_FileOpen_Slot.lpFilePath]
											mov esi, edx
										mov edi,ecx

										FileManager_OpenFile_NFO_FP_to_FileManager:
											lodsb
											cmp al, 0
											je FileManager_OpenFile_NFO_Fn_to_FileManager_Pre
											stosb
											jmp FileManager_OpenFile_NFO_FP_to_FileManager




										FileManager_OpenFile_NFO_Fn_to_FileManager_Pre:
											mov edx, [New_FileOpen_Slot.lpFilename]										
												mov esi, edx

											FileManager_OpenFile_NFO_Fn_to_FileManager:
												lodsb
												cmp al, 0
												je FileManager_OpenFile_NFO_F_PaN_to_FileManager_Pre
												stosb
												jmp FileManager_OpenFile_NFO_Fn_to_FileManager




										FileManager_OpenFile_NFO_F_PaN_to_FileManager_Pre:
											mov edx, [New_FileOpen_Slot.lpFile_PathAndName]
												mov esi, edx

											FileManager_OpenFile_NFO_F_PaN_to_FileManager:
												lodsb
												cmp al, 0
												je FileManager_OpenFile_NFO_FH_to_FileManager_Pre
												stosb
												jmp FileManager_OpenFile_NFO_F_PaN_to_FileManager



										FileManager_OpenFile_NFO_FH_to_FileManager_Pre:
											;mov edx, [New_FileOpen_Slot.FileHandle]
												;mov esi, edx
											mov esi, New_FileOpen_Slot.FileHandle

											FileManager_OpenFile_NFO_FH_to_FileManager:
												lodsb													; <---- Problem line. Causes access violation!
												cmp al, 0
												je FileManager_OpenFile_NFO_ROB_to_FileManager_Pre
												stosb
												jmp FileManager_OpenFile_NFO_FH_to_FileManager



										FileManager_OpenFile_NFO_ROB_to_FileManager_Pre:
										;	mov edx, [New_FileOpen_Slot.FileHandle]
										;		mov esi, edx

										;	FileManager_OpenFile_NFO_ROB_to_FileManager:
										;		lodsb
										;		cmp al, 0
										;		je FileManager_OpenFile_NFO_US_to_FileManager_Pre
										;		stosb
										;		jmp FileManager_OpenFile_NFO_ROB_to_FileManager


										;FileManager_OpenFile_NFO_US_to_FileManager_Pre:
										;	mov edx, [New_FileOpen_Slot.FileHandle]
										;		mov esi, edx

										;	FileManager_OpenFile_NFO_US_to_FileManager:
										;		lodsb
										;		cmp al, 0
										;		je FileManager_OpenFile_NFO_to_FileManager_Done
										;		stosb
										;		jmp FileManager_OpenFile_NFO_US_to_FileManager

						FileManager_OpenFile_NFO_to_FileManager_Done:
								pop ecx
							pop edx
							jmp OpenFile_Exit

						;Copy over all of the elements from New_FileOpen_Slot to the new slot
						;	push ecx
						;	push ebx
						;	push edx
						;	push esi
						;	push edi




				OpenFile_Split_SkipCopy:		
				;Restore EDX register
					pop edx

					;push edx
					;	mov edx, [eax]
							push edx
							push New_FileOpen_Slot
							call FileManager_Copy_FileOpen_Slot
					;pop edx

					;	pop edi
					;	pop esi
					;	pop edx
					;	pop ebx
					;	pop ecx
					
						jmp OpenFile_Exit

					;OpenFile_Split_SkipCopy:
						jmp OpenFile_Exit
						
					OpenFile_Error:

		OpenFile_FileAlreadyOpen:

	OpenFile_Exit:

ret
endp
;Split refers to the fact that filename with path is split and passed in as two parameters (One as path and one as a filename)

;end of proc FileManager_OpenFile_Split Path, Filename








FileManager_ReadFromFile_ByIndex_Label:

proc FileManager_ReadFromFile_ByIndex Index, lpBuffer, NumBytesToRead, NumBytesRead:DWORD

	push ebx
	push ecx
	push edx
		xor ebx, ebx
		xor ecx, ecx
		xor edx, edx
		
		mov ebx, lpFileManager.FilesOpened
		mov edx, [ebx]
		xor ebx, ebx
		mov edx, ebx
		xor edx, edx
		
		FileManager_ReadFile_Check1:
			cmp [Index], lpFileManager.OpenFileCount
			jg FileManager_ReadFile_Check2
			;jmp FileManager_ReadFile_No_OpenFiles_Err
			jmp FileManager_ReadFile_Index_OOB_Err
		
		FileManager_ReadFile_Check2:
			mov ecx, [Index]
			cmp [Index], 0
			;je FileManager_ReadFile_Check2_EQ_0
			je FileManager_ReadFile_ChecksPassed
			jg FileManager_ReadFile_Check2_GT_0
			jmp FileManager_ReadFile_Index_OOB_Err

		;FileManager_ReadFile_Check2_EQ_0:
		;	jmp FileManager_ReadFile_ChecksPassed

		FileManager_ReadFile_Check2_GT_0:
			cmp [Index], lpFileManager.OpenFileCount
			jge FileManager_ReadFile_Index_OOB_Err

			;mov ch, Index
			mov edx, sizeof.FileInfo_Struct
			imul ecx, edx
			add ebx, ecx
			;jmp FileManager_ReadFile_ChecksPassed

		FileManager_ReadFile_ChecksPassed:
			mov eax, ebx
			add eax, 12	;3 DWORD (2 bytes) pointers into structure to point at FileHandle
			invoke ReadFile, dword ptr eax, dword ptr lpBuffer, [NumBytesToRead], [NumBytesRead], NULL
			jmp FileManager_ReadFile_Done
			
		FileManager_ReadFile_Index_OOB_Err:

	FileManager_ReadFile_Done:
	pop edx
	pop ecx

;return
ret
endp


FileManager_WriteToFile_ByIndex_Label:

proc FileManager_WriteToFile_ByIndex Index, String:DWORD

;return
ret
endp
;end of proc FileManager_WriteToFile_ByIndex Index, String:DWORD


FileManager_WriteToFile_ByHandleNum_Label:

proc FileManager_WriteToFile_ByHandleNum HandleNumber, String:DWORD

;return
ret
endp
;end of proc FileManager_WriteToFile_ByHandleNum HandleNumber, String:DWORD


;Write to file by name has not been implemented simply because it's somewhat dangerous to as a file can be stored in multiple
;locations and the same name could be used. This could be implemented if a unique file ID string/name is implemented...