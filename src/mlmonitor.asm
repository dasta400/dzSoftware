;******************************************************************************
; Name:         mlmonitor.asm
; Description:  Machine Language Monitor
;               Done:
;                   - C - Call.
;                   - E - Enter program in Hexadecimal.
;                   - F - Fill a range of locations with a specified byte.
;                   - M - Display memory as a hexadecimal dump.
;                   - P - Modify a single memory address (poke) with a specified value.
;                   - T - Transfer segments of memory from one memory area to another.
;                   - Y - Display the value (peek) from a memory address.
;                   - X - Exit Monitor back to OS.
;               Partially working:
;                   - D - Disassemble machine code into assembly language mnemonics and operands.
;                   - A - Assemble a line of assembly code.
;               To Do:
;                   - L - Load data from disk into memory.
;                   - Q - Modify a single video memory address (vpoke) with a specified value.
;                   - S - Save the contents of memory onto disk.
;                   - V - Display video memory (vmemdump) as a hexadecimal dump.
;                   - Z - Display the value (vpeek) from a video memory address.
; Author:       David Asta
; License:      The MIT License 
; Created:      5 Sep 2023
; Version:      0.4.0 (beta)
; Last Modif.:  22 Nov 2023
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
        cp      'A'
        jp      z, cmd_assemble
        cp      'C'
        jp      z, cmd_call
        cp      'D'
        jp      z, cmd_disassemble
        cp      'E'
        jp      z, cmd_enterhex
        cp      'F'
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
cmd_assemble:
; assemble a line of assembly code.
; Syntax: A <address_in_hex> <mnemonic> <operands>

        ; get pointer to operands (3rd param)
        ld      B, 3
        call    get_param_pointer
        ex      DE, HL                  ; DE = pointer 3rd param
        ; get pointer to mnemonic (2nd param)
        ld      B, 2
        call    get_param_pointer
        push    HL                      ; backup pointer 2nd param
        ; calculate number of bytes between 3rd and 2nd param (i.e. length of mnemonic)
        or      A                       ; clear Carry flag
        ex      DE, HL                  ; DE = pointer 2nd param
                                        ; HL = pointer 3rd param
        sbc     HL, DE                  ; HL = length of mnemonic + <space>
        cp      CR
        jr      z, _has_no_operands
        dec     HL                      ; discount 1 for the <space>
_has_no_operands:
        ; copy mnemonic to mem buffer
        ld      B, H                    ; total number of bytes
        ld      C, L                    ;   to copy
        pop     HL                      ; restore pointer 2nd param
        ld      DE, buff_parm2          ; will copy into buff_parm2
        ldir
        ; copy address_in_hex (1st param) to mem buffer
        ld      B, 1
        call    get_param_pointer
        ld      DE, buff_parm1
        ld      BC, 4
        ldir
        ; and convert it into hexadecimal
        ld      IX, buff_parm1
        call    F_KRN_ASCIIADR_TO_HEX
        ld      (buff_parm1), HL

        call    _parse_and_jump
        jr      c, _mnemonic_unknown

        jp      main_loop

_mnemonic_unknown:
        ld      HL, error_unknown_mnemonic
        call    F_KRN_SERIAL_WRSTR
        jp      main_loop

_parse_and_jump:
        ld      B, 0                    ; subroutine counter
_parse_loop:
        ld      HL, 0                   ; reset HL
        ld      A, B                    ; If checking the first mnemonic
        cp      0                       ;   (i.e. 0), don't need to calculate
        jp      z, _parse_get           ;   the extra offset
        cp      JMPTABLE_LENGTH         ; If all commands in jump table
        ccf                             ;   were checked already
        ret     c                       ;   return with Carry Flag set
        ld      DE, 2                   ; If not 1st mnemonic, then needs
        push    BC                      ;   an offset of 2 bytes for each
        call    F_KRN_MULTIPLY816_SLOW  ;   value in the table
        pop     BC                      ; restore subroutine counter
_parse_get:
        call    _parse_get_from_jtable  ; get mnemonic address from jump table
        ld      HL, buff_parm2          ; Compare mnemonic
        ld      A, (HL)                 ;    in jump table
        call    _search_mnemonic        ;    with mnemonic entered by user
        jp      z, _parse_do_jmptable   ; is the same? Yes, jump to subroutine
        inc     B                       ; No, increment subroutine counter
        jp      _parse_loop             ;     and check next mnemonic in jump table
_parse_do_jmptable:
        ld      A, B                    ; If subroutine number
        cp      JMPTABLE_LENGTH         ;   is invalid
        ccf                             ;   then set Carry flag
        ret     c                       ;   and return

        add     A, A                    ; double index for word length entries
        ld      HL, MNEMONICS_JMPTABLE  ; HL = pointer to jump table
        add     A, L                    ; A = points to subroutine in jump table
        ld      L, A                    ; Copy subroutine address
        xor     A                       ;   within jump table
        adc     A, H                    ;   to
        ld      H, A                    ;   HL
        ld      A, (HL)                 ; Copy address
        inc     HL                      ;   of subroutine
        ld      H, (HL)                 ;   from 
        ld      L, A                    ;   jump table
        ex      (SP), HL                ;   to Stack Pointer, so that when
        ret                             ;   doing ret it goes to the address

_parse_get_from_jtable:
        ld      DE, MNEMONICS_TABLE     ; DE = points to list of commands table
        add     HL, DE                  ; HL = points to subroutine number (with offset)
        ld      E, (HL)                 ; Copy address
        inc     HL                      ;   to
        ld      D, (HL)                 ;   DE
        ret

_search_mnemonic:
        dec     DE
_search_loop:
        cp      ' '                     ; is it a space (start parameter)?
        ret     z                       ; yes, return
        inc     DE                      ; no, continue checking
        ld      A, (DE)
        cpi                             ; compare content of A with HL, and increment HL
        jp      z, _test_end_hl         ; A = (HL)
        ret     nz
_test_end_hl:                           ; check if end (0) was reached on buffered command
        ld      A, (HL)
        cp      0
        jp      z, _test_end_de
        jp      _search_loop
_test_end_de:                           ; check if end (0) was reached on command to check against to
        inc     DE
        ld      A, (DE)
        cp      0
        ret
_put_byte:
        ld      HL, (buff_parm1)
        ld      (HL), A
        jp      main_loop
_put_byte_ret:
        ld      HL, (buff_parm1)
        ld      (HL), A
        ret
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
cmd_disassemble:
; disassemble machine code into assembly language mnemonics and operands.
; Syntax: D <start_address_in_hex> <end_address_in_hex>
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
        ld      (buff_parm2), HL        ; store end_address in Hex in memory
        ; calculate number of bytes to disassemble (end_addr - start_addr)
        or      A                       ; clear Carry flag
        sbc     HL, DE                  ; end_addr - start_addr
        inc     HL                      ; add 1 to account for first address (0)
        ld      (byte_counter), HL      ; store counter in memory

        pop     IX                      ; restore start_address in Hex

        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
_disasm_loop:
        ld      (cur_addr), IX
        ; print address and separator (:<space>)
        ld      HL, (cur_addr)
        call    F_KRN_SERIAL_PRN_WORD
        ld      A, ':'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A

        ld      A, (IX)                 ; get byte (opcode) from address
        ; test for special opcodes
        cp      $CB
        jp      z, _opcode_CB
        cp      $DD
        jp      z, _opcode_DD
        cp      $ED
        jp      z, _opcode_ED
        cp      $FD
        jp      z, _opcode_FD
        ; normal opcodes
        ld      DE, JMPTAB
        ; get corresponding opcode address in jump table
        call    _get_opcode_addr
        ; print mnemonic
_after_opcode_addr:
        call    _print_mnemonic         ; print mnemonic and optional operands
        inc     IX                      ; point to next byte
        ld      (cur_addr), IX          ; store address pointed in memory
        ; check if we finished (i.e. reached end_address)
        ld      HL, (buff_parm2)        ; load end_address
        ld      DE, (cur_addr)
        or      A                       ; clear Carry flag before doing sbc
        sbc     HL, DE                  ; HL = end_addr - start_addr
        jr      nc, _disasm_loop        ; if result of sbc is >= 0 then continue
        jp      main_loop               ;   otherwise, end
_get_opcode_addr:                       ; get opcode's address in jump table
; DE must contain the address of a jump table (JMPTABx)
        ld      H, 0                    ; initialise H
        ld      L, A                    ; L = opcode
        add     HL, HL                  ; opcodes in table are 2 bytes long
        add     HL, DE                  ; add address from jump table
        ld      A, (HL)                 ; get address' 1st byte
        inc     HL
        ld      H, (HL)                 ; put address' 2nd byte in H
        ld      L, A                    ; put address' 1st byte in L
        ret

_print_mnemonic:
        ld      A, (HL)                 ; character from mnemonic
        cp      0                       ; repeat
        jr      z, _end_prt             ;   until character is 0
        cp      '!'                     ; branch if need
        jr      z, _print_byte          ;   to print a byte
        cp      '$'                     ; branch if need
        jr      z, _print_word          ;   to print a word
        cp      '@'                     ; branch if need
        jr      z, _print_addr          ;   to print an address
        call    F_BIOS_SERIAL_CONOUT_A  ; otherwise, print character
        inc     HL                      ; point to next character
        jr      _print_mnemonic         ; repeat
_end_prt:                               ; mnemonic and operands printed
        ld      B, 1                    ; print an empty line
        call    F_KRN_SERIAL_EMPTYLINES ;   as separator
        ret                             ; and return to loop
_print_byte:
        ld      A, '$'                  ; will print symbol that indicates Hex
        call    F_BIOS_SERIAL_CONOUT_A  ;   in front of bytes
        push    HL                      ; backup pointer to operands characters
        inc     IX                      ; point to next byte in memory
        push    IX                      ; copy pointer bytes in memmory
        pop     HL                      ;   into HL
        ld      A, (HL)                 ; load byte to print
        call    F_KRN_SERIAL_PRN_BYTE
        pop     HL                      ; restore pointer to operands characters
        inc     HL                      ; point to next character
        jr      _print_mnemonic         ; continue printing
_print_word:
        ld      A, '$'                  ; will print symbol that indicates Hex
        call    F_BIOS_SERIAL_CONOUT_A  ;   in front of bytes
        push    HL                      ; backup pointer to operands characters
        inc     IX                      ; point to MSB
        inc     IX                      ;   of next byte in memory
        push    IX                      ; copy pointer bytes in memmory
        pop     HL                      ;   into HL
        ld      A, (HL)                 ; load byte to print
        call    F_KRN_SERIAL_PRN_BYTE
        dec     IX                      ; point to LSB of next byte in memory
        push    IX                      ; copy pointer bytes in memmory
        pop     HL                      ;   into HL
        ld      A, (HL)                 ; load byte to print
        call    F_KRN_SERIAL_PRN_BYTE
        inc     IX                      ; skip byte that we just processed
        pop     HL                      ; restore pointer to operands characters
        inc     HL                      ; point to next character
        jr      _print_mnemonic         ; continue printing
_print_addr:
        ld      A, '$'                  ; will print symbol that indicates Hex
        call    F_BIOS_SERIAL_CONOUT_A  ;   in front of addresses
        push    HL                      ; backup pointer to operands characters
        inc     IX                      ; address is 2 bytes
        inc     IX                      ;   point to MSB
        push    IX                      ; copy pointer
        pop     HL                      ;   into HL
        ld      A, (HL)                 ; load byte to print
        call    F_KRN_SERIAL_PRN_BYTE
        dec     HL                      ; point to LSB
        ld      A, (HL)                 ; load byte to print
        call    F_KRN_SERIAL_PRN_BYTE
        pop     HL                      ; restore pointer to operands characters
        inc     HL                      ; point to next character
        jr      _print_mnemonic         ; continue printing
; Special opcodes have another byte that determines the mnemonic,
;   instead of being the opcode itself
_opcode_CB:
        ld      DE, JMPTAB_CB           ; load jumptable addrees into DE
        jr      _special_opcode
_opcode_DD:
        ld      DE, JMPTAB_DD           ; load jumptable addrees into DE
        jr      _special_opcode
_opcode_ED:
        ld      DE, JMPTAB_ED           ; load jumptable addrees into DE
        jr      _special_opcode
_opcode_FD:
        ld      DE, JMPTAB_FD           ; load jumptable addrees into DE
        jr      _special_opcode
_special_opcode:
        inc     IX                      ; point to "another byte"
        ld      (cur_addr), IX          ; update cur_addr
        ld      A, (IX)                 ; load character
        call    _get_opcode_addr
        jp      _after_opcode_addr
; -----------------------------------------------------------------------------
cmd_enterhex:
; allow user to enter hex values strating at a specific address.
; Syntax: E <address_in_hex>
        ; print CR+LF
        ld      A, CR
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, LF
        call    F_BIOS_SERIAL_CONOUT_A
        ; get param1 (start_address)
        ld      B, 1
        call    get_param_pointer
        ld      DE, buff_parm1          ; will copy param to buff1
        ld      BC, 4                   ; 4 bytes (an address)
        ldir                            ;   to copy
        ; convert param1 from ASCII to Hex
        ld      IX, buff_parm1          ; and convert it
        call    F_KRN_ASCIIADR_TO_HEX   ;    into Hex
enterhex_loop:
        push    HL                      ; backup Hex value (start_address)
        ; print current address
        ld      A, H                    ; get address high byte
        call    F_KRN_HEX_TO_ASCII      ; convert it to ASCII
        ld      A, H                    ; print
        call    F_BIOS_SERIAL_CONOUT_A  ;   high byte
        ld      A, L                    ; print
        call    F_BIOS_SERIAL_CONOUT_A  ;   low byte
        pop     HL                      ; restore address
        push    HL                      ; backup address
        ld      A, L                    ; get address low byte
        call    F_KRN_HEX_TO_ASCII      ; convert it to ASCII
        ld      A, H                    ; print
        call    F_BIOS_SERIAL_CONOUT_A  ;   high byte
        ld      A, L                    ; print
        call    F_BIOS_SERIAL_CONOUT_A  ;   low byte
        ; print a space separator
        ld      A, SPACE
        call    F_BIOS_SERIAL_CONOUT_A
        ; print value at current address
        pop     HL                      ; restore address
        push    HL                      ; backup address
        ld      A, (HL)                 ; load value at address
        call    F_KRN_HEX_TO_ASCII      ; convert it to ASCII
        ld      A, H                    ; print
        call    F_BIOS_SERIAL_CONOUT_A  ;   high byte
        ld      A, L                    ; print
        call    F_BIOS_SERIAL_CONOUT_A  ;   low byte
        ; print a space separator
        ld      A, SPACE
        call    F_BIOS_SERIAL_CONOUT_A
        ; ask for new value entered by user
        call    F_BIOS_SERIAL_CONIN_A   ; high byte
        cp      CR                      ; if it was just ENTER pressed
        jr      z, enterhex_end         ;   exit from this command
        call    F_BIOS_SERIAL_CONOUT_A  ; print it
        ld      H, A                    ; store it in H
        call    F_BIOS_SERIAL_CONIN_A   ; low byte
        cp      CR                      ; if it was just ENTER pressed
        jr      z, enterhex_end         ;   exit from this command
        call    F_BIOS_SERIAL_CONOUT_A  ; print it
        ld      L, A                    ; store it in L
        call    F_KRN_ASCII_TO_HEX      ; convert ASCII HL to hex A
        push    AF                      ; backup hex A
        ; print CR+LF
        ld      A, CR
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, LF
        call    F_BIOS_SERIAL_CONOUT_A
        ; store new value in memory address
        pop     AF                      ; restore hex A
        pop     HL                      ; restore address
        ld      (HL), A                 ; put A in address
        inc     HL                      ; point to next address
        jp      enterhex_loop           ; repeat
enterhex_end:
        jp      main_loop
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
        ; Convert param1 from ASCII to Hexadecimal
        ld      IX, buff_parm1
        call    F_KRN_ASCIIADR_TO_HEX
        ; get byte at <address> and print it
        ld      B, 1                    ; print 1
        call    F_KRN_SERIAL_EMPTYLINES ;   empty line
        ld      A, (HL)                 ; byte at <address>
        call    F_KRN_SERIAL_PRN_BYTE   ; print byte in hexadecimal notation
        jp      main_loop
; -----------------------------------------------------------------------------
; cmd_save_to_disk:
; ; save the contents of memory onto disk.
; ; Syntax: S <filename> <start_address_in_hex> <end_address_in_hex>
;         jp      main_loop
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
; Assembler subroutines
;==============================================================================
subr_ADC:
        jp      main_loop
subr_ADD:
        jp      main_loop
subr_AND:
        jp      main_loop
subr_BIT:
        jp      main_loop
subr_CALL:
        jp      main_loop
subr_CCF:
        ld      A, $3F
        jp      _put_byte
subr_CP:
        jp      main_loop
subr_CPD:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $A9
        jp      _put_byte
subr_CPDR:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $B9
        jp      _put_byte
subr_CPI:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $A1
        jp      _put_byte
subr_CPIR:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $B1
        jp      _put_byte
subr_CPL:
        ld      A, $2F
        jp      _put_byte
subr_DAA:
        ld      A, $27
        jp      _put_byte
subr_DEC:
        jp      main_loop
subr_DI:
        ld      A, $F3
        jp      _put_byte
subr_DJNZ:
        ld      A, $10
        jp      _put_byte
subr_EI:
        ld      A, $FB
        jp      _put_byte
subr_EX:
        jp      main_loop
subr_EXX:
        ld      A, $D9
        jp      _put_byte
subr_HALT:
        ld      A, $76
        jp      _put_byte
subr_IM:
        jp      main_loop
subr_IN:
        jp      main_loop
subr_INC:
        ; get pointer to operands (3rd param)
        ld      B, 3
        call    get_param_pointer       ; HL = pointer
        ld      A, (HL)
        cp      'A'
        jp      z, _inc_A
        cp      'B'
        jp      z, _inc_B
        cp      'C'
        jp      z, _inc_C
        cp      'D'
        jp      z, _inc_D
        cp      'E'
        jp      z, _inc_E
        cp      'H'
        jp      z, _inc_H
        cp      'L'
        jp      z, _inc_L
        cp      'S'
        jp      z, _inc_SP
        cp      'I'
        jp      z, _inc_I
        jp      main_loop
        ;  _____     ____
        ; |_   _|__ |  _ \  ___
        ;   | |/ _ \| | | |/ _ \
        ;   | | (_) | |_| | (_) |       INC (HL), INC (IX+N), INC (IY+N)
        ;   |_|\___/|____/ \___/
_inc_A:
        ld      A, $3C
        jp      _do_inc
_inc_B:
        ; check if next character is C
        inc     HL
        ld      A, (HL)
        cp      'C'
        jp      z, _inc_BC
        ld      A, $04
        jp      _do_inc
_inc_C:
        ld      A, $0C
        jp      _do_inc
_inc_BC:
        ld      A, $03
        jp      _do_inc
_inc_D:
        ; check if next character is E
        inc     HL
        ld      A, (HL)
        cp      'E'
        jp      z, _inc_DE
        ld      A, $14
        jp      _do_inc
_inc_E:
        ld      A, $1C
        jp      _do_inc
_inc_DE:
        ld      A, $13
        jp      _do_inc
_inc_H:
        ; check if next character is L
        inc     HL
        ld      A, (HL)
        cp      'L'
        jp      z, _inc_HL
        ld      A, $24
        jp      _do_inc
_inc_L:
        ld      A, $2C
        jp      _do_inc
_inc_HL:
        ld      A, $23
        jp      _do_inc
_inc_SP:
        ld      A, $33
        jp      _do_inc
_inc_I:
        ; check if next character is X or Y
        inc     HL
        ld      A, (HL)
        cp      'X'
        jp      z, _inc_IX
        cp      'Y'
        jp      z, _inc_IY
        jp      main_loop
_inc_IX:
        ld      A, $DD
        call    _do_inc_ret
_inc_I_common:
        inc     HL
        ld      A, $23
        ld      (HL), A
        jp      main_loop
_inc_IY:
        ld      A, $FD
        call    _do_inc_ret
        jr      _inc_I_common
_do_inc:
        ld      HL, (buff_parm2)
        ld      (HL), A
        jp      main_loop
_do_inc_ret:
        ld      HL, (buff_parm2)
        ld      (HL), A
        ret
subr_IND:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $AA
        jp      _put_byte
subr_INDR:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $BA
        jp      _put_byte
subr_INI:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $A2
        jp      _put_byte
subr_INIR:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $B2
        jp      _put_byte
subr_JP:
        jp      main_loop
subr_JR:
        jp      main_loop
subr_LD:
        jp      main_loop
subr_LDD:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $A8
        jp      _put_byte
subr_LDDR:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $B8
        jp      _put_byte
subr_LDI:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $A
        jp      _put_byte
subr_LDIR:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $B0
        jp      _put_byte
subr_NEG:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $44
        jp      _put_byte
subr_NOP:
        ld      A, $00
        jp      _put_byte
subr_OR:
        jp      main_loop
subr_OUT:
        jp      main_loop
subr_OUTD:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $AB
        jp      _put_byte
subr_OTDR:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $BB
        jp      _put_byte
subr_OUTI:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $A3
        jp      _put_byte
subr_OTIR:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $B3
        jp      _put_byte
subr_POP:
        jp      main_loop
subr_PUSH:
        jp      main_loop
subr_RES:
        jp      main_loop
subr_RET:
        ld      A, $C9
        jp      _put_byte
subr_RETI:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $4D
        jp      _put_byte
subr_RETN:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $45
        jp      _put_byte
subr_RLA:
        ld      A, $17
        jp      _put_byte
subr_RL:
        jp      main_loop
subr_RLCA:
        ld      A, $07
        jp      _put_byte
subr_RLC:
        jp      main_loop
subr_RLD:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $6F
        jp      _put_byte
subr_RRA:
        ld      A, $1F
        jp      _put_byte
subr_RR:
        jp      main_loop
subr_RRCA:
        ld      A, $0F
        jp      _put_byte
subr_RRC:
        jp      main_loop
subr_RRD:
        ld      A, $ED
        call    _put_byte_ret
        ld      A, $67
        jp      _put_byte
subr_RST:
        jp      main_loop
subr_SBC:
        jp      main_loop
subr_SCF:
        ld      A, $37
        jp      _put_byte
subr_SET:
        jp      main_loop
subr_SLA:
        jp      main_loop
subr_SRA:
        jp      main_loop
subr_SLL:
        jp      main_loop
subr_SRL:
        jp      main_loop
subr_SUB:
        jp      main_loop
subr_XOR:
        jp      main_loop
;==============================================================================
; BUFFERS
;==============================================================================
buff_parm1:     .FILL   4, 0            ; 1st param is always an address (4 bytes)
buff_parm2:     .FILL   12, 0           ; 2nd param can be an address (4 bytes), a byte, or an assembly instruction (many bytes)
buff_parm3:     .FILL   14, 0           ; 3rd param can be an address (4 bytes), a byte, or a filename (14 bytes max.)
cur_addr:       .FILL   2, 0
byte_counter:   .FILL   2, 0
;==============================================================================
; MESSAGES
;==============================================================================
msg_welcome:
        .BYTE   CR, LF, CR, LF
        .BYTE   "Machine Language Monitor v0.3.0 (beta)", 0
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
error_bad_params:
        .BYTE   CR, LF
        .BYTE   "Bad parameter(s)", CR, LF, 0
error_unknown_mnemonic:
        .BYTE   CR, LF
        .BYTE   "Unknown mnemonic", CR, LF, 0
;==============================================================================
; DATA for Assembler
;==============================================================================
JMPTABLE_LENGTH     .EQU    68           ; Number of mnemonics in tables

