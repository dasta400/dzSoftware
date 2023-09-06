;******************************************************************************
; Name:         mlmonitor.asm
; Description:  Machine Language Monitor
;               Done:
;                   - C - Call.
;                   - F - Fill a range of locations with a specified byte.
;                   - M - Display memory as a hexadecimal dump.
;                   - P - Modify a single memory address (poke) with a specified value.
;                   - T - Transfer segments of memory from one memory area to another.
;                   - Y - Display the value (peek) from a memory address.
;                   - X - Exit Monitor back to OS.
;               To Do:
;                   - A - Assemble a line of assembly code.
;                   - D - Disassemble machine code into assembly language mnemonics and operands.
;                   - L - Load data from disk into memory.
;                   - Q - Modify a single video memory address (vpoke) with a specified value.
;                   - S - Save the contents of memory onto disk.
;                   - V - Display video memory (vmemdump) as a hexadecimal dump.
;                   - Z - Display the value (vpeek) from a video memory address.
; Author:       David Asta
; License:      The MIT License 
; Created:      5 Sep 2023
; Version:      0.1.0
; Last Modif.:  5 Sep 2023
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
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
; -----------------------------------------------------------------------------

.NOLIST
#include "src/_header.inc"              ; This include will add the other needed includes
                                        ; And set the start of code at address $4420
.LIST

LINESPERPAGE    .EQU    20              ; 20 lines per page

;==============================================================================
; MAIN LOOP
;==============================================================================
        ld      HL, msg_welcome
        call    F_KRN_SERIAL_WRSTR
main_loop:
        ld      A, ANSI_COLR_BLU
        call    F_KRN_SERIAL_SETFGCOLR  ; set prompt colour
        ld      HL, msg_prompt
        call    F_KRN_SERIAL_WRSTR      ; print prompt

        ld      A, SPACE
        call    F_BIOS_SERIAL_CONOUT_A  ; print separator

        ld      A, ANSI_COLR_WHT        ; Set text colour
        call    F_KRN_SERIAL_SETFGCOLR  ;   for user input

        call    read_user_cmd           ; read command from user
        jp      parse_exec_cmd          ; parse and execute command
;==============================================================================
; SUBROUTINES
;==============================================================================
; -----------------------------------------------------------------------------
read_user_cmd:
; Read characters entered by user at prompt, stores them in buffer. Until
;   user has pressed the ENTER key.
        ld      HL, CLI_buffer_full_cmd ; address where command is stored
_readcmd_loop:
        call    F_KRN_SERIAL_RDCHARECHO ; A = character read from serial (keyboard)
        cp      CR                      ; ENTER?
        jr      z, _readcmd_end         ; yes, command was fully entered
        ld      (HL), A                 ; no, store character in buffer
        inc     HL
        jr      _readcmd_loop           ; and read more characters
_readcmd_end:
        ret
; -----------------------------------------------------------------------------
parse_exec_cmd:
; Parse a command entered by the user (stored in buffer) and call
;   corresponding subroutine
;  _____     ____
; |_   _|__ |  _ \  ___
;   | |/ _ \| | | |/ _ \
;   | | (_) | |_| | (_) |       See below
;   |_|\___/|____/ \___/

        ; Commands are one character long,
        ;   so just need to read 1st character in buffer
        ld      HL, CLI_buffer_full_cmd ; address where command is stored
        ld      A, (HL)
; ToDo   cp      'A'
; ToDo   jp      z, cmd_assemble
        cp      'C'
        jp      z, cmd_call
        cp      'D'
; ToDo   jp      z, cmd_disassemble
; ToDo   cp      'F'
        jp      z, cmd_fill
; ToDo   cp      'L'
; ToDo   jp      z, cmd_load
        cp      'M'
        jp      z, cmd_display_mem
        cp      'P'
        jp      z, cmd_poke
; ToDo   cp      'Q'
; ToDo   jp      z, cmd_vpoke
; ToDo   cp      'S'
; ToDo   jp      z, cmd_save_to_disk
        cp      'T'
        jp      z, cmd_transfer
; ToDo   cp      'V'
; ToDo   jp      z, cmd_display_vmem
        cp      'X'
        jp      z, cmd_exit
        cp      'Y'
        jp      z, cmd_peek
; ToDo   cp      'Z'
; ToDo   jp      z, cmd_vpeek
        ; None of the above, error because command is unknown
        ld      HL, error_cmd_unknown
        ld      A, ANSI_COLR_RED
        call    F_KRN_SERIAL_WRSTRCLR
        jp      main_loop
