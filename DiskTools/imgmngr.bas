/'******************************************************************************
 * imgmngr.bas
 *
 * DZFS Image Manager for DZFS (dastaZ80 File System)
 * by David Asta (Nov 2022)
 * 
 * Allows to add, rename, delete and change attributes of files inside a DZFS
 * image file. Plus create new image file, display the image file's catalogue
 * and display the Superblock information.
 * 
 * Version 1.1.0
 * Created on 08 Nov 2022
 * Last Modification 14 Jun 2023
 *******************************************************************************
 * CHANGELOG
 *   - 14 Jun 2023 - Added -get parameter
 *******************************************************************************
 *******************************************************************************
 * To Dos
 *   - create new image file
 *   - Change file's attributes
 *   - Display attributes as RHSE in -cat option
 *******************************************************************************
 *'/

/'* ---------------------------LICENSE NOTICE--------------------------------
 *  MIT License
 *  
 *  Copyright (c) 2022 David Asta
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

#lang "fblite"  ' So that we can use variable-length array (Option Dynamic)

' **** INCLUDES ****
#include "crt/stdio.bi"
#include "file.bi"

' **** CONSTANTS ****
Const As Integer    SECTOR_SIZE                 = 512
Const As Integer    SECTORS_PER_BLOCK           = 64
Const As Integer    SECTOR_OFFSET_SBLOCK        = 0
Const As Integer    SECTOR_OFFSET_BAT           = 1
Const As Integer    ENTRIES_PER_BAT             = 1024
Const As Integer    BAT_ENTRY_SIZE              = 32
Const As Integer    FILENAME_SIZE               = 13
Const As Integer    ID_SIZE                     = 7
Const As Integer    SN_SIZE                     = 3
Const As Integer    LABEL_SIZE                  = 15
Const As Integer    DATECREA_SIZE               = 7
Const As Integer    TIMECREA_SIZE               = 5
Const As Integer    CRIGHT_SIZE                 = 50
Const As ULong      NEWIMAGE_SIZE               = 128188416
Const As String     NEWIMAGE_FSID               = "DZFSV1  "
Const As String     NEWIMAGE_COPYRIGHT          = "Copyright 2022David Asta      The MIT License (MIT)"

' **** STRUCTURES ****
Type superblock
    signature                       As UShort
    notused                         As UByte
    id(ID_SIZE)                     As UByte
    serial_number(SN_SIZE)          As UByte
    notused2                        As UByte
    label(LABEL_SIZE)               As UByte
    date_creation(DATECREA_SIZE)    As UByte
    time_creation(TIMECREA_SIZE)    As UByte
    bytes_per_sector                As UShort
    sectors_per_block               As UByte
    notused3                        As UByte
    copyright(CRIGHT_SIZE)          As UByte
    notused4(411)                   As UByte
End Type

Type bat_entry Field = 1
    filename(FILENAME_SIZE) As UByte
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
Dim         As Long         fileNum 
Dim Shared  As String       arg_filename
Dim         As String       arg_option, arg_suboption, arg_suboption2
Dim         As Integer      result, numItems, item
Dim         As LongInt      imgfile_len
Dim Shared  As FILE Ptr     filePtr
Dim Shared  As bat_entry    bat(ENTRIES_PER_BAT)
Dim Shared  As superblock   sblock
Option Dynamic
Dim Shared  As UByte        buffer(1)
Option Static

' **** SUBROUTINES *****
Declare Sub ShowCatalogue
Declare Sub ShowSuperblock
Declare Sub CreateNewImage(filename As String, label As String)

' **** FUNCTIONS ****
Declare Function LoadBAT() As Boolean
Declare Function FindFreeEntryInBAT() As Integer
Declare Function AddFile(filename As String) As Integer
Declare Function ExtractFile(filename As String) As Integer
Declare Function DeleteFile(filename As String) As Integer
Declare Function RenameFile(oldname As String, newname As String) As Integer
Declare Function DecodeTime(intime As UShort) As String
Declare Function DecodeDate(indate As UShort) As String
Declare Function EncodeTime(timenow As String) As UShort
Declare Function EncodeDate(datenow As String) As UShort
Declare Function SwapEndian(invalue As UShort) As UShort
Declare Function SearchFileInBAT(filename As String) As Integer
Declare Function CalculateVolumeSerialNumber() As ULong
Declare Function GetBATFilenameLength(bat_entry As Integer) As Integer
Declare Function GetBATFilenameString(bat_entry As Integer) As String

' *****************************************************************************
' MAIN
' *****************************************************************************
arg_filename    = Command(1)
arg_option      = Command(2)
arg_suboption   = Command(3)
arg_suboption2  = Command(4)