_ADC    .BYTE   "adc", 0
_ADD    .BYTE   "add", 0
_AND    .BYTE   "and", 0
_BIT    .BYTE   "bit", 0
_CALL   .BYTE   "call", 0
_CCF    .BYTE   "ccf", 0
_CP     .BYTE   "cp", 0
_CPD    .BYTE   "cpd", 0
_CPDR   .BYTE   "cpdr", 0
_CPI    .BYTE   "cpi", 0
_CPIR   .BYTE   "cpir", 0
_CPL    .BYTE   "cpl", 0
_DAA    .BYTE   "daa", 0
_DEC    .BYTE   "dec", 0
_DI     .BYTE   "di", 0
_DJNZ   .BYTE   "djnz", 0
_EI     .BYTE   "ei", 0
_EX     .BYTE   "ex", 0
_EXX    .BYTE   "exx", 0
_HALT   .BYTE   "halt", 0
_IM     .BYTE   "im", 0
_IN     .BYTE   "in", 0
_INC    .BYTE   "inc", 0
_IND    .BYTE   "ind", 0
_INDR   .BYTE   "indr", 0
_INI    .BYTE   "ini", 0
_INIR   .BYTE   "inir", 0
_JP     .BYTE   "jp", 0
_JR     .BYTE   "jr", 0
_LD     .BYTE   "ld", 0
_LDD    .BYTE   "ldd", 0
_LDDR   .BYTE   "lddr", 0
_LDI    .BYTE   "ldi", 0
_LDIR   .BYTE   "ldir", 0
_NEG    .BYTE   "neg", 0
_NOP    .BYTE   "nop", 0
_OR     .BYTE   "or", 0
_OUT    .BYTE   "out", 0
_OUTD   .BYTE   "outd", 0
_OTDR   .BYTE   "otdr", 0
_OUTI   .BYTE   "outi", 0
_OTIR   .BYTE   "otir", 0
_POP    .BYTE   "pop", 0
_PUSH   .BYTE   "push", 0
_RES    .BYTE   "res", 0
_RET    .BYTE   "ret", 0
_RETI   .BYTE   "reti", 0
_RETN   .BYTE   "retn", 0
_RLA    .BYTE   "rla", 0
_RL     .BYTE   "rl", 0
_RLCA   .BYTE   "rlca", 0
_RLC    .BYTE   "rlc", 0
_RLD    .BYTE   "rld", 0
_RRA    .BYTE   "rra", 0
_RR     .BYTE   "rr", 0
_RRCA   .BYTE   "rrca", 0
_RRC    .BYTE   "rrc", 0
_RRD    .BYTE   "rrd", 0
_RST    .BYTE   "rst", 0
_SBC    .BYTE   "sbc", 0
_SCF    .BYTE   "scf", 0
_SET    .BYTE   "set", 0
_SLA    .BYTE   "sla", 0
_SRA    .BYTE   "sra", 0
_SLL    .BYTE   "sll", 0
_SRL    .BYTE   "srl", 0
_SUB    .BYTE   "sub", 0
_XOR    .BYTE   "xor", 0

MNEMONICS_TABLE:
        .WORD   _ADC
        .WORD   _ADD
        .WORD   _AND
        .WORD   _BIT
        .WORD   _CALL
        .WORD   _CCF
        .WORD   _CP
        .WORD   _CPD
        .WORD   _CPDR
        .WORD   _CPI
        .WORD   _CPIR
        .WORD   _CPL
        .WORD   _DAA
        .WORD   _DEC
        .WORD   _DI
        .WORD   _DJNZ
        .WORD   _EI
        .WORD   _EX
        .WORD   _EXX
        .WORD   _HALT
        .WORD   _IM
        .WORD   _IN
        .WORD   _INC
        .WORD   _IND
        .WORD   _INDR
        .WORD   _INI
        .WORD   _INIR
        .WORD   _JP
        .WORD   _JR
        .WORD   _LD
        .WORD   _LDD
        .WORD   _LDDR
        .WORD   _LDI
        .WORD   _LDIR
        .WORD   _NEG
        .WORD   _NOP
        .WORD   _OR
        .WORD   _OUT
        .WORD   _OUTD
        .WORD   _OTDR
        .WORD   _OUTI
        .WORD   _OTIR
        .WORD   _POP
        .WORD   _PUSH
        .WORD   _RES
        .WORD   _RET
        .WORD   _RETI
        .WORD   _RETN
        .WORD   _RLA
        .WORD   _RL
        .WORD   _RLCA
        .WORD   _RLC
        .WORD   _RLD
        .WORD   _RRA
        .WORD   _RR
        .WORD   _RRCA
        .WORD   _RRC
        .WORD   _RRD
        .WORD   _RST
        .WORD   _SBC
        .WORD   _SCF
        .WORD   _SET
        .WORD   _SLA
        .WORD   _SRA
        .WORD   _SLL
        .WORD   _SRL
        .WORD   _SUB
        .WORD   _XOR

MNEMONICS_JMPTABLE:
        .WORD   subr_ADC
        .WORD   subr_ADD
        .WORD   subr_AND
        .WORD   subr_BIT
        .WORD   subr_CALL
        .WORD   subr_CCF
        .WORD   subr_CP
        .WORD   subr_CPD
        .WORD   subr_CPDR
        .WORD   subr_CPI
        .WORD   subr_CPIR
        .WORD   subr_CPL
        .WORD   subr_DAA
        .WORD   subr_DEC
        .WORD   subr_DI
        .WORD   subr_DJNZ
        .WORD   subr_EI
        .WORD   subr_EX
        .WORD   subr_EXX
        .WORD   subr_HALT
        .WORD   subr_IM
        .WORD   subr_IN
        .WORD   subr_INC
        .WORD   subr_IND
        .WORD   subr_INDR
        .WORD   subr_INI
        .WORD   subr_INIR
        .WORD   subr_JP
        .WORD   subr_JR
        .WORD   subr_LD
        .WORD   subr_LDD
        .WORD   subr_LDDR
        .WORD   subr_LDI
        .WORD   subr_LDIR
        .WORD   subr_NEG
        .WORD   subr_NOP
        .WORD   subr_OR
        .WORD   subr_OUT
        .WORD   subr_OUTD
        .WORD   subr_OTDR
        .WORD   subr_OUTI
        .WORD   subr_OTIR
        .WORD   subr_POP
        .WORD   subr_PUSH
        .WORD   subr_RES
        .WORD   subr_RET
        .WORD   subr_RETI
        .WORD   subr_RETN
        .WORD   subr_RLA
        .WORD   subr_RL
        .WORD   subr_RLCA
        .WORD   subr_RLC
        .WORD   subr_RLD
        .WORD   subr_RRA
        .WORD   subr_RR
        .WORD   subr_RRCA
        .WORD   subr_RRC
        .WORD   subr_RRD
        .WORD   subr_RST
        .WORD   subr_SBC
        .WORD   subr_SCF
        .WORD   subr_SET
        .WORD   subr_SLA
        .WORD   subr_SRA
        .WORD   subr_SLL
        .WORD   subr_SRL
        .WORD   subr_SUB
        .WORD   subr_XOR

;==============================================================================
; DATA for Disassembler
;==============================================================================
JMPTAB:     ; Jump table for opcodes' addresses in OPCODES table
        .BYTE   OP00,OP01,OP02,OP03,OP04,OP05,OP06,OP07,OP08,OP09
        .BYTE   OP0A,OP0B,OP0C,OP0D,OP0E,OP0F
        .BYTE   OP10,OP11,OP12,OP13,OP14,OP15,OP16,OP17,OP18,OP19
        .BYTE   OP1A,OP1B,OP1C,OP1D,OP1E,OP1F
        .BYTE   OP20,OP21,OP22,OP23,OP24,OP25
        .BYTE   OP30,OP31,OP32,OP33,OP34,OP35,OP36,OP37,OP38,OP39
        .BYTE   OP3A,OP3B,OP3C,OP3D,OP3E,OP3F
        .BYTE   OP40,OP41,OP42,OP43,OP44,OP45,OP46,OP47,OP48,OP49
        .BYTE   OP4A,OP4B,OP4C,OP4D,OP4E,OP4F
        .BYTE   OP50,OP51,OP52,OP53,OP54,OP55,OP56,OP57,OP58,OP59
        .BYTE   OP5A,OP5B,OP5C,OP5D,OP5E,OP5F
        .BYTE   OP60,OP61,OP62,OP63,OP64,OP65,OP66,OP67,OP68,OP69
        .BYTE   OP6A,OP6B,OP6C,OP6D,OP6E,OP6F
        .BYTE   OP70,OP71,OP72,OP73,OP74,OP75,OP76,OP77,OP78,OP79
        .BYTE   OP7A,OP7B,OP7C,OP7D,OP7E,OP7F
        .BYTE   OP80,OP81,OP82,OP83,OP84,OP85,OP86,OP87,OP88,OP89
        .BYTE   OP8A,OP8B,OP8C,OP8D,OP8E,OP8F
        .BYTE   OP90,OP91,OP92,OP93,OP94,OP95,OP96,OP97,OP98,OP99
        .BYTE   OP9A,OP9B,OP9C,OP9D,OP9E,OP9F
        .BYTE   OPA0,OPA1,OPA2,OPA3,OPA4,OPA5,OPA6,OPA7,OPA8,OPA9
        .BYTE   OPAA,OPAB,OPAC,OPAD,OPAE,OPAF
        .BYTE   OPB0,OPB1,OPB2,OPB3,OPB4,OPB5,OPB6,OPB7,OPB8,OPB9
        .BYTE   OPBA,OPBB,OPBC,OPBD,OPBE,OPBF
        .BYTE   OPC0,OPC1,OPC2,OPC3,OPC4,OPC5,OPC6,OPC7,OPC8,OPC9
        .BYTE   OPCA,OPCB,OPCC,OPCD,OPCE,OPCF
        .BYTE   OPD0,OPD1,OPD2,OPD3,OPD4,OPD5,OPD6,OPD7,OPD8,OPD9
        .BYTE   OPDA,OPDB,OPDC,OPDD,OPDE,OPDF
        .BYTE   OPE0,OPE1,OPE2,OPE3,OPE4,OPE5,OPE6,OPE7,OPE8,OPE9
        .BYTE   OPEA,OPEB,OPEC,OPED,OPEE,OPEF
        .BYTE   OPF0,OPF1,OPF2,OPF3,OPF4,OPF5,OPF6,OPF7,OPF8,OPF9
        .BYTE   OPFA,OPFB,OPFC,OPFD,OPFE,OPFF
