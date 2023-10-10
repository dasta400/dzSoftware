;******************************************************************************
; Name:         loadscr.asm
; Description:  Gets the contents of a specified .SC1, .SC2 or .SC3 file,
;               puts the bytes into the VRAM, and changes the current Mode
;               depending on the file type (e.g. a .SC2 will change to Mode 2)
; Author:       David Asta
; License:      The MIT License 
; Created:      09 Jan 2023
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
        call    change_to_file_mode
        ; SC files are a dump of VRAM, hence we just need to copy each byte from
        ; the disk buffer to VRAM, starting at VRAM $0000
        ld      HL, 0                    ; Set VRAM to start writing
        call    F_BIOS_VDP_SET_ADDR_WR  ;   at address $0000
        call    F_BIOS_VDP_DI
        call    copy_to_vram
        call    rebuild_name_table
        call    F_BIOS_VDP_EI

        ld      HL, msg_done
        call    F_KRN_SERIAL_WRSTR

        jp      exitpgm
; -----------------------------------------------------------------------------
check_file_exists:
        ; Check if specified file exist
        call    F_KRN_DZFS_CHECK_FILE_EXISTS
        jp      z, error_nofile         ; filename not found, error and exit

        ; Check if specified file type is a screen file (types $5, $7 or $9)
        ld      A, (DISK_cur_file_attribs)
        srl     A                       ; Discard
        srl     A                       ;   low
        srl     A                       ;   nibble
        srl     A                       ;   of A
        cp      $5
        jr      z, _allgood
        cp      $7
        jr      z, _allgood
        cp      $9
        jr      z, _allgood
        jp      error_noscr
_allgood:
        ret
; -----------------------------------------------------------------------------
change_to_file_mode:
; The screen mode is changed to be the same as the file type
; (e.g. a .SC2 will change to Mode 2)
; IN <= A = file type
        cp      $5
        jr      z, _change_to_g1
        cp      $7
        jr      z, _change_to_g2

        ld      HL, msg_chgg3
        call    F_KRN_SERIAL_WRSTR
        call    F_BIOS_VDP_SET_MODE_MULTICLR
        ret
_change_to_g1:
        ld      HL, msg_chgg1
        call    F_KRN_SERIAL_WRSTR
        call    F_BIOS_VDP_SET_MODE_G1
        ld      A, 7
        ld      B, 0
        call    F_BIOS_VDP_SET_REGISTER
        ret
_change_to_g2:
        ld      HL, msg_chgg2
        call    F_KRN_SERIAL_WRSTR
        call    F_BIOS_VDP_SET_MODE_G2BM
        ld      A, 7
        ld      B, 0
        call    F_BIOS_VDP_SET_REGISTER
        ret
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
rebuild_name_table:
; Because this program copies entire sectors to VRAM, at the end destroyes part
;   of the Pattern Table. So we need to rebuild it.
; Todo - Depends on the Mode

        ld      HL, VDP_G2_NAME_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      B, 0                            ; byte counter (256 times)
        xor     A                               ; all bytes will be set to zero
_clear_loop:
        call    F_BIOS_VDP_BYTE_TO_VRAM         ; copy two bytes each time
        inc     A
        call    F_BIOS_VDP_BYTE_TO_VRAM         ;   so we copy 512 in total
        inc     A
        djnz    _clear_loop
        ld      B, 0                            ; byte counter (256 times)
_clear_loop2:
        call    F_BIOS_VDP_BYTE_TO_VRAM         ; copy one bytes each time for 256
        inc     A
        djnz    _clear_loop2
        ret
; -----------------------------------------------------------------------------
error_param:
        ld      HL, err_param
        call    F_KRN_SERIAL_WRSTR
        jr      exitpgm
error_noscr:
        ld      HL, err_filenoscr
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
msg_chgg1:
        .BYTE   "Changing to Mode 1 (Graphics I Mode).", 0
msg_chgg2:
        .BYTE   "Changing to Mode 2 (Graphics II Mode).", 0
msg_chgg3:
        .BYTE   "Changing to Mode 3 (Multicolour Mode).", 0
msg_copying:
        .BYTE   CR, LF
        .BYTE   "Copying bytes to VRAM...", 0
msg_done:
        .BYTE   CR, LF
        .BYTE   "Done.", 0
err_param:
        .BYTE   "Parameter missing.", 0
err_filenoscr:
        .BYTE   "Specified file is not a screen file (.SC1, .SC2 or .SC3).", 0
err_nofile:
        .BYTE   "Specified file not found.", 0

;==============================================================================
; END of CODE
;==============================================================================
        .END