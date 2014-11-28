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
	.addr	MultiplicationPage1
	.addr	MultiplicationPage2
	.addr	MultiplicationPage3
	.addr	DivisionPage1

PageRoutinesEnd:


; Sets color red if Y is wrong, otherwise green.
.macro Check_U16Y expected
	PHA
	PHY
	PHX
		CPY	#expected
		IF_NE
			Text_SetColor	#1
		ELSE
			Text_SetColor	#2
		ENDIF
	PLX
	PLY
	PLA
.endmacro

; Sets color red if X is wrong, otherwise green.
.macro Check_U16X expected
	PHA
	PHY
	PHX
		CPX	#expected
		IF_NE
			Text_SetColor	#1
		ELSE
			Text_SetColor	#2
		ENDIF
	PLX
	PLY
	PLA
.endmacro

; Sets color red if XY is wrong, otherwise green.
.macro Check_U32XY expected
	PHA
	PHX
	PHY
		CPX	#.hiword(expected)
		IF_NE
			Text_SetColor	#1
		ELSE
			CPY	#.loword(expected)
			IF_NE
				Text_SetColor	#1
			ELSE
				Text_SetColor	#2
			ENDIF
		ENDIF
	PLY
	PLX
	PLA
.endmacro

; Sets color red if A is wrong, otherwise green.
.macro Check_U8A expectedA
	PHA
	PHX
	PHY
		CMP	#expectedA
		IF_NE
			Text_SetColor	#1
		ELSE
			Text_SetColor	#2
		ENDIF
	PLY
	PLX
	PLA
.endmacro


.A8
.I16
ROUTINE SignedPrintingPage
	Text_SetColor	#4
	Text_PrintStringLn "Signed Printing Page"

	Text_SetColor	#0
	Text_NewLine

	Text_PrintString " S8A   Minus 33     = "
	LDA	#.lobyte(-33)
	JSR	Text__PrintDecimal_S8A

	Text_NewLine

	Text_PrintString " S16Y  Minus 1      = "
	LDY	#.loword(-1)
	JSR	Text__PrintDecimal_S16Y

	Text_NewLine

	Text_PrintString " S32XY Minus 123456 = "
	LDXY	#-123456
	JSR	Text__PrintDecimal_S32XY

	Text_NewLine
	Text_NewLine

	Text_PrintString " S8A   Plus 33      = "
	LDA	#.lobyte(33)
	JSR	Text__PrintDecimal_S8A

	Text_NewLine

	Text_PrintString " S16Y  Plus 1       = "
	LDA	#6
	LDY	#.loword(1)
	JSR	Text__PrintDecimalPadded_S16Y

	Text_NewLine

	Text_PrintString " S32XY Plus 123456  = "
	LDA	#8
	LDXY	#123456
	JSR	Text__PrintDecimalPadded_S32XY

	Text_NewLine

	Text_PrintString " S16Y  Minus 1      = "
	LDA	#6
	LDY	#.loword(-1)
	JSR	Text__PrintDecimalPadded_S16Y

	Text_NewLine

	Text_PrintString " S32XY Minus 123456 = "
	LDA	#8
	LDXY	#-123456
	JSR	Text__PrintDecimalPadded_S32XY

	RTS


.A8
.I16
ROUTINE MultiplicationPage1
	Text_SetColor	#4
	Text_PrintString "Multiply_U8Y_U8X"
	
	.macro Test_Multiply_U8Y_U8X factorY, factorX
		Text_NewLine
		Text_SetColor	#0
		Text_PrintString .sprintf("%10u * %3u = ", factorY, factorX)

		LDY	#factorY
		LDX	#factorX
		JSR	Math__Multiply_U8Y_U8X

		Check_U16Y (factorY * factorX)
		JSR	Text__PrintDecimal_U16Y
	.endmacro

	Test_Multiply_U8Y_U8X	2, 2
	Test_Multiply_U8Y_U8X	123, 56

	Text_SetColor	#4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Multiply_U16Y_U8A"

	.macro Test_Multiply_U16Y_U8A factorY, factorA
		Text_NewLine
		Text_SetColor	#0
		Text_PrintString .sprintf("%10u * %3u = ", factorY, factorA)

		LDY	#factorY
		LDA	#factorA
		JSR	Math__Multiply_U16Y_U8A
		LDXY	Math__product32

		Check_U32XY (factorY * factorA)
		JSR	Text__PrintDecimal_U32XY
	.endmacro

	Test_Multiply_U16Y_U8A	12345, 67
	Test_Multiply_U16Y_U8A	$FEFE, $FE



	Text_SetColor	#4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Multiply_U32XY_U8A"

	.macro Test_Multiply_U32XY_U8A factor32, factorA
		Text_NewLine
		Text_SetColor	#0
		Text_PrintString .sprintf("%10u * %3u = ", factor32, factorA)

		LDXY	#factor32
		LDA	#factorA
		JSR	Math__Multiply_U32XY_U8A

		Check_U32XY (factor32 * factorA)
		JSR	Text__PrintDecimal_U32XY
	.endmacro

	Test_Multiply_U32XY_U8A	1234567, 89
	Test_Multiply_U32XY_U8A	9876543, 21
	Test_Multiply_U32XY_U8A	1984, 0
	Test_Multiply_U32XY_U8A	$FEFEFEFE, $FE

	RTS



.A8
.I16
ROUTINE MultiplicationPage2
	Text_SetColor	#4
	Text_PrintString "Multiply_U16Y_U16X"

	.macro Test_Multiply_U16Y_U16X factorY, factorX
		Text_NewLine
		Text_SetColor	#0
		Text_PrintString .sprintf("%7u * %6u = ", factorY, factorX)

		LDY	#factorY
		LDX	#factorX
		JSR	Math__Multiply_U16Y_U16X

		Check_U32XY (factorY * factorX)
		JSR	Text__PrintDecimal_U32XY
	.endmacro

	Test_Multiply_U16Y_U16X	123, 456
	Test_Multiply_U16Y_U16X	9876, 54321
	Test_Multiply_U16Y_U16X	393, 28966
	Test_Multiply_U16Y_U16X	10776, 9568
	Test_Multiply_U16Y_U16X	$FEFE, $FEFE


	Text_SetColor	#4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Multiply_U32_U16Y"

	.macro Test_Multiply_U32_U16Y factor32, factorY
		Text_NewLine
		Text_SetColor	#0
		Text_PrintString .sprintf("%8u * %5u = ", factor32, factorY)

		LDXY	#factor32
		STXY	Math__factor32
		LDY	#factorY
		JSR	Math__Multiply_U32_U16Y

		Check_U32XY (factor32 * factorY)
		JSR	Text__PrintDecimal_U32XY
	.endmacro

	Test_Multiply_U32_U16Y	123, 456
	Test_Multiply_U32_U16Y	9876, 54321
	Test_Multiply_U32_U16Y	393, 28966
	Test_Multiply_U32_U16Y	$FEFE, $FEFE
	Test_Multiply_U32_U16Y	$FEFEFE, $FEFE

	RTS



.A8
.I16
ROUTINE MultiplicationPage3
	Text_SetColor	#4
	Text_PrintStringLn "Multiply_U32_U32XY (hex)"
	Text_NewLine

	.macro Test_Multiply_U32_U32XY factor32, factorXY
		; no new line, because of text overflow
		Text_SetColor	#0
		Text_PrintString .sprintf("%8X * %8X = ", factor32, factorXY)

		LDXY	#factor32
		STXY	Math__factor32
		LDXY	#factorXY
		JSR	Math__Multiply_U32_U32XY

		Check_U32XY (factor32 * factorXY)
		Text_PrintHex	Math__product32
	.endmacro

	Test_Multiply_U32_U32XY	$01234567, $89ABCDEF
	Test_Multiply_U32_U32XY	$FEDCBA98, $76543210
	Test_Multiply_U32_U32XY	$0, $1234567
	Test_Multiply_U32_U32XY	$12343457, 0
	Test_Multiply_U32_U32XY	$FEFEFE, $FEFEFE
	Test_Multiply_U32_U32XY	$FEFEFEFE, $FEFEFEFE




	RTS



.A8
.I16
ROUTINE DivisionPage1
	Text_SetColor	#4
	Text_PrintString "Divide_U16Y_U16X"

	.macro Test_Divide_U16Y_U16X dividend, divisor
		Text_NewLine
		Text_SetColor	#0
		Text_PrintString .sprintf("%8u / %3u = ", dividend, divisor)

		LDY	#dividend
		LDX	#divisor
		JSR	Math__Divide_U16Y_U16X

		PHX
		Check_U16Y (dividend / divisor)
		JSR	Text__PrintDecimal_U16Y

		Text_SetColor	#0
		Text_PrintString " r "

		PLY
		Check_U16Y (dividend .mod divisor)
		JSR	Text__PrintDecimal_U16Y
	.endmacro


	Test_Divide_U16Y_U16X 12345, 678
	; Divisor is one byte test.
	Test_Divide_U16Y_U16X 9876, 5
	Test_Divide_U16Y_U16X 12345, 67

	Text_SetColor	#4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Divide_U32XY_U8A"

	.macro Test_Divide_U32_U8A dividend, divisor
		Text_NewLine
		Text_SetColor	#0
		Text_PrintString .sprintf("%8u / %3u = ", dividend, divisor)

		LDXY	#dividend
		STXY	Math__dividend32
		LDA	#divisor
		JSR	Math__Divide_U32_U8A

		PHA
		LDXY	Math__result32
		Check_U32XY (dividend / divisor)
		JSR	Text__PrintDecimal_U32XY

		Text_SetColor #0
		Text_PrintString " r "

		PLA
		Check_U8A (dividend .mod divisor)
		JSR	Text__PrintDecimal_U8A
	.endmacro

	Test_Divide_U32_U8A 9876, 54
	Test_Divide_U32_U8A 9876543, 21


	Text_NewLine
	Text_NewLine
	Text_SetColor	#4
	Text_PrintString "Divide_U32_U32"
	.macro Test_Divide_U32_U32 dividend, divisor
		Text_NewLine
		Text_SetColor	#0
		Text_PrintString .sprintf("%6u / %6u = ", dividend, divisor)

		LDXY	#dividend
		STXY	Math__dividend32
		LDXY	#divisor
		STXY	Math__divisor32
		JSR	Math__Divide_U32_U32

		LDXY	Math__result32
		Check_U32XY (dividend / divisor)
		JSR	Text__PrintDecimal_U32XY

		Text_SetColor #0
		Text_PrintString " r "

		LDXY	Math__remainder32
		Check_U32XY (dividend .mod divisor)
		JSR	Text__PrintDecimal_U32XY
	.endmacro

	Test_Divide_U32_U32 123456, 789
	Test_Divide_U32_U32 987654, 321
	Test_Divide_U32_U32 987, 654321

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