;------------------------------------------------------------------------------
OPCODES:    ; Z80 "normal" opcodes table
;  _____     ____
; |_   _|__ |  _ \  ___
;   | |/ _ \| | | |/ _ \
;   | | (_) | |_| | (_) |       See below
;   |_|\___/|____/ \___/
OP00:   .BYTE   "nop", 0
OP01:   .BYTE   "ld BC, !!", 0
OP02:   .BYTE   "ld (BC), A", 0
OP03:   .BYTE   "inc BC", 0
OP04:   .BYTE   "inc B", 0
OP05:   .BYTE   "dec B", 0
OP06:   .BYTE   "ld B, !", 0
OP07:   .BYTE   "rlca", 0
OP08:   .BYTE   "ex AF,AF*", 0
OP09:   .BYTE   "add HL, BC", 0
OP0A:   .BYTE   "ld A, (BC)", 0
OP0B:   .BYTE   "dec BC", 0
OP0C:   .BYTE   "inc C", 0
OP0D:   .BYTE   "dec C", 0
OP0E:   .BYTE   "ld C, !", 0
OP0F:   .BYTE   "rrca", 0
OP10:   .BYTE   "djnz !", 0
OP11:   .BYTE   "ld DE, !!", 0
OP12:   .BYTE   "ld (DE), A", 0
OP13:   .BYTE   "inc DE", 0
OP14:   .BYTE   "inc D", 0
OP15:   .BYTE   "dec D", 0
OP16:   .BYTE   "ld D, !", 0
OP17:   .BYTE   "rla", 0
OP18:   .BYTE   "jr !", 0
OP19:   .BYTE   "add HL, DE", 0
OP1A:   .BYTE   "ld A, (DE)", 0
OP1B:   .BYTE   "dec DE", 0
OP1C:   .BYTE   "inc E", 0
OP1D:   .BYTE   "dec E", 0
OP1E:   .BYTE   "ld E, !", 0
OP1F:   .BYTE   "rra", 0
OP20:   .BYTE   "jr nz, !", 0
OP21:   .BYTE   "ld HL, !!", 0
OP22:   .BYTE   "ld (!!), HL", 0
OP23:   .BYTE   "inc HL", 0
OP24:   .BYTE   "inc H", 0
OP25:   .BYTE   "dec H", 0
OP26:   .BYTE   "ld H, !", 0
OP27:   .BYTE   "daa", 0
OP28:   .BYTE   "jr z, !", 0
OP29:   .BYTE   "add HL, HL", 0
OP2A:   .BYTE   "ld HL, (!!)", 0
OP2B:   .BYTE   "dec HL", 0
OP2C:   .BYTE   "inc L", 0
OP2D:   .BYTE   "dec L", 0
OP2E:   .BYTE   "ld L, !", 0
OP2F:   .BYTE   "cpl", 0
OP30:   .BYTE   "jr nc, !", 0
OP31:   .BYTE   "ld SP, !!", 0
OP32:   .BYTE   "ld (!!), A", 0
OP33:   .BYTE   "inc SP", 0
OP34:   .BYTE   "inc (HL)", 0
OP35:   .BYTE   "dec (HL)", 0
OP36:   .BYTE   "ld (HL), !", 0
OP37:   .BYTE   "scf", 0
OP38:   .BYTE   "jr c, !", 0
OP39:   .BYTE   "add HL, SP", 0
OP3A:   .BYTE   "ld A, (!!)", 0
OP3B:   .BYTE   "dec SP", 0
OP3C:   .BYTE   "inc A", 0
OP3D:   .BYTE   "dec A", 0
OP3E:   .BYTE   "ld A, !", 0
OP3F:   .BYTE   "ccf", 0
OP40:   .BYTE   "ld B, B", 0
OP41:   .BYTE   "ld B, C", 0
OP42:   .BYTE   "ld B, D", 0
OP43:   .BYTE   "ld B, E", 0
OP44:   .BYTE   "ld B, H", 0
OP45:   .BYTE   "ld B, L", 0
OP46:   .BYTE   "ld B, (HL)", 0
OP47:   .BYTE   "ld B, A", 0
OP48:   .BYTE   "ld C, B", 0
OP49:   .BYTE   "ld C, C", 0
OP4A:   .BYTE   "ld C, D", 0
OP4B:   .BYTE   "ld C, E", 0
OP4C:   .BYTE   "ld C, H", 0
OP4D:   .BYTE   "ld C, L", 0
OP4E:   .BYTE   "ld C, (HL)", 0
OP4F:   .BYTE   "ld C, A", 0
OP50:   .BYTE   "ld D, B", 0
OP51:   .BYTE   "ld D, C", 0
OP52:   .BYTE   "ld D, D", 0
OP53:   .BYTE   "ld D, E", 0
OP54:   .BYTE   "ld D, H", 0
OP55:   .BYTE   "ld D, L", 0
OP56:   .BYTE   "ld D, (HL)", 0
OP57:   .BYTE   "ld D, A", 0
OP58:   .BYTE   "ld E, B", 0
OP59:   .BYTE   "ld E, C", 0
OP5A:   .BYTE   "ld E, D", 0
OP5B:   .BYTE   "ld E, E", 0
OP5C:   .BYTE   "ld E, H", 0
OP5D:   .BYTE   "ld E, L", 0
OP5E:   .BYTE   "ld E, (HL)", 0
OP5F:   .BYTE   "ld E, A", 0
OP60:   .BYTE   "ld H, B", 0
OP61:   .BYTE   "ld H, C", 0
OP62:   .BYTE   "ld H, D", 0
OP63:   .BYTE   "ld H, E", 0
OP64:   .BYTE   "ld H, H", 0
OP65:   .BYTE   "ld H, L", 0
OP66:   .BYTE   "ld H, (HL)", 0
OP67:   .BYTE   "ld H, A", 0
OP68:   .BYTE   "ld L, B", 0
OP69:   .BYTE   "ld L, C", 0
OP6A:   .BYTE   "ld L, D", 0
OP6B:   .BYTE   "ld L, E", 0
OP6C:   .BYTE   "ld L, H", 0
OP6D:   .BYTE   "ld L, L", 0
OP6E:   .BYTE   "ld L, (HL)", 0
OP6F:   .BYTE   "ld L, A", 0
OP70:   .BYTE   "ld (HL), B", 0
OP71:   .BYTE   "ld (HL), C", 0
OP72:   .BYTE   "ld (HL), D", 0
OP73:   .BYTE   "ld (HL), E", 0
OP74:   .BYTE   "ld (HL), H", 0
OP75:   .BYTE   "ld (HL), L", 0
OP76:   .BYTE   "halt", 0
OP77:   .BYTE   "ld (HL), A", 0
OP78:   .BYTE   "ld A, B", 0
OP79:   .BYTE   "ld A, C", 0
OP7A:   .BYTE   "ld A, D", 0
OP7B:   .BYTE   "ld A, E", 0
OP7C:   .BYTE   "ld A, H", 0
OP7D:   .BYTE   "ld A, L", 0
OP7E:   .BYTE   "ld A, (HL)", 0
OP7F:   .BYTE   "ld A, A", 0
OP80:   .BYTE   "add A, B", 0
OP81:   .BYTE   "add A, C", 0
OP82:   .BYTE   "add A, D", 0
OP83:   .BYTE   "add A, E", 0
OP84:   .BYTE   "add A, H", 0
OP85:   .BYTE   "add A, L", 0
OP86:   .BYTE   "add A, (HL)", 0
OP87:   .BYTE   "add A, A", 0
OP88:   .BYTE   "adc A, B", 0
OP89:   .BYTE   "adc A, C", 0
OP8A:   .BYTE   "adc A, D", 0
OP8B:   .BYTE   "adc A, E", 0
OP8C:   .BYTE   "adc A, H", 0
OP8D:   .BYTE   "adc A, L", 0
OP8E:   .BYTE   "adc A, (HL)", 0
OP8F:   .BYTE   "adc A, A", 0
OP90:   .BYTE   "sub B", 0
OP91:   .BYTE   "sub C", 0
OP92:   .BYTE   "sub D", 0
OP93:   .BYTE   "sub E", 0
OP94:   .BYTE   "sub H", 0
OP95:   .BYTE   "sub L", 0
OP96:   .BYTE   "sub (HL)", 0
OP97:   .BYTE   "sub A", 0
OP98:   .BYTE   "sbc A, B", 0
OP99:   .BYTE   "sbc A, C", 0
OP9A:   .BYTE   "sbc A, D", 0
OP9B:   .BYTE   "sbc A, E", 0
OP9C:   .BYTE   "sbc A, H", 0
OP9D:   .BYTE   "sbc A, L", 0
OP9E:   .BYTE   "sbc A, (HL)", 0
OP9F:   .BYTE   "sbc A, A", 0
OPA0:   .BYTE   "and B", 0
OPA1:   .BYTE   "and C", 0
OPA2:   .BYTE   "and D", 0
OPA3:   .BYTE   "and E", 0
OPA4:   .BYTE   "and H", 0
OPA5:   .BYTE   "and L", 0
OPA6:   .BYTE   "and (HL)", 0
OPA7:   .BYTE   "and A", 0
OPA8:   .BYTE   "xor B", 0
OPA9:   .BYTE   "xor C", 0
OPAA:   .BYTE   "xor D", 0
OPAB:   .BYTE   "xor E", 0
OPAC:   .BYTE   "xor H", 0
OPAD:   .BYTE   "xor L", 0
OPAE:   .BYTE   "xor (HL)", 0
OPAF:   .BYTE   "xor A", 0
OPB0:   .BYTE   "or B", 0
OPB1:   .BYTE   "or C", 0
OPB2:   .BYTE   "or D", 0
OPB3:   .BYTE   "or E", 0
OPB4:   .BYTE   "or H", 0
OPB5:   .BYTE   "or L", 0
OPB6:   .BYTE   "or (HL)", 0
OPB7:   .BYTE   "or A", 0
OPB8:   .BYTE   "cp B", 0
OPB9:   .BYTE   "cp C", 0
OPBA:   .BYTE   "cp D", 0
OPBB:   .BYTE   "cp E", 0
OPBC:   .BYTE   "cp H", 0
OPBD:   .BYTE   "cp L", 0
OPBE:   .BYTE   "cp (HL)", 0
OPBF:   .BYTE   "cp A", 0
OPC0:   .BYTE   "ret nz", 0
OPC1:   .BYTE   "pop BC", 0
OPC2:   .BYTE   "jp nz, !!", 0
OPC3:   .BYTE   "jp !!", 0
OPC4:   .BYTE   "call nz, !!", 0
OPC5:   .BYTE   "push BC", 0
OPC6:   .BYTE   "add A, !", 0
OPC7:   .BYTE   "rst 00h", 0
OPC8:   .BYTE   "ret z", 0
OPC9:   .BYTE   "ret", 0
OPCA:   .BYTE   "jp z, !!", 0
OPCB:   .BYTE   "OPCB", 0
OPCC:   .BYTE   "call z, !!", 0
OPCD:   .BYTE   "call !!", 0
OPCE:   .BYTE   "adc A, !", 0
OPCF:   .BYTE   "rst 08h", 0
OPD0:   .BYTE   "ret nc", 0
OPD1:   .BYTE   "pop DE", 0
OPD2:   .BYTE   "jp nc, !!", 0
OPD3:   .BYTE   "out (!), A", 0
OPD4:   .BYTE   "call nc, !!", 0
OPD5:   .BYTE   "push DE", 0
OPD6:   .BYTE   "sub !", 0
OPD7:   .BYTE   "rst 10h", 0
OPD8:   .BYTE   "ret c", 0
OPD9:   .BYTE   "exx", 0
OPDA:   .BYTE   "jp c, !!", 0
OPDB:   .BYTE   "in A, (!)", 0
OPDC:   .BYTE   "call c, !!", 0
OPDD:   .BYTE   "OPDD", 0
OPDE:   .BYTE   "sbc A, !", 0
OPDF:   .BYTE   "rst 18h", 0
OPE0:   .BYTE   "ret po", 0
OPE1:   .BYTE   "pop HL", 0
OPE2:   .BYTE   "jp po, !!", 0
OPE3:   .BYTE   "ex (SP), HL", 0
OPE4:   .BYTE   "call po, !!", 0
OPE5:   .BYTE   "push HL", 0
OPE6:   .BYTE   "and !", 0
OPE7:   .BYTE   "rst 20h", 0
OPE8:   .BYTE   "ret pe", 0
OPE9:   .BYTE   "jp (HL)", 0
OPEA:   .BYTE   "jp pe, !!", 0
OPEB:   .BYTE   "ex DE, HL", 0
OPEC:   .BYTE   "call pe, !!", 0
OPED:   .BYTE   "OPED", 0
OPEE:   .BYTE   "xor !", 0
OPEF:   .BYTE   "rst 28h", 0
OPF0:   .BYTE   "ret p", 0
OPF1:   .BYTE   "pop AF", 0
OPF2:   .BYTE   "jp p, !!", 0
OPF3:   .BYTE   "di", 0
OPF4:   .BYTE   "call p, !!", 0
OPF5:   .BYTE   "push AF", 0
OPF6:   .BYTE   "or !", 0
OPF7:   .BYTE   "rst 30h", 0
OPF8:   .BYTE   "ret m", 0
OPF9:   .BYTE   "ld SP, HL", 0
OPFA:   .BYTE   "jp m, !!", 0
OPFB:   .BYTE   "ei", 0
OPFC:   .BYTE   "call m, !!", 0
OPFD:   .BYTE   "OPFD", 0               ; To Do
OPFE:   .BYTE   "cp !", 0
OPFF:   .BYTE   "rst 38h", 0

JMPTAB_CB:  ; Z80 "special" opcodes CB table
    .WORD CB00,CB01,CB02,CB03,CB04,CB05,CB06,CB07,CB08,CB09
    .WORD CB0A,CB0B,CB0C,CB0D,CB0E,CB0F
    .WORD CB10,CB11,CB12,CB13,CB14,CB15,CB16,CB17,CB18,CB19
    .WORD CB1A,CB1B,CB1C,CB1D,CB1E,CB1F
    .WORD CB20,CB21,CB22,CB23,CB24,CB25,CB26,CB27,CB28,CB29
    .WORD CB2A,CB2B,CB2C,CB2D,CB2E,CB2F
    .WORD CB30,CB31,CB32,CB33,CB34,CB35,CB36,CB37,CB38,CB39
    .WORD CB3A,CB3B,CB3C,CB3D,CB3E,CB3F
    .WORD CB40,CB41,CB42,CB43,CB44,CB45,CB46,CB47,CB48,CB49
    .WORD CB4A,CB4B,CB4C,CB4D,CB4E,CB4F
    .WORD CB50,CB51,CB52,CB53,CB54,CB55,CB56,CB57,CB58,CB59
    .WORD CB5A,CB5B,CB5C,CB5D,CB5E,CB5F
    .WORD CB60,CB61,CB62,CB63,CB64,CB65,CB66,CB67,CB68,CB69
    .WORD CB6A,CB6B,CB6C,CB6D,CB6E,CB6F
    .WORD CB70,CB71,CB72,CB73,CB74,CB75,CB76,CB77,CB78,CB79
    .WORD CB7A,CB7B,CB7C,CB7D,CB7E,CB7F
    .WORD CB80,CB81,CB82,CB83,CB84,CB85,CB86,CB87,CB88,CB89
    .WORD CB8A,CB8B,CB8C,CB8D,CB8E,CB8F
    .WORD CB90,CB91,CB92,CB93,CB94,CB95,CB96,CB97,CB98,CB99
    .WORD CB9A,CB9B,CB9C,CB9D,CB9E,CB9F
    .WORD CBA0,CBA1,CBA2,CBA3,CBA4,CBA5,CBA6,CBA7,CBA8,CBA9
    .WORD CBAA,CBAB,CBAC,CBAD,CBAE,CBAF
    .WORD CBB0,CBB1,CBB2,CBB3,CBB4,CBB5,CBB6,CBB7,CBB8,CBB9
    .WORD CBBA,CBBB,CBBC,CBBD,CBBE,CBBF
    .WORD CBC0,CBC1,CBC2,CBC3,CBC4,CBC5,CBC6,CBC7,CBC8,CBC9
    .WORD CBCA,CBCB,CBCC,CBCD,CBCE,CBCF
    .WORD CBD0,CBD1,CBD2,CBD3,CBD4,CBD5,CBD6,CBD7,CBD8,CBD9
    .WORD CBDA,CBDB,CBDC,CBCB,CBDE,CBDF
    .WORD CBE0,CBE1,CBE2,CBE3,CBE4,CBE5,CBE6,CBE7,CBE8,CBE9
    .WORD CBEA,CBEB,CBEC,CBED,CBEE,CBEF
    .WORD CBF0,CBF1,CBF2,CBF3,CBF4,CBF5,CBF6,CBF7,CBF8,CBF9
    .WORD CBFA,CBFB,CBFC,CBFD,CBFE,CBFF
