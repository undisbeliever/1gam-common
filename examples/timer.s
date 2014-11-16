; A test of `routines/text.s` number routuines

.define VERSION 1
.define REGION NTSC
.define ROM_NAME "TIMER"


.include "includes/sfc_header.inc"
.include "includes/import_export.inc"
.include "includes/synthetic.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"

.include "routines/math.h"
.include "routines/reset-snes.h"
.include "routines/text.h"
.include "routines/text8x8.h"

FPS		= 60 ; ::TODO make configurable::

BG1_MAP		= $0400
BG1_TILES	= $1000

.segment "SHADOW"
	UINT32	frameCounter
	WORD	hours
	BYTE	minutes
	BYTE	seconds
	BYTE	fractionOfSeconds

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

	Text_LoadFont Font8BoldTransparent, BG1_TILES, BG1_MAP
	Text_SetInterface Text8x8::DoubleSpacingInterface, 0
	Text_SetStringBasic

	JSR	LoadPalette

	LDA	#$0F
	STA	INIDISP

	Text_SetupWindow 3, 3, 28, 24, Text::WINDOW_BORDER

	REPEAT
		JSR	CalculateTime

		; Hex

		LDX	#18
		LDY	#0
		JSR	Text::SetCursor

		LDX	frameCounter + 2
		JSR	Text::PrintHex_U16X
		LDX	frameCounter
		JSR	Text::PrintHex_U16X

		LDX	#13
		LDY	#1
		JSR	Text::SetCursor

		LDX	hours
		JSR	Text::PrintHex_U16X

		LDA	#':'
		JSR	Text::PrintChar

		LDA	minutes
		JSR	Text::PrintHex_U8A

		LDA	#':'
		JSR	Text::PrintChar

		LDA	seconds
		JSR	Text::PrintHex_U8A

		LDA	#':'
		JSR	Text::PrintChar

		LDA	fractionOfSeconds
		JSR	Text::PrintHex_U8A

		; Decimals

		LDX	#8
		LDY	#9
		JSR	Text::SetCursor

		LDX	frameCounter
		LDY	frameCounter + 2
		LDA	#10
		JSR	Text::PrintDecimalPadded_U32XY

		LDX	#8
		LDY	#12
		JSR	Text::SetCursor

		LDX	hours
		JSR	Text::PrintDecimal_U16X

		LDA	#':'
		JSR	Text::PrintChar

		LDA	minutes
		JSR	Text::PrintDecimalPadded_U8A_2

		LDA	#':'
		JSR	Text::PrintChar

		LDA	seconds
		JSR	Text::PrintDecimalPadded_U8A_2

		LDA	#':'
		JSR	Text::PrintChar

		LDA	fractionOfSeconds
		JSR	Text::PrintDecimalPadded_U8A_2

		JSR	Text::NewLine

		WAI
	FOREVER

ROUTINE CalculateTime
	LDX	frameCounter
	STX	Math::dividend32
	LDX	frameCounter + 2
	STX	Math::dividend32 + 2

	LDA	#FPS
	JSR	Math::DIVIDE_U32_U8A

	STA	fractionOfSeconds ; A = remainder

	; result32 and dividend32 share memory location

	LDA	#60
	JSR	Math::DIVIDE_U32_U8A

	STA	seconds

	; result32 and dividend32 share memory location
	LDA	#60
	JSR	Math::DIVIDE_U32_U8A

	STA	minutes

	LDX	Math::result32
	STX	hours
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

	INC	frameCounter
	IF_ZERO
		INC	frameCounter + 2
	ENDIF

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

	LDX	#Font8BoldTransparentPalette_End - Font8BoldTransparentPalette
	STX	DAS0

	LDX	#.loword(Font8BoldTransparentPalette)
	STX	A1T0
	LDA	#.bankbyte(Font8BoldTransparentPalette)
	STA	A1B0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN
	
	RTS



.rodata

Font8BoldTransparent:
	.incbin "../resources/font8-bold-transparent.2bpp"
Font8BoldTransparent_End:

Font8BoldTransparentPalette:               ; ANSI Colors
	.word	$7FFF, $0000, $4e73, $6b3a ; Black   (0)
	.word	$7FFF, $001F, $4e73, $6b3a ; Red     (1)
	.word	$7FFF, $02E0, $4e73, $6b3a ; Green   (2)
	.word	$7FFF, $02FF, $4e73, $6b3a ; Yellow  (3)
	.word	$7FFF, $7C00, $4e73, $6b3a ; Blue    (4)
	.word	$7FFF, $3C0F, $4e73, $6b3a ; Magenta (5)
	.word	$7FFF, $3DE0, $4e73, $6b3a ; Cyan    (6)
	.word	$7FFF, $3DEF, $4e73, $6b3a ; Gray    (7)
Font8BoldTransparentPalette_End:

