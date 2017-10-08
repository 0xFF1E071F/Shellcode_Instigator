include 'FileManager_Util_Library.inc'

include 'Util_Library.inc'

include 'FileManager_Structs.inc'


FileManager_Initialize_Label:

proc FileManager_Initialize

	push ecx
		xor ecx, ecx

		push ebx
		push edx 

			mov cl, [lpFileManager.OpenFileCount]
			;add ecx, 1
			add cl, 1
			mov edx, sizeof.FileInfo_Struct
			imul ecx, edx
			;Add one extra byte for FilesOpened_ElementsInUse
			;add ecx, 1
			add cl, 1

		pop edx
		pop ebx

		invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ecx
		mov [lpFileManager.FilesOpened], eax
	pop ecx

	;Initialize FilesOpened_ElementsInUse
		push ecx

			lea ecx, [lpFileManager]

			;Position ecx to be pointing at FilesOpened_ElementsInUse
				add ecx, 4

				mov [ecx], byte 0
		pop ecx
;return
ret
endp














FileManager_Is_Index_Valid_Label:

;Functions taking indexes are designed as 
proc FileManager_Is_Index_Valid

;return
ret
endp


FileManager_Get_FileOpen_NextFreeIndex_Label:

proc FileManager_Get_FileOpen_NextFreeIndex

	push ecx
		xor ecx, ecx
		cmp [lpFileManager.OpenFileCount], 0
		jle Get_FileOpen_NoElements
		push esi
			mov esi, lpFileManager.lpFilesOpened_ElementsInUse
				Check_IndexInUse:
					lodsb
					cmp al, 0x31
					je Continue_Check_IndexInUse
					cmp al, 0x30
					je Found_Free_Index
					;jne						;else case...
		
					Continue_Check_IndexInUse:
						add ecx, 1
						;cmp ecx, [FileManager.OpenFileCount]
						cmp cl, [lpFileManager.OpenFileCount]
						jge Get_FileOpen_ElementList_Exhausted
						add esi, 1
						jmp Check_IndexInUse
		
					Found_Free_Index:
						sub ecx, 1
						mov eax, ecx
		pop esi
						jmp Get_FileOpen_NextFreeIndex_Exit
		
			Get_FileOpen_ElementList_Exhausted:
				;mov eax, -1
				mov eax, ERROR_GET_FILEOPEN_INDEX_INDEX_NOT_FOUND
		pop esi
				jmp Get_FileOpen_NextFreeIndex_Exit
		
			Get_FileOpen_NoElements:
				;mov eax, -2
				mov eax, ERROR_GET_FILEOPEN_INDEX_NO_ELEMENTS_ALLOCATED

	Get_FileOpen_NextFreeIndex_Exit:
		pop ecx
	
;return
ret
endp





FileManager_Create_FileOpen_Slot_Label:

;This should creates the (first-tier) slot in FileManager, it does NOT allocate memory of a FileInfo_Struct's members since those
;are pointers to memory whose size is currently not known and thus unable to be HeapAlloc'ed
proc FileManager_Create_FileOpen_Slot
;local TempArray[FileManager_Struct.OpenFileCount]:FileInfo_Struct
;local TempArray[FileManager_Struct.OpenFileCount]:FileInfo_Struct
local Temp_ElemInUseArray:DWORD

