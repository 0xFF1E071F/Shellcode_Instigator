;Some useful FASM-specific notes:

;Procedures, parameters, calling conventions, and arrays

;From: http://flatassembler.net/docs.php?article=win32  -- also includes win64 stuff as well
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;To define the procedure that uses the stack for parameters and local variables, you should use the proc macroinstruction. In its
;simplest form it has to be followed by the name for the procedure and then names for the all the parameters it takes, like:

;	proc WindowProc,hwnd,wmsg,wparam,lparam

;The comma between the name of procedure and the first parameter is optional. The procedure instructions should follow in the
;next lines, ended with the endp macroinstruction. The stack frame is set up automatically on the entry to procedure, the EBP register
;is used as a base to access the parameters, so you should avoid using this register for other purposes. The names specified for 
;he parameters are used to define EBP-based labels, which you can use to access the parameters as regular variables. For
;example the mov eax,[hwnd] instruction inside the procedure defined as in above sample, is equivalent to mov eax,[ebp+8]. The
;scope of those labels is limited to the procedure, so you may use the same names for other purposes outside the given procedure.

;Since any parameters are pushed on the stack as double words when calling such procedures, the labels for parameters are
;defined to mark the double word data by default, however you can you specify the sizes for the parameters if you want, by
;following the name of parameter with colon and the size operator. The previous sample can be rewritten this way, which is
;again equivalent:

;	proc WindowProc,hwnd:DWORD,wmsg:DWORD,wparam:DWORD,lparam:DWORD

;If you specify a size smaller than double word, the given label applies to the smaller portion of the whole double word stored
;on stack. If you you specify a larger size, like far pointer of quad word, the two double word parameters are defined to hold this
;value, but are labelled as one variable.

;The name of procedure can be also followed by either the stdcall or c keyword to define the calling convention it uses. When
;no such type is specified, the default is used, which is equivalent to STDCALL. Then also the uses keyword may follow, and
;after it the list of registers (separated only with spaces) that will be automatically stored on entry to procedure and restored on
;exit. In this case the comma after the list of registers and before the first parameter is required. So the fully featured procedure
;statement might look like this:

;proc WindowProc stdcall uses ebx esi edi,\
;       hwnd:DWORD,wmsg:DWORD,wparam:DWORD,lparam:DWORD

;To declare the local variable you can use the local macroinstruction, followed by one or more declarations separated with
;commas, each one consisting of the name for variable followed by colon and the type of variable - either one of the standard
;types (must be upper case) or the name of data structure. For example:

;  local hDC:DWORD,rc:RECT

;To declare a local array, you can follow the name of variable by the size of array enclosed in square brackets, like:

;  local str[256]:BYTE

;The other way to define the local variables is to declare them inside the block started with "locals" macroinstruction and ended
;with "endl", in this case they can be defined just like regular data. This declaration is the equivalent of the earlier sample:

;  locals
;    hDC dd ?
;    rc RECT
;  endl
  
;The local variables can be declared anywhere inside the procedure, with the only limitation that they have to be declared before
;they are used. The scope of labels for the variables defined as local is limited to inside the procedure, you can use the same
;names for other purposes outside the procedure. If you give some initialized values to the variables declared as local, the
;macroinstruction generates the instructions that will initialize these variables with the given values and puts these instruction
;at the same position in procedure, where the declaration is placed.

;The ret placed anywhere inside the procedure, generates the complete code needed to correctly exit the procedure,
;restoring the stack frame and the registers used by procedure. If you need to generate the raw return instruction, use
;the retn mnemonic, or follow the ret with the number parameter, what also causes it to be interpreted as single instruction

;To recapitulate, the complete definition of procedure may look like this:

;  proc WindowProc uses ebx esi edi,hwnd,wmsg,wparam,lparam
;    local hDC:DWORD,rc:RECT
;    ; the instructions
;    ret
;  endp
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



;Procedure prologues and epilogues

