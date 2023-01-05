;******************************************************************************
; Name:         vramdump.asm
; Description:  Shows (bytes) contents of a specified section (range) of VRAM.
; Author:       David Asta
; License:      The MIT License 
; Created:      04 Jan 2023
; Version:      1.0
; Last Modif.:  04 Jan 2023
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

LINESPERPAGE    .EQU    20              ; 20 lines per page

;==============================================================================
        ld      HL, msg_welcome
        call    F_KRN_SERIAL_WRSTR
main_loop:
        call    askaddresses
        call    F_BIOS_VDP_SET_ADDR_RD  ; Set first address. VDP will autoincrement
        call    start_dump_line
        jp      main_loop

; -----------------------------------------------------------------------------
start_dump_line:
        ld      C, LINESPERPAGE         ; we will print 23 lines per page
_dump_line_loop:
        call    dump_line

        push    HL                      ; backup HL before doing sbc instruction
        and     A                       ; clear carry flag
        sbc     HL, DE                  ; have we reached the end address?
        pop     HL                      ; restore HL
        jr      c, _dump_next           ; end address not reached. Dump next line
        ret

_dump_next:
        dec     C                       ; 1 line was printed
        jp      z, _askmoreorquit       ; printed all lines fitting in the screen. More?
        jp      _dump_line_loop         ; print another line

_askmoreorquit:
        push    HL                      ; backup HL
        ld      HL, msg_moreorquit
        call    F_KRN_SERIAL_WRSTR
        call    F_BIOS_SERIAL_CONIN_A   ;read key
        cp      SPACE                   ; was the SPACE key?
        jp      z, _wantsmore           ; user wants more
        pop     HL                      ; yes, user wants more. Restore HL
        ret                             ; no
_wantsmore:
        ; print header
        ld      HL, msg_memdump_hdr
        call    F_KRN_SERIAL_WRSTR
        pop     HL                      ; restore HL
        jp      start_dump_line         ; return to start, so we print 23 more lines
; -----------------------------------------------------------------------------
exitpgm:
        ld      HL, msg_goodbye
        call    F_KRN_SERIAL_WRSTR
        ld      HL, (CLI_prompt_addr)
        jp      (HL)                    ; return control to CLI
; -----------------------------------------------------------------------------
askaddresses:
        ; ask for start_address and convert it from ASCII to Hex
        ld      HL, msg_askstartaddr    ; HL = message to display
        call    F_KRN_SERIAL_WRSTR
        ; get 1st (out of 4) character
        call    F_KRN_SERIAL_RDCHARECHO
        cp      CR                      ; user entered a CR?
        jp      z, exitpgm              ; yes, exit program
        ld      (buffer + 0), A             ; store character in buffer
        ; get 2nd (out of 4) character
        call    F_KRN_SERIAL_RDCHARECHO
        ld      (buffer + 1), A             ; store character in buffer
        ; get 3rd (out of 4) character
        call    F_KRN_SERIAL_RDCHARECHO
        ld      (buffer + 2), A             ; store character in buffer
        ; get 4th (out of 4) character
        call    F_KRN_SERIAL_RDCHARECHO
        ld      (buffer + 3), A             ; store character in buffer

        ; ask for end_address
        ld      HL, msg_askendaddr
        call    F_KRN_SERIAL_WRSTR
        ; get 1st (out of 4) character
        call    F_KRN_SERIAL_RDCHARECHO
        cp      CR                      ; user entered a CR?
        jp      z, exitpgm              ; yes, exit program
        ld      (buffer + 4), A             ; store character in buffer
        ; get 2nd (out of 4) character
        call    F_KRN_SERIAL_RDCHARECHO
        ld      (buffer + 5), A             ; store character in buffer
        ; get 3rd (out of 4) character
        call    F_KRN_SERIAL_RDCHARECHO
        ld      (buffer + 6), A             ; store character in buffer
        ; get 4th (out of 4) character
        call    F_KRN_SERIAL_RDCHARECHO
        ld      (buffer + 7), A             ; store character in buffer

        ; print header
        ld      HL, msg_memdump_hdr
        call    F_KRN_SERIAL_WRSTR

        ; Convert end address from ASCII to Hexadecimal
        ld      A, (buffer + 4)
        ld      H, A
        ld      A, (buffer + 5)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        ld      D, A
        ld      A, (buffer + 6)
        ld      H, A
        ld      A, (buffer + 7)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        ld      E, A
        ; DE contains the binary value for end address
        push    DE                      ; store it in the stack
        ; Convert start address from ASCII to Hexadecimal
        ld      A, (buffer + 0)
        ld      H, A
        ld      A, (buffer + 1)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        ld      D, A
        ld      A, (buffer + 2)
        ld      H, A
        ld      A, (buffer + 3)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        ld      E, A
        ; DE contains the binary value for start address
        ex      DE, HL                  ; HL = start address
        pop     DE                      ; DE = end address
        ret
; -----------------------------------------------------------------------------
dump_line:
        ld      A, CR
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, LF
        call    F_BIOS_SERIAL_CONOUT_A
        call    F_KRN_SERIAL_PRN_WORD
        ld      A, ':'                  ; semicolon separates mem address from data
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, ' '                  ; and an extra space to separate
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, $10                  ; we will output 16 bytes in each line
dump_loop:  ; Print bytes as Hex
        push    BC                      ; backup linecounter (C)
        call    F_BIOS_VDP_VRAM_TO_BYTE ; get byte from VRAM
        pop     BC                      ; restore linecounter (C)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        inc     HL                      ; increment address counter
        djnz    dump_loop
        ret

;==============================================================================
; Buffer for user input
;==============================================================================
buffer          .EQU    $
        .FILL   8, 0                    ; buffer for addresses entered by user

;==============================================================================
; Messages
;==============================================================================
msg_welcome:
        .BYTE   CR, LF, CR, LF
        .BYTE   "vramdump - Shows contents of a range in VRAM.", 0
msg_goodbye:
        .BYTE   CR, LF
        .BYTE   "Goodbye!", 0
msg_askstartaddr:
        .BYTE   CR, LF, CR, LF
        .BYTE   "Start Address? (blank to exit program) ", 0
msg_askendaddr:
        .BYTE   CR, LF
        .BYTE   "End Address? ", 0
msg_memdump_hdr:
        .BYTE   CR, LF, CR, LF
        .BYTE   "      00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F", CR, LF
        .BYTE   "      .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. ..", 0
msg_moreorquit:
        .BYTE   CR, LF
        .BYTE   "[SPACE] for more or another key for stop.", 0
msg_error_noendaddr:
        .BYTE   CR, LF
        .BYTE   "ERROR: End Address was not specified.", 0

        .END