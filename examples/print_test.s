; A test of `routines.text.s`

.define VERSION 1
.define REGION NTSC
.define ROM_NAME "PRINT TEST"


.include "includes/sfc_header.inc"
.include "includes/import_export.inc"
.include "includes/synthetic.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"

.include "routines/reset-snes.h"
.include "routines/text.h"

BG1_MAP		= $0400
BG1_TILES	= $1000


.code
ROUTINE Main
	REP	#$10        ; X/Y 16-bit
	SEP	#$20        ; A 8-bit
.A8
.I16

	JSR	SetupPPU

	; Enable V-Blank
	LDA	#NMITIMEN_VBLANK_FLAG
	STA	NMITIMEN

	Text_LoadFont Font8Bold, BG1_TILES, BG1_MAP, 1
	JSR	LoadPalette

	LDA	#$0F
	STA	INIDISP

	Text_SetupWindow 2, 2, 29, 25, Text::BORDER, 2

	LDA	#4
	JSR	Text::SetColor

	Text_PrintStringWrap "The quick brown fox jumped over the lazy dog."

	JSR	Text::NewLine

	LDA	#5
	JSR	Text::SetColor

	Text_PrintStringWrap "THE QUICK BROWN FOX JUMPED OVER THE LAZY DOG."

	JSR	Text::NewLine

	LDA	#6
	JSR	Text::SetColor

	Text_PrintString StringFromLabel

	LDA	#7
	JSR	Text::SetColor

	Text_PrintStringWrap StringFromLabel

	REPEAT
		WAI
	FOREVER

.rodata

StringFromLabel:
	.byte "123456789 123456789 123456789", EOL 
	.byte "123456789012345678901234567890", EOL, 0 ; Word wrap test

.code

;; Blank Handlers
IrqHandler:
CopHandler:
	RTI


VBlank:
	; Save state
	REP	#$30
	PHA
	PHX
	PHY

	SEP	#$20
.A8
.I16
	Text_VBlank

	; restore state
	REP	#$30
	PLY
	PLX
	PLA
	RTI



;; Sets up the screen base addresses and mode.
;;
;; Mode 0, BG1 enabled, BG1 tilepos set by BG1_Tilemap and BG1_Tiles
; ::TODO write macro::
.A8
.I16
ROUTINE SetupPPU
	LDA	#INIDISP_FORCE
	STA	INIDISP

	LDA	#BGMODE_MODE0
	STA	BGMODE

	LDA	#(BG1_MAP / BGXSC_BASE_WALIGN) << 2
	STA	BG1SC

	LDA	#BG1_TILES / BG12NBA_BASE_WALIGN
	STA	BG12NBA

	LDA	#TM_BG1
	STA	TM

	RTS



;; Copies the palette to CGRAM
;;
;; REQUIRES 8 bit A, 16 bit Index, Forced Blank
.A8
.I16
ROUTINE LoadPalette
	; Load white to color 1
	LDA	#0
	STA	CGADD

	LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_1REG
	STA	DMAP0

	LDA	#.lobyte(CGDATA)
	STA	BBAD0

	LDX	#Font8BoldPalette_End - Font8BoldPalette
	STX	DAS0

	LDX	#.loword(Font8BoldPalette)
	STX	A1T0
	LDA	#.bankbyte(Font8BoldPalette)
	STA	A1B0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN
	
	RTS



.rodata

Font8Bold:
	.res 16, 0
	.incbin "../resources/font8-bold.2bpp"
Font8Bold_End:

Font8BoldPalette:                          ; ANSI Colors
	.word	$001f, $7FFF, $0000, $5294 ; Black   (0)
	.word	$7FFF, $7FFF, $001F, $5294 ; Red     (1)
	.word	$7FFF, $7FFF, $02E0, $5294 ; Green   (2)
	.word	$7FFF, $7FFF, $02FF, $5294 ; Yellow  (3)
	.word	$7FFF, $7FFF, $7C00, $5294 ; Blue    (4)
	.word	$7FFF, $7FFF, $3C0F, $5294 ; Magenta (5)
	.word	$7FFF, $7FFF, $3DE0, $5294 ; Cyan    (6)
	.word	$7FFF, $7FFF, $3DEF, $5294 ; Gray    (7)
Font8BoldPalette_End:

