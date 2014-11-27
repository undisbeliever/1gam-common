; a 30x28 grid of Conway's Game of Life

; ::TODO add randomizer after all 3 games are played::

.define VERSION 3
.define REGION NTSC
.define ROM_NAME "GAME OF LIFE"

.include "includes/sfc_header.inc"
.include "includes/import_export.inc"
.include "includes/synthetic.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"

.include "routines/reset-snes.h"
.include "routines/cpu-usage.h"

; Ignore interrupts
IrqHandler	= EmptyHandler
CopHandler	= EmptyHandler

; Cell format
;
; a---nnnn
;
; a    = alive
; nnnn = number of neighbours
;
; This lets me:
;
;  1) Check if cell is dead and has no neighbours in 1 instruction
;  2) We can check if alive by testing the n Status flag
;  3) We can fit this all in shadow RAM

.define CELL_ALIVE	%10000000

.define	EOL		$0A

BG1_Tilemap		= $0400
BG1_Tiles		= $1000


.zeropage
	WORD	tmp
	WORD	tmp1
	WORD	tmp2
	WORD	rmp3

.define	GAME_HEIGHT 28
.define GAME_WIDTH  30
.define CELLS_WIDTH 32

.segment "SHADOW"
	BYTE	cellsPaddingBefore, 	CELLS_WIDTH
	BYTE	cells,			CELLS_WIDTH * GAME_HEIGHT
	BYTE	cellsPaddingAfter,	CELLS_WIDTH
	BYTE	prevCells,		CELLS_WIDTH * GAME_HEIGHT

	;; Number of frames before refesh
	UINT16	framesLeft

	;; If set then upate tilemap on VBlank
	BYTE	updateTilemap

	;; The low bytes of the tilemap
	BYTE	tilemapBuffer, 	32 * 32

	;; The current game number
	BYTE	gameNumber


; -----------------------------------------------------------------------------

.code

ROUTINE Main
	REP	#$10
	SEP	#$20
.A8
.I16
	JSR	CpuUsage__CalcReference

	JSR	SetupPPU
	JSR	LoadTiles

	LDA	#NMITIMEN_VBLANK_FLAG
	STA	NMITIMEN

	; Start with a dull screen
	LDA	#$08
	STA	INIDISP

	STZ	gameNumber


	REPEAT
		JSR	LoadGame

		; Wait a second
		; ::SHOULDDO use symbol (FRAMES_PER_SECOND) instead of hard numbers::
		LDA	#60
		JSR	CpuUsage__WaitLimited

		LDA	#$0F
		STA	INIDISP

		JSR	PlayGame

		; Dull the screen and wait a bit
		LDA	#$08
		STA	INIDISP

		LDA	#10
		JSR	CpuUsage__WaitLimited

		; Increment to the next game
		LDA	gameNumber
		CMP	#NUM_GAMES - 1
		IF_GE
			STZ	gameNumber
		ELSE
			INC	gameNumber
		ENDIF
		
	FOREVER


;; Play game
.A8
.I16
ROUTINE PlayGame
	REPEAT
		JSR	ProcessFrame

		; Clip the framerate (to known worst case)
		LDA	#3
		JSR	CpuUsage__WaitLimited

		LDX	framesLeft
		DEX
		STX	framesLeft
	UNTIL_ZERO

	RTS


; Helper macro to unroll the Process Frame Loop
; REQUIRE: 8 bit A, 16 bit Index
; X = Current position in `cells` array
.macro _ProcessFrame_UnrollLoop cell, prev_cell, buffer
	.local continue 

	; Get and check cell's new state
	LDA prev_cell, X
	IF_N_SET
		CMP #CELL_ALIVE + 2
		BEQ continue
		CMP #CELL_ALIVE + 3
		BEQ continue

		; Cell is alive but doesn't have 2 or 3 neighbours
		; Kill it

		; Set cell dead
		LDA	cell, X
		AND	#.lobyte(~CELL_ALIVE)
		STA	cell, X

		; Update buffer
		STZ	buffer, X

		; Increment its neighbours
		DEC	cell - 1, X
		DEC	cell + 1, X
		DEC	cell - CELLS_WIDTH, X
		DEC	cell - CELLS_WIDTH - 1, X
		DEC	cell - CELLS_WIDTH + 1, X
		DEC	cell + CELLS_WIDTH, X 
		DEC	cell + CELLS_WIDTH - 1, X
		DEC	cell + CELLS_WIDTH + 1, X
	ELSE
		CMP #3
		IF_EQ
			; No cell, and has 3 live neighbours
			; A new one is born

			; Set cell alive
			LDA	cell, X
			ORA	#CELL_ALIVE
			STA	cell, X

			; Update buffer
			LDA	#1
			STA	buffer, X

			; Increment its neighbours
			INC	cell - 1, X
			INC	cell + 1, X
			INC	cell - CELLS_WIDTH, X
			INC	cell - CELLS_WIDTH - 1, X
			INC	cell - CELLS_WIDTH + 1, X
			INC	cell + CELLS_WIDTH, X 
			INC	cell + CELLS_WIDTH - 1, X
			INC	cell + CELLS_WIDTH + 1, X
		ENDIF
	ENDIF

	BRA continue


continue:

.endmacro

;; Process a Game of Life Frame.
;;
;; INPUT: long of data in in rlepos
;;
ROUTINE ProcessFrame
	REP	#$30
.I16
.A16
	; Copy cells to prevCells
	LDA	#.sizeof(cells) - 1
	LDX	#.loword(cells)
	LDY	#.loword(prevCells)
	MVN	.bankbyte(cells), .bankbyte(prevCells)

	SEP	#$20
.A8

	LDX	#0
	REPEAT
		; I have lots of free space, So I'll unroll the loop.
		;
		; Unfortunatly for each line unrolled, 2790 bytes is added to the ROM.
		; Also UNROLL must be divisble by 28.
		;
		; Testing using `cpu_usage` bogos revealed the following spedups:
		;
		; Reference bogo:        $0A3C
		;   no unrolling    ($00 $026F) best case        ($02 $04E2) worst case
		;   1 line  - 17.1% ($00 $042E) best case, 5.7 % ($02 $06A1) worst case
		;   2 lines - 18.1% ($00 $0448) best case, 6.0 % ($02 $06BB) worst case
		;   4 lines - 18.5% ($00 $0455) best case, 6.2 % ($02 $06CB) worst case
		;   7 lines - 18.8% ($00 $045B) best case, 6.2 % ($02 $06CD) worst case
		UNROLL = 7

		.repeat UNROLL, H
			.repeat GAME_WIDTH, V
				delta .set H * CELLS_WIDTH + V + 1 ; +1 to remove left padding
				_ProcessFrame_UnrollLoop cells + delta, prevCells + delta, tilemapBuffer + delta
			.endrepeat
		.endrepeat

		REP	#$20
.A16
		TXA
		ADD	#UNROLL * CELLS_WIDTH
		TAX
		SEP	#$20
.A8

		CPX #.sizeof(cells)
	UNTIL_EQ

	LDA	#1
	STA	updateTilemap

	RTS


;; Loads the game specified by `gameNumber`.
;;
;; REQUIRES 8 bit A, 16 bit Index.
;;
;; GAME FORMAT
;;
;;	word - number of frames
;;	byte - starting X Positon
;;	byte - starting Y
;;
;;	repeat:
;;		'O': New Cell
;;		EOL: New Line (Cursor will be shifted X positon cells)
;;
;;	byte 0 - End of FILE
;;
;; NOTE:
;;	The cell format cannot wrap lines automatically,
;;	it must be done manually
.A8
.I16
ROUTINE LoadGame

.scope 

startX   = tmp


	; Clear the CellMap
	FOR_X #0, INC, #GAME_WIDTH
		STZ	cellsPaddingBefore, X
	NEXT
	FOR_X #0, INC, #.sizeof(cells) + GAME_WIDTH
		STZ	cells, X
	NEXT

	; Clear the Tilemap
	FOR_X #0, INC, #.sizeof(tilemapBuffer)
		STZ	tilemapBuffer, X
	NEXT

	; Get the address of the game
	REP	#$30