If Len(arg_filename) = 0 Or Len(arg_option) = 0 Then
    Print
    Print "ERROR: not enough parameters"
    Print "Usage " + Command(0) + " <image_file> <option>"
    Print "Options:"
    Print "         -new <file> <label> = create a new image"
    Print "         -sblock             = show Superblock"
    Print "         -cat                = show disk Catalogue"
    Print "         -add <file>         = add file to image"
    Print "         -get <file>         = extract file from image"
    Print "         -del <file>         = mark file as deleted"
    Print "         -ren <old> <new>    = rename old filename to new"
    Print "         -attr <file> <RHSE> = set new attributes to file"
    End
End If

filePtr = fopen(arg_filename, "r+b")
If filePtr = 0 Then
    Print "File ";arg_filename;" couldn't be opened"
    End
End If

Select Case arg_option
' Case "-new"
'     If Len(arg_suboption) = 0 OrElse Len(arg_suboption2) = 0 Then
'         Print "ERROR: not enough parameters"
'     Else
'         CreateNewImage(arg_suboption, arg_suboption2)
'     End If
Case "-sblock"
    ShowSuperblock
Case "-cat"
    If LoadBAT() Then
        ShowCatalogue
    End If
Case "-add"
    If Len(arg_suboption) = 0 Then
        Print "ERROR: not enough parameters"
    Else
        If LoadBAT() Then
            If AddFile(arg_suboption) > 0 Then
                Print arg_suboption;" was added successfully."
            Else
                Print "ERROR: ";arg_suboption;" was not added."
            End If
        End If
    End If
Case "-get"
    If Len(arg_suboption) = 0 Then
        Print "ERROR: not enough parameters"
    Else
        If LoadBAT() Then
            If ExtractFile(arg_suboption) > 0 Then
                Print arg_suboption;" was extracted successfully."
            Else
                Print "ERROR: ";arg_suboption;" was not extracted."
            End If
        Else
            Print "ERROR: ";arg_suboption;" was not extracted."
        End If
    End If
Case "-del"
    If Len(arg_suboption) = 0 Then
        Print "ERROR: not enough parameters"
    Else
        If LoadBAT() Then
            If DeleteFile(arg_suboption) > 0 Then
                Print arg_suboption;" was deleted successfully."
            Else
                Print "ERROR: ";arg_suboption;" was not deleted."
            End If
        End If
    End If
Case "-ren"
    If Len(arg_suboption) = 0 OrElse Len(arg_suboption2) = 0 Then
        Print "ERROR: not enough parameters"
    Else
        If LoadBAT() Then
            If RenameFile(arg_suboption, arg_suboption2) > 0 Then
                Print arg_suboption;" was renamed successfully."
            Else
                Print "ERROR: ";arg_suboption;" was not renamed."
            End If
        End If
    End If
' Case "-attr"
'     If Len(arg_suboption) = 0 OrElse Len(arg_suboption2) = 0 Then
'         Print "ERROR: not enough parameters"
'     Else
'         AssignAttributes(arg_suboption, arg_suboption2)
'     End If
Case Else
    Print "ERROR: unknown option ";arg_option
End Select

fclose(filePtr)

' *****************************************************************************
' SUBROUTINES
' *****************************************************************************

' *****************************************************************************
Sub ShowCatalogue
    Dim As Integer e, f, c

    Print
    Print "File            Created               Modified              Size   Attributes Load Address"
    Print "------------------------------------------------------------------------------------------"

    For e = 0 To ENTRIES_PER_BAT
        If bat(e).filename(0) = 0 Then Exit For 

        Print(GetBATFilenameString(e));
        For c = GetBATFilenameLength(e) To FILENAME_SIZE
            Print(" ");
        Next c
        Print Using "  & &   & & ##,###   &          &";_
            DecodeTime(SwapEndian(bat(e).time_created));_
            DecodeDate(SwapEndian(bat(e).date_created));_
            DecodeTime(SwapEndian(bat(e).time_modified));_
            DecodeDate(SwapEndian(bat(e).date_modified));_
            bat(e).file_size_bytes;_
            Hex(bat(e).attributes);_
            Hex(bat(e).load_address)
    Next e
End Sub

' *****************************************************************************
Sub ShowSuperblock
    Dim As Integer c
    If fseek(filePtr, SECTOR_OFFSET_SBLOCK * SECTOR_SIZE, SEEK_SET) <> 0 Then
        Print "Failed to set file stream position"
    Else
        fread(@sblock, SizeOf(sblock), 1, filePtr)
        
        Print:Print "Signature         : " + Hex(SwapEndian(sblock.signature))
        Print "File system id    : ";
        For c = 0 To ID_SIZE
            Print Chr(sblock.id(c));
        Next c
        Print:Print "Serial Number     : ";
        For c = 0 To SN_SIZE
            Print Hex(sblock.serial_number(c));" ";
        Next c
        Print:Print "Label             : ";
        For c = 0 To LABEL_SIZE
            Print Chr(sblock.label(c));
        Next c
        Print:Print "Date Creation     : "; 
        For c = 0 To DATECREA_SIZE
            Print Chr(sblock.date_creation(c));
        Next c
        Print:Print "Time Creation     : "; 
        For c = 0 To TIMECREA_SIZE
            Print Chr(sblock.time_creation(c));
        Next c
        Print:Print "Bytes per Sector  : ";sblock.bytes_per_sector
        Print "Sectors per Block : ";sblock.sectors_per_block
        Print "Copyright notice  : ";
        For c = 0 To CRIGHT_SIZE
            Print Chr(sblock.copyright(c));
        Next c
        Print
    End If 
End Sub

' *****************************************************************************
Sub CreateNewImage(filename As String, label As String)
' TODO
End Sub

' *****************************************************************************
' FUNCTIONS
' *****************************************************************************

' *****************************************************************************
Function LoadBAT() As Boolean
    Dim As UByte buffer(FileLen(arg_filename))
    Dim As Integer e

    If fseek(filePtr, SECTOR_OFFSET_BAT * SECTOR_SIZE, SEEK_SET) <> 0 Then
        Print "Failed to set file stream position"
        LoadBAT = False
    Else
        LoadBAT = True
        For e = 0 To ENTRIES_PER_BAT
            fread(@bat(e), BAT_ENTRY_SIZE, 1, filePtr)

            If bat(e).filename(0) = 0 Then Exit For 

            bat(e).time_created     = SwapEndian(bat(e).time_created)
            bat(e).date_created     = SwapEndian(bat(e).date_created)
            bat(e).time_modified    = SwapEndian(bat(e).time_modified)
            bat(e).date_modified    = SwapEndian(bat(e).date_modified)
        Next e    
    End If

    LoadBAT = True
End Function

' *****************************************************************************
Function FindFreeEntryInBAT() As Integer
    Dim As Integer e

    For e = 0 To ENTRIES_PER_BAT
        ' If first character is 00, then there is a free (unused) entry
        If bat(e).filename(0) = 0 Then Exit For
    Next e

    ' No unused entries found. Lets search for deleted files
    If e = ENTRIES_PER_BAT Then
        For e = 0 To ENTRIES_PER_BAT
            If bat(e).filename(0) = &h7E Then Exit For
        Next e
    End If

    FindFreeEntryInBAT = e
End Function

' *****************************************************************************
Function DeleteFile(filename As String) As Integer
    Dim As Integer result, batentry

    result = 0
    batentry = SearchFileInBAT(filename)

    if batentry = -1 Then
        Print "ERROR: file ";filename;" not found in BAT"
    Else
        bat(batentry).filename(0) = &h7E
        fseek(filePtr, (SECTOR_OFFSET_BAT * SECTOR_SIZE) + (batentry * 32), SEEK_SET)
        result = fwrite(@bat(batentry), BAT_ENTRY_SIZE, 1, filePtr)
    End If
        
    DeleteFile = result 
End Function

' *****************************************************************************
Function RenameFile(oldname As String, newname As String) As Integer
    Dim As Integer c, result, batentry_old, batentry_new

    result = 0
    batentry_old = SearchFileInBAT(oldname)

    if batentry_old = -1 Then
        Print "ERROR: file ";oldname;" not found in BAT"
    Else
        batentry_new = SearchFileInBAT(newname)

        If batentry_new > -1 Then
            Print "ERROR: file ";newname;" already exists in BAT"
        Else
            For c = 0 to FILENAME_SIZE
                If newname[c] = 0 Then Exit For
                bat(batentry_old).filename(c) = newname[c]
            Next c

            If c < FILENAME_SIZE Then
                For c = c To FILENAME_SIZE
                    bat(batentry_old).filename(c) = &h20
                Next c
            End If

            fseek(filePtr, (SECTOR_OFFSET_BAT * SECTOR_SIZE) + (batentry_old * 32), SEEK_SET)
            result = fwrite(@bat(batentry_old), BAT_ENTRY_SIZE, 1, filePtr)
        End If
    End If

    RenameFile = result
End Function

' *****************************************************************************
Function ExtractFile(filename As String) As Integer
    Dim As Integer b, result, batentry, file_1stsector, file_size_bytes
    Dim AS Integer byte_count
    Dim As ULong file_1stbyte
    Dim As UByte file_byte
    Dim As FILE Ptr extractFilePtr

    result = 0
    batentry = SearchFileInBAT(filename)

    If batentry = -1 Then
        Print "ERROR: file ";filename;" not found in BAT"
    Else
        file_1stsector = bat(batentry).first_sector
        file_1stbyte = file_1stsector * SECTOR_SIZE
        file_size_bytes = bat(batentry).file_size_bytes

        Print "File '";
        For f = 0 To FILENAME_SIZE
            If Chr(bat(batentry).filename(f)) <> " " Then
                Print Chr(bat(batentry).filename(f));
            End If
        Next f
        Print "', of size";file_size_bytes;
        Print " bytes, found at Sector";file_1stsector;" / Address 0x";Hex(file_1stbyte)
        extractFilePtr = fopen(filename, "wb")
        If extractFilePtr = 0 Then
            Print "File ";filename;" couldn't be opened"
        Else
            byte_count = 0
            fseek(filePtr, (file_1stsector * SECTOR_SIZE), SEEK_SET)
            For b = 0 To file_size_bytes - 1
                fread(@file_byte, SizeOf(UByte), 1, filePtr)
                result = fwrite(@file_byte, SizeOf(UByte), 1, extractFilePtr)
                byte_count += 1
            Next b
            fclose(extractFilePtr)
        End If
    End If

    ExtractFile = result
End Function

' *****************************************************************************
Function AddFile(filename As String) As Integer
    Dim As Integer b, result, batentry, newfile_1stsector
    Dim As UShort newfile_size
    Dim As UByte newfile_buffer, newfile_byte, load_address_lsb, load_address_msb
    Dim As FILE Ptr newFilePtr

    result = 0

    batentry = SearchFileInBAT(filename)

    If batentry > -1 Then
        Print "ERROR: file ";filename;" already exists in BAT"
    Else
        newFilePtr = fopen(filename, "rb")
        If newFilePtr = 0 Then
            Print "File ";filename;" couldn't be opened"
        Else
            batentry = FindFreeEntryInBAT()
            newfile_1stsector = 65 + 64 * batentry
            newfile_size = FileLen(filename)
            Redim buffer(0 To newfile_size)

            ' Save data from file into image, starting at 1st Sector
            fseek(filePtr, (newfile_1stsector * SECTOR_SIZE), SEEK_SET)
            Print "Saving at"
            Print "     Sector   :"; newfile_1stsector;
            Print " (0x";Hex(newfile_1stsector);")"
            Print "     Offset   :"; newfile_1stsector * SECTOR_SIZE;
            Print " (0x";Hex(newfile_1stsector * SECTOR_SIZE);")"
            Print "     BAT Entry:"; batentry
            For b = 0 To newfile_size
                fread(@newfile_byte, SizeOf(UByte), 1, newFilePtr)
                ' Store Load Address from bytes 2 and 3
                If b = 2 Then load_address_msb = newfile_byte
                If b = 3 Then load_address_lsb = newfile_byte
                result += fwrite(@newfile_byte, SizeOf(UByte), 1, filePtr)
            Next b

            ' Add a new entry to the BAT
            If result > 0 Then
                For b = 0 To FILENAME_SIZE
                    bat(batentry).filename(b)   = Asc(Mid(filename, b + 1, 1))
                Next b
                bat(batentry).attributes        = &h08
                bat(batentry).time_created      = EncodeTime(Time)
                bat(batentry).date_created      = EncodeDate(Date)
                bat(batentry).time_modified     = EncodeTime(Time)
                bat(batentry).date_modified     = EncodeDate(Date)
                bat(batentry).file_size_bytes   = newfile_size
                bat(batentry).file_size_sectors = SwapEndian(newfile_size / SECTOR_SIZE)
                bat(batentry).entry_number      = batentry
                bat(batentry).first_sector      = newfile_1stsector
                bat(batentry).load_address      = (load_address_msb Shl 8) Or load_address_lsb

                fseek(filePtr, (SECTOR_OFFSET_BAT * SECTOR_SIZE) + (batentry * 32), SEEK_SET)
                result = fwrite(@bat(batentry), BAT_ENTRY_SIZE, 1, filePtr)
            Else
                Print "ERROR: couldn't copy bytes from ";filename
            End If
        End If
    End If

    AddFile = result
End Function