OPCODES_CB:
CB00:   .BYTE "rlc B", 0
CB01:   .BYTE "rlc C", 0
CB02:   .BYTE "rlc D", 0
CB03:   .BYTE "rlc E", 0
CB04:   .BYTE "rlc H", 0
CB05:   .BYTE "rlc L", 0
CB06:   .BYTE "rlc (HL)", 0
CB07:   .BYTE "rlc A", 0
CB08:   .BYTE "rrc B", 0
CB09:   .BYTE "rrc C", 0
CB0A:   .BYTE "rrc D", 0
CB0B:   .BYTE "rrc E", 0
CB0C:   .BYTE "rrc H", 0
CB0D:   .BYTE "rrc L", 0
CB0E:   .BYTE "rrc (HL)", 0
CB0F:   .BYTE "rrc A", 0
CB10:   .BYTE "rl B", 0
CB11:   .BYTE "rl C", 0
CB12:   .BYTE "rl D", 0
CB13:   .BYTE "rl E", 0
CB14:   .BYTE "rl H", 0
CB15:   .BYTE "rl L", 0
CB16:   .BYTE "rl (HL)", 0
CB17:   .BYTE "rl A", 0
CB18:   .BYTE "rr B", 0
CB19:   .BYTE "rr C", 0
CB1A:   .BYTE "rr D", 0
CB1B:   .BYTE "rr E", 0
CB1C:   .BYTE "rr H", 0
CB1D:   .BYTE "rr L", 0
CB1E:   .BYTE "rr (HL)", 0
CB1F:   .BYTE "rr A", 0
CB20:   .BYTE "sla B", 0
CB21:   .BYTE "sla C", 0
CB22:   .BYTE "sla D", 0
CB23:   .BYTE "sla E", 0
CB24:   .BYTE "sla H", 0
CB25:   .BYTE "sla L", 0
CB26:   .BYTE "sla (HL)", 0
CB27:   .BYTE "sla A", 0
CB28:   .BYTE "sra B", 0
CB29:   .BYTE "sra C", 0
CB2A:   .BYTE "sra D", 0
CB2B:   .BYTE "sra E", 0
CB2C:   .BYTE "sra H", 0
CB2D:   .BYTE "sra L", 0
CB2E:   .BYTE "sra (HL)", 0
CB2F:   .BYTE "sra A", 0
CB30:   .BYTE "sll B", 0
CB31:   .BYTE "sll C", 0
CB32:   .BYTE "sll D", 0
CB33:   .BYTE "sll E", 0
CB34:   .BYTE "sll H", 0
CB35:   .BYTE "sll L", 0
CB36:   .BYTE "sll (HL)", 0
CB37:   .BYTE "sll A", 0
CB38:   .BYTE "srl B", 0
CB39:   .BYTE "srl C", 0
CB3A:   .BYTE "srl D", 0
CB3B:   .BYTE "srl E", 0
CB3C:   .BYTE "srl H", 0
CB3D:   .BYTE "srl L", 0
CB3E:   .BYTE "srl (HL)", 0
CB3F:   .BYTE "srl A", 0
CB40:   .BYTE "bit 0, B", 0
CB41:   .BYTE "bit 0, C", 0
CB42:   .BYTE "bit 0, D", 0
CB43:   .BYTE "bit 0, E", 0
CB44:   .BYTE "bit 0, H", 0
CB45:   .BYTE "bit 0, L", 0
CB46:   .BYTE "bit 0, (HL)", 0
CB47:   .BYTE "bit 0, A", 0
CB48:   .BYTE "bit 1, B", 0
CB49:   .BYTE "bit 1, C", 0
CB4A:   .BYTE "bit 1, D", 0
CB4B:   .BYTE "bit 1, E", 0
CB4C:   .BYTE "bit 1, H", 0
CB4D:   .BYTE "bit 1, L", 0
CB4E:   .BYTE "bit 1, (HL)", 0
CB4F:   .BYTE "bit 1, A", 0
CB50:   .BYTE "bit 2, B", 0
CB51:   .BYTE "bit 2, C", 0
CB52:   .BYTE "bit 2, D", 0
CB53:   .BYTE "bit 2, E", 0
CB54:   .BYTE "bit 2, H", 0
CB55:   .BYTE "bit 2, L", 0
CB56:   .BYTE "bit 2, (HL)", 0
CB57:   .BYTE "bit 2, A", 0
CB58:   .BYTE "bit 3, B", 0
CB59:   .BYTE "bit 3, C", 0
CB5A:   .BYTE "bit 3, D", 0
CB5B:   .BYTE "bit 3, E", 0
CB5C:   .BYTE "bit 3, H", 0
CB5D:   .BYTE "bit 3, L", 0
CB5E:   .BYTE "bit 3, (HL)", 0
CB5F:   .BYTE "bit 3, A", 0
CB60:   .BYTE "bit 4, B", 0
CB61:   .BYTE "bit 4, C", 0
CB62:   .BYTE "bit 4, D", 0
CB63:   .BYTE "bit 4, E", 0
CB64:   .BYTE "bit 4, H", 0
CB65:   .BYTE "bit 4, L", 0
CB66:   .BYTE "bit 4, (HL)", 0
CB67:   .BYTE "bit 4, A", 0
CB68:   .BYTE "bit 5, B", 0
CB69:   .BYTE "bit 5, C", 0
CB6A:   .BYTE "bit 5, D", 0
CB6B:   .BYTE "bit 5, E", 0
CB6C:   .BYTE "bit 5, H", 0
CB6D:   .BYTE "bit 5, L", 0
CB6E:   .BYTE "bit 5, (HL)", 0
CB6F:   .BYTE "bit 5, A", 0
CB70:   .BYTE "bit 6, B", 0
CB71:   .BYTE "bit 6, C", 0
CB72:   .BYTE "bit 6, D", 0
CB73:   .BYTE "bit 6, E", 0
CB74:   .BYTE "bit 6, H", 0
CB75:   .BYTE "bit 6, L", 0
CB76:   .BYTE "bit 6, (HL)", 0
CB77:   .BYTE "bit 6, A", 0
CB78:   .BYTE "bit 7, B", 0
CB79:   .BYTE "bit 7, C", 0
CB7A:   .BYTE "bit 7, D", 0
CB7B:   .BYTE "bit 7, E", 0
CB7C:   .BYTE "bit 7, H", 0
CB7D:   .BYTE "bit 7, L", 0
CB7E:   .BYTE "bit 7, (HL)", 0
CB7F:   .BYTE "bit 7, A", 0
CB80:   .BYTE "res 0, B", 0
CB81:   .BYTE "res 0, C", 0
CB82:   .BYTE "res 0, D", 0
CB83:   .BYTE "res 0, E", 0
CB84:   .BYTE "res 0, H", 0
CB85:   .BYTE "res 0, L", 0
CB86:   .BYTE "res 0, (HL)", 0
CB87:   .BYTE "res 0, A", 0
CB88:   .BYTE "res 1, B", 0
CB89:   .BYTE "res 1, C", 0
CB8A:   .BYTE "res 1, D", 0
CB8B:   .BYTE "res 1, E", 0
CB8C:   .BYTE "res 1, H", 0
CB8D:   .BYTE "res 1, L", 0
CB8E:   .BYTE "res 1, (HL)", 0
CB8F:   .BYTE "res 1, A", 0
CB90:   .BYTE "res 2, B", 0
CB91:   .BYTE "res 2, C", 0
CB92:   .BYTE "res 2, D", 0
CB93:   .BYTE "res 2, E", 0
CB94:   .BYTE "res 2, H", 0
CB95:   .BYTE "res 2, L", 0
CB96:   .BYTE "res 2, (HL)", 0
CB97:   .BYTE "res 2, A", 0
CB98:   .BYTE "res 3, B", 0
CB99:   .BYTE "res 3, C", 0
CB9A:   .BYTE "res 3, D", 0
CB9B:   .BYTE "res 3, E", 0
CB9C:   .BYTE "res 3, H", 0
CB9D:   .BYTE "res 3, L", 0
CB9E:   .BYTE "res 3, (HL)", 0
CB9F:   .BYTE "res 3, A", 0
CBA0:   .BYTE "res 4, B", 0
CBA1:   .BYTE "res 4, C", 0
CBA2:   .BYTE "res 4, D", 0
CBA3:   .BYTE "res 4, E", 0
CBA4:   .BYTE "res 4, H", 0
CBA5:   .BYTE "res 4, L", 0
CBA6:   .BYTE "res 4, (HL)", 0
CBA7:   .BYTE "res 4, A", 0
CBA8:   .BYTE "res 5, B", 0
CBA9:   .BYTE "res 5, C", 0
CBAA:   .BYTE "res 5, D", 0
CBAB:   .BYTE "res 5, E", 0
CBAC:   .BYTE "res 5, H", 0
CBAD:   .BYTE "res 5, L", 0
CBAE:   .BYTE "res 5, (HL)", 0
CBAF:   .BYTE "res 5, A", 0
CBB0:   .BYTE "res 6, B", 0
CBB1:   .BYTE "res 6, C", 0
CBB2:   .BYTE "res 6, D", 0
CBB3:   .BYTE "res 6, E", 0
CBB4:   .BYTE "res 6, H", 0
CBB5:   .BYTE "res 6, L", 0
CBB6:   .BYTE "res 6, (HL)", 0
CBB7:   .BYTE "res 6, A", 0
CBB8:   .BYTE "res 7, B", 0
CBB9:   .BYTE "res 7, C", 0
CBBA:   .BYTE "res 7, D", 0
CBBB:   .BYTE "res 7, E", 0
CBBC:   .BYTE "res 7, H", 0
CBBD:   .BYTE "res 7, L", 0
CBBE:   .BYTE "res 7, (HL)", 0
CBBF:   .BYTE "res 7, A", 0
CBC0:   .BYTE "set 0, B", 0
CBC1:   .BYTE "set 0, C", 0
CBC2:   .BYTE "set 0, D", 0
CBC3:   .BYTE "set 0, E", 0
CBC4:   .BYTE "set 0, H", 0
CBC5:   .BYTE "set 0, L", 0
CBC6:   .BYTE "set 0, (HL)", 0
CBC7:   .BYTE "set 0, A", 0
CBC8:   .BYTE "set 1, B", 0
CBC9:   .BYTE "set 1, C", 0
CBCA:   .BYTE "set 1, D", 0
CBCB:   .BYTE "set 1, E", 0
CBCC:   .BYTE "set 1, H", 0
CBCD:   .BYTE "set 1, L", 0
CBCE:   .BYTE "set 1, (HL)", 0
CBCF:   .BYTE "set 1, A", 0
CBD0:   .BYTE "set 2, B", 0
CBD1:   .BYTE "set 2, C", 0
CBD2:   .BYTE "set 2, D", 0
CBD3:   .BYTE "set 2, E", 0
CBD4:   .BYTE "set 2, H", 0
CBD5:   .BYTE "set 2, L", 0
CBD6:   .BYTE "set 2, (HL)", 0
CBD7:   .BYTE "set 2, A", 0
CBD8:   .BYTE "set 3, B", 0
CBD9:   .BYTE "set 3, C", 0
CBDA:   .BYTE "set 3, D", 0
CBDB:   .BYTE "set 3, E", 0
CBDC:   .BYTE "set 3, H", 0
CBDD:   .BYTE "set 3, L", 0
CBDE:   .BYTE "set 3, (HL)", 0
CBDF:   .BYTE "set 3, A", 0
CBE0:   .BYTE "set 4, B", 0
CBE1:   .BYTE "set 4, C", 0
CBE2:   .BYTE "set 4, D", 0
CBE3:   .BYTE "set 4, E", 0
CBE4:   .BYTE "set 4, H", 0
CBE5:   .BYTE "set 4, L", 0
CBE6:   .BYTE "set 4, (HL)", 0
CBE7:   .BYTE "set 4, A", 0
CBE8:   .BYTE "set 5, B", 0
CBE9:   .BYTE "set 5, C", 0
CBEA:   .BYTE "set 5, D", 0
CBEB:   .BYTE "set 5, E", 0
CBEC:   .BYTE "set 5, H", 0
CBED:   .BYTE "set 5, L", 0
CBEE:   .BYTE "set 5, (HL)", 0
CBEF:   .BYTE "set 5, A", 0
CBF0:   .BYTE "set 6, B", 0
CBF1:   .BYTE "set 6, C", 0
CBF2:   .BYTE "set 6, D", 0
CBF3:   .BYTE "set 6, E", 0
CBF4:   .BYTE "set 6, H", 0
CBF5:   .BYTE "set 6, L", 0
CBF6:   .BYTE "set 6, (HL)", 0
CBF7:   .BYTE "set 6, A", 0
CBF8:   .BYTE "set 7, B", 0
CBF9:   .BYTE "set 7, C", 0
CBFA:   .BYTE "set 7, D", 0
CBFB:   .BYTE "set 7, E", 0
CBFC:   .BYTE "set 7, H", 0
CBFD:   .BYTE "set 7, L", 0
CBFE:   .BYTE "set 7, (HL)", 0
CBFF:   .BYTE "set 7, A", 0

