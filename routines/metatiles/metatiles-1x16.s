
.include "metatiles-1x16.h"
.include "includes/registers.inc"
.include "includes/structure.inc"
.include "includes/synthetic.inc"
.include "routines/block.h"
.include "routines/screen.h"
.include "routines/text.h"
.include "routines/math.h"


MODULE MetaTiles1x16

.segment "SHADOW"
	UINT16	xPos
	UINT16	yPos

	UINT16	mapWidth
	UINT16	mapHeight

	UINT16	displayXoffset
	UINT16	displayYoffset

	BYTE	updateBgBuffer



.segment "WRAM7E"
	STRUCT	metaTiles, MetaTile16Struct, N_METATILES
	WORD	map, METATILES_MAP_TILE_ALLOCATION

	WORD	bgBuffer, 32 * 32
	WORD	bgColumnBuffer1, 32
	WORD	bgColumnBuffer2, 32

	;; Location on the map that represents 0,0 of the tilemap
	UINT16	displayScreenDeltaX
	UINT16	displayScreenDeltaY

	;; The ending position of the draw loop.
	UINT16	endOfLoop

	UINT16	indexNextColumn
	UINT16	indexNextColumnTimesFourteen


.code

.A8
.I16
ROUTINE MapInit
	; indexNextColumn = mapWidth / 16 * 2
	; indexNextColumnTimesFourteen = indexNextColumn * 14
	; DrawEntireScreen()

	REP	#$30
.A16

	LDA	mapWidth
	LSR
	LSR
	LSR
	AND	#$FFFE
	STA	f:indexNextColumn

	ASL
	ADD	f:indexNextColumn
	ASL
	ADD	f:indexNextColumn
	ASL
	STA	f:indexNextColumnTimesFourteen

	SEP	#$20

	.assert * = DrawEntireScreen, lderror, "Bad Flow"



.A8
.I16
ROUTINE DrawEntireScreen
	; // Building from bottom-right to top-left because it saves a comparison.
	; x = (yPos / 16 + 14) * indexNextColumn + xPos / 16 * 2 + 32 - 2
	; y = 15 * 2 * 64 - 2
	;
	; repeat
	;	endOfLoop = y - 64
	;	repeat
	;		bgBuffer[y] = metaTiles[map[x]].bottomRight
	;		bgBuffer[y - 2] = metaTiles[map[x]].bottomLeft
	;		bgBuffer[y - 64] = metaTiles[map[x]].topRight
	;		bgBuffer[y - 64 - 2] = metaTiles[map[x]].topLeft
	;		x -= 2
	;		y -= 4
	;	until y == endOfLoop
	;	x = x - indexNextColumn - 32	// width of display in metatile * 2
	;	y -= 64
	; until y < 0
	;
	; set data bank to $7E
	;
	; displayScreenDeltaX = xPos & 0xFFF0
	; displayScreenDeltaY = yPos & 0xFFF0
	;
	; displayXoffset = xPos & 0x000F
	; displayYoffset = yPos & 0x000F
	;
	; updateBgBuffer = METATILES_UPDATE_WHOLE_BUFFER

	PHB
	LDA	#$7E
	PHA

	REP	#$30
.A16

	LDA	f:indexNextColumn
	TAX

	LDA	a:yPos
	LSR
	LSR
	LSR
	LSR
	ADD	#14
	TAY
	JSR	Math__Multiply_U16Y_U16X_U16Y

	PLB					; set DB to $7E, from previous 7E, saves a SEP/REP.
						; had to have DB <= $3F for the multiplication.

	LDA	a:xPos
	LSR
	LSR
	LSR
	AND	#$FFFE
	ADD	a:Math__product32
	ADD	#32 - 2
	TAX

	; Building from the bottom-right to top-left because it saves a comparison.
	LDA	#15 * 2 * 64 - 2
	REPEAT
		TAY
		SUB	#64
		STA	a:endOfLoop

		REPEAT
			PHX

BREAKPOINT
			LDA	a:map, X
			TAX

			LDA	a:metaTiles + MetaTile16Struct::bottomRight, X
			STA	a:bgBuffer, Y

			LDA	a:metaTiles + MetaTile16Struct::bottomLeft, X
			STA	a:bgBuffer - 2, Y

			LDA	a:metaTiles + MetaTile16Struct::topRight, X
			STA	a:bgBuffer - 64, Y

			LDA	a:metaTiles + MetaTile16Struct::topLeft, X
			STA	a:bgBuffer - 64 - 2, Y

			PLX
			DEX
			DEX

			DEY
			DEY
			DEY
			DEY

			CPY	a:endOfLoop
		UNTIL_EQ

		TXA
		SUB	a:indexNextColumn
		ADD	#32
		TAX

		TYA
		SUB	#64
	UNTIL_MINUS

	LDA	xPos
	AND	#$FFF0
	STA	displayScreenDeltaX

	LDA	yPos
	AND	#$FFF0
	STA	displayScreenDeltaY

	;; ::TODO right column::

	LDA	xPos
	AND	#$000F
	STA	displayXoffset

	LDA	yPos
	AND	#$000F
	STA	displayYoffset

	SEP	#$20
.A8
	LDA	#METATILE16_UPDATE_WHOLE_BUFFER
	STA	updateBgBuffer

	PLB
	RTS

ENDMODULE