;From: http://flatassembler.net/docs.php?article=win32  -- also includes win64 stuff as well
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;It is possible to create a custom code for procedure framework when using proc macroinstruction. There are three symbolic
;variables, prologue@proc, epilogue@proc and close@proc, which define the names of macroinstructions that proc calls upon
;entry to the procedure, return from procedure (created with ret macro) and at the end of procedure (made with endp macro). Those
;variables can be re-defined to point to some other macroinstructions, so that all the code generated with proc macro can be customized.
;Each of those three macroinstructions takes five parameters. The first one provides a label of procedure entry point, which is
;the name of procedure aswell. The second one is a bitfield containing some flags, notably the bit 4 is set when the caller is
;supposed to restore the stack, and cleared otherwise. The third one is a value that specifies the number of bytes that parameters
;to the procedure take on the stack. The fourth one is a value that specified the number of bytes that should be reserved for the
;local variables. Finally, the fifth an last parameter is the list of comma-separated registers, which procedure declared to be used
;and which should therefore be saved by prologue and restored by epilogue.

;The prologue macro apart from generating code that would set up the stack frame and the pointer to local variables has to
;define two symbolic variables, parmbase@proc and localbase@proc. The first one should provide the base address for where
;the parameters reside, and the second one should provide the address for where the local variables reside - usually relative to
;EBP/RBP register, but it is possible to use other bases if it can be ensured that those pointers will be valid at any point inside
;the procedure where parameters or local variables are accessed. It is also up to the prologue macro to make any alignments
;necessary for valid procedure implementation; the size of local variables provided as fourth parameter may itself be not aligned at all.

;The default behavior of proc is defined by prologuedef and epiloguedef macros (in default case there is no need for closing
;macro, so the close@proc has an empty value). If it is needed to return to the defaults after some customizations were used, it
;should be done with the following three lines:

;  prologue@proc equ prologuedef
;  epilogue@proc equ epiloguedef
;  close@proc equ

;As an example of modified prologue, below is the macroinstruction that implements stack-probing prologue for 32-bit Windows. Such
;method of allocation should be used every time the area of local variables may get larger than 4096 bytes.

;  macro sp_prologue procname,flag,parmbytes,localbytes,reglist
;  { local loc
;    loc = (localbytes+3) and (not 3)
;    parmbase@proc equ ebp+8
;    localbase@proc equ ebp-loc
;    if parmbytes | localbytes
;     push ebp
;     mov ebp,esp
;     if localbytes
;      repeat localbytes shr 12
;       mov byte [esp-%*4096],0
;      end repeat
;      sub esp,loc
;     end if
;    end if
;    irps reg, reglist \{ push reg \} }

;  prologue@proc equ sp_prologue

;It can be easily modified to use any other stack probing method of the programmer's preference.
;The 64-bit headers provide an additional set of prologue/epilogue macros, which allow to define procedure that uses RSP to
;access parameters and local variables (so RBP register is free to use for any other by procedure) and also allocates the common
;space for all the procedure calls made inside, so that fastcall or invoke macros called do not need to allocate any stack space
;themselves. It is an effect similar to the one obtained by putting the code inside the procedure into frame block, but in this case
;the allocation of stack space for procedure calls is merged with the allocation of space for local variables. The code inside such
;procedure must not alter RSP register in any way. To switch to this behavior of 64-bit proc, use the following instructions:
;  prologue@proc equ static_rsp_prologue
;  epilogue@proc equ static_rsp_epilogue
;  close@proc equ static_rsp_close
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



;Exports

;From: http://flatassembler.net/docs.php?article=win32  -- also includes win64 stuff as well
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

;A couple of very critical notes will be stared (*) and contain a note as to why it's critical.

;The export macroinstruction constructs the export data for the PE file (it should be either placed in the section marked as export, or
;within the data export block. The first argument should be quoted string defining the name of library file, and the rest should be any
;number of pairs of arguments, first in each pair being the name of procedure defined somewhere inside the source (*), and the second
;being the quoted string containing the name under which this procedure should be exported by the library. This sample:

;  export 'MYLIB.DLL',\
;         MyStart,'Start',\
;         MyStop,'Stop'

;defines the table exporting two functions, which are defined under the names MyStart and MyStop in the sources, but will be
;exported by library under the shorter names. The macroinstruction take care of the alphabetical sorting of the table, which is
;required by PE format (**).

;*	- "first in each pair being the name of procedure defined somewhere inside the source" This could be why sometimes the fasm
;	  compiler complains about undefined symbols for labels inside of procedures?!


;** 	- I never knew the PE format required alphabetical listings of the exports! I wonder what else it requires?! Perhaps, there is a
;	  length limit on the name for the exports???
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------







;Calls HeapAlloc, requesting Bytes number of bytes from HeapAddr heap, and storing the returning address from the call in DestAddr
proc Allocate_Memory HeapAddr,Bytes,DestAddr:DWORD
	push edx
		mov edx, [Bytes]
		invoke HeapAlloc,[HeapAddr],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,edx
		mov [DestAddr], eax
	pop edx
ret
endp



;Util_Build_Escaped_PathAndFilename
Util_Str_Escaped_Label:

;proc Util_Build_Escaped_PathAndFilename StrSrc, EscapeChr
proc Util_Str_Escaped StrSrc:DWORD, DestStr:DWORD, EscapeChar:DWORD
local StringLen: DWORD
local CharCount:DWORD

mov [StringLen], 0
mov [CharCount], 0

	xor eax, eax

	push edx

		push esi
			xor esi, esi
			mov esi,  [EscapeChar]
			lodsb
				;mov dx, al
				mov dl, al
		pop esi

		cmp al, 0
		je Error_Param_NoEscapeChar

		;Count the number of characters in the string as well as the number of characters to be escaped.
			push esi
			mov esi, [StrSrc]
				Count_Start:
					lodsb
					
					cmp al, 0
					je Count_End

					add [StringLen], 1
					
					;cmp [al], dx
					cmp al, dl
					jne Count_Start
					
					add [StringLen], 1
					jmp Count_Start


				Count_End:

			pop esi

					add [StringLen], 1	;Add one last space for the null-terminator
					push ecx		 
						xor ecx, ecx
						mov ecx, [StringLen]
						add ecx, [CharCount]		;The only reason the number of characters to be escaped is counted is
											;so the correct amount of bytes can be allocated for storing the string
											;that will be created.



						push ecx
						push edx
							invoke HeapAlloc, [ProcessHeap], HEAP_GENERATE_EXCEPTIONS + HEAP_ZERO_MEMORY, ecx
							mov [DestStr], eax
						pop edx
						pop ecx

						;Now needs toactually build/store the escaped string in [eax]
							push esi
								mov esi, [StrSrc]

							push edi
								mov edi, eax
								xor eax, eax
								Generate_Escaped_String_Start:
									lodsb
									cmp al, 0	;Is the string parsing at the end of the original string?
									je Generate_Escaped_String_End
												;No, copy the character into the new string (regardless if it's an escape character or not)
									stosb		;This may need to be moved to just after lodsb...

									cmp al, dl	;Does the current character read in from the old string match the escaped character?
									jne Generate_Escaped_String_Start
									stosb
									jmp Generate_Escaped_String_Start

								Generate_Escaped_String_End:
							pop edi
							pop esi

						;mov eax, ecx
						mov eax, [DestStr]

					pop ecx
	pop edx 
ret
	Error_Param_NoEscapeChar:
	pop edx
		ret
endp





Util_Get_NonEscaped_StrLen_Label:

;._/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_.
;|	proc Util_Get_StrLen SrcStr: DWORD											 |
;|																		 |
;|  This function takes in a string and will return out the length							 |
;`_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_'
proc Util_Get_NonEscaped_StrLen SrcStr: DWORD

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




Util_Get_StrLen_Label:

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;|	proc Util_Get_StrLen SrcStr: DWORD											 |
;|																		 |
;|  This function returns the length of a null-terminated string.								 |
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
proc Util_Get_StrLen SrcStr: DWORD

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

	;Calculate the length of the end-result string (escaped '\' and the null-terminator)
		;Preserve value of esi (whatever it may be)
			push esi

			xor esi, esi
			
			;Set value of esi to address of SrcStr
				mov esi, dword ptr SrcStr

				push ecx
					xor ecx, ecx

				Util_StrLen_CountLoop_Start:
						lodsb

						cmp al, 0
						je Util_StrLen_CountLoop_End

						add ecx, 1
						jmp Util_StrLen_CountLoop_Start

					Util_StrLen_CountLoop_End:
						;Add one for the null-terminator
							add ecx, 1
		xor eax, eax
		mov eax, ecx
		
		pop ecx
		
		;Restore value of esi (whatever it may be)
			pop esi
ret
endp






Util_Generate_Escape_Backslash_Label:

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;|	proc Util_Generate_Escape_Backslash SrcStr: DWORD							 |
;|																		 |
;|  This function takes in a string and unescaped string and will return out the string with the		 |
;|	each backslash causing an extra backslash. This is useful for strings that are file paths.	 	 |
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
proc Util_Generate_Escape_Backslash SrcStr: DWORD, bAdd_ZeroTerminator: DWORD

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