local TempArray:FileInfo_Struct
;local Temp_FilesOpened_ElementsInUse:DWORD
local Create_Slot_RetObj:FileManager_New_FileOpen_Obj

	;First see if there is an index that is already created but marked as free
		;invoke Get_FileOpen_NextFreeIndex
		call FileManager_Get_FileOpen_NextFreeIndex
		;return values
		;>= 0 the next available index
		;  -1 element list exhausted looking for a free open slot 	(ERROR_GET_FILEOPEN_INDEX_INDEX_NOT_FOUND)
		;  -2 No elements created.									(ERROR_GET_FILEOPEN_INDEX_NO_ELEMENTS_ALLOCATED)
			cmp eax, 0
			jge Create_FileOpen_FreeIndexExists
			;cmp eax, -1
			;cmp eax, -2

	push ecx
	push edx

		xor ecx, ecx
		xor edx, edx

		;mov ecx, lpFileManager.OpenFileCount
		;mov edx, Initial_FilesOpened_ArraySize
		;mov cl, [lpFileManager.OpenFileCount]
		;mov dl, [Initial_FilesOpened_ArraySize]
			;cmp [ecx], edx
			;cmp byte [ecx], edx
			;cmp [lpFileManager.OpenFileCount], byte edx
			;cmp [lpFileManager.OpenFileCount], [Initial_FilesOpened_ArraySize]
			;cmp ecx, edx
			;This works...
		;		cmp cl, dl
		;			jge Resize_FilesOpenedArray		;If the array needs to be sized +1 then no sense in incrementing by 1
													;if the function is not ready to return +1 yet.

				;add [ecx], byte 1
				;add [ecx], 1					;Because there are initial slots available, just increment by 1 and
												;return that index.


	Create_FileOpen_Resize_Prime:
		cmp [lpFileManager.OpenFileCount], 0
		jle Create_FileOpen_ResizeOnly
		jmp Resize_FilesOpenedArray

	Create_FileOpen_ResizeOnly:
		push ecx

			;Just allocate the array. Since there's no elements being used, there's no need for a temporary array!
			;Calculate the needed size of bytes for lpFileManager.FilesOpened
				xor ecx, ecx
				push ebx
				push edx
						;mov ecx, lpFileManager.OpenFileCount
						;Since it has already been determined that there are no allocated array elements, there's
						;no point in moving the variable into the cl register and incrementing it. 
							mov cl, [lpFileManager.OpenFileCount]
							add cl, 1
						mov edx, sizeof.FileInfo_Struct
						imul ecx, edx
				pop edx
				pop ebx				 

				invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ecx
				mov [lpFileManager.FilesOpened], eax

				;Increment lpFilesOpened_ElementsInUse
					;lpFilesOpened_ElementsInUse needs to be realloc'ed since it is a bit-mask of what elements are in use and
					;thus, as more slots are created, the mask needs to be increased to accomodate another slot representation.
						add [lpFileManager.OpenFileCount], 1
						invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,dword ptr lpFileManager.OpenFileCount
							;mov dword ptr lpFileManager.FilesOpened_ElementsInUse, eax
