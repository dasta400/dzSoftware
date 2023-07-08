;******************************************************************************
; Name:         msx_fn6.asm
; Description:  MSX 6x8 Fonts (only space, and from $30 to $7A ASCII)
; Created:      08 Jan 2023
; Version:      1.0
; Last Modif.:  08 Jan 2023
;******************************************************************************

.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 00
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 01
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 02
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 03
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 04
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 05
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 06
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 07
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 08
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 09
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 0A
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 0B
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 0C
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 0D
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 0E
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 0F
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 10
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 11
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 12
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 13
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 14
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 15
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 16
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 17
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 18
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 19
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 1A
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 1B
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 1C
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 1D
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 1E
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 1F

.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; space

.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 21
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 22
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 23
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 24
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 25
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 26
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 27
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 28
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 29
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 2A
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 2B
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 2C
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 2D
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 2E
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 2F

.BYTE $70,$88,$98,$A8,$C8,$88,$70,$00   ; 0
.BYTE $20,$60,$A0,$20,$20,$20,$F8,$00   ; 1
.BYTE $70,$88,$08,$10,$60,$80,$F8,$00   ; 2
.BYTE $70,$88,$08,$30,$08,$88,$70,$00   ; 3
.BYTE $10,$30,$50,$90,$F8,$10,$10,$00   ; 4
.BYTE $F8,$80,$E0,$10,$08,$10,$E0,$00   ; 5
.BYTE $30,$40,$80,$F0,$88,$88,$70,$00   ; 6
.BYTE $F8,$88,$10,$20,$20,$20,$20,$00   ; 7
.BYTE $70,$88,$88,$70,$88,$88,$70,$00   ; 8
.BYTE $70,$88,$88,$78,$08,$10,$60,$00   ; 9
.BYTE $00,$00,$20,$00,$00,$20,$00,$00   ; :
.BYTE $00,$00,$20,$00,$00,$20,$20,$40   ; ;
.BYTE $18,$30,$60,$C0,$60,$30,$18,$00   ; <
.BYTE $C0,$60,$30,$18,$30,$60,$C0,$00   ; =
.BYTE $00,$00,$F8,$00,$F8,$00,$00,$00   ; >
.BYTE $70,$88,$08,$10,$20,$00,$20,$00   ; ?
.BYTE $70,$88,$08,$68,$A8,$A8,$70,$00   ; @
.BYTE $20,$50,$88,$88,$F8,$88,$88,$00   ; A
.BYTE $F0,$48,$48,$70,$48,$48,$F0,$00   ; B
.BYTE $30,$48,$80,$80,$80,$48,$30,$00   ; C
.BYTE $E0,$50,$48,$48,$48,$50,$E0,$00   ; D
.BYTE $F8,$80,$80,$F0,$80,$80,$F8,$00   ; E
.BYTE $F8,$80,$80,$F0,$80,$80,$80,$00   ; F
.BYTE $70,$88,$80,$B8,$88,$88,$70,$00   ; G
.BYTE $88,$88,$88,$F8,$88,$88,$88,$00   ; H
.BYTE $70,$20,$20,$20,$20,$20,$70,$00   ; I
.BYTE $38,$10,$10,$10,$90,$90,$60,$00   ; J
.BYTE $88,$90,$A0,$C0,$A0,$90,$88,$00   ; K
.BYTE $80,$80,$80,$80,$80,$80,$F8,$00   ; L
.BYTE $88,$D8,$A8,$A8,$88,$88,$88,$00   ; M
.BYTE $88,$C8,$C8,$A8,$98,$98,$88,$00   ; N
.BYTE $70,$88,$88,$88,$88,$88,$70,$00   ; O
.BYTE $F0,$88,$88,$F0,$80,$80,$80,$00   ; P
.BYTE $70,$88,$88,$88,$A8,$90,$68,$00   ; Q
.BYTE $F0,$88,$88,$F0,$A0,$90,$88,$00   ; R
.BYTE $70,$88,$80,$70,$08,$88,$70,$00   ; S
.BYTE $F8,$20,$20,$20,$20,$20,$20,$00   ; T
.BYTE $88,$88,$88,$88,$88,$88,$70,$00   ; U
.BYTE $88,$88,$88,$88,$50,$50,$20,$00   ; V
.BYTE $88,$88,$88,$A8,$A8,$D8,$88,$00   ; W
.BYTE $88,$88,$50,$20,$50,$88,$88,$00   ; X
.BYTE $88,$88,$88,$70,$20,$20,$20,$00   ; Y
.BYTE $F8,$08,$10,$20,$40,$80,$F8,$00   ; Z
.BYTE $70,$40,$40,$40,$40,$40,$70,$00   ; [
.BYTE $00,$00,$80,$40,$20,$10,$08,$00   ; \
.BYTE $20,$50,$88,$00,$00,$00,$00,$00   ; ]
.BYTE $70,$10,$10,$10,$10,$10,$70,$00   ; ^
.BYTE $00,$00,$00,$00,$00,$00,$F8,$00   ; _
.BYTE $40,$20,$10,$00,$00,$00,$00,$00   ; `
.BYTE $00,$00,$70,$08,$78,$88,$78,$00   ; a
.BYTE $80,$80,$B0,$C8,$88,$C8,$B0,$00   ; b
.BYTE $00,$00,$70,$88,$80,$88,$70,$00   ; c
.BYTE $08,$08,$68,$98,$88,$98,$68,$00   ; d
.BYTE $00,$00,$70,$88,$F8,$80,$70,$00   ; e
.BYTE $10,$28,$20,$F8,$20,$20,$20,$00   ; f
.BYTE $00,$00,$68,$98,$98,$68,$08,$70   ; g
.BYTE $80,$80,$F0,$88,$88,$88,$88,$00   ; h
.BYTE $20,$00,$60,$20,$20,$20,$70,$00   ; i
.BYTE $10,$00,$30,$10,$10,$10,$90,$60   ; j
.BYTE $40,$40,$48,$50,$60,$50,$48,$00   ; k
.BYTE $60,$20,$20,$20,$20,$20,$70,$00   ; l
.BYTE $00,$00,$D0,$A8,$A8,$A8,$A8,$00   ; m
.BYTE $00,$00,$B0,$C8,$88,$88,$88,$00   ; n
.BYTE $00,$00,$70,$88,$88,$88,$70,$00   ; o
.BYTE $00,$00,$B0,$C8,$C8,$B0,$80,$80   ; p
.BYTE $00,$00,$68,$98,$98,$68,$08,$08   ; q
.BYTE $00,$00,$B0,$C8,$80,$80,$80,$00   ; r
.BYTE $00,$00,$78,$80,$F0,$08,$F0,$00   ; s
.BYTE $40,$40,$F0,$40,$40,$48,$30,$00   ; t
.BYTE $00,$00,$90,$90,$90,$90,$68,$00   ; u
.BYTE $00,$00,$88,$88,$88,$50,$20,$00   ; v
.BYTE $00,$00,$88,$A8,$A8,$A8,$50,$00   ; w
.BYTE $00,$00,$88,$50,$20,$50,$88,$00   ; x
.BYTE $00,$00,$88,$88,$98,$68,$08,$70   ; y
.BYTE $00,$00,$F8,$10,$20,$40,$F8,$00   ; z

.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 7B
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 7C
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 7D
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 7E
.BYTE $00,$00,$00,$00,$00,$00,$00,$00   ; Hex 7F

.END