;******************************************************************************
; Name:         sysvarview.asm
; Description:  Shows the current values stored in SYSVARS
; Author:       David Asta
; License:      The MIT License
; Created:      27 Dec 2023
; Version:      1.0.0
; Last Modif.:  27 Dec 2023
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; Copyright (C) 2023
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

; Superblock ------------------------------------------------------------------
        ld      HL, title_sblock
        ld      A, ANSI_COLR_CYA
        call    print_title

        ld      HL, sysvar_40AB
        call    print_header
        ld      HL, DISK_is_formatted
        call    print_bytevalue

        ld      HL, sysvar_40AC
        call    print_header
        ld      HL, DISK_show_deleted
        call    print_bytevalue

        ld      HL, sysvar_40AD
        call    print_header
        ld      DE, (DISK_cur_sector)
        call    print_wordvalue
; DISK BAT --------------------------------------------------------------------
        ; ld      HL, title_BAT
        ; ld      A, ANSI_COLR_CYA
        ; call    print_title

        ; ld      HL, sysvar_40AF
        ; call    print_header
        ; ld      B, 14
        ; ld      IX, DISK_cur_file_name
        ; call    print_nvalue

        ; ld      HL, sysvar_40BD
        ; call    print_header
        ; ld      HL, DISK_cur_file_attribs
        ; call    print_bytevalue

        ; ld      HL, sysvar_40BE
        ; call    print_header
        ; ld      DE, (DISK_cur_file_time_created)
        ; call    print_wordvalue

        ; ld      HL, sysvar_40C0
        ; call    print_header
        ; ld      DE, (DISK_cur_file_date_created)
        ; call    print_wordvalue

        ; ld      HL, sysvar_40C2
        ; call    print_header
        ; ld      DE, (DISK_cur_file_time_modified)
        ; call    print_wordvalue

        ; ld      HL, sysvar_40C4
        ; call    print_header
        ; ld      DE, (DISK_cur_file_date_modified)
        ; call    print_wordvalue

        ; ld      HL, sysvar_40C6
        ; call    print_header
        ; ld      DE, (DISK_cur_file_size_bytes)
        ; call    print_wordvalue

        ; ld      HL, sysvar_40C8
        ; call    print_header
        ; ld      HL, DISK_cur_file_size_sectors
        ; call    print_bytevalue

        ; ld      HL, sysvar_40C9
        ; call    print_header
        ; ld      DE, (DISK_cur_file_entry_number)
        ; call    print_wordvalue

        ; ld      HL, sysvar_40CB
        ; call    print_header
        ; ld      DE, (DISK_cur_file_1st_sector)
        ; call    print_wordvalue

        ; ld      HL, sysvar_40CD
        ; call    print_header
        ; ld      DE, (DISK_cur_file_load_addr)
        ; call    print_wordvalue
; CLI -------------------------------------------------------------------------
        ld      HL, title_CLI
        ld      A, ANSI_COLR_CYA
        call    print_title

        ld      HL, sysvar_40CF
        call    print_header
        ld      DE, (CLI_prompt_addr)
        call    print_wordvalue

        ld      HL, sysvar_40D1
        call    print_header
        ld      B, 6
        ld      IX, CLI_buffer
        call    print_nvalue

        ld      HL, sysvar_40D7
        call    print_header
        ld      B, 16
        ld      IX, CLI_buffer_cmd
        call    print_nvalue

        ld      HL, sysvar_40E7
        call    print_header
        ld      B, 16
        ld      IX, CLI_buffer_parm1_val
        call    print_nvalue

        ld      HL, sysvar_40F7
        call    print_header
        ld      B, 16
        ld      IX, CLI_buffer_parm2_val
        call    print_nvalue

        ld      HL, sysvar_4107
        call    print_header
        ld      B, 32
        ld      IX, CLI_buffer_pgm
        call    print_nvalue

        ld      HL, sysvar_4127
        call    print_header
        ld      B, 64
        ld      IX, CLI_buffer_full_cmd
        call    print_nvalue
; RTC -------------------------------------------------------------------------
        ld      HL, title_RTC
        ld      A, ANSI_COLR_CYA
        call    print_title

        ld      HL, sysvar_4167
        call    print_header
        ld      HL, RTC_hour
        call    print_bytevalue

        ld      HL, sysvar_4168
        call    print_header
        ld      HL, RTC_minutes
        call    print_bytevalue

        ld      HL, sysvar_4169
        call    print_header
        ld      HL, RTC_seconds
        call    print_bytevalue

        ld      HL, sysvar_416A
        call    print_header
        ld      HL, RTC_century
        call    print_bytevalue

        ld      HL, sysvar_416B
        call    print_header
        ld      HL, RTC_year
        call    print_bytevalue

        ld      HL, sysvar_416C
        call    print_header
        ld      DE, (RTC_year4)
        call    print_wordvalue

        ld      HL, sysvar_416E
        call    print_header
        ld      HL, RTC_month
        call    print_bytevalue

        ld      HL, sysvar_416F
        call    print_header
        ld      HL, RTC_day
        call    print_bytevalue

        ld      HL, sysvar_4170
        call    print_header
        ld      HL, RTC_day_of_the_week
        call    print_bytevalue

; Math ------------------------------------------------------------------------
        ; ld      HL, title_math
        ; ld      A, ANSI_COLR_CYA
        ; call    print_title

; Generic ---------------------------------------------------------------------
        ld      HL, title_generic
        ld      A, ANSI_COLR_CYA
        call    print_title

        ld      HL, sysvar_4175
        call    print_header
        ld      HL, FDD_detected
        call    print_bytevalue

        ld      HL, sysvar_4176
        call    print_header
        ld      HL, SD_images_num
        call    print_bytevalue

        ld      HL, sysvar_4177
        call    print_header
        ld      HL, DISK_current
        call    print_bytevalue

        ld      HL, sysvar_4178
        call    print_header
        ld      HL, DISK_status
        call    print_bytevalue

        ld      HL, sysvar_4179
        call    print_header
        ld      HL, DISK_file_type
        call    print_bytevalue

        ld      HL, sysvar_417A
        call    print_header
        ld      DE, (DISK_loadsave_addr)
        call    print_wordvalue

        ld      HL, sysvar_417C
        call    print_header
        ld      DE, (tmp_addr1)
        call    print_wordvalue

        ld      HL, sysvar_417E
        call    print_header
        ld      DE, (tmp_addr2)
        call    print_wordvalue

        ld      HL, sysvar_4180
        call    print_header
        ld      DE, (tmp_addr3)
        call    print_wordvalue

        ld      HL, sysvar_4182
        call    print_header
        ld      HL, tmp_byte
        call    print_bytevalue

        ld      HL, sysvar_4183
        call    print_header
        ld      HL, tmp_byte2
        call    print_bytevalue
; VDP -------------------------------------------------------------------------
        ld      HL, title_VDP
        ld      A, ANSI_COLR_CYA
        call    print_title

        ld      HL, sysvar_4184
        call    print_header
        ld      HL, NMI_enable
        call    print_bytevalue

        ld      HL, sysvar_4185
        call    print_header
        ld      HL, NMI_usr_jump
        call    print_bytevalue

        ld      HL, sysvar_4186
        call    print_header
        ld      HL, VDP_cur_mode
        call    print_bytevalue

        ld      HL, sysvar_4187
        call    print_header
        ld      HL, VDP_cursor_x
        call    print_bytevalue

        ld      HL, sysvar_4188
        call    print_header
        ld      HL, VDP_cursor_y
        call    print_bytevalue

        ld      HL, sysvar_4189
        call    print_header
        ld      DE, (VDP_PTRNTAB_addr)
        call    print_wordvalue

        ld      HL, sysvar_418B
        call    print_header
        ld      DE, (VDP_NAMETAB_addr)
        call    print_wordvalue

        ld      HL, sysvar_418D
        call    print_header
        ld      DE, (VDP_COLRTAB_addr)
        call    print_wordvalue

        ld      HL, sysvar_418F
        call    print_header
        ld      DE, (VDP_SPRPTAB_addr)
        call    print_wordvalue

        ld      HL, sysvar_4191
        call    print_header
        ld      DE, (VDP_SPRATAB_addr)
        call    print_wordvalue

        ld      HL, sysvar_4193
        call    print_header
        ld      HL, VDP_jiffy_byte1
        call    print_bytevalue

        ld      HL, sysvar_4194
        call    print_header
        ld      HL, VDP_jiffy_byte2
        call    print_bytevalue

        ld      HL, sysvar_4195
        call    print_header
        ld      HL, VDP_jiffy_byte3
        call    print_bytevalue
; System Colour Scheme --------------------------------------------------------
        ld      HL, title_colsch
        ld      A, ANSI_COLR_CYA
        call    print_title

        ld      HL, sysvar_4196
        call    print_header
        ld      HL, col_kernel_debug
        call    print_bytevalue

        ld      HL, sysvar_4197
        call    print_header
        ld      HL, col_kernel_disk
        call    print_bytevalue

        ld      HL, sysvar_4198
        call    print_header
        ld      HL, col_kernel_error
        call    print_bytevalue

        ld      HL, sysvar_4199
        call    print_header
        ld      HL, col_kernel_info
        call    print_bytevalue

        ld      HL, sysvar_419A
        call    print_header
        ld      HL, col_kernel_notice
        call    print_bytevalue

        ld      HL, sysvar_419B
        call    print_header
        ld      HL, col_kernel_warning
        call    print_bytevalue

        ld      HL, sysvar_419C
        call    print_header
        ld      HL, col_kernel_welcome
        call    print_bytevalue

        ld      HL, sysvar_419D
        call    print_header
        ld      HL, col_CLI_debug
        call    print_bytevalue

        ld      HL, sysvar_419E
        call    print_header
        ld      HL, col_CLI_disk
        call    print_bytevalue

        ld      HL, sysvar_419F
        call    print_header
        ld      HL, col_CLI_error
        call    print_bytevalue

        ld      HL, sysvar_41A0
        call    print_header
        ld      HL, col_CLI_info
        call    print_bytevalue

        ld      HL, sysvar_41A1
        call    print_header
        ld      HL, col_CLI_input
        call    print_bytevalue

        ld      HL, sysvar_41A2
        call    print_header
        ld      HL, col_CLI_notice
        call    print_bytevalue

        ld      HL, sysvar_41A3
        call    print_header
        ld      HL, col_CLI_prompt
        call    print_bytevalue

        ld      HL, sysvar_41A4
        call    print_header
        ld      HL, col_CLI_warning
        call    print_bytevalue

        jp      exitpgm
; -----------------------------------------------------------------------------
print_header:
; Prints the name of the SYSVAR variable in magenta colour,
;   and then switches to white colour
; IN <= HL = points to text that contains the variable's name
        ld      A, ANSI_COLR_MGT
print_title:
; IN <= A = ANSI colour
        call    F_KRN_SERIAL_WRSTRCLR
        ; Switch to ANSI white
        ld      A, ANSI_COLR_WHT
        call    F_KRN_SERIAL_SETFGCOLR
        ret
; -----------------------------------------------------------------------------
print_bytevalue:
; Prints a 1 byte SYSVAR value
; IN <= HL = points to the SYSVARS value
        ; Get SYSVAR value and convert it to ASCII
        ld      A, (HL)
print_preldvalue:
        call    F_KRN_HEX_TO_ASCII
        ; Print value (1 byte)
        ld      A, H
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, L
        call    F_BIOS_SERIAL_CONOUT_A
        ret
; -----------------------------------------------------------------------------
print_wordvalue:
; Prints a 2 bytes SYSVAR value. Each byte is separated by a space
; IN <= DE = contains the value loaded from SYSVARS
        ; Get SYSVAR value and convert MSB to ASCII
        ld      A, D
        call    F_KRN_HEX_TO_ASCII
        ; Print value (1st byte)
        ld      A, H
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, L
        call    F_BIOS_SERIAL_CONOUT_A
        ; Print space separator
        ld      A, SPACE
        call    F_BIOS_SERIAL_CONOUT_A
        ; Get SYSVAR value and convert LSB to ASCII
        ld      A, E
        call    F_KRN_HEX_TO_ASCII
        ; Print value (2nd byte)
        ld      A, H
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, L
        call    F_BIOS_SERIAL_CONOUT_A
        ret
; -----------------------------------------------------------------------------
print_nvalue:
; Prints a n bytes SYSVAR value. Each byte is separated by a space
; IN <= IX = points to the 1st byte of the SYSVARS value
;        B = number of bytes to print
_print_bytes:
        push    BC
        ld      A, (IX)
        call    print_preldvalue
        ; Print space separator
        ld      A, SPACE
        call    F_BIOS_SERIAL_CONOUT_A
        inc     IX
        pop     BC
        djnz    _print_bytes
        ret


;==============================================================================
; RETURN TO DZOS CLI
;==============================================================================
exitpgm:
        ; Print CR+LF and exit to CLI
        ld      A, CR
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, LF
        call    F_BIOS_SERIAL_CONOUT_A
        ld      HL, (CLI_prompt_addr)
        jp      (HL)                    ; return control to CLI
;==============================================================================
; Messages
;==============================================================================
title_SIO:     .BYTE   CR, LF, "SIO", 0
title_sblock:  .BYTE   CR, LF, "DISK Superblock", 0
title_BAT:     .BYTE   CR, LF, "DISK BAT", 0
title_CLI:     .BYTE   CR, LF, "CLI", 0
title_RTC:     .BYTE   CR, LF, "RTC", 0
title_math:    .BYTE   CR, LF, "Math", 0
title_generic: .BYTE   CR, LF, "Generic", 0
title_VDP:     .BYTE   CR, LF, "VDP", 0
title_colsch:  .BYTE   CR, LF, "System Colour Scheme", 0
; sysvar_4020:    .BYTE   CR, LF, "    SIO_CH_A_BUFFER: ", 0
; sysvar_4060:    .BYTE   CR, LF, "    SIO_CH_A_IN_PTR: ", 0
; sysvar_4062:    .BYTE   CR, LF, "    SIO_CH_A_RD_PTR: ", 0
; sysvar_4064:    .BYTE   CR, LF, "    SIO_CH_A_BUFFER_USED: ", 0
; sysvar_4065:    .BYTE   CR, LF, "    SIO_CH_A_LASTCHAR: ", 0
; sysvar_4066:    .BYTE   CR, LF, "    SIO_CH_B_BUFFER: ", 0
; sysvar_40A6:    .BYTE   CR, LF, "    SIO_CH_B_IN_PTR: ", 0
; sysvar_40A8:    .BYTE   CR, LF, "    SIO_CH_B_RD_PTR: ", 0
; sysvar_40AA:    .BYTE   CR, LF, "    SIO_CH_B_BUFFER_USED: ", 0
sysvar_40AB:    .BYTE   CR, LF, "    DISK_is_formatted: ", 0
sysvar_40AC:    .BYTE   CR, LF, "    DISK_show_deleted: ", 0
sysvar_40AD:    .BYTE   CR, LF, "    DISK_cur_sector: ", 0
sysvar_40AF:    .BYTE   CR, LF, "    DISK_cur_file_name: ", 0
sysvar_40BD:    .BYTE   CR, LF, "    DISK_cur_file_attribs: ", 0
sysvar_40BE:    .BYTE   CR, LF, "    DISK_cur_file_time_created: ", 0
sysvar_40C0:    .BYTE   CR, LF, "    DISK_cur_file_date_created: ", 0
sysvar_40C2:    .BYTE   CR, LF, "    DISK_cur_file_time_modified: ", 0
sysvar_40C4:    .BYTE   CR, LF, "    DISK_cur_file_date_modified: ", 0
sysvar_40C6:    .BYTE   CR, LF, "    DISK_cur_file_size_bytes: ", 0
sysvar_40C8:    .BYTE   CR, LF, "    DISK_cur_file_size_sectors: ", 0
sysvar_40C9:    .BYTE   CR, LF, "    DISK_cur_file_entry_number: ", 0
sysvar_40CB:    .BYTE   CR, LF, "    DISK_cur_file_1st_sector: ", 0
sysvar_40CD:    .BYTE   CR, LF, "    DISK_cur_file_load_addr: ", 0
sysvar_40CF:    .BYTE   CR, LF, "    CLI_prompt_addr: ", 0
sysvar_40D1:    .BYTE   CR, LF, "    CLI_buffer: ", 0
sysvar_40D7:    .BYTE   CR, LF, "    CLI_buffer_cmd: ", 0
sysvar_40E7:    .BYTE   CR, LF, "    CLI_buffer_parm1_val: ", 0
sysvar_40F7:    .BYTE   CR, LF, "    CLI_buffer_parm2_val: ", 0
sysvar_4107:    .BYTE   CR, LF, "    CLI_buffer_pgm: ", 0
sysvar_4127:    .BYTE   CR, LF, "    CLI_buffer_full_cmd: ", 0
sysvar_4167:    .BYTE   CR, LF, "    RTC_hour: ", 0
sysvar_4168:    .BYTE   CR, LF, "    RTC_minutes: ", 0
sysvar_4169:    .BYTE   CR, LF, "    RTC_seconds: ", 0
sysvar_416A:    .BYTE   CR, LF, "    RTC_century: ", 0
sysvar_416B:    .BYTE   CR, LF, "    RTC_year: ", 0
sysvar_416C:    .BYTE   CR, LF, "    RTC_year4: ", 0
sysvar_416E:    .BYTE   CR, LF, "    RTC_month: ", 0
sysvar_416F:    .BYTE   CR, LF, "    RTC_day: ", 0
sysvar_4170:    .BYTE   CR, LF, "    RTC_day_of_the_week: ", 0
sysvar_4171:    .BYTE   CR, LF, "    MATH_CRC: ", 0
sysvar_4173:    .BYTE   CR, LF, "    MATH_polynomial: ", 0
sysvar_4175:    .BYTE   CR, LF, "    FDD_detected: ", 0
sysvar_4176:    .BYTE   CR, LF, "    SD_images_num: ", 0
sysvar_4177:    .BYTE   CR, LF, "    DISK_current: ", 0
sysvar_4178:    .BYTE   CR, LF, "    DISK_status: ", 0
sysvar_4179:    .BYTE   CR, LF, "    DISK_file_type: ", 0
sysvar_417A:    .BYTE   CR, LF, "    DISK_loadsave_addr: ", 0
sysvar_417C:    .BYTE   CR, LF, "    tmp_addr1: ", 0
sysvar_417E:    .BYTE   CR, LF, "    tmp_addr2: ", 0
sysvar_4180:    .BYTE   CR, LF, "    tmp_addr3: ", 0
sysvar_4182:    .BYTE   CR, LF, "    tmp_byte: ", 0
sysvar_4183:    .BYTE   CR, LF, "    tmp_byte2: ", 0
sysvar_4184:    .BYTE   CR, LF, "    NMI_enable: ", 0
sysvar_4185:    .BYTE   CR, LF, "    NMI_usr_jump: ", 0
sysvar_4186:    .BYTE   CR, LF, "    VDP_cur_mode: ", 0
sysvar_4187:    .BYTE   CR, LF, "    VDP_cursor_x: ", 0
sysvar_4188:    .BYTE   CR, LF, "    VDP_cursor_y: ", 0
sysvar_4189:    .BYTE   CR, LF, "    VDP_PTRNTAB_addr: ", 0
sysvar_418B:    .BYTE   CR, LF, "    VDP_NAMETAB_addr: ", 0
sysvar_418D:    .BYTE   CR, LF, "    VDP_COLRTAB_addr: ", 0
sysvar_418F:    .BYTE   CR, LF, "    VDP_SPRPTAB_addr: ", 0
sysvar_4191:    .BYTE   CR, LF, "    VDP_SPRATAB_addr: ", 0
sysvar_4193:    .BYTE   CR, LF, "    VDP_jiffy_byte1: ", 0
sysvar_4194:    .BYTE   CR, LF, "    VDP_jiffy_byte2: ", 0
sysvar_4195:    .BYTE   CR, LF, "    VDP_jiffy_byte3: ", 0
sysvar_4196:    .BYTE   CR, LF, "    col_kernel_debug: ", 0
sysvar_4197:    .BYTE   CR, LF, "    col_kernel_disk: ", 0
sysvar_4198:    .BYTE   CR, LF, "    col_kernel_error: ", 0
sysvar_4199:    .BYTE   CR, LF, "    col_kernel_info: ", 0
sysvar_419A:    .BYTE   CR, LF, "    col_kernel_notice: ", 0
sysvar_419B:    .BYTE   CR, LF, "    col_kernel_warning: ", 0
sysvar_419C:    .BYTE   CR, LF, "    col_kernel_welcome: ", 0
sysvar_419D:    .BYTE   CR, LF, "    col_CLI_debug: ", 0
sysvar_419E:    .BYTE   CR, LF, "    col_CLI_disk: ", 0
sysvar_419F:    .BYTE   CR, LF, "    col_CLI_error: ", 0
sysvar_41A0:    .BYTE   CR, LF, "    col_CLI_info: ", 0
sysvar_41A1:    .BYTE   CR, LF, "    col_CLI_input: ", 0
sysvar_41A2:    .BYTE   CR, LF, "    col_CLI_notice: ", 0
sysvar_41A3:    .BYTE   CR, LF, "    col_CLI_prompt: ", 0
sysvar_41A4:    .BYTE   CR, LF, "    col_CLI_warning: ", 0

;==============================================================================
; END of CODE
;==============================================================================
        .END