;section '.extdata' data readable writeable
; Main timer ID:
MAINTIMERID				equ		3748h
DIRECTORYMONITORTIMERID	equ		3800h
FILEWATCHTIMERID		equ		3748h

; Used to swap text being displayed
;TEXTSWAPTIMER1 	equ		3752h

;-----------------------------------------------------------------------------
; Main window width & height
;-----------------------------------------------------------------------------

; NOTE: WINDOW_WIDTH is the width of the actual window. This can be anything
;		as long as it's less than ALIGNED_WIDTH.
;		ALIGNED_WIDTH is the window size rounded up to the next power of 2.
;		This is done so the macros PLOTPIXEL etc can use a shift instead
;		of a mul, which is a lot faster. WIDTH_SHIFT_OFFSET is the power of
;		2 used for ALIGNED_WIDTH
;		(WIDTH_SHIFT_OFFSET = log(ALIGNED_WIDTH) / log(2))
;		WINDOW_HEIGHT can be anything.
;
WINDOW_WIDTH		equ		256 ; Can be anything less than ALIGNED_WIDTH
ALIGNED_WIDTH		equ		256 ; window width aligned to next power of 2
;WINDOW_WIDTH		equ		400 ; Can be anything less than ALIGNED_WIDTH
;ALIGNED_WIDTH		equ		400 ; window width aligned to next power of 2
WIDTH_SHIFT_OFFSET	equ		8   ; = log(ALIGNED_WIDTH) / log(2)
WINDOW_HEIGHT		equ		60
;WINDOW_HEIGHT		equ		300
;ALIGNED_HEIGHT 	equ		256


;MAX_PATH				= 260

struct FILE_NOTIFY_INFORMATION
	NextEntryOffset		dd	?
	Action				dd	?
	FileNameLength		dd	?
	FileName			dw	?
ends

;struct FILE_NOTIFY_INFORMATION
;	NextEntryOffset		dd	?
;	Action				dd	?
;	FileNameLength		dd	?
;	;FileName			WCHAR <?>
;	FileName			du	?
;ends

struct OVERLAPPED
	Internal		dd	0,0
	InternalHigh	dd	0,0
	union
		offst		dd	0,0
		offsetHigh	dd	0,0
	ends
	Pointer			dd	0,0
	hEvent			dd	?
ends

;DirectoryChange_Buffer FILE_NOTIFY_INFORMATION

SEE_MASK_DEFAULT		= 0x00000000 
SEE_MASK_CLASSNAME		= 0x00000001 
SEE_MASK_CLASSKEY		= 0x00000003 
SEE_MASK_IDLIST 		= 0x00000004 
SEE_MASK_INVOKEIDLIST		= 0x0000000C 
SEE_MASK_ICON			= 0x00000010 
SEE_MASK_HOTKEY 		= 0x00000020 
SEE_MASK_NOCLOSEPROCESS 	= 0x00000040 
SEE_MASK_CONNECTNETDRV		= 0x00000080 
SEE_MASK_NOASYNC		= 0x00000100 
SEE_MASK_FLAG_DDEWAIT		= 0x00000100 
SEE_MASK_DOENVSUBST		= 0x00000200 
SEE_MASK_FLAG_NO_UI		= 0x00000400 
SEE_MASK_UNICODE		= 0x00004000 
SEE_MASK_NO_CONSOLE		= 0x00008000 
SEE_MASK_ASYNCOK		= 0x00100000 
SEE_MASK_HMONITOR		= 0x00200000 
SEE_MASK_NOZONECHECKS		= 0x00800000 
SEE_MASK_NOQUERYCLASSSTORE	= 0x01000000 
SEE_MASK_WAITFORINPUTIDLE	= 0x02000000 
SEE_MASK_FLAG_LOG_USAGE 	= 0x04000000 

struct SHELLEXECUTEINFO
  cbSize		       dw ?
  fMask 		       dd ?
  hwnd			       dd ?
  lpVerb	       dd ?
  lpFile	       dd ?
  lpParameters	   dd ?
  lpDirectory	   dd ?
  nShow 		       db ?
  hInstApp	       dd ?
  lpIDList		       dd ?
  lpClass		       dd ?
  ;hkeyClass		       HKEY
  hkeyClass		       dd ?
  ;dwHotKey		       dw ?
  dwHotKey		       dd ?
  union
       hIcon	       dd      ?
       hMonitor        dd      ?
  ends
  hProcess		       dd ?
ends

;From: bitRAKE - http://board.flatassembler.net/topic.php?t=11899
; Requests the OS to run the executable elevated. 
; Returns TRUE if successful, or FALSE otherwise. 
; If FALSE then return error information in edx 
;struc SHELLEXECUTEINFO {
;  .:
;  .cbSize	 dd ?
;  .fMask	 dd ?
;  .hwnd	 dd ?
;  .lpVerb	 dd ?
;  .lpFile	 dd ?
;  .lpParameters dd ?
;  .lpDirectory  dd ?
;  .nShow	 dd ?
;  .hInstApp	 dd ?
;  .lpIDList	 dd ?
;  .lpClass	 dd ?
;  .hkeyClass	 dd ?
;  .dwHotKey	 dd ?
;  label .hIcon dword
;  .hMonitor	 dd ?
;  .hProcess	 dd ?
;  .. = $ - .
  
;  macro .RunElevated hWnd*,pFilename*,pParameters* \{
;    \local ..okay
;    invoke RtlZeroMemory,.,..
;    mov [.cbSize],..
;    mov [.hwnd],hWnd
;    mov [.fMask],SEE_MASK_FLAG_DDEWAIT or SEE_MASK_FLAG_NO_UI
;    mov [.lpVerb],_runas
;    mov [.lpFile],pFilename
;    mov [.lpParameters],pParameters
;    mov [.nShow],SW_SHOWNORMAL
;    invoke ShellExecuteEx,.
;    test eax,eax
;    jnz ..okay
;    invoke GetLastError
;    mov edx, eax
;    xor eax, eax
;    ..okay:
;  \}
;}



;From WIN32A.INC
	;struc TCHAR [val] { common match any, val \{ . db val \}
    ;			    match , val \{ . db ? \} }
	;sizeof.TCHAR = 1

;MAX_PATH = 260

NAME_SIZE	equ (MAX_PATH + 1)

struct VolumeInformation
	;lpRootPathName 			db	"   ",0
	;;lpVolumeName_Buffer			dd	?
	;lpVolumeName_Buffer			db  256 dup(?)
	;;lpVolumeName_Buffer			rd	261
	;;lpVolumeName_Buffer			rd	255
	;;lpVolumeName_Buffer			db	?
	;;lpVolumeName_Buffer			rb	261
	;;nVolumeNameSize				EQU 255
	;;nVolumeNameSize				EQU 261
	;;nVolumeNameSize				TCHAR	?
	;;nVolumeNameSize				TCHAR ?
	;nVolumeNameSize				rb  3
	;;nVolumeNameSize				db	261
	;;lpVolumeSerialNumber		dd	?
	;lpVolumeSerialNumber		rd	255
	;lpMaximumComponentLength	dd	?
	;;lpMaximumComponentLength	TCHAR
	;lpFileSystemFlags			dd	?
	;;lpFileSystemNameBuffer		dd	?
	;;lpFileSystemNameBuffer		dd	?
	;lpFileSystemNameBuffer 	db 256 dup(?)
	;;nFileSystemNameSize			dd	?
	;;nFileSystemNameSize			db	?
	;;nFileSystemNameSize			rb	261
	;;nFileSystemNameSize			TCHAR ?

	;;nFileSystemNameSize			db 261
	;;nFileSystemNameSize			EQU 261
	;nFileSystemNameSize			EQU MAX_PATH

	lpRootPathName				db  4 dup (?)
	;lpVolumeName_Buffer		db 50 dup(?)
	lpVolumeName_Buffer			rb NAME_SIZE
	;nVolumeNameSize			dd 50
	nVolumeNameSize 			dd NAME_SIZE
	lpVolumeSerialNumber		dd  0
	lpMaximumComponentLength	dd  ?
	lpFileSystemFlags			dd  ?
	lpFileSystemNameBuffer		db MAX_PATH dup(?)
	;nFileSystemNameSize			dd MAX_PATH
	nFileSystemNameSize			dd NAME_SIZE
ends