; -----------------------------------------------------------------------------
; cmd_assemble:
; assemble a line of assembly code.
; Syntax: A <address_in_hex> <mnemonic> <operands>
; -----------------------------------------------------------------------------
cmd_call:
; Call. Transfers the Program Counter (PC) of the Z80 to the specified address.
; Syntax: C <address>
        ; store current address + in the Stack, so that when the called
        ;   subroutine ends with a RET, it will come back to the mlmonitor
        ld      HL, _after_call         ; put in the Stack the address where the
        push    HL                      ;   PC will go after the called subroutine
        ; Make jump to the specified address
        ld      B, 1
        call    get_param_pointer
        ld      DE, buff_parm1          ; will copy param to buff1
        ld      BC, 4                   ; 4 bytes (an address)
        ldir                            ;   to copy
        ld      IX, buff_parm1          ; Convert param1
        call    F_KRN_ASCIIADR_TO_HEX   ;   from ASCII to Hexadecimal
        jp      (HL)                    ; jump to specified address
_after_call:                            ; if the called subroutine had a RET
                                        ;   it will come back here. Otherwise, who knows
        jp      main_loop
; -----------------------------------------------------------------------------
; cmd_disassemble:
; disassemble machine code into assembly language mnemonics and operands.
; Syntax: D <start_address_in_hex> <end_address_in_hex>
; -----------------------------------------------------------------------------
cmd_fill:
; fill a range of locations with a specified byte.
; Syntax: F <start_address_in_hex> <end_address_in_hex> <byte_in_hex>
        ; get param1 (start_address)
        ld      B, 1
        call    get_param_pointer
        ld      DE, buff_parm1          ; will copy param to buff1
        ld      BC, 4                   ; 4 bytes (an address)
        ldir                            ;   to copy
        ; get param2 (end_address)
        ld      B, 2
        call    get_param_pointer
        ld      DE, buff_parm2          ; will copy param to buff2
        ld      BC, 4                   ; 4 bytes to copy
        ldir                            ;   to copyldir
        ; convert param1 from ASCII to Hex
        ld      IX, buff_parm1          ; convert parm1
        call    F_KRN_ASCIIADR_TO_HEX   ;    into Hex (returned in HL)
        push    HL                      ; backup Hex value
        ex      DE, HL                  ; copy Hex value to DE
        ; convert param2 from ASCII to Hex
        ld      IX, buff_parm2          ; convert parm2
        call    F_KRN_ASCIIADR_TO_HEX   ;    into Hex (returned in HL)
        ; calculate number of bytes to fill (i.e. end_address - start_address)
        or      A                       ; clear Carry flag before doing sbc
        sbc     HL, DE                  ; HL = param2 - param1
        push    HL                      ; backup diff (param2 - param1)
        ; get param3 (byte)
        ld      B, 3
        call    get_param_pointer
        ld      D, (HL)                 ; copy contents
        inc     HL                      ;   of param
        ld      E, (HL)                 ;   into DE
        ld      H, D                    ; and then
        ld      L, E                    ;   into HL
        call    F_KRN_ASCII_TO_HEX      ; convert it into Hex (returned in A)
        
        pop     BC                      ; restore diff in BC to use it as byte counter
        pop     HL                      ; restore param1 (start address) in Hex
        call    F_KRN_SETMEMRNG         ; fill memory range

        jp      main_loop
; -----------------------------------------------------------------------------
cmd_display_mem:
; display memory as a hexadecimal dump.
; Syntax: M <start_address_in_hex> <end_address_in_hex>
        ; get param1 (start_address)
        ld      B, 1
        call    get_param_pointer
        ld      DE, buff_parm1          ; will copy param to buff1
        ld      BC, 4                   ; 4 bytes (an address)
        ldir                            ;   to copy
        ; get param2 (end_address)
        ld      B, 2
        call    get_param_pointer
        ld      DE, buff_parm2          ; will copy param to buff1
        ld      BC, 4                   ; 4 bytes to copy
        ldir                            ;   to copyldir
        ; convert param1 from ASCII to Hex
        ld      IX, buff_parm1          ; and convert it
        call    F_KRN_ASCIIADR_TO_HEX   ;    into Hex
        push    HL                      ; backup Hex value
        ; convert param2 from ASCII to Hex
        ld      IX, buff_parm2          ; and convert it
        call    F_KRN_ASCIIADR_TO_HEX   ;    into Hex
        ex      DE, HL                  ; copy Hex value to DE

        ; Print header
        ld      HL, msg_header
        call    F_KRN_SERIAL_WRSTR
        pop     HL                      ; restore parm1 in Hex (pointer to byte)
_start_dump_line:
        ld      C, LINESPERPAGE         ; lines printed counter
