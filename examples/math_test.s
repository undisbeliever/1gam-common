;; Routine that tests the Math Routines for correctness.

.define VERSION 1
.define REGION NTSC
.define ROM_NAME "MATH TEST"


.include "includes/sfc_header.inc"
.include "includes/import_export.inc"
.include "includes/synthetic.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"

.include "routines/math.h"
.include "routines/reset-snes.h"
.include "routines/text.h"
.include "routines/text8x8.h"
.include "routines/text8x16.h"

BG1_MAP			= $0400
BG1_TILES		= $1000

.zeropage
	BYTE	tmpByte
	WORD	tmpWord

.segment "SHADOW"
	ADDR	pageIndex


.code
ROUTINE Main
	REP	#$10        ; X/Y 16-bit
	SEP	#$20        ; A 8-bit
.A8
.I16

	JSR	SetupPPU

	Text_LoadFont Font8x16BoldTransparent, BG1_TILES, BG1_MAP

	JSR	LoadPalette

	Text_SelectWindow #0
	Text_SetStringWordWrapping
	Text_SetInterface Text8x16__Interface, 0
	Text_SetupWindow 1, 1, 30, 26, Text__WINDOW_NO_BORDER

	LDA	#$0F
	STA	INIDISP


	LDX	#0
	STX	pageIndex

	REPEAT
		JSR	Text__ClearWindow

		LDX	pageIndex
		JSR	(.loword(PageRoutines), X)

		JSR	WaitForKeypress

		; Increment pageIndex
		LDX	pageIndex
		INX
		INX
		CPX	#PageRoutinesEnd - PageRoutines
		IF_GE
			LDX	#0
		ENDIF

		STX	pageIndex
	FOREVER


LABEL PageRoutines
	.addr	SignedPrintingPage
	.addr	DivisionPage

PageRoutinesEnd:


.A8
.I16
ROUTINE SignedPrintingPage
	Text_PrintStringLn "Signed Printing Page"
	Text_PrintStringLn "--------------------"

	Text_NewLine

	Text_PrintString "S8A   Minus 33     "
	LDA	#.lobyte(-33)
	JSR	Text__PrintDecimal_S8A

	Text_NewLine

	Text_PrintString "S16Y  Minus 1      "
	LDY	#.loword(-1)
	JSR	Text__PrintDecimal_S16Y

	Text_NewLine

	Text_PrintString "S32XY Minus 123456 "
	LDXY	#-123456
	JSR	Text__PrintDecimal_S32XY

	Text_NewLine
	Text_NewLine

	Text_PrintString "S8A   Plus 33      "
	LDA	#.lobyte(33)
	JSR	Text__PrintDecimal_S8A

	Text_NewLine

	Text_PrintString "S16Y  Plus 1       "
	LDA	#6
	LDY	#.loword(1)
	JSR	Text__PrintDecimalPadded_S16Y

	Text_NewLine

	Text_PrintString "S32XY Plus 123456  "
	LDA	#8
	LDXY	#123456
	JSR	Text__PrintDecimalPadded_S32XY

	Text_NewLine
	Text_NewLine

	Text_PrintString "S16Y  Minus 1      "
	LDA	#6
	LDY	#.loword(-1)
	JSR	Text__PrintDecimalPadded_S16Y

	Text_NewLine

	Text_PrintString "S32XY Minus 123456 "
	LDA	#8
	LDXY	#-123456
	JSR	Text__PrintDecimalPadded_S32XY

	Text_NewLine

	RTS



