;According to: https://msdn.microsoft.com/en-us/library/windows/desktop/aa365282(v=vs.85).aspx

struct OFSTRUCT_struct
	cBytes			db	0
	fFixedDisk			db	0
	nErrcode			dw	0
	Reserved1			dw	0
	Reserved2			dw	0
	;szPathName			db	OFS_MAXPATHNAME	dup (?)
	szPathName		db	128	dup (?)
ends
;OFSTRUCT_struct size
;1+1+2+2+2+128 =
;9 bytes heap but 24 byte size
;but 136 bytes heap
;maybe 141 bytes heap depending on zero termination implementation? 

struct FileInfo_Struct
	lpFilePath			dd				?
	lpFilename			dd				?
	lpFile_PathAndName	dd				?
	FileHandle			dd				?
	lpReOpenBuff		OFSTRUCT_struct	?
	uStyle			dw				?
ends
;FileInfo_Struct size
;1+4+1+4+32+2 =
;1+4+1+4+136?+2 = 152???
;94 in hex is 148 so the math is off by 4 bytes

;44 bytes heap but 16 bytes

;Deprecated, this was put in before it was decided that each member of
;the FileInfo_Struct would be pointers to each of their own respectivce 1-element values.
;Tbis decision was made due to filepaths and filenames being of different sizes and elements
;not being able to be reused.
	;Initial_FilesOpened_ArraySize 		equ	20
	;Initial_FilesOpened_ArraySize 		equ	0
	Initial_FilesOpened_ArraySize 		db	0

struct FileManager_New_FileOpen_Obj
	ElementIndex						dd	?
	lpOpenFileSlot						dd	?
ends

struct FileManager_NameIndex
	Path								dd  ?
	File								dd  ?
	Index								dd	?
	UniqueName						dd	?
ends

struct FileManager_Struct
	OpenFileCount						db	0
	;OpenFileCount						dd	0
	;FilesOpened_ElementsInUse			db	-1		;This will be tied to OpenFileCount for HeapAlloc purposes
	lpFilesOpened_ElementsInUse			dd	?		;This will be tied to OpenFileCount for HeapAlloc purposes
	lpUniqueNameTable					dd	?
	FilesOpened						dd	?		;This points to an array of FileInfo_Struct entries

	;FilesOpened						FileInfo_Struct	Initial_FilesOpened_ArraySize dup (?)			;Create an array of Initial_FilesOpened_ArraySize sized
	;lpFilesOpened						FileInfo_Struct
ends

lpFileManager		FileManager_Struct

New_FileOpen_Slot	FileInfo_Struct					;TODO: NOT thread-safe!


EscapeCharacter	dd	"\",0