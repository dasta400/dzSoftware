/'******************************************************************************
 * makeimgfile.bas
 *
 * Takes a file with list of files assembled, and creates a DZFS Image File 
 * for dastaZ80
 * by David Asta (Jan 2023)
 * 
 * Version 1.2.0
 * Created on 2 Jan 2023
 * Last Modification 25 Jan 2023
 *******************************************************************************
 * CHANGELOG
 *   -  8 Jan 2023 - Load Address and Attributes assigned as per file extension.
 *   - 11 Jan 2023 - Calculates the max. number of files depending on image size.
 *   - 25 Jan 2023 - Skip lines starting with # in filelist
 *******************************************************************************
 *'/

/'* ---------------------------LICENSE NOTICE--------------------------------
 *  MIT License
 *  
 *  Copyright (c) 2023 David Asta
 *  
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *  
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *  
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 *'/

' **** INCLUDES ****
#include "crt/stdio.bi"
#include "file.bi"
#include "vbcompat.bi"

' **** CONSTANTS ****
Const As Integer    MAXFILES_IN_IMAGE           = 1023
Const As Integer    SECTOR_SIZE                 = 512
Const As Integer    SECTORS_PER_BLOCK           = 64
Const As Integer    SBLOCK_TRAIL_SIZE           = 411
Const As ULong      NEWIMAGE_MAXSIZE            = 33
Const As UShort     NEWIMAGE_SIGNATURE          = &hBAAB
Const As String     NEWIMAGE_FSID               = "DZFSV1  "
Const As String     NEWIMAGE_COPYRIGHT          = "Copyright 2022David Asta      The MIT License (MIT)"
Const As UByte      DEFAULT_RHSE_EXE            = &h18  ' E  EXE
Const As UByte      DEFAULT_RHSE_FN6            = &h60  ' RS FN6
Const As UByte      DEFAULT_RHSE_FN8            = &h80  ' RS FN8
Const As UByte      DEFAULT_RHSE_SC1            = &h50  ' RS FN8
Const As UByte      DEFAULT_RHSE_SC2            = &h70  ' RS FN8
Const As UByte      DEFAULT_RHSE_SC3            = &h90  ' RS FN8
Const As UShort     DEFAULT_LOAD_ADDR           = &h4420
Const As Integer    BAT_SIZE                    = SECTORS_PER_BLOCK * SECTOR_SIZE
Const As Integer    MAXFILESIZE                 = SECTORS_PER_BLOCK * SECTOR_SIZE

' **** STRUCTURES ****
Type bat_entry Field = 1
    filename                As String * 14
    attributes              As UByte
    time_created            As UShort
    date_created            As UShort
    time_modified           As UShort
    date_modified           As UShort
    file_size_bytes         As UShort
    file_size_sectors       As UByte
    entry_number            As UShort
    first_sector            As UShort
    load_address            As UShort
End Type

' **** GLOBAL VARIABLES ****
Dim Shared As String        arg_filelist
Dim Shared As String        arg_imgfile
Dim Shared As String        arg_label
Dim Shared As Integer       arg_imgsize
Dim Shared As Long          imgfilePtr
Dim Shared As Long          filelistPtr
Dim Shared As UShort        bat_entry_number
Dim Shared As String        filelist (1 To MAXFILES_IN_IMAGE)
Dim Shared As Integer       filecounter
Dim Shared As Integer       maxFiles

' **** SUBROUTINES *****
Declare Sub OpenFiles
Declare Sub CreateSuperblock
Declare Sub CreateBAT
Declare Sub SaveBATdata(bat As bat_entry)
Declare Sub CreateFilesData
Declare Sub AddImgFileTrail

' **** FUNCTIONS ****
Declare Function StripFilename(filename As String) As String
Declare Function CalcFileSizeSectors(filesize As Integer) As UByte
Declare Function CalcFirstSector(entry_number As UShort) As UShort
Declare Function EncodeDate(datenow As String) As UShort
Declare Function EncodeTime(timenow As String) As UShort
Declare Function SwapEndianShort(invalue As UShort) As UShort
Declare Function SwapEndianLong(invalue As ULong) As ULong
Declare Function GetDateNow() As String
Declare Function GetTimeNow() As String
Declare Function CalcSerialNumber(datenow As String, timenow As String) As ULong
Declare Function LabelPadTo16(label As String) As String
Declare Function GetAttribAsPerExtension(extension As String) As UByte
Declare Function GetLoadAddrAsPerExtension(extension As String) As UShort
Declare Function GetMaxFilesAllowed(imgsize As Integer) As Integer

' *****************************************************************************
' MAIN
' *****************************************************************************
arg_filelist    = Command(1)
arg_imgfile     = Command(2)
arg_label       = Command(3)
arg_imgsize     = Val(Command(4))

If Len(arg_filelist) = 0_
  Or Len(arg_imgfile) = 0_
  Or Len(arg_label) = 0_
  Or arg_imgsize = 0 Then
    Print
    Print "ERROR: not enough parameters"
    Print "Usage " + Command(0) + " <filelist> <imgfile> <label> <imgsize>"
    Print "Options:"
    Print "         <filelist> = list of files to include in Image File"
    Print "         <imgfile>  = Image File (name) to be created"
    Print "         <label>    = Volume Label"
    Print "         <imgsize>  = Image File size in MB (max. 33)"
    End
End If

If arg_imgsize > NEWIMAGE_MAXSIZE Then
    Print "ERROR: Image Files can be of maximum " & NEWIMAGE_MAXSIZE & " MB"
    End
End If

maxFiles = GetMaxFilesAllowed(arg_imgsize)
Print "Max. files for a " & arg_imgsize & " MB Image File: " & maxFiles

OpenFiles

CreateSuperblock
CreateBAT
CreateFilesData
AddImgFileTrail

Close #filelistPtr
Close #imgfilePtr


Print "Disk Image File '" & arg_imgfile & "' created successfully."

' *****************************************************************************
' SUBROUTINES
' *****************************************************************************
' *****************************************************************************
Sub OpenFiles
    imgfilePtr = FreeFile()
    Open arg_imgfile For Binary Access Write As #imgfilePtr
    If Err > 0 Then
        Print "Failed to open " & arg_imgfile & " for writing"
        End
    End If

    filelistPtr = FreeFile()
    Open arg_filelist For Input As #filelistPtr
    If Err > 0 Then
        Print "Failed to open " & arg_filelist & " for writing"
        End
    End If
End Sub
' *****************************************************************************
Sub CreateSuperblock
    Dim As Integer  i
    Dim As UShort   signature
    Dim As ULong    sn
    Dim As UByte    empty
    Dim As UShort   sectorsize
    Dim As UByte    sectorsperblock
    Dim As String   datenow, timenow

    datenow = GetDateNow()
    timenow = GetTimeNow()
    
    signature       = NEWIMAGE_SIGNATURE '&hBAAB
    sn              = CalcSerialNumber(datenow, timenow)
    sectorsize      = SECTOR_SIZE
    sectorsperblock = SECTORS_PER_BLOCK

    Put #imgfilePtr, 1, signature
    Put #imgfilePtr,  , empty
    Put #imgfilePtr,  , NEWIMAGE_FSID
    Put #imgfilePtr,  , SwapEndianLong(sn)
    Put #imgfilePtr,  , empty
    Put #imgfilePtr,  , LabelPadTo16(arg_label)
    Put #imgfilePtr,  , datenow
    Put #imgfilePtr,  , timenow
    Put #imgfilePtr,  , sectorsize
    Put #imgfilePtr,  , sectorsperblock
    Put #imgfilePtr,  , empty
    Put #imgfilePtr,  , NEWIMAGE_COPYRIGHT

    For i =1 To SBLOCK_TRAIL_SIZE
        Put #imgfilePtr,  , empty
    Next i
End Sub
' *****************************************************************************
Sub CreateBAT
    Dim As Integer      i, c, f
    Dim As String       filename
    Dim As String       files (1 To MAXFILES_IN_IMAGE)
    Dim As Double       filedattim
    Dim As String       filedateStr
    Dim As String       filetimeStr
    Dim As UByte        trail
    Dim As bat_entry    bat

    f = FreeFile()

    bat_entry_number = 0
    filecounter = 1

    Do
        Line Input #filelistPtr, filename
        If Len(filename) > 0 Then
            If Left(filename, 1) <> "#" Then
                files(filecounter) = filename
                filelist(filecounter) = filename
                filecounter += 1
                If filecounter > maxFiles Then
                    Print "Max. files (MAXFILES_IN_IMAGE) reached!"
                    Print "Image file not created."
                    End
                End If
            End If
        End If
    Loop Until filename = ""
    
    filecounter -= 1

    For i = 1 To filecounter
        If files(i) = "" Then Exit For
        If FileExists(files(i)) Then
            Open files(i) For Input As #f
            If Err > 0 Then
                Print "Failed to open " & filelist(i) & " for reading."
                End
            End If

            filedattim = FileDateTime(files(i))
            filedateStr = Left(Format(filedattim, "yyyy-mm-dd hh:mm:ss"), 10)
            filetimeStr = Right(Format(filedattim, "yyyy-mm-dd hh:mm:ss"), 8)

            bat.filename = StripFilename(files(i))
            bat.attributes = GetAttribAsPerExtension(Right(files(i), 3))
            bat.time_created = EncodeTime(filetimeStr)
            bat.date_created = EncodeDate(filedateStr)
            bat.time_modified = bat.time_created
            bat.date_modified = bat.date_created
            bat.file_size_bytes = LOF(f)
            bat.file_size_sectors = CalcFileSizeSectors(bat.file_size_bytes)
            bat.entry_number = bat_entry_number
            bat.first_sector = CalcFirstSector(bat_entry_number)
            bat.load_address = GetLoadAddrAsPerExtension(Right(files(i), 3))

            SaveBATdata(bat)
            Close #f

        End If
            bat_entry_number += 1
    Next i

    ' BAT size = 32768 bytes
    ' Trail data = BAT size - num entries * 32
    trail = 0
    For i = 1 To (BAT_SIZE - filecounter * 32)
        Put #imgfilePtr, , trail
    Next i
End Sub
' *****************************************************************************
Sub SaveBATdata(bat As bat_entry)
    Dim As Integer  lenfilename, i

    Put #imgfilePtr,  , bat.filename
    Put #imgfilePtr,  , bat.attributes
    Put #imgfilePtr,  , bat.time_created
    Put #imgfilePtr,  , bat.date_created
    Put #imgfilePtr,  , bat.time_modified
    Put #imgfilePtr,  , bat.date_modified
    Put #imgfilePtr,  , bat.file_size_bytes
    Put #imgfilePtr,  , bat.file_size_sectors
    Put #imgfilePtr,  , bat.entry_number
    Put #imgfilePtr,  , bat.first_sector
    Put #imgfilePtr,  , SwapEndianShort(bat.load_address)
End Sub
' *****************************************************************************
Sub CreateFilesData
    Dim As Integer  i, f, t
    Dim As UByte    buffer
    Dim As UByte    trail

    f = FreeFile()

    For i = 1 To filecounter
        Open filelist(i) For Input As #f
        If Err > 0 Then
            Print "Failed to open " & filelist(i) & " for reading"
            End
        End If
        Do Until EOF(f)
            Get #f, , buffer
            Put #imgfilePtr, , buffer 
        Loop
        ' Add file trail
        '   1 File = 1 Block (32,768 bytes)
        '   Hence, need to fill 32,768 - file_size
        trail = 0
        For t = 1 To MAXFILESIZE - LOF(f)
            Put #imgfilePtr, , trail
            If Err > 0 Then
                Print "Failed to write to " & filelist(i)
                End
            End If
        Next t

        Close #f
    Next i
End Sub
' *****************************************************************************
Sub AddImgFileTrail
    Dim As Integer imgfileLen, i
    Dim As UByte        trail

    imgfileLen = LOF(imgfilePtr)

    trail = 0

    For i = imgfileLen To (arg_imgsize * 1024 * 1024) - 1
        Put #imgfilePtr, , trail
    Next i
End Sub

' *****************************************************************************
' FUNCTIONS
' *****************************************************************************

' *****************************************************************************
Function StripFilename(filename As String) As String
    Dim As Integer  slash, dot, i
    Dim AS String   temp

    slash = InStr(filename, "/")
    dot   = InStr(filename, ".")

    If slash > 0 Then
        temp = Mid(filename, slash + 1)
        dot   = InStr(temp, ".")
        temp = Left(temp, dot - 1)
    Else
        temp = Left(filename, dot - 1)
    End If

    ' Add padding until 14 characters
    For i = Len(temp) To 14
        temp = temp + " "
    Next i

    StripFilename = temp
End Function
' *****************************************************************************
Function CalcFirstSector(entry_number As UShort) As UShort
    CalcFirstSector = 65 + 64 * entry_number
End Function
' *****************************************************************************
Function CalcFileSizeSectors(filesize As Integer) As UByte
    CalcFileSizeSectors = (filesize \ SECTOR_SIZE) + 1
End Function
' *****************************************************************************
Function EncodeTime(timenow As String) As UShort
    ' datenow = hh:mm:ss

    Dim As UShort encoded

    encoded = Val(Left(timenow, 2))                     ' Hours
    encoded Shl= 6
    encoded = encoded Or Val(Mid(timenow, 4, 2))        ' Minutes
    encoded Shl= 5

    EncodeTime = encoded Or Val(Right(timenow, 2)) / 2  ' Seconds
End Function
' *****************************************************************************
Function EncodeDate(datenow As String) As UShort
    ' datenow = yyyy-mm-dd
    Dim As UShort encoded

    encoded = Val(Mid(datenow, 3, 2))               ' Year 2 digits
    encoded Shl= 4
    encoded = encoded Or Val(Mid(datenow, 6, 2))    ' Month
    encoded Shl= 5
    EncodeDate = encoded Or Val(Mid(datenow, 9, 2))  ' Day
End Function
' *****************************************************************************
Function SwapEndianLong(invalue As ULong) As ULong
    SwapEndianLong = (  ( ( invalue And &HFF000000 ) Shr 24 ) Or _
                        ( ( invalue And &H00FF0000 ) Shr  8 ) Or _
                        ( ( invalue And &H0000FF00 ) Shl  8 ) Or _
                        ( ( invalue And &H000000FF ) Shl 24 ) )
End Function

Function SwapEndianShort(invalue As UShort) As UShort
    SwapEndianShort = (invalue Shr 8) Or (invalue Shl 8)
End Function
' *****************************************************************************
Function GetDateNow() As String
' Returns current system date as ddmmyyyy
    Dim As String datenow   ' format mm-dd-yyyy

    datenow = Date
    GetDateNow = Mid(datenow, 4, 2) & Left(datenow, 2) & Right(datenow, 4)
End Function
' *****************************************************************************
Function GetTimeNow() As String
' Returns current system time as hhmmss
    Dim As String timenow   ' format hh:mm:ss

    timenow = Time
    GetTimeNow = Left(timenow, 2) & Mid(timenow, 4, 2) & Right(timenow, 2)
End Function
' *****************************************************************************
Function CalcSerialNumber(datenow As String, timenow As String) As ULong
    Dim As UByte first_byte, second_byte
    Dim As UShort last_bytes
    Dim As ULong serial_number
    Dim As UByte bhours, bmins, bsecs, bmilis
    Dim As UByte bday, bmonth, byear

    bhours  = Val(Left(timenow, 2))
    bmins   = Val(Mid(timenow, 3, 2))
    bsecs   = Val(Right(timenow, 2))
    Randomize bsecs                     ' FreeBASIC doesn't provide miliseconds.
    bmilis  = Int(Rnd * bsecs) + 1      ' We'll use a random number, using the seconds as seed

    bday    = Val(Left(datenow, 2))
    bmonth  = Val(Mid(datenow, 3, 2))
    byear   = Val(Right(datenow, 4))

    first_byte = bday + bmilis
    second_byte = bmonth + bsecs
    last_bytes = (bhours * 256 ) + bmins + byear

    serial_number = first_byte
    serial_number Shl= 8
    serial_number = serial_number Or second_byte
    serial_number Shl= 16

    CalcSerialNumber = serial_number Or last_bytes
End Function
' *****************************************************************************
Function LabelPadTo16(label As String) As String
    Dim As Integer i
    
    ' Add padding until 16 characters
    For i = Len(label) To 15
        label = label + " "
    Next i

    LabelPadTo16 = label
End Function
' *****************************************************************************
Function GetAttribAsPerExtension(extension As String) As UByte
    Select Case extension:
    Case "bin":
        GetAttribAsPerExtension = DEFAULT_RHSE_EXE
    Case "fn6":
        GetAttribAsPerExtension = DEFAULT_RHSE_FN6
    Case "fn8":
        GetAttribAsPerExtension = DEFAULT_RHSE_FN8
    Case "sc1":
        GetAttribAsPerExtension = DEFAULT_RHSE_SC1
    Case "sc2":
        GetAttribAsPerExtension = DEFAULT_RHSE_SC2
    Case "sc3":
        GetAttribAsPerExtension = DEFAULT_RHSE_SC3
    End Select
End Function
' *****************************************************************************
Function GetLoadAddrAsPerExtension(extension As String) As UShort
    Select Case extension:
    Case "bin":
        GetLoadAddrAsPerExtension = SwapEndianShort(DEFAULT_LOAD_ADDR)
    Case Else:
        GetLoadAddrAsPerExtension = &h0000
    End Select
End Function
' *****************************************************************************
Function GetMaxFilesAllowed(imgsize As Integer) As Integer
' A DZFS Image File conssist of:
'   1 Sector (512 bytes) - Superblock
'   1 Block (64 Sectors = 32,768 bytes) - BAT
'   rest of bytes - Data

    '                    Image Size              - Superblock  - BAT                  / Bytes per file
    GetMaxFilesAllowed = ((imgsize * 1024 * 1024) - SECTOR_SIZE - (64 * SECTOR_SIZE)) / (SECTORS_PER_BLOCK * SECTOR_SIZE)
End Function