JMPTAB_DD:  ; Z80 "special" opcodes DD table
    .WORD DD00,DD01,DD02,DD03,DD04,DD05,DD06,DD07,DD08,DD09
    .WORD DD0A,DD0B,DD0C,DD0D,DD0E,DD0F
    .WORD DD10,DD11,DD12,DD13,DD14,DD15,DD16,DD17,DD18,DD19
    .WORD DD1A,DD1B,DD1C,DD1D,DD1E,DD1F
    .WORD DD20,DD21,DD22,DD23,DD24,DD25,DD26,DD27,DD28,DD29
    .WORD DD2A,DD2B,DD2C,DD2D,DD2E,DD2F
    .WORD DD30,DD31,DD32,DD33,DD34,DD35,DD36,DD37,DD38,DD39
    .WORD DD3A,DD3B,DD3C,DD3D,DD3E,DD3F
    .WORD DD40,DD41,DD42,DD43,DD44,DD45,DD46,DD47,DD48,DD49
    .WORD DD4A,DD4B,DD4C,DD4D,DD4E,DD4F
    .WORD DD50,DD51,DD52,DD53,DD54,DD55,DD56,DD57,DD58,DD59
    .WORD DD5A,DD5B,DD5C,DD5D,DD5E,DD5F
    .WORD DD60,DD61,DD62,DD63,DD64,DD65,DD66,DD67,DD68,DD69
    .WORD DD6A,DD6B,DD6C,DD6D,DD6E,DD6F
    .WORD DD70,DD71,DD72,DD73,DD74,DD75,DD76,DD77,DD78,DD79
    .WORD DD7A,DD7B,DD7C,DD7D,DD7E,DD7F
    .WORD DD80,DD81,DD82,DD83,DD84,DD85,DD86,DD87,DD88,DD89
    .WORD DD8A,DD8B,DD8C,DD8D,DD8E,DD8F
    .WORD DD90,DD91,DD92,DD93,DD94,DD95,DD96,DD97,DD98,DD99
    .WORD DD9A,DD9B,DD9C,DD9D,DD9E,DD9F
    .WORD DDA0,DDA1,DDA2,DDA3,DDA4,DDA5,DDA6,DDA7,DDA8,DDA9
    .WORD DDAA,DDAB,DDAC,DDAD,DDAE,DDAF
    .WORD DDB0,DDB1,DDB2,DDB3,DDB4,DDB5,DDB6,DDB7,DDB8,DDB9
    .WORD DDBA,DDBB,DDBC,DDBD,DDBE,DDBF
    .WORD DDC0,DDC1,DDC2,DDC3,DDC4,DDC5,DDC6,DDC7,DDC8,DDC9
    .WORD DDCA,DDCB,DDCC,DDCD,DDCE,DDCF
    .WORD DDD0,DDD1,DDD2,DDD3,DDD4,DDD5,DDD6,DDD7,DDD8,DDD9
    .WORD DDDA,DDDB,DDDC,DDDD,DDDE,DDDF
    .WORD DDE0,DDE1,DDE2,DDE3,DDE4,DDE5,DDE6,DDE7,DDE8,DDE9
    .WORD DDEA,DDEB,DDEC,DDED,DDEE,DDEF
    .WORD DDF0,DDF1,DDF2,DDF3,DDF4,DDF5,DDF6,DDF7,DDF8,DDF9
    .WORD DDFA,DDFB,DDFC,DDFD,DDFE,DDFF
OPCODES_DD:
;  _____     ____
; |_   _|__ |  _ \  ___
;   | |/ _ \| | | |/ _ \
;   | | (_) | |_| | (_) |       See below
;   |_|\___/|____/ \___/
DD00:   .BYTE 0
DD01:   .BYTE 0
DD02:   .BYTE 0
DD03:   .BYTE 0
DD04:   .BYTE 0
DD05:   .BYTE 0
DD06:   .BYTE 0
DD07:   .BYTE 0
DD08:   .BYTE 0
DD09:   .BYTE "add IX, BC", 0
DD0A:   .BYTE 0
DD0B:   .BYTE 0
DD0C:   .BYTE 0
DD0D:   .BYTE 0
DD0E:   .BYTE 0
DD0F:   .BYTE 0
DD10:   .BYTE 0
DD11:   .BYTE 0
DD12:   .BYTE 0
DD13:   .BYTE 0
DD14:   .BYTE 0
DD15:   .BYTE 0
DD16:   .BYTE 0
DD17:   .BYTE 0
DD18:   .BYTE 0
DD19:   .BYTE "add IX, DE", 0
DD1A:   .BYTE 0
DD1B:   .BYTE 0
DD1C:   .BYTE 0
DD1D:   .BYTE 0
DD1E:   .BYTE 0
DD1F:   .BYTE 0
DD20:   .BYTE 0
DD21:   .BYTE "ld IX, @", 0
DD22:   .BYTE "ld (@), IX", 0
DD23:   .BYTE "inc IX", 0
DD24:   .BYTE 0
DD25:   .BYTE 0
DD26:   .BYTE 0
DD27:   .BYTE 0
DD28:   .BYTE 0
DD29:   .BYTE "add IX, IX", 0
DD2A:   .BYTE "ld IX, (@)", 0
DD2B:   .BYTE "dec IX", 0
DD2C:   .BYTE 0
DD2D:   .BYTE 0
DD2E:   .BYTE 0
DD2F:   .BYTE 0
DD30:   .BYTE 0
DD31:   .BYTE 0
DD32:   .BYTE 0
DD33:   .BYTE 0
DD34:   .BYTE "inc (IX+!)", 0
DD35:   .BYTE "dec (IX+!)", 0
DD36:   .BYTE "ld (IX+!), !", 0
DD37:   .BYTE 0
DD38:   .BYTE 0
DD39:   .BYTE "add IX, SP", 0
DD3A:   .BYTE 0
DD3B:   .BYTE 0
DD3C:   .BYTE 0
DD3D:   .BYTE 0
DD3E:   .BYTE 0
DD3F:   .BYTE 0
DD40:   .BYTE 0
DD41:   .BYTE 0
DD42:   .BYTE 0
DD43:   .BYTE 0
DD44:   .BYTE 0
DD45:   .BYTE 0
DD46:   .BYTE "ld B, (IX+!)", 0
DD47:   .BYTE 0
DD48:   .BYTE 0
DD49:   .BYTE 0
DD4A:   .BYTE 0
DD4B:   .BYTE 0
DD4C:   .BYTE 0
DD4D:   .BYTE 0
DD4E:   .BYTE "ld C, (IX+!)", 0
DD4F:   .BYTE 0
DD50:   .BYTE 0
DD51:   .BYTE 0
DD52:   .BYTE 0
DD53:   .BYTE 0
DD54:   .BYTE 0
DD55:   .BYTE 0
DD56:   .BYTE "ld D, (IX+!)", 0
DD57:   .BYTE 0
DD58:   .BYTE 0
DD59:   .BYTE 0
DD5A:   .BYTE 0
DD5B:   .BYTE 0
DD5C:   .BYTE 0
DD5D:   .BYTE 0
DD5E:   .BYTE "ld E, (IX+!)", 0
DD5F:   .BYTE 0
DD60:   .BYTE 0
DD61:   .BYTE 0
DD62:   .BYTE 0
DD63:   .BYTE 0
DD64:   .BYTE 0
DD65:   .BYTE 0
DD66:   .BYTE "ld H, (IX+!)", 0
DD67:   .BYTE 0
DD68:   .BYTE 0
DD69:   .BYTE 0
DD6A:   .BYTE 0
DD6B:   .BYTE 0
DD6C:   .BYTE 0
DD6D:   .BYTE 0
DD6E:   .BYTE "ld L, (IX+!)", 0
DD6F:   .BYTE 0
DD70:   .BYTE "ld (IX+!), B", 0
DD71:   .BYTE "ld (IX+!), C", 0
DD72:   .BYTE "ld (IX+!), D", 0
DD73:   .BYTE "ld (IX+!), E", 0
DD74:   .BYTE "ld (IX+!), H", 0
DD75:   .BYTE "ld (IX+!), L", 0
DD76:   .BYTE 0
DD77:   .BYTE "ld (IX+!), A", 0
DD78:   .BYTE 0
DD79:   .BYTE 0
DD7A:   .BYTE 0
DD7B:   .BYTE 0
DD7C:   .BYTE 0
DD7D:   .BYTE 0
DD7E:   .BYTE "ld A, (IX+!)", 0
DD7F:   .BYTE 0
DD80:   .BYTE 0
DD81:   .BYTE 0
DD82:   .BYTE 0
DD83:   .BYTE 0
DD84:   .BYTE 0
DD85:   .BYTE 0
DD86:   .BYTE "add A, (IX+!)", 0
DD87:   .BYTE 0
DD88:   .BYTE 0
DD89:   .BYTE 0
DD8A:   .BYTE 0
DD8B:   .BYTE 0
DD8C:   .BYTE 0
DD8D:   .BYTE 0
DD8E:   .BYTE "adc A, (IX+!)", 0
DD8F:   .BYTE 0
DD90:   .BYTE 0
DD91:   .BYTE 0
DD92:   .BYTE 0
DD93:   .BYTE 0
DD94:   .BYTE 0
DD95:   .BYTE 0
DD96:   .BYTE "sub (IX+!)", 0
DD97:   .BYTE 0
DD98:   .BYTE 0
DD99:   .BYTE 0
DD9A:   .BYTE 0
DD9B:   .BYTE 0
DD9C:   .BYTE 0
DD9D:   .BYTE 0
DD9E:   .BYTE "sbc A, (IX+!)", 0
DD9F:   .BYTE 0
DDA0:   .BYTE 0
DDA1:   .BYTE 0
DDA2:   .BYTE 0
DDA3:   .BYTE 0
DDA4:   .BYTE 0
DDA5:   .BYTE 0
DDA6:   .BYTE "and (IX+!)", 0
DDA7:   .BYTE 0
DDA8:   .BYTE 0
DDA9:   .BYTE 0
DDAA:   .BYTE 0
DDAB:   .BYTE 0
DDAC:   .BYTE 0
DDAD:   .BYTE 0
DDAE:   .BYTE "xor (IX+!)", 0
DDAF:   .BYTE 0
DDB0:   .BYTE 0
DDB1:   .BYTE 0
DDB2:   .BYTE 0
DDB3:   .BYTE 0
DDB4:   .BYTE 0
DDB5:   .BYTE 0
DDB6:   .BYTE "or (IX+!)", 0
DDB7:   .BYTE 0
DDB8:   .BYTE 0
DDB9:   .BYTE 0
DDBA:   .BYTE 0
DDBB:   .BYTE 0
DDBC:   .BYTE 0
DDBD:   .BYTE 0
DDBE:   .BYTE "cp (IX+!)", 0
DDBF:   .BYTE 0
DDC0:   .BYTE 0
DDC1:   .BYTE 0
DDC2:   .BYTE 0
DDC3:   .BYTE 0
DDC4:   .BYTE 0
DDC5:   .BYTE 0
DDC6:   .BYTE 0
DDC7:   .BYTE 0
DDC8:   .BYTE 0
DDC9:   .BYTE 0
DDCA:   .BYTE 0
DDCB:   .BYTE 0                         ; ToDo  4 bytes
DDCC:   .BYTE 0
DDCD:   .BYTE 0
DDCE:   .BYTE 0
DDCF:   .BYTE 0
DDD0:   .BYTE 0
DDD1:   .BYTE 0
DDD2:   .BYTE 0
DDD3:   .BYTE 0
DDD4:   .BYTE 0
DDD5:   .BYTE 0
DDD6:   .BYTE 0
DDD7:   .BYTE 0
DDD8:   .BYTE 0
DDD9:   .BYTE 0
DDDA:   .BYTE 0
DDDB:   .BYTE 0
DDDC:   .BYTE 0
DDDD:   .BYTE 0
DDDE:   .BYTE 0
DDDF:   .BYTE 0
DDE0:   .BYTE 0
DDE1:   .BYTE "pop IX", 0
DDE2:   .BYTE 0
DDE3:   .BYTE "ex (SP), IX", 0
DDE4:   .BYTE 0
DDE5:   .BYTE "push IX", 0
DDE6:   .BYTE 0
DDE7:   .BYTE 0
DDE8:   .BYTE 0
DDE9:   .BYTE "jp (IX)", 0
DDEA:   .BYTE 0
DDEB:   .BYTE 0
DDEC:   .BYTE 0
DDED:   .BYTE 0
DDEE:   .BYTE 0
DDEF:   .BYTE 0
DDF0:   .BYTE 0
DDF1:   .BYTE 0
DDF2:   .BYTE 0
DDF3:   .BYTE 0
DDF4:   .BYTE 0
DDF5:   .BYTE 0
DDF6:   .BYTE 0
DDF7:   .BYTE 0
DDF8:   .BYTE 0
DDF9:   .BYTE "ld SP, IX", 0
DDFA:   .BYTE 0
DDFB:   .BYTE 0
DDFC:   .BYTE 0
DDFD:   .BYTE 0
DDFE:   .BYTE 0
DDFF:   .BYTE 0

JMPTAB_ED:  ; Z80 "special" opcodes ED table
    .WORD ED00,ED01,ED02,ED03,ED04,ED05,ED06,ED07,ED08,ED09
    .WORD ED0A,ED0B,ED0C,ED0D,ED0E,ED0F
    .WORD ED10,ED11,ED12,ED13,ED14,ED15,ED16,ED17,ED18,ED19
    .WORD ED1A,ED1B,ED1C,ED1D,ED1E,ED1F
    .WORD ED20,ED21,ED22,ED23,ED24,ED25,ED26,ED27,ED28,ED29
    .WORD ED2A,ED2B,ED2C,ED2D,ED2E,ED2F
    .WORD ED30,ED31,ED32,ED33,ED34,ED35,ED36,ED37,ED38,ED39
    .WORD ED3A,ED3B,ED3C,ED3D,ED3E,ED3F
    .WORD ED40,ED41,ED42,ED43,ED44,ED45,ED46,ED47,ED48,ED49
    .WORD ED4A,ED4B,ED4C,ED4D,ED4E,ED4F
    .WORD ED50,ED51,ED52,ED53,ED54,ED55,ED56,ED57,ED58,ED59
    .WORD ED5A,ED5B,ED5C,ED5D,ED5E,ED5F
    .WORD ED60,ED61,ED62,ED63,ED64,ED65,ED66,ED67,ED68,ED69
    .WORD ED6A,ED6B,ED6C,ED6D,ED6E,ED6F
    .WORD ED70,ED71,ED72,ED73,ED74,ED75,ED76,ED77,ED78,ED79
    .WORD ED7A,ED7B,ED7C,ED7D,ED7E,ED7F
    .WORD ED80,ED81,ED82,ED83,ED84,ED85,ED86,ED87,ED88,ED89
    .WORD ED8A,ED8B,ED8C,ED8D,ED8E,ED8F
    .WORD ED90,ED91,ED92,ED93,ED94,ED95,ED96,ED97,ED98,ED99
    .WORD ED9A,ED9B,ED9C,ED9D,ED9E,ED9F
    .WORD EDA0,EDA1,EDA2,EDA3,EDA4,EDA5,EDA6,EDA7,EDA8,EDA9
    .WORD EDAA,EDAB,EDAC,EDAD,EDAE,EDAF
    .WORD EDB0,EDB1,EDB2,EDB3,EDB4,EDB5,EDB6,EDB7,EDB8,EDB9
    .WORD EDBA,EDBB,EDBC,EDBD,EDBE,EDBF
OPCODES_ED:
ED00:   .BYTE 0
ED01:   .BYTE 0
ED02:   .BYTE 0
ED03:   .BYTE 0
ED04:   .BYTE 0
ED05:   .BYTE 0
ED06:   .BYTE 0
ED07:   .BYTE 0
ED08:   .BYTE 0
ED09:   .BYTE 0
ED0A:   .BYTE 0
ED0B:   .BYTE 0
ED0C:   .BYTE 0
ED0D:   .BYTE 0
ED0E:   .BYTE 0
ED0F:   .BYTE 0
ED10:   .BYTE 0
ED11:   .BYTE 0
ED12:   .BYTE 0
ED13:   .BYTE 0
ED14:   .BYTE 0
ED15:   .BYTE 0
ED16:   .BYTE 0
ED17:   .BYTE 0
ED18:   .BYTE 0
ED19:   .BYTE 0
ED1A:   .BYTE 0
ED1B:   .BYTE 0
ED1C:   .BYTE 0
ED1D:   .BYTE 0
ED1E:   .BYTE 0
ED1F:   .BYTE 0
ED20:   .BYTE 0
ED21:   .BYTE 0
ED22:   .BYTE 0
ED23:   .BYTE 0
ED24:   .BYTE 0
ED25:   .BYTE 0
ED26:   .BYTE 0
ED27:   .BYTE 0
ED28:   .BYTE 0
ED29:   .BYTE 0
ED2A:   .BYTE 0
ED2B:   .BYTE 0
ED2C:   .BYTE 0
ED2D:   .BYTE 0
ED2E:   .BYTE 0
ED2F:   .BYTE 0
ED30:   .BYTE 0
ED31:   .BYTE 0
ED32:   .BYTE 0
ED33:   .BYTE 0
ED34:   .BYTE 0
ED35:   .BYTE 0
ED36:   .BYTE 0
ED37:   .BYTE 0
ED38:   .BYTE 0
ED39:   .BYTE 0
ED3A:   .BYTE 0
ED3B:   .BYTE 0
ED3C:   .BYTE 0
ED3D:   .BYTE 0
ED3E:   .BYTE 0
ED3F:   .BYTE 0
ED40:   .BYTE "in B, (C)", 0
ED41:   .BYTE "out (C), B)", 0
ED42:   .BYTE "sbc HL, BC", 0
ED43:   .BYTE "ld (@), BC", 0
ED44:   .BYTE "neg", 0
ED45:   .BYTE "retn", 0
ED46:   .BYTE "im 0", 0
ED47:   .BYTE "ld I, A", 0
ED48:   .BYTE "in C, (C)", 0
ED49:   .BYTE "out (C), C", 0
ED4A:   .BYTE "adc HL, BC", 0
ED4B:   .BYTE "ld BC, (@)", 0
ED4C:   .BYTE 0
ED4D:   .BYTE "reti", 0
ED4E:   .BYTE 0
ED4F:   .BYTE "ld R, A", 0
ED50:   .BYTE "in D, (C)", 0
ED51:   .BYTE "out (C), D", 0
ED52:   .BYTE "sbc HL, DE", 0
ED53:   .BYTE "ld (@), DE", 0
ED54:   .BYTE 0
ED55:   .BYTE 0
ED56:   .BYTE "im 1", 0
ED57:   .BYTE "ld A, I", 0
ED58:   .BYTE "in E, (C)", 0
ED59:   .BYTE "out (C), E", 0
ED5A:   .BYTE "adc HL, DE", 0
ED5B:   .BYTE "ld DE, (@)", 0
ED5C:   .BYTE 0
ED5D:   .BYTE 0
ED5E:   .BYTE "im 2", 0
ED5F:   .BYTE "ld A, R", 0
ED60:   .BYTE "in H, (C)", 0
ED61:   .BYTE "out (C), H", 0
ED62:   .BYTE "sbc HL, HL", 0
ED63:   .BYTE 0
ED64:   .BYTE 0
ED65:   .BYTE 0
ED66:   .BYTE 0
ED67:   .BYTE "rrd", 0
ED68:   .BYTE "in L, (C)", 0
ED69:   .BYTE "out (C), L", 0
ED6A:   .BYTE "adc HL, HL", 0
ED6B:   .BYTE 0
ED6C:   .BYTE 0
ED6D:   .BYTE 0
ED6E:   .BYTE 0
ED6F:   .BYTE "rld", 0
ED70:   .BYTE 0
ED71:   .BYTE 0
ED72:   .BYTE "sbc HL, SP", 0
ED73:   .BYTE "ld (@), SP", 0
ED74:   .BYTE 0
ED75:   .BYTE 0
ED76:   .BYTE 0
ED77:   .BYTE 0
ED78:   .BYTE "in A, (C)", 0
ED79:   .BYTE "out (C), A", 0
ED7A:   .BYTE "adc HL, SP", 0
ED7B:   .BYTE "ld SP, (@)", 0
ED7C:   .BYTE 0
ED7D:   .BYTE 0
ED7E:   .BYTE 0
ED7F:   .BYTE 0
ED80:   .BYTE 0
ED81:   .BYTE 0
ED82:   .BYTE 0
ED83:   .BYTE 0
ED84:   .BYTE 0
ED85:   .BYTE 0
ED86:   .BYTE 0
ED87:   .BYTE 0
ED88:   .BYTE 0
ED89:   .BYTE 0
ED8A:   .BYTE 0
ED8B:   .BYTE 0
ED8C:   .BYTE 0
ED8D:   .BYTE 0
ED8E:   .BYTE 0
ED8F:   .BYTE 0
ED90:   .BYTE 0
ED91:   .BYTE 0
ED92:   .BYTE 0
ED93:   .BYTE 0
ED94:   .BYTE 0
ED95:   .BYTE 0
ED96:   .BYTE 0
ED97:   .BYTE 0
ED98:   .BYTE 0
ED99:   .BYTE 0
ED9A:   .BYTE 0
ED9B:   .BYTE 0
ED9C:   .BYTE 0
ED9D:   .BYTE 0
ED9E:   .BYTE 0
ED9F:   .BYTE 0
EDA0:   .BYTE "ldi", 0
EDA1:   .BYTE "cpi", 0
EDA2:   .BYTE "ini", 0
EDA3:   .BYTE "outi", 0
EDA4:   .BYTE 0
EDA5:   .BYTE 0
EDA6:   .BYTE 0
EDA7:   .BYTE 0
EDA8:   .BYTE "ldd", 0
EDA9:   .BYTE "cpd", 0
EDAA:   .BYTE "ind", 0
EDAB:   .BYTE "outd", 0
EDAC:   .BYTE 0
EDAD:   .BYTE 0
EDAE:   .BYTE 0
EDAF:   .BYTE 0
EDB0:   .BYTE "ldir", 0
EDB1:   .BYTE "cpir", 0
EDB2:   .BYTE "inir", 0
EDB3:   .BYTE "otir", 0
EDB4:   .BYTE 0
EDB5:   .BYTE 0
EDB6:   .BYTE 0
EDB7:   .BYTE 0
EDB8:   .BYTE "lddr", 0
EDB9:   .BYTE "cpdr", 0
EDBA:   .BYTE "indr", 0
EDBB:   .BYTE "otdr", 0
EDBC:   .BYTE 0
EDBD:   .BYTE 0
EDBE:   .BYTE 0
EDBF:   .BYTE 0

JMPTAB_FD:  ; Z80 "special" opcodes FD table
    .WORD FD00,FD01,FD02,FD03,FD04,FD05,FD06,FD07,FD08,FD09
    .WORD FD0A,FD0B,FD0C,FD0D,FD0E,FD0F
    .WORD FD10,FD11,FD12,FD13,FD14,FD15,FD16,FD17,FD18,FD19
    .WORD FD1A,FD1B,FD1C,FD1D,FD1E,FD1F
    .WORD FD20,FD21,FD22,FD23,FD24,FD25,FD26,FD27,FD28,FD29
    .WORD FD2A,FD2B,FD2C,FD2D,FD2E,FD2F
    .WORD FD30,FD31,FD32,FD33,FD34,FD35,FD36,FD37,FD38,FD39
    .WORD FD3A,FD3B,FD3C,FD3D,FD3E,FD3F
    .WORD FD40,FD41,FD42,FD43,FD44,FD45,FD46,FD47,FD48,FD49
    .WORD FD4A,FD4B,FD4C,FD4D,FD4E,FD4F
    .WORD FD50,FD51,FD52,FD53,FD54,FD55,FD56,FD57,FD58,FD59
    .WORD FD5A,FD5B,FD5C,FD5D,FD5E,FD5F
    .WORD FD60,FD61,FD62,FD63,FD64,FD65,FD66,FD67,FD68,FD69
    .WORD FD6A,FD6B,FD6C,FD6D,FD6E,FD6F
    .WORD FD70,FD71,FD72,FD73,FD74,FD75,FD76,FD77,FD78,FD79
    .WORD FD7A,FD7B,FD7C,FD7D,FD7E,FD7F
    .WORD FD80,FD81,FD82,FD83,FD84,FD85,FD86,FD87,FD88,FD89
    .WORD FD8A,FD8B,FD8C,FD8D,FD8E,FD8F
    .WORD FD90,FD91,FD92,FD93,FD94,FD95,FD96,FD97,FD98,FD99
    .WORD FD9A,FD9B,FD9C,FD9D,FD9E,FD9F
    .WORD FDA0,FDA1,FDA2,FDA3,FDA4,FDA5,FDA6,FDA7,FDA8,FDA9
    .WORD FDAA,FDAB,FDAC,FDAD,FDAE,FDAF
    .WORD FDB0,FDB1,FDB2,FDB3,FDB4,FDB5,FDB6,FDB7,FDB8,FDB9
    .WORD FDBA,FDBB,FDBC,FDBD,FDBE,FDBF
OPCODES_FD:
;  _____     ____
; |_   _|__ |  _ \  ___
;   | |/ _ \| | | |/ _ \
;   | | (_) | |_| | (_) |       See below
;   |_|\___/|____/ \___/
FD00:   .BYTE 0
FD01:   .BYTE 0
FD02:   .BYTE 0
FD03:   .BYTE 0
FD04:   .BYTE 0
FD05:   .BYTE 0
FD06:   .BYTE 0
FD07:   .BYTE 0
FD08:   .BYTE 0
FD09:   .BYTE "add IY, BC", 0
FD0A:   .BYTE 0
FD0B:   .BYTE 0
FD0C:   .BYTE 0
FD0D:   .BYTE 0
FD0E:   .BYTE 0
FD0F:   .BYTE 0
FD10:   .BYTE 0
FD11:   .BYTE 0
FD12:   .BYTE 0
FD13:   .BYTE 0
FD14:   .BYTE 0
FD15:   .BYTE 0
FD16:   .BYTE 0
FD17:   .BYTE 0
FD18:   .BYTE 0
FD19:   .BYTE "add IY, DE", 0
FD1A:   .BYTE 0
FD1B:   .BYTE 0
FD1C:   .BYTE 0
FD1D:   .BYTE 0
FD1E:   .BYTE 0
FD1F:   .BYTE 0
FD20:   .BYTE 0
FD21:   .BYTE "ld IY, @", 0
FD22:   .BYTE "ld (@), IY", 0
FD23:   .BYTE "inc IY", 0
FD24:   .BYTE 0
FD25:   .BYTE 0
FD26:   .BYTE 0
FD27:   .BYTE 0
FD28:   .BYTE 0
FD29:   .BYTE "add IY, IY", 0
FD2A:   .BYTE "ld IY, (@)", 0
FD2B:   .BYTE "dec IY", 0
FD2C:   .BYTE 0
FD2D:   .BYTE 0
FD2E:   .BYTE 0
FD2F:   .BYTE 0
FD30:   .BYTE 0
FD31:   .BYTE 0
FD32:   .BYTE 0
FD33:   .BYTE 0
FD34:   .BYTE "inc (IY+?)", 0           ; ToDo
FD35:   .BYTE "dec (IY+?)", 0           ; ToDo
FD36:   .BYTE "ld (IY+?)", 0            ; ToDo
FD37:   .BYTE 0
FD38:   .BYTE 0
FD39:   .BYTE "add IY, SP", 0
FD3A:   .BYTE 0
FD3B:   .BYTE 0
FD3C:   .BYTE 0
FD3D:   .BYTE 0
FD3E:   .BYTE 0
FD3F:   .BYTE 0
FD40:   .BYTE 0
FD41:   .BYTE 0
FD42:   .BYTE 0
FD43:   .BYTE 0
FD44:   .BYTE 0
FD45:   .BYTE 0
FD46:   .BYTE "ld B, (IY+?)", 0         ; ToDo
FD47:   .BYTE 0
FD48:   .BYTE 0
FD49:   .BYTE 0
FD4A:   .BYTE 0
FD4B:   .BYTE 0
FD4C:   .BYTE 0
FD4D:   .BYTE 0
FD4E:   .BYTE "ld C, (IY+?)", 0         ; ToDo
FD4F:   .BYTE 0
FD50:   .BYTE 0
FD51:   .BYTE 0
FD52:   .BYTE 0
FD53:   .BYTE 0
FD54:   .BYTE 0
FD55:   .BYTE 0
FD56:   .BYTE "ld D, (IY+?)", 0         ; ToDo
FD57:   .BYTE 0
FD58:   .BYTE 0
FD59:   .BYTE 0
FD5A:   .BYTE 0
FD5B:   .BYTE 0
FD5C:   .BYTE 0
FD5D:   .BYTE 0
FD5E:   .BYTE "ld E, (IY+?)", 0         ; ToDo
FD5F:   .BYTE 0
FD60:   .BYTE 0
FD61:   .BYTE 0
FD62:   .BYTE 0
FD63:   .BYTE 0
FD64:   .BYTE 0
FD65:   .BYTE 0
FD66:   .BYTE "ld H, (IY+?)", 0         ; ToDo
FD67:   .BYTE 0
FD68:   .BYTE 0
FD69:   .BYTE 0
FD6A:   .BYTE 0
FD6B:   .BYTE 0
FD6C:   .BYTE 0
FD6D:   .BYTE 0
FD6E:   .BYTE "ld L, (IY+?)", 0         ; ToDo
FD6F:   .BYTE 0
FD70:   .BYTE "ld (IY+?), B", 0         ; ToDo
FD71:   .BYTE "ld (IY+?), C", 0         ; ToDo
FD72:   .BYTE "ld (IY+?), D", 0         ; ToDo
FD73:   .BYTE "ld (IY+?), E", 0         ; ToDo
FD74:   .BYTE "ld (IY+?), H", 0         ; ToDo
FD75:   .BYTE "ld (IY+?), L", 0         ; ToDo
FD76:   .BYTE 0
FD77:   .BYTE "ld (IY+?), A", 0         ; ToDo
FD78:   .BYTE 0
FD79:   .BYTE 0
FD7A:   .BYTE 0
FD7B:   .BYTE 0
FD7C:   .BYTE 0
FD7D:   .BYTE 0
FD7E:   .BYTE "ld A, (IY+?)", 0         ; ToDo
FD7F:   .BYTE 0
FD80:   .BYTE 0
FD81:   .BYTE 0
FD82:   .BYTE 0
FD83:   .BYTE 0
FD84:   .BYTE 0
FD85:   .BYTE 0
FD86:   .BYTE "add A, (IY+?)", 0        ; ToDo
FD87:   .BYTE 0
FD88:   .BYTE 0
FD89:   .BYTE 0
FD8A:   .BYTE 0
FD8B:   .BYTE 0
FD8C:   .BYTE 0
FD8D:   .BYTE 0
FD8E:   .BYTE "adc A, (IY+?)", 0        ; ToDo
FD8F:   .BYTE 0
FD90:   .BYTE 0
FD91:   .BYTE 0
FD92:   .BYTE 0
FD93:   .BYTE 0
FD94:   .BYTE 0
FD95:   .BYTE 0
FD96:   .BYTE "sub (IY+?)", 0           ; ToDo
FD97:   .BYTE 0
FD98:   .BYTE 0
FD99:   .BYTE 0
FD9A:   .BYTE 0
FD9B:   .BYTE 0
FD9C:   .BYTE 0
FD9D:   .BYTE 0
FD9E:   .BYTE "sbc A, (IY+?)", 0        ; ToDo
FD9F:   .BYTE 0
FDA0:   .BYTE 0
FDA1:   .BYTE 0
FDA2:   .BYTE 0
FDA3:   .BYTE 0
FDA4:   .BYTE 0
FDA5:   .BYTE 0
FDA6:   .BYTE "and (IY+?)", 0           ; ToDo
FDA7:   .BYTE 0
FDA8:   .BYTE 0
FDA9:   .BYTE 0
FDAA:   .BYTE 0
FDAB:   .BYTE 0
FDAC:   .BYTE 0
FDAD:   .BYTE 0
FDAE:   .BYTE "xor (IY+?)", 0           ; ToDo
FDAF:   .BYTE 0
FDB0:   .BYTE 0
FDB1:   .BYTE 0
FDB2:   .BYTE 0
FDB3:   .BYTE 0
FDB4:   .BYTE 0
FDB5:   .BYTE 0
FDB6:   .BYTE "or (IY+?)", 0            ; ToDo
FDB7:   .BYTE 0
FDB8:   .BYTE 0
FDB9:   .BYTE 0
FDBA:   .BYTE 0
FDBB:   .BYTE 0
FDBC:   .BYTE 0
FDBD:   .BYTE 0
FDBE:   .BYTE "cp (IY+?)", 0            ; ToDo
FDBF:   .BYTE 0
FDC0:   .BYTE 0
FDC1:   .BYTE 0
FDC2:   .BYTE 0
FDC3:   .BYTE 0
FDC4:   .BYTE 0
FDC5:   .BYTE 0
FDC6:   .BYTE 0
FDC7:   .BYTE 0
FDC8:   .BYTE 0
FDC9:   .BYTE 0
FDCA:   .BYTE 0
FDCB:   .BYTE 0                         ; ToDo 4 bytes
FDCC:   .BYTE 0
FDCD:   .BYTE 0
FDCE:   .BYTE 0
FDCF:   .BYTE 0
FDD0:   .BYTE 0
FDD1:   .BYTE 0
FDD2:   .BYTE 0
FDD3:   .BYTE 0
FDD4:   .BYTE 0
FDD5:   .BYTE 0
FDD6:   .BYTE 0
FDD7:   .BYTE 0
FDD8:   .BYTE 0
FDD9:   .BYTE 0
FDDA:   .BYTE 0
FDDB:   .BYTE 0
FDDC:   .BYTE 0
FDDD:   .BYTE 0
FDDE:   .BYTE 0
FDDF:   .BYTE 0
FDE0:   .BYTE 0
FDE1:   .BYTE "pop IY", 0
FDE2:   .BYTE 0
FDE3:   .BYTE "ex (SP), IY", 0
FDE4:   .BYTE 0
FDE5:   .BYTE "push IY", 0
FDE6:   .BYTE 0
FDE7:   .BYTE 0
FDE8:   .BYTE 0
FDE9:   .BYTE "jp (IY)", 0
FDEA:   .BYTE 0
FDEB:   .BYTE 0
FDEC:   .BYTE 0
FDED:   .BYTE 0
FDEE:   .BYTE 0
FDEF:   .BYTE 0
FDF0:   .BYTE 0
FDF1:   .BYTE 0
FDF2:   .BYTE 0
FDF3:   .BYTE 0
FDF4:   .BYTE 0
FDF5:   .BYTE 0
FDF6:   .BYTE 0
FDF7:   .BYTE 0
FDF8:   .BYTE 0
FDF9:   .BYTE "ld SP, IY", 0
FDFA:   .BYTE 0
FDFB:   .BYTE 0
FDFC:   .BYTE 0
FDFD:   .BYTE 0
FDFE:   .BYTE 0
FDFF:   .BYTE 0

        .END