' *****************************************************************************
Function SearchFileInBAT(filename As String) As Integer
' Searches a specified filename in the BAT.
' If the filename is found, the variable bat (structure bat_entry) is loaded
'   with the values from the read BAT, and return value is the BAT entry number.
' If not found, returns -1
    Dim As Integer e, c, batentry

    batentry = -1

    For e = 0 To ENTRIES_PER_BAT
        If bat(e).filename(0) = 0 Then Exit For

        If filename = GetBATFilenameString(e) Then
            batentry = e
            Exit For
        End If
    Next e

    SearchFileInBAT = batentry
End Function

' *****************************************************************************
Function SwapEndian(invalue As UShort) As UShort
    SwapEndian = (invalue Shr 8) Or (invalue Shl 8)
End Function
' *****************************************************************************
Function DecodeTime(intime As UShort) As String
    Dim As UByte hh, mm, ss
    Dim As UShort mmss
    Dim As String shh, smm, sss

    hh = intime Shr 11
    mmss = intime Shl 5
    mm = mmss Shr 10
    mmss = intime Shl 11
    ss = mmss Shr 10

    If hh < 10 Then shh = "0" + Str(hh) Else shh = Str(hh)
    If mm < 10 Then smm = "0" + Str(mm) Else smm = Str(mm)
    If ss < 10 Then sss = "0" + Str(ss) Else sss = Str(ss)

    DecodeTime = shh + ":" + smm + ":" + sss
End Function

' *****************************************************************************
Function DecodeDate(indate As UShort) As String
    Dim As UByte yy, mm, dd
    Dim As UShort yymm, mmdd, yyyy
    Dim As String smm, sdd
    
    yy = indate Shr 9
    yyyy = 2000 + yy
    yymm = indate Shl 7
    mm = yymm Shr 12
    mmdd = indate Shl 11
    dd = mmdd Shr 11

    If mm < 10 Then smm = "0" + Str(mm) Else smm = Str(mm)
    If dd < 10 Then sdd = "0" + Str(dd) Else sdd = Str(dd)

    DecodeDate = sdd + "/" + smm + "/" + Str(yyyy)
End Function

' *****************************************************************************
Function EncodeTime(timenow As String) As UShort
    ' timenow = hh:mm:ss
    Dim As UShort encoded

    encoded = Val(Left(timenow, 2))
    encoded Shl= 6
    encoded = encoded Or Val(Mid(timenow, 4, 2))
    encoded Shl= 5

    EncodeTime = encoded Or Val(Right(timenow, 2)) / 2
End Function

' *****************************************************************************
Function EncodeDate(datenow As String) As UShort
    ' datenow = mm-dd-yyyy
    Dim As UShort encoded

    encoded = Val(Right(datenow, 2))
    encoded Shl= 4
    encoded = encoded Or Val(Left(datenow, 2))
    encoded Shl= 5
    
    EncodeDate = encoded Or Val(Mid(datenow, 4, 2))
End Function

' *****************************************************************************
Function CalculateVolumeSerialNumber() As ULong
    Dim As String datenow, timenow
    Dim As UByte first_byte, second_byte, milis
    Dim As UShort last_bytes
    Dim As ULong serial_number

    datenow = Date  ' mm-dd-yyyy
    timenow = Time  ' hh:mm:ss

    ' First byte = day + miliseconds
    ' FreeBASIC doesn't provide miliseconds.
    ' We'll use a random number, using the seconds as seed
    Randomize
    first_byte = Val(Mid(datenow, 4, 2)) + Int(Rnd * 59) + 1
    ' Second byte = month + seconds
    second_byte = Val(Left(datenow, 2)) + Val(Right(timenow, 2))
    ' Last two bytes = (hours [if pm + 12] * 256) + minutes + year
    last_bytes = Val(Left(timenow, 2)) * 256 + Val(Mid(timenow, 4, 2)) + Val(Right(datenow, 4))

    serial_number = first_byte
    serial_number Shl= 8
    serial_number = serial_number Or second_byte
    serial_number Shl= 16

    CalculateVolumeSerialNumber = serial_number Or last_bytes
End Function

' *****************************************************************************
Function GetBATFilenameLength(bat_entry As Integer) As Integer
    Dim As Integer c, length

    length = 0

    For c = 0 To FILENAME_SIZE
        If bat(bat_entry).filename(c) = &h20 Then Exit For
        length += 1
    Next c

    GetBATFilenameLength = length
End Function

' *****************************************************************************
Function GetBATFilenameString(bat_entry As Integer) As String
    Dim As Integer c
    Dim As String filename

    For c = 0 To FILENAME_SIZE
        If bat(bat_entry).filename(c) = &h20 Then Exit For
        filename += Chr(bat(bat_entry).filename(c))
    Next c

    GetBATFilenameString = filename
End Function