;******************************************************************************
; Name:         ?????.asm
; Description:  ?????
; Author:       ?????
; License:      The MIT License
; Created:      ?? ??? ????
; Version:      ?????
; Last Modif.:  ?? ??? ????
; Length bytes: ??
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; Copyright (C) ?????
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
; YOUR PROGRAM GOES HERE
;==============================================================================

;==============================================================================
; RETURN TO DZOS CLI
;==============================================================================
; To return to CLI, jump to the address stored at SYSVARS.CLI_prompt_addr
; This ensure that any changes in the Operating System won't affect your program
        ld      HL, (CLI_prompt_addr)
        jp      (HL)                    ; return control to CLI

;==============================================================================
; END of CODE
;==============================================================================
        .END