.A16
	LDA	gameNumber
	AND	#$00FF
	ASL
	TAX

	LDY	GamesTable, X


	; Byte 0 + 1 = Number of frames
	; Byte 2     = Start X position
	; Byte 3     = Starting Y Position
	;
	; startX = Starting X + 1
	; position = Starting Y * 32 + startX

	; Index X = Cells Position
	; Index Y = game file position

	LDA	0, Y
	STA	framesLeft

	INY
	INY

	LDA	0, Y
	AND	#$00FF
	INC
	STA	startX

	LDA	0, Y
	AND	#$FF00
	LSR		; 128
	LSR		; 64
	LSR		; 32
	ADD	startX
	TAX

	INY

	SEP #$20
.A8

	REPEAT
		INY
		LDA	0, Y
		IF_ZERO
			BREAK
		ENDIF

		CMP	#EOL
		IF_EQ
			; pos = (pos & ~$1F) + 32 + startX
			REP	#$30
.A16
			TXA
			AND	#.loword(~$1F)
			ADD	#32
			ADC	startX
			TAX

			SEP	#$20
.A8
		ELSE
			CMP	#'O'
			IF_EQ
				; +1 to remove left padding
				; Set cell alive
				LDA	cells, X
				ORA	#CELL_ALIVE
				STA	cells, X

				; Show in buffer
				LDA	#1
				STA	tilemapBuffer, X

				; Increment its neighbours
				INC	cells - 1, X
				INC	cells + 1, X
				INC	cells - CELLS_WIDTH, X
				INC	cells - CELLS_WIDTH - 1, X
				INC	cells - CELLS_WIDTH + 1, X
				INC	cells + CELLS_WIDTH, X 
				INC	cells + CELLS_WIDTH - 1, X
				INC	cells + CELLS_WIDTH + 1, X
			ENDIF

			INX
		ENDIF

		CPX #CELLS_WIDTH * GAME_HEIGHT
	UNTIL_GE

	; Set padding of buffer to blank tile

	LDX #0
	REPEAT
		LDA #PADDING_TILE
		STA tilemapBuffer, X
		INC
		STA tilemapBuffer + CELLS_WIDTH - 1, X

		REP #$20
.A16
		TXA
		ADD	#32
		TAX

		SEP #$20
.A8

		CPX #.sizeof(::tilemapBuffer)
	UNTIL_EQ

	LDA	#1
	STA	updateTilemap

	RTS
.endscope



;; VBlank Handler
;; 
;; Copies `tilemapBuffer` to VRAM when `updateTilemap` is set
.export VBlank
VBlank:
	; Save state
	REP #$30
	PHA
	PHB
	PHD
	PHX
	PHY

	SEP #$20
.A8
.I16
	CpuUsage_NMI

	; If updateTilemap is set then load buffer into VRAM
	; Remember that tilemapBuffer only stores the low byte of the tilemap
	; Thus we use VMAIN_INCREMENT_LOW and 1 Register Transfer
	LDA updateTilemap
	IF_NOT_ZERO
		LDA	#VMAIN_INCREMENT_LOW | VMAIN_INCREMENT_1
		STA	VMAIN

		LDX	#BG1_Tilemap
		STX	VMADD

		STZ	VMDATAH

		LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_1REG
		STA	DMAP0

		LDA	#.lobyte(VMDATAL)
		STA	BBAD0

		LDX	#.sizeof(tilemapBuffer)
		STX	DAS0

		LDX	#tilemapBuffer
		STX	A1T0
		LDA	#.bankbyte(tilemapBuffer)
		STA	A1B0

		LDA	#MDMAEN_DMA0
		STA	MDMAEN
	ENDIF


	; Load State
	REP	#$30
	PLY
	PLX
	PLD
	PLB
	PLA

	RTI



