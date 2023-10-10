;******************************************************************************
; Name:         loadfont.asm
; Description:  Gets the contents of a specified .FN6 or .FN8 file
;               and puts the bytes to the VRAM Pattern Table of the current
;               Mode
; Author:       David Asta
; License:      The MIT License 
; Created:      08 Jan 2023
; Version:      1.0
; Last Modif.:  18 Aug 2023
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; Copyright (C) 2023 David Asta
;
; Permission is hereby granted, free of charge, to any person obtaining a copy 
; of this software and associated documentation files (the "Software"), to deal 
; in the Software without restriction, including without limitation the rights 
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
; copies of the Software, and to permit persons to whom the Software is furnished 
; to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all 
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
; INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
; PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
; -----------------------------------------------------------------------------

.NOLIST
#include "src/_header.inc"              ; This include will add the other needed includes
                                        ; And set the start of code at address $4420
.LIST

;==============================================================================
        ld      HL, CLI_buffer_parm1_val  ; filename entered by user
        call    check_file_exists
        ; call    get_pttrn_tab_addr              ; HL = Pattern Table address
        ld      HL, (VDP_PTRNTAB_addr)  ; HL = Pattern Table address
        call    F_BIOS_VDP_SET_ADDR_WR
        call    F_BIOS_VDP_DI
        call    copy_to_vram
        call    F_BIOS_VDP_EI

        ld      HL, msg_done
        call    F_KRN_SERIAL_WRSTR

        jp      exitpgm
; -----------------------------------------------------------------------------
check_file_exists:
        ; Check if specified file exist
        call    F_KRN_DZFS_CHECK_FILE_EXISTS
        jp      z, error_nofile         ; filename not found, error and exit

        ; Check if specified file type is a font file (types $6 or $8)
        ld      A, (DISK_cur_file_attribs)
        srl     A                       ; Discard
        srl     A                       ;   low
        srl     A                       ;   nibble
        srl     A                       ;   of A
        cp      $6
        jr      z, _valid_file
        cp      $8
        jp      nz, error_nofont        ; neither $6 nor $8

_valid_file:
        ; Check if font type in the specified file corresponds to current VDP mode
        ; file type + mode must match with:
        ;        mode    file type
        ;           0  +     6 (FN6)    =   6
        ;           1  +     8 (FN8)    =   9
        ;           2  +     8 (FN8)    =   10 ($A)
        ; which means that after type + mode, only $6, $9 or $A are valid
        ld      HL, VDP_cur_mode        ; get mode address
        add     A, (HL)                 ; A = file type (from attribs.) + mode
        cp      $6                      ; Is A = $6 ?
        ret     z                       ; yes, all good. Return
        cp      $9                      ; If not, is A = $9 ?
        ret     z                       ; yes, all good. Return
        cp      $A                      ; If not, is A = $A ?
        ret     z                       ; yes, all good. Return
        ; neither $6, $9, nor $A. Error
        ld      HL, err_mode
        call    F_KRN_SERIAL_WRSTR
        jr      exitpgm
; -----------------------------------------------------------------------------
copy_to_vram:
; Load bytes from file and transfer to VRAM
        ld      HL, msg_copying
        call    F_KRN_SERIAL_WRSTR
        ld      HL, (DISK_cur_file_1st_sector)  ; 1st sector to load
        ld      A, (DISK_cur_file_size_sectors) ; how many sectors
        ld      B, A                            ;    to load
_copy_sector:
        push    BC
        push    HL
        call    F_KRN_DZFS_SEC_TO_BUFFER        ; load HL sector
        pop     HL
        call    copy_buffer_to_vram
        inc     HL                              ; next sector
        pop     BC
        djnz    _copy_sector                    ; until all sectors copied
        ret
; -----------------------------------------------------------------------------
copy_buffer_to_vram:
        push    HL
        ld      B, 0                            ; byte counter (256 times)
        ld      DE, DISK_BUFFER_START
_read_512:  ; copy 2 bytes each time, 256 times, hence 512 in total
        ld      A, (DE)                         ; read byte from DISK buffer
        inc     DE                              ; point to next byte
        call    F_BIOS_VDP_BYTE_TO_VRAM         ; copy it to VRAM's Pattern Table
        ld      A, (DE)                         ; read byte from DISK buffer
        inc     DE                              ; point to next byte
        call    F_BIOS_VDP_BYTE_TO_VRAM         ; copy it to VRAM's Pattern Table
        djnz    _read_512
        pop     HL
        ret
; -----------------------------------------------------------------------------
; get_pttrn_tab_addr:
; ; Depending on the current VDP mode,
; ; the Pattern Address is stored at a different start address
;         ld      A, (VDP_cur_mode)
;         cp      0
;         jr      z, _is_mode0
;         cp      1
;         jr      z, _is_mode1
;         cp      2
;         jr      z, _is_mode2
;         cp      3
;         jr      z, _is_mode3
;         ld      HL, err_modenoset
;         call    F_KRN_SERIAL_WRSTR
;         pop     BC
;         pop     HL
;         jr      exitpgm
; _is_mode3:
;         ld      HL, VDP_MM_PATT_TAB
;         ret
; _is_mode0:
;         ld      HL, VDP_TXT_PATT_TAB
;         ret
; _is_mode1:
;         ld      HL, VDP_G1_PATT_TAB
;         ret
; _is_mode2:
;         ld      HL, VDP_G2_PATT_TAB
;         ret
; -----------------------------------------------------------------------------
error_param:
        ld      HL, err_param
        call    F_KRN_SERIAL_WRSTR
        jr      exitpgm
error_nofont:
        ld      HL, err_filenofont
        call    F_KRN_SERIAL_WRSTR
        jr      exitpgm
error_nofile:
        ld      HL, err_nofile
        call    F_KRN_SERIAL_WRSTR
        jr      exitpgm

;==============================================================================
; RETURN TO DZOS CLI
;==============================================================================
exitpgm:
        ld      HL, (CLI_prompt_addr)
        jp      (HL)                    ; return control to CLI

;==============================================================================
; Messages
;==============================================================================
msg_copying:
        .BYTE   CR, LF
        .BYTE   "Copying bytes to VRAM...", 0
msg_done:
        .BYTE   CR, LF
        .BYTE   "Done.", 0
err_param:
        .BYTE   CR, LF
        .BYTE   "Parameter missing.", 0
err_filenofont:
        .BYTE   CR, LF
        .BYTE   "Specified file is not a font file (.FN6 or .FN8).", 0
err_nofile:
        .BYTE   CR, LF
        .BYTE   "Specified file not found.", 0
err_mode:
        .BYTE   CR, LF
        .BYTE   "Current VDP mode is not compatible with the font file.", 0
err_modenoset:
        .BYTE   CR, LF
        .BYTE   "VDP mode is not set in SYSVARS.", 0


;==============================================================================
; END of CODE
;==============================================================================
        .END