;[00401226]:
							mov [lpFileManager.lpFilesOpened_ElementsInUse], eax
							;push ebx
							;	mov ebx, [lpFileManager.lpFilesOpened_ElementsInUse]
							;	mov [ebx], eax
							;pop ebx

				;Doesn't work. It only replaces the 4-byte value of the variable, not the value pointed to
				;by the 4-bytes value as an address!									
					;mov dword ptr lpFileManager.FilesOpened_ElementsInUse, 0
				;Store a 0 (0x30) at the memory address pointed to by lpFilesOpened_ElementsInUse's 4-byte value
					push edx
						xor edx, edx
						mov edx, [lpFileManager.lpFilesOpened_ElementsInUse]
						mov [edx], byte 0x30
					pop edx

				mov eax, [lpFileManager.FilesOpened]

		pop ecx
		jmp Create_FileOpen_Exit



	;Elements ARE already being used, so a Temporary array needs to be created first!
	Resize_FilesOpenedArray:	
		push ecx
			xor ecx, ecx

			;First create a temporary storage container for all the existing elements
				push ebx
				push edx
					mov cl, [lpFileManager.OpenFileCount]
					;add ecx, 1
					mov edx, sizeof.FileInfo_Struct
					imul ecx, edx
				pop edx
				pop ebx				 

			;This causes an Access violation (ERROR_INVALIDPARAMETER?) crash!!!!
				invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ecx
				mov [TempArray], eax



				push esi
				push edi

					mov esi, [lpFileManager.FilesOpened]
					mov edi, [TempArray]

					push ebx
					xor ebx, ebx

					;Pushes not for preservation, but because a call is about to be made!
						push edi
						push esi
						Copy_FilesOpened_To_Temp_Continue:
							call FileManager_Copy_FileOpen_Slot
							add bl, 1
							push edx
								xor edx, edx
								mov dl, [lpFileManager.OpenFileCount]
								sub dl, 1
							;cmp bl, [lpFileManager.OpenFileCount]
								cmp bl, dl
							pop edx
							jge Copy_FileOpened_To_Temp_Done
							;If you notice, we don't do anything with esi, edi! We want them to continue being offset
							;every call to FileManager_Copy_FileOpen_Slot!!!!
							jmp Copy_FilesOpened_To_Temp_Continue

						Copy_FileOpened_To_Temp_Done:
					pop ebx

				pop esi
				pop edi


			;ElementsInUse field also has to be expanded, not just the files opened!
				;Increment lpFilesOpened_ElementsInUse
				;Allocate the bit-mask array for FilesOpened_ElementsInUse by using how many files are opened (OpenFileCount)
					;lpFilesOpened_ElementsInUse needs to be realloc'ed since it is a bit-mask of what elements are in use and
					;thus, as more slots are created, the mask needs to be increased to accomodate another slot representation.
					;push ebx
						add [lpFileManager.OpenFileCount], 1	;Since OpenFileCount is an array of Bytes, the number of Files opened is the number of bytes to request for allocation
						invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,lpFileManager.OpenFileCount
						mov [Temp_ElemInUseArray], eax

				;Initialize the FilesOpened_ElementsInUse array
					mov esi, lpFileManager.lpFilesOpened_ElementsInUse
					;;mov edi, Temp_FilesOpened_ElementsInUse
					;lea edi, [TempArray + 4]
					mov edi, [Temp_ElemInUseArray]
					Copy_EIU_Mask_ToTemp:
						lodsb
						cmp al, 0			;In use: '1' (0x31), Not In-Use: '0' (0x30), End of array: 0 (0x00)
						je Copy_EIU_Mask_ToTemp_Finished
						stosb
						jmp Copy_EIU_Mask_ToTemp
					Copy_EIU_Mask_ToTemp_Finished:
					
				;Faulty! TempArray + 4 has NOT been allocated! You cannot just add 4 (offset the memory ahead by 4 bytes) and
				;just start using it and not expect adverse behavior!
					;push ebx
					;	;mov ebx, dword ptr TempArray.FilesOpened_ElementsInUse
					;	push edx
					;		;mov edx, TempArray
					;		;add edx, 4
					;		;mov ebx, dword ptr edx
					;		lea edx, [TempArray]
					;		add edx, 4
					;	;mov [ebx], eax
					;	mov [edx], eax
					;	pop edx
					;pop ebx

				;mov [Temp_FilesOpened_ElementsInUse], eax



		;Debugger crases here
			pop ecx



		Create_FileOpen_StoreToTemp_Prime:


		;TODO:If no elements have been created, there's nothing to copy over!!!!
		Create_FileOpen_StoreToTemp:

		Create_FileOpen_CopyBackOver:

		;Free original members
			push ecx
				;Next, free the original lpFilesOpened_ElementsInUse
					xor ecx, ecx
					;This may require trampling all the values of the members and submembers' zero-terminator so that
					;when HeapFree is scanning/freeing it doesn't prematurely stop!
					;TODO: [POTENTIAL_BUG]: This may not be a "deep"-free!
						invoke HeapFree,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,lpFileManager.lpFilesOpened_ElementsInUse
			pop ecx
			
			push ecx
				;Next, free the original storage container
					xor ecx, ecx
					;mov ecx, [FileManager.OpenFileCount * sizeof.FileInfo_Struct]
					mov cl, [lpFileManager.OpenFileCount]
					imul ecx, sizeof.FileInfo_Struct
					;This may require trampling all the values of the members and submembers' zero-terminator so that
					;when HeapFree is scanning/freeing it doesn't prematurely stop!
					;TODO: [POTENTIAL_BUG]: This may not be a "deep"-free! But that's ok because we're just going to re-use the already allocated existing memory???
						invoke HeapFree,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,lpFileManager.FilesOpened
			pop ecx


		;Allocate memory
			push ecx
	
				;Finally create the new lpFilesOpened_ElementsInUse for all the existing elements
					xor ecx, ecx
					;mov ecx, [(FileManager.OpenFileCount + 1) * sizeof.FileInfo_Struct]
					mov cl, [lpFileManager.OpenFileCount]
					add cl, 1	;+1 element now
					imul ecx, sizeof.FileInfo_Struct
		
					invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ecx
					mov [lpFileManager.lpFilesOpened_ElementsInUse], eax
	
			pop ecx

			push ecx
	
				;Finally create the new storage container for all the existing elements
					xor ecx, ecx
					;mov ecx, [(FileManager.OpenFileCount + 1) * sizeof.FileInfo_Struct]
					mov cl, [lpFileManager.OpenFileCount]
					;Already added 1 in the above allocation block.
						;add ch, 1	;+1 element now
					imul ecx, sizeof.FileInfo_Struct

					;This just allocates enough storage for the memory pointers of each of
					;lpFilesOpened members, it doesn't actually allocate memory
					;those pointers point to.
						invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ecx
						mov [lpFileManager.FilesOpened], eax
	
			pop ecx

		;Iterate over all of the existing elements in Temp_ElemInUseArray, copying them over as the iteration occurs.
			push ebx
				push esi
				push edi

					mov esi, [Temp_ElemInUseArray]
					mov edi, [lpFileManager.lpFilesOpened_ElementsInUse]

					Create_FileOpen_Copy_ElementInUse_Continue:
						lodsb
						cmp al, 0
						je Create_FileOpen_Copy_ElementInUse_Done
						stosb
						jmp Create_FileOpen_Copy_ElementInUse_Continue
					Create_FileOpen_Copy_ElementInUse_Done:
				pop edi
				pop esi
			pop ebx

		;Iterate over all of the existing storage-container's elements, copying them over as the iteration occurs.
			push ebx
				Create_FileOpen_CopyElementFromTempArray:
					push esi
					push edi

						mov esi, [TempArray]
						mov edi, [lpFileManager.FilesOpened]
	
						push ebx
						xor ebx, ebx
	
						;Pushes not for preservation, but because a call is about to be made!
							push edi
							push esi
							Copy_FilesOpened_From_Temp_Continue:
								call FileManager_Copy_FileOpen_Slot
								add bl, 1
								push edx
									xor edx, edx
									;mov dl, [TempArray.OpenFileCount]
									mov dl, [lpFileManager.OpenFileCount]
									sub dl, 1
								;cmp bl, [lpFileManager.OpenFileCount]
									cmp bl, dl
								pop edx
								jge Copy_FileOpened_From_Temp_Done
								;If you notice, we don't do anything with esi, edi! We want them to continue being offset
								;every call to FileManager_Copy_FileOpen_Slot!!!!
								jmp Copy_FilesOpened_From_Temp_Continue
	
							Copy_FileOpened_From_Temp_Done:
						pop ebx

					pop esi
					pop edi
			pop ebx



		push ecx
			;Next, free the temporary storage container
				xor ecx, ecx
				;mov ecx, [FileManager.OpenFileCount * sizeof.FileInfo_Struct]
				;This may require trampling all the values of the members and submembers' zero-terminator so that
				;when HeapFree is scanning/freeing it doesn't prematurely stop!
					invoke HeapFree,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,dword ptr TempArray
		pop ecx

	Create_FileOpen_Exit:
		pop edx
		pop ecx

	Create_FileOpen_FreeIndexExists:

;return
ret
endp
;This should creates the (first-tier) slot in FileManager, it does NOT allocate memory of a FileInfo_Struct's members since those
;are pointers to memory whose size is currently not known and thus unable to be HeapAlloc'ed

;end of proc FileManager_Create_FileOpen_Slot









FileManager_CloseFile_ByIndex_Label:

proc FileManager_CloseFile_ByIndex uses ecx esi edi, Index:DWORD

	;First, get the amount of memory needed to be allocated.
		xor ecx, ecx
			push ebx
			push edx
				;mov ecx, lpFileManager.OpenFileCount
				mov cl, [lpFileManager.OpenFileCount]
				sub cl, 1
				mov edx, sizeof.FileInfo_Struct
				imul ecx, edx
			pop edx
			pop ebx				 

	;Next, allocate the new array of FilesOpened with 1 less element
		invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ecx
		;mov [lpFileManager.FilesOpened], eax
		;Line is deliberately messed up so as not to forget to fix this!
			mov ,eax

	push edx
	push ebx

		;Store the allocated memory in edx temporarily so that lpFileManager.FilesOpened can be cleared/free'ed out.
			mov edx, eax

		push edx

			mov ebx, [lpFileManager.FilesOpened]
			push ebx

				;Copy over the elements, skipping the element being closed, to temporary storage.
					push ecx
						mov ecx, 0

							Copy_FilesOpened_Continue:
								cmp ecx, [Index]
								je Copy_FilesOpened_Skip

								cmp ecx, [lpFileManager.OpenFileCount]
								jge Copy_FilesOpened_Done
								jmp Copy_FilesOpened_Copy

								Copy_FilesOpened_Skip:
									add ecx, 1
									add ebx, sizeof.FileInfo_Struct
									jmp Copy_FilesOpened_Continue

								Copy_FilesOpened_Copy:
									;push ebx
									;	mov ebx, sizeof.FileInfo_Struct
									;	imul ebx, ecx

									;Copy single slot over to the temporary storage.
										push edx
										push ebx
										call FileManager_Copy_FileOpen_Slot

									;Increment/Offset the src storage pointer one element.
										add ebx, sizeof.FileInfo_Struct		

									add ecx, 1
									jmp Copy_FilesOpened_Continue

								Copy_FilesOpened_Done:
				pop ecx

			pop ebx	;ebx now at this point equals [lpFileManager.FilesOpened]

			;Free the memory being used at lpFileManager.FilesOpened address
				;TODO: [POTENTIAL_BUG]: This may not be a "deep"-free! But that's ok because we're just going to re-use the already allocated existing memory???
					invoke HeapFree,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,[ebx]

			push eax
				mov eax, [lpFileManager.OpenFileCount]
				sub [eax], 1
			pop eax

		;Allocate the memory for lpFileManager.FilesOpened now with one less element
			xor ecx, ecx
				push ebx
				push edx
					mov cl, [lpFileManager.OpenFileCount]
					;sub cl, 1
					mov edx, sizeof.FileInfo_Struct
					imul ecx, edx
				pop edx
				pop ebx				 

				invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ecx
				mov [lpFileManager.FilesOpened], eax

		;Since the element being eliminated was skipped when the array was copied to temporary storage, the entire
		;temporary storage can just be copied back over.

			;Store the allocated memory in edx temporarily so that lpFileManager.FilesOpened can be cleared/free'ed out.
				mov ebx, eax

			push edx	;edx is the temporary storage
			push ebx

			;Copy over the elements, skipping the element being closed, to temporary storage.
				push ecx
					mov ecx, 0

					Copy_FilesOpened_Continue:
						;cmp ecx, [Index]
						;je Copy_FilesOpened_Skip

						cmp ecx, [lpFileManager.OpenFileCount]
						jge Copy_FilesOpened_Done
						;jmp Copy_FilesOpened_Copy

						;Copy_FilesOpened_Skip:
						;	add ecx, 1
						;	add ebx, sizeof.FileInfo_Struct
						;	jmp Copy_FilesOpened_Continue

						;Copy_FilesOpened_Copy:
							;push ebx
							;	mov ebx, sizeof.FileInfo_Struct
							;	imul ebx, ecx

							;Copy single slot over to the temporary storage.
								push ebx
								push edx
								call FileManager_Copy_FileOpen_Slot

							;Increment/Offset the src storage pointer one element.
								add edx, sizeof.FileInfo_Struct
								add ebx, sizeof.FileInfo_Struct		

							jmp Copy_FilesOpened_Continue

						Copy_FilesOpened_Done:
				pop ecx

			pop ebx
			pop edx


		pop edx

		;Free the temporary storage
			;TODO: [POTENTIAL_BUG]: This may not be a "deep"-free! But that's ok because we're just going to re-use the already allocated existing memory???
				invoke HeapFree,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,[edx]

		;Next, allocate temporary storage for all the entries in lpUniqueNameTable with 1 element less
			push eax
				mov eax, [lpFileManager.OpenFileCount]
				;sub [eax], 1
			pop eax

			;Allocate the memory for lpFileManager.FilesOpened now with one less element
				xor ecx, ecx
					push ebx
					push edx
						mov cl, [lpFileManager.OpenFileCount]
						;sub cl, 1
						mov edx, sizeof.FileManager_NameIndex
						imul ecx, edx
					pop edx
					pop ebx				 

					invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ecx
					;mov [lpFileManager.FilesOpened], eax
					;Line is deliberately messed up so as not to forget to fix this!
					;	mov , eax
			push eax

				mov esi, lpFileManager.lpUniqueNameTable
				mov edi, [eax]

			push ecx

				;Now, copy over all the original elements, skipping the index needed, over to temporary storage
					FileManager_CloseFile_Copy_NameTable_ToTemp_Continue:
						cmp ecx, [Index]
						je FileManager_CloseFile_Copy_NameTable_ToTemp_Skip

						push edx, [lpFileManager.OpenFileCount]
							;sub edx, 1	;lpFileManager.OpenFileCount should already be decremented from previously in this routine
							cmp edx, ecx
						pop edx
						jge  FileManager_CloseFile_Copy_NameTable_ToTemp_Done



					FileManager_CloseFile_Copy_NameTable_ToTemp_Skip:
						add ecx, 1
						add eax, sizeof.FileManager_NameIndex

						;TODO: This should free the element's contents!
							;...

						jmp FileManager_CloseFile_Copy_NameTable_ToTemp_Continue



					FileManager_CloseFile_Copy_NameTable_ToTemp_Copy:
						push eax

							lodsd
							stosd

							lodsd
							stosd

							lodsd
							stosd

							lodsd
							stosd

						pop eax
						jmp FileManager_CloseFile_Copy_NameTable_ToTemp_Continue



					FileManager_CloseFile_Copy_NameTable_ToTemp_Done:

		;Next, allocate the new lpFileManager.lpUnqieuNameTable
			;...


				mov esi, lpFileManager.lpUniqueNameTable
				mov edi, [eax]
				
				mov ecx, 0
		;Since the element being eliminated was skipped when the array was copied to temporary storage, the entire
		;temporary storage can just be copied back over.
			FileManager_CloseFile_Copy_NameTable_FromTemp_Continue:
				cmp ecx, [Index]


			FileManager_CloseFile_Copy_NameTable_ToTemp_Copy:


			FileManager_CloseFile_Copy_NameTable_ToTemp_Done:


		;Next, re-adjust all the indices in lpFileManager so that the NameTable entries match.
			push ecx
				mov ecx, [Index]
				cmp ecx, [lpFileManager.OpenFileCount)
				jg FileManager_CloseFile_Done

				mov ecx, 0

				push ebx
					mov ebx, [lpFileManager.lpUniqueNameTable]

				FileManager_CloseFile_Adjust_NameTable_Continue:
					cmp ecx, [Index]
					;Line deliberately is messed up so as not to forget to fix it!
						jge FileManager

		;Finally, free the temporary storage.

	FileManager_CloseFile_Done:
		pop ebx
		pop edx

;return
ret
endp






FileManager_Fill_New_FileOpen_Slot_Label:
proc __FileManager_Fill_New_FileOpen_Slot uses esi edi,Slot:DWORD

ret
endp

;proc __

 
FileManager_Copy_NameTable_Slot_Label:

;start of proc FileManager_Copy_NameTable_Slot uses esi edi Src, Dest:DWORD
proc FileManager_Copy_NameTable_Slot uses esi edi, Src, Dest:DWORD

	mov esi, [Src]
	mov edi, [Dest]

	;Direct struct FileManager_NameIndex members
		;Because lpPath is a pointer, only 4 bytes need to be copied since it's a memory address
			lodsd
			stosd

		;Because lpFile is a pointer, only 4 bytes need to be copied since it's a memory address
			lodsd
			stosd

		;Because lpIndex is a pointer, only 4 bytes need to be copied since it's a memory address
			lodsd
			stosd

		;Because lpUniqueName is a pointer, only 4 bytes need to be copied since it's a memory address
			lodsd
			stosd

ret
endp
;end of proc FileManager_Copy_NameTable_Slot uses esi edi Src, Dest:DWORD



FileManager_Copy_FileOpen_Slot_Label:

;start of proc FileManager_Copy_FileOpen_Slot uses esi edi ecx, Src, Dest:DWORD
proc FileManager_Copy_FileOpen_Slot uses esi edi ecx, Src, Dest:DWORD

	;mov ecx, New_FileOpen_Slot
	;mov ebx, ecx

		;push edx

				;mov esi, ebx
				;mov edi, edx

	mov esi, [Src]
	mov edi, [Dest]
	
			;Direct struct FileInfo_Struct members
				;Because lpFilePath is a pointer, only 4 bytes need to be copied since it's a memory address
					lodsd
					stosd

				;Because lpFileName is a pointer, only 4 bytes need to be copied since it's a memory address
					lodsd
					stosd

				;Because lpFile_PathAndName is a pointer, only 4 bytes need to be copied since it's a memory address
					lodsd
					stosd

				;Because FileHandle is a pointer, only 4 bytes need to be copied since it's a memory address
					lodsd
					stosd

				;Because lpReOpenBuff is a pointer, only 4 bytes need to be copied since it's a memory address
				;	lodsd
				;	stosd
				
				;lpReOpenBuff is of OFSTRUCT_struct type which contains various element sizes.... This
				;member is not a simple memory address copy. Each memember must be copied over
					;OFSTRUCT_struct.cBytes is a byte
						lodsb
						stosb
					;OFSTRUCT_struct.fFixedDisk is a byte
						lodsb
						stosb
					;OFSTRUCT_struct.nErrcode is a word
						lodsw
						stosw
					;OFSTRUCT_struct.Reserved1 and OFSTRUCT_struct.Reserved2 are both word sizes so copy a dword for optimization purposes
						lodsd
						stosd
					;OFFSTRUCT_struct.szPathName is a character array (zero-terminated) of 128 bytes
						push ecx
							mov ecx, 31		;We can optimize this by copy'ing dwords at a time, it just so happens 4 bytes (1 dword) goes
											;into 128 an even number of times -- 32 times (0 is counted! to be exact, this is 1/4th the number of operations over copying
											;byte by byte!!!!
							Copy_OFStruct_Continue:
								lodsd
								stosd
								sub ecx, 1
								cmp ecx, 0
								jl Copy_OFStruct_Done
								jmp Copy_OFStruct_Continue
							Copy_OFStruct_Done:
						pop ecx
						
				;uStyle is a word size so copy 2 bytes
					lodsw
					stosw

		;pop edx
		;;pop ecx
		;;pop eax
ret
endp
;end of ;start of proc FileManager_Copy_FileOpen_Slot uses esi edi ecx, Src, Dest:DWORD




;FileManager_CloseFile_ByIndex_Label:

proc FileManager_CloseFile_ByIndex Index

;return
ret
endp
;end of proc FileManager_CloseFile_ByIndex Index


FileManager_CloseFile_ByHandleNum_Label:

proc FileManager_CloseFile_ByHandleNum HandleNumber

;return
ret
endp
;end of proc FileManager_CloseFile_ByHandleNum HandleNumber