;; Sets up the screen base addresses and mode.
;;
;; Mode 0, BG1 enabled, BG1 tilepos set by BG1_Tilemap and BG1_Tiles
.A8
.I16
ROUTINE SetupPPU
	LDA	#INIDISP_FORCE
	STA	INIDISP

	LDA	#BGMODE_MODE0
	STA	BGMODE

	LDA	#(BG1_Tilemap / BGXSC_BASE_WALIGN) << 2
	STA	BG1SC

	LDA	#BG1_Tiles / BG12NBA_BASE_WALIGN
	STA	BG12NBA

	LDA	#TM_BG1
	STA	TM

	RTS



;; Copies the characters from Tiles to VRAM at word address  BG1_Tiles
;;
;; REQUIRES 8 bit A, 16 bit Index, Forced Blank
.A8
.I16
ROUTINE LoadTiles
	; Load tiles to BG1 VRAM
	LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
	STA	VMAIN

	LDX	#BG1_Tiles
	STX	VMADD

	LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_2REGS
	STA	DMAP0

	LDA	#.lobyte(VMDATA)
	STA	BBAD0

	LDX	#EndTiles - Tiles
	STX	DAS0

	LDX	#.loword(Tiles)
	STX	A1T0
	LDA	#.bankbyte(Tiles)
	STA	A1B0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN


	; Load white to color 1
	LDA	#1
	STA	CGADD

	LDA	#$FF
	STA	CGDATA
	LDA	#$7F
	STA	CGDATA

	; Load blue/gray to color 2 (border color)
	LDA	#$EF
	STA	CGDATA
	LDA	#$4D
	STA	CGDATA

	RTS

; -----------------------------------------------------------------------------

.rodata

PADDING_TILE = 2

.export Tiles
Tiles:
	; Dead Cell
	.byte $00, $FF, $00, $81, $00, $81, $00, $81
	.byte $00, $81, $00, $81, $00, $81, $00, $FF

	; Alive Cell
	.byte $00, $81, $7E, $00, $7E, $00, $7E, $00
	.byte $7E, $00, $7E, $00, $7E, $00, $00, $81

	; Padding Left
	.byte $00, $01, $00, $01, $00, $01, $00, $01
	.byte $00, $01, $00, $01, $00, $01, $00, $01

	; Padding Right
	.byte $00, $80, $00, $80, $00, $80, $00, $80
	.byte $00, $80, $00, $80, $00, $80, $00, $80
EndTiles:

.proc Games

::NUM_GAMES = (EndGamesTable - GamesTable) / 2

::GamesTable:
	.addr Life
	.addr Glider
	.addr Multum_in_parvo
EndGamesTable:



Life:
	.word 300
	.byte 5, 10
	.byte ".O....OOO.OOOO.OOOO.", EOL
	.byte ".O.....O..O....O....", EOL
	.byte ".O.....O..O....O....", EOL
	.byte ".O.....O..OOO..OOOO.", EOL
	.byte ".O.....O..O....O....", EOL
	.byte ".O.....O..O....O....", EOL
	.byte ".O.....O..O....O....", EOL
	.byte ".OOOO.OOO.O....OOOO.", EOL
	.byte 0

Glider:
	.word 120
	.byte 0, 0
	.byte ".O.", EOL
	.byte "..O", EOL
	.byte "OOO", EOL
	.byte 0


;Name: Multum in parvo
;Author: Charles Corderman
;A methuselah with lifespan 3933.
;www.conwaylife.com/wiki/index.php?title=Multum_in_parvo
Multum_in_parvo:
	.word 600
	.byte 12, 11
	.byte "...OOO", EOL
	.byte "..O..O", EOL
	.byte ".O", EOL
	.byte "O", EOL
	.byte 0


BestCase:
	.word 1
	.byte 0,0
	.byte 0


WorstCase:
	.word 2
	.byte 0, 0
	.repeat 28
		.res 30, 'O'
		.byte EOL
	.endrepeat
	.byte 0

.endproc