_dump_line_loop:
        call    _dump_line
        push    HL                      ; backup pointer to byte
        or      A                       ; clear Carry flag before doing sbc
        sbc     HL, DE                  ; have we reached the end address?
                                        ; Carry flag set if sbc result in 0 or negative
        pop     HL                      ; restore pointer to byte
        jr      c, _dump_next           ; if sbc resulted in Carry, dump another line
        jp      main_loop               ; otherwise, end
_dump_next:
        dec     C                       ; decrement lines printed counter
        jr      z, _askmoreorquit       ; if we printed all lines per page, ask if wants more
        jr      _dump_line_loop         ; otherwise, print more lines
_askmoreorquit:
        push    HL                      ; backup pointer to byte
        ld      HL, msg_moreorquit
        call    F_KRN_SERIAL_WRSTR
        call    F_BIOS_SERIAL_CONIN_A
        cp      SPACE                   ; if user pressed <SPACE>,
        jr      z, _wantsmore           ;   wants more lines dumped
        pop     HL                      ; restore pointer to byte
        jp      main_loop               ; if user pressed something else, end
_wantsmore:
        ld      HL, msg_header
        call    F_KRN_SERIAL_WRSTR
        pop     HL                      ; restore pointer to byte
        jp      _start_dump_line

        ; Display address, 16 bytes in hexadecimal and the same bytes in ASCII
_dump_line:
        ; Print CR + LF + address + separator (:<space>)
        push    HL                      ; backup pointer to byte
        ld      A, CR
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, LF
        call    F_BIOS_SERIAL_CONOUT_A
        call    F_KRN_SERIAL_PRN_WORD
        ld      A, ':'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 16                   ; byte counter = 16 bytes to be printed
        ; Print bytes in Hexadecimal
_dump_loop:
        ld      A, (HL)                 ; get byte
        call    F_KRN_SERIAL_PRN_BYTE   ; print it
        ld      A, ' '                  ; print
        call    F_BIOS_SERIAL_CONOUT_A  ;   separator
        inc     HL                      ; point to next byte
        djnz    _dump_loop              ; repeat until byte counter is 0
        ; Print bytes in ASCII
        pop     HL                      ; restore pointer to byte
        ld      B, 16                   ; byte counter = 16 bytes to be printed
        ld      A, ' '                  ; Print
        call    F_BIOS_SERIAL_CONOUT_A  ;   a separator
        call    F_BIOS_SERIAL_CONOUT_A  ;   of two <space>
_ascii_loop:
        ld      A, (HL)                 ; get byte
        call    F_KRN_IS_PRINTABLE      ; if byte is an ASCII character
        jr      c, _printable           ;   print it as ASCII
        ld      A, '.'                  ;   otherwise print just a dot
_printable:
        call    F_BIOS_SERIAL_CONOUT_A
        inc     HL                      ; point to next byte
        djnz    _ascii_loop             ; repeat until byte counter is 0
        ret
; -----------------------------------------------------------------------------
cmd_poke:
; modify a single memory address (poke) with a specified value.
; Syntax: P <address_in_hex> <byte_in_hex>
        ; get param1 (start_address)
        ld      B, 1
        call    get_param_pointer
        ld      DE, buff_parm1          ; will copy param to buff1
        ld      BC, 4                   ; 4 bytes (an address)
        ldir                            ;   to copy
        ; convert param1 from ASCII to Hex
        ld      IX, buff_parm1          ; and convert it
        call    F_KRN_ASCIIADR_TO_HEX   ;    into Hex
        push    HL                      ; backup Hex value (start_address)
        ; get param2 (byte)
        ld      B, 2
        call    get_param_pointer
        ld      D, (HL)                 ; copy contents
        inc     HL                      ;   of param
        ld      E, (HL)                 ;   into DE
        ld      H, D                    ; and then
        ld      L, E                    ;   into HL
        call    F_KRN_ASCII_TO_HEX      ; convert it into Hex (returned in A)
        pop     HL                      ; restore start_address in Hex
        ld      (HL), A                 ; Store <byte> in <address>
        jp      main_loop
; -----------------------------------------------------------------------------
cmd_peek:
; display the value from a memory address (peek).
; Syntax: P <address_in_hex>
        ; get param1 (start_address)
        ld      B, 1
        call    get_param_pointer
        ld      DE, buff_parm1          ; will copy param to buff1
        ld      BC, 4                   ; 4 bytes (an address)
        ldir                            ;   to copy
        ; convert param1 from ASCII to Hex
        ld      IX, buff_parm1          ; and convert it
        call    F_KRN_ASCIIADR_TO_HEX   ;    into Hex
        ; get byte at <address> and print it
        ld      B, 1                    ; print 1
        call    F_KRN_SERIAL_EMPTYLINES ;   empty line
        ld      A, (HL)                 ; byte at <address>
        call    F_KRN_SERIAL_PRN_BYTE   ; print byte in hexadecimal notation
        jp      main_loop
; -----------------------------------------------------------------------------
; cmd_save_to_disk:
; save the contents of memory onto disk.
; Syntax: S <filename> <start_address_in_hex> <end_address_in_hex>
; ; -----------------------------------------------------------------------------
cmd_transfer:
; transfer segments of memory from one memory area to another.
; Syntax: T <start_address_in_hex> <end_address_in_hex> <start_destination_address>
        ; get param1 (start_address)
        ld      B, 1
        call    get_param_pointer
        ld      DE, buff_parm1          ; copy param to buff1
        ld      BC, 4                   ; 4 bytes (an address)
        ldir                            ;   to copy
        ; get param2 (end_address)
        ld      B, 2
        call    get_param_pointer
        ld      DE, buff_parm2          ; copy param to buff1
        ld      BC, 4                   ; 4 bytes (an address)
        ldir                            ;   to copy
        ; get param3 (start_destination_address)
        ld      B, 3
        call    get_param_pointer
        ld      DE, buff_parm3          ; copy param to buff1
        ld      BC, 4                   ; 4 bytes (an address)
        ldir                            ;   to copy

        ld      IX, buff_parm1          ; convert
        call    F_KRN_ASCIIADR_TO_HEX   ;    into Hex
        ld      (buff_parm1), HL        ;   and store in memory
        ld      IX, buff_parm2          ; convert
        call    F_KRN_ASCIIADR_TO_HEX   ;    into Hex
        ld      (buff_parm2), HL        ;   and store in memory
        ld      IX, buff_parm3          ; convert
        call    F_KRN_ASCIIADR_TO_HEX   ;    into Hex
        ld      (buff_parm3), HL        ;   and store in memory

        ; calculate number of bytes to transfer (i.e. end_address - start_address)
        ld      DE, (buff_parm1)        ; DE = start address
        ld      HL, (buff_parm2)        ; HL = end address
        or      A                       ; clear Carry flag before doing sbc
        sbc     HL, DE                  ; HL = end - start
        inc     HL                      ; add inclusive end address
        ld      B, H                    ; store number of bytes in BC
        ld      C, L                    ;   to be used as byte counter for ldir
        ; do the transfer
        ld      HL, (buff_parm1)        ; HL = start address
        ld      DE, (buff_parm3)        ; HL = start destination address
        ldir
        jp      main_loop
; -----------------------------------------------------------------------------
cmd_exit:
; exit back to OS.
        ld      HL, msg_goodbye
        call    F_KRN_SERIAL_WRSTR
        ld      HL, (CLI_prompt_addr)
        jp      (HL)                    ; return control to CLI
; -----------------------------------------------------------------------------
get_param_pointer:
; IN <= B = parameter number to point to
; OUT => HL = address where parameter starts
        ld      HL, CLI_buffer_full_cmd ; read bytes from CLI buffer
_get_param_loop:
        ld      A, (HL)                 ; get character
        cp      SPACE                   ; if is an SPACE
        jr      z, _space_found         ;   we found <space>
        inc     HL                      ; otherwise, loop
        jr      _get_param_loop         ;   for next character
_space_found:
        inc     HL                      ; move pointer to next character (to skip <space>)
        djnz    _get_param_loop         ; loop until found parameter number
        ret                             ; if found, return
;==============================================================================
; BUFFERS
;==============================================================================
buff_parm1:     .FILL   4, 0            ; 1st param is always an address (4 bytes)
buff_parm2:     .FILL   12, 0           ; 2nd param can be an address (4 bytes), a byte, or an assembly instruction (many bytes)
buff_parm3:     .FILL   14, 0           ; 3rd param can be an address (4 bytes), a byte, or a filename (14 bytes max.)
;==============================================================================
; MESSAGES
;==============================================================================
msg_welcome:
        .BYTE   CR, LF, CR, LF
        .BYTE   "Machine Language Monitor v0.1.0 (beta)", 0
msg_goodbye:
        .BYTE   CR, LF
        .BYTE   "Goodbye!", 0
msg_prompt:
        .BYTE   CR, LF
        .BYTE   ". ", 0
msg_header:
        .BYTE   CR, LF
        .BYTE   "      00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F"
        .BYTE   CR, LF
        .BYTE   "      .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. ..", 0
msg_moreorquit:
        .BYTE   CR, LF
        .BYTE   "(SPACE) for more, or another key to stop.", 0
;------------------------------------------------------------------------------
; Error Messages
;------------------------------------------------------------------------------
error_cmd_unknown:
        .BYTE   CR, LF
        .BYTE   "Command unknown", CR, LF, 0
; error_bad_params:
;         .BYTE   CR, LF
;         .BYTE   "Bad parameter(s)", CR, LF, 0

        .END