.A8
.I16
ROUTINE DivisionPage
	Text_PrintStringLn "DIVIDE_U16X_U16Y"
	Text_PrintString "  12345 / 678   = "
	LDX	#12345
	LDY	#678
	JSR	Math__DIVIDE_U16X_U16Y

	STY	tmpWord
	TXY
	JSR	Text__PrintDecimal_U16Y

	Text_PrintString " r "

	Text_PrintDecimal tmpWord

	Text_NewLine

	; Divisor is one byte test.
	Text_PrintString "  12345 / 67    = "
	LDX	#12345
	LDY	#67
	JSR	Math__DIVIDE_U16X_U16Y

	STY	tmpWord
	TXY
	JSR	Text__PrintDecimal_U16Y

	Text_PrintString " r "

	Text_PrintDecimal tmpWord
	
	Text_NewLine
	Text_NewLine

	Text_PrintStringLn "DIVIDE_U16X_U8A"
	Text_PrintString "  9876 / 54     = "
	LDX	#9876
	LDA	#54
	JSR	Math__DIVIDE_U16X_U8A

	STY	tmpWord
	TXY
	JSR	Text__PrintDecimal_U16Y

	Text_PrintString " r "

	Text_PrintDecimal tmpWord
	
	Text_NewLine
	Text_NewLine

	Text_PrintStringLn "DIVIDE_U32_U32"
	Text_PrintString "  123456 / 789  = "

	LDXY	#123456
	STXY	Math__dividend32
	LDXY	#789
	STXY	Math__divisor32

	JSR	Math__DIVIDE_U32_U32

	Text_PrintDecimal Math__result32
	Text_PrintString " r "
	Text_PrintDecimal Math__remainder32

	Text_NewLine

	Text_PrintString "  987 / 654321  = "

	LDXY	#987
	STXY	Math__dividend32
	LDXY	#654321
	STXY	Math__divisor32

	JSR	Math__DIVIDE_U32_U32

	Text_PrintDecimal Math__result32
	Text_PrintString " r "
	Text_PrintDecimal Math__remainder32

	Text_NewLine
	Text_NewLine

	Text_PrintStringLn "DIVIDE_U32_U8A"
	Text_PrintString "  12345678 / 9  = "

	LDXY	#12345678
	STXY	Math__dividend32
	LDA	#9

	JSR	Math__DIVIDE_U32_U8A

	STA	tmpByte

	Text_PrintDecimal Math__result32
	Text_PrintString " r "
	Text_PrintDecimal tmpByte

	RTS



;; Waits for a keypress, then until keys released.
;;
;; REQUIRES: 16 bit Index
.I16
ROUTINE WaitForKeypress
	; Wait until button pressed
	REPEAT
		WAI
		LDY	JOY1
	UNTIL_NOT_ZERO

	; Wait until button released
	REPEAT
		WAI
		LDY	JOY1
	UNTIL_ZERO

	RTS



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
;; Mode 0, BG1 enabled, BG1 tilepos set by BG1_Tilemap and BG1_Tiles, and VBlank enabled
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

	LDA	#NMITIMEN_VBLANK_FLAG | NMITIMEN_AUTOJOY_FLAG
	STA	NMITIMEN

	RTS



;; Copies the palette to CGRAM
;;
;; REQUIRES 8 bit A, 16 bit Index, Forced Blank
.A8
.I16
ROUTINE LoadPalette
	; ::TODO DMAPalette macro::
	; Load white to color 1
	LDA	#0
	STA	CGADD

	LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_1REG
	STA	DMAP0

	LDA	#.lobyte(CGDATA)
	STA	BBAD0

	LDX	#FontBoldTransparentPalette_End - FontBoldTransparentPalette
	STX	DAS0

	LDX	#.loword(FontBoldTransparentPalette)
	STX	A1T0
	LDA	#.bankbyte(FontBoldTransparentPalette)
	STA	A1B0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN
	
	RTS



.rodata

Font8x8BoldTransparent:
	.incbin "../resources/font8x8-bold-transparent.2bpp"
Font8x8BoldTransparent_End:

Font8x16BoldTransparent:
	.incbin "../resources/font8x16-bold-transparent.2bpp"
Font8x16BoldTransparent_End:

FontBoldTransparentPalette:                ; ANSI Colors
	.word	$7FFF, $0000, $4e73, $6b3a ; Black   (0)
	.word	$7FFF, $001F, $4e73, $6b3a ; Red     (1)
	.word	$7FFF, $02E0, $4e73, $6b3a ; Green   (2)
	.word	$7FFF, $02FF, $4e73, $6b3a ; Yellow  (3)
	.word	$7FFF, $7C00, $4e73, $6b3a ; Blue    (4)
	.word	$7FFF, $3C0F, $4e73, $6b3a ; Magenta (5)
	.word	$7FFF, $3DE0, $4e73, $6b3a ; Cyan    (6)
	.word	$7FFF, $3DEF, $4e73, $6b3a ; Gray    (7)
FontBoldTransparentPalette_End:

