;******************************************************************************
; Name:         _header.inc
; Description:  Standard include for software to be run on dastaZ80
;               It contains the necessary includes and the standard load address
; Author:       David Asta
; License:      The MIT License
; Created:      28 Aug 2022
; Version:      1.0
; Last Modif.:  28 Aug 2022
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; Copyright (C) 2022 David Asta
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
#include "src/equates.inc"
#include "exp/dzOS.exp"
#include "exp/sysvars.exp"
.LIST

        .ORG    $4420                   ; start of code at start of free RAM
        jp      $4425                   ; first instruction must jump to the executable code
        .BYTE   $20, $44                ; load address (values must be same as .org above)

        .ORG	$4425                   ; start of program (must be same as jp above)
