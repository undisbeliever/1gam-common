
.include "metatiles-1x16.h"
.include "includes/registers.inc"
.include "includes/structure.inc"
.include "includes/synthetic.inc"
.include "routines/block.h"
.include "routines/screen.h"
.include "routines/text.h"
.include "routines/math.h"

.import METATILES_BG1_MAP

MODULE MetaTiles1x16

;; Ensure MetaTiles1x16_VBlank is used
.forceimport _MetaTiles1x16_VBlank__Called:zp


.segment "SHADOW"
	UINT16	mapWidth
	UINT16	mapHeight

	UINT16	xPos
	UINT16	yPos

	UINT16	displayXoffset
	UINT16	displayYoffset

	BYTE	updateBgBuffer

	ADDR	bgVerticalBufferVramLocation
	ADDR	bgHorizontalBufferVramLocation1
	ADDR	bgHorizontalBufferVramLocation2


.segment "WRAM7E"
	STRUCT	metaTiles, MetaTile16Struct, N_METATILES
	WORD	map, METATILES_MAP_TILE_ALLOCATION

	WORD	bgBuffer, 32 * 32
	WORD	bgVerticalBufferLeft, 32
	WORD	bgVerticalBufferRight, 32

	SAME_VARIABLE	bgHorizontalBuffer, bgBuffer

	;; Pixel location on the map that represents 0,0 of the tilemap
	UINT16	displayScreenDeltaX
	UINT16	displayScreenDeltaY

	;; Number of bytes in a single Map Row.
	WORD	sizeOfMapRow
	WORD	sizeOfMapRowTimesFourteen

	;; Tile index within `map` that represents the top left of the visible display.
	WORD	visibleTopLeftMapIndex

	;; Pixel location of `visibleTopLeftMapIndex`
	UINT16	visibleTopLeftMapXpos
	UINT16	visibleTopLeftMapYpos

	;; The ending position of the draw loop.
	UINT16	endOfLoop

	;; The topmost tile within `bgVerticalBufferLeft` that is updated within `_ProcessVerticalBuffer`
	WORD	columnBufferIndex
	;; The leftmost tile within `bgHorizontalBuffer` that is updated within `_ProcessHorizontalBuffer`
	WORD	rowBufferIndex

	;; Tile offset for the vertical update metatile address.
	;; Number of 16x16 tiles in the vertical offset.
	;; Bitwize math is used to convert this value into `bgVerticalBufferVramLocation`.
	WORD	columnVramMetaTileOffset

	;; VRAM word address offset for the horizontal update.
	;; Number of 8x8 tiles in the horizontal offset.
	;; Unlike the column no fancy bitwize math is needed.
	WORD	rowVramMetaTileOffset

.code

.A8
.I16
ROUTINE MapInit
	; sizeOfMapRow = (mapWidth + 15) / 16 * 2
	; sizeOfMapRowTimesFourteen = sizeOfMapRow * 14
	; DrawEntireScreen()

	REP	#$31		; also clear carry
.A16

	LDA	mapWidth
	ADC	#15		; carry clear from REP
	LSR
	LSR
	LSR
	AND	#$FFFE
	STA	f:sizeOfMapRow

	ASL
	ASL
	ASL
	ASL
	SUB	f:sizeOfMapRow
	SUB	f:sizeOfMapRow

	STA	f:sizeOfMapRowTimesFourteen

	SEP	#$20

	.assert * = DrawEntireScreen, lderror, "Bad Flow"



.A8
.I16
ROUTINE DrawEntireScreen
	PHB
	LDA	#$7E
	PHA
	PLB

	REP	#$30
.A16
	.assert * = _DrawEntireScreen_Bank7E, lderror, "Bad Flow"


;; REQUIRES: DB = $7E, DB on stack, 16 bit A, 16 bit Index
.A16
.I16
ROUTINE _DrawEntireScreen_Bank7E
	; // Building from bottom-right to top-left because it saves a comparison.
	; visibleTopLeftMapIndex = (yPos / 16) * sizeOfMapRow + xPos / 16 * 2
	; x = visibleTopLeftMapIndex + sizeOfMapRowTimesFourteen + 32 - 2
	; y = 15 * 2 * 64 - 2
	; mapColumnIndex = (xPos / 16)
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
	;	x = x - sizeOfMapRow - 32	// width of display in metatile * 2
	;	y -= 64
	; until y < 0
	;
	; set data bank to $7E
	;
	; displayScreenDeltaX = xPos & 0xFFF0
	; displayScreenDeltaY = yPos & 0xFFF0
	;
	; visibleTopLeftMapXpos = xPos & 0xFFF0
	; visibleTopLeftMapYpos = yPos & 0xFFF0
	;
	; displayXoffset = xPos & 0x000F
	; displayYoffset = yPos & 0x000F
	;
	; _ProcessVerticalBuffer(visibleTopLeftMapIndex + 16 * 2)
	; bgVerticalBufferVramLocation = METATILES_BG1_MAP + 32 * 32
	; columnVramMetaTileOffset = 0
	; rowVramMetaTileOffset = 0
	;
	; updateBgBuffer = METATILES_UPDATE_WHOLE_BUFFER

	LDA	a:sizeOfMapRow
	TAX

	LDA	a:yPos
	LSR
	LSR
	LSR
	LSR
	TAY

	; ::SHOULDDO have Multiply set DB::
	PEA	$7E00
	PLB
	JSR	Math__Multiply_U16Y_U16X_U16Y

	PLB					; set DB to $7E, from previous 7E, saves a SEP/REP.
						; had to have DB <= $3F for the multiplication.

	LDA	a:xPos
	LSR
	LSR
	LSR
	AND	#$FFFE
	ADD	a:Math__product32
	STA	a:visibleTopLeftMapIndex

	ADD	a:sizeOfMapRowTimesFourteen
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
		SUB	a:sizeOfMapRow
		ADD	#32
		TAX

		TYA
		SUB	#64
	UNTIL_MINUS

	LDA	xPos
	AND	#$FFF0
	STA	displayScreenDeltaX
	STA	visibleTopLeftMapXpos

	LDA	yPos
	AND	#$FFF0
	STA	displayScreenDeltaY
	STA	visibleTopLeftMapYpos

	LDA	xPos
	AND	#$000F
	STA	displayXoffset

	LDA	yPos
	AND	#$000F
	STA	displayYoffset

	STZ	columnBufferIndex
	STZ	rowBufferIndex

	; Do right column
	
	LDA	visibleTopLeftMapIndex
	ADD	#17 * 2
	JSR	_ProcessVerticalBuffer

	LDA	#METATILES_BG1_MAP + 32 * 32
	STA	bgVerticalBufferVramLocation

	STZ	columnVramMetaTileOffset
	STZ	rowVramMetaTileOffset

	SEP	#$20
.A8
	LDA	#METATILE16_UPDATE_WHOLE_BUFFER
	STA	updateBgBuffer

	PLB
	RTS



.A8
.I16
ROUTINE Update
	; if xPos - visibleTopLeftMapXpos > 0
	;	if xPos - visibleTopLeftMapXpos > 16
	;		if xPos - visibleTopLeftMapXpos > 16 * 2
	;			DrawEntireScreen()
	;			return
	; 		visibleTopLeftMapXpos += 16
	;		visibleTopLeftMapIndex += 2
	;		_ProcessVerticalBuffer(visibleTopLeftMapIndex + 17 * 2)
	;
	;		rowBufferIndex += 4
	;		columnVramMetaTileOffset++
	;		a = (columnVramMetaTileOffset + 16) & $001F
	;		if a & $0010
	;			a ^= $0210 	// (The equivalent of a = a | $0200 & ~$0010)
	;		bgVerticalBufferVramLocation = METATILES_BG1_MAP + a * 2 
	;
	;		updateBgBuffer |= METATILE16_UPDATE_VERTICAL_BUFFER
	; else
	;	if xPos - visibleTopLeftMapXpos < -16 * 2
	;		DrawEntireScreen()
	;		return
	;
	;	visibleTopLeftMapXpos -= 16
	;	visibleTopLeftMapIndex -= 2
	;	_ProcessVerticalBuffer(visibleTopLeftMapIndex + 2)
	;
	;	rowBufferIndex -= 4
	;	columnVramMetaTileOffset--
	;	a = (columnVramMetaTileOffset - 1) & $001F
	;	if a & $0010
	;		a ^= $0210 	// (The equivalent of a = a | $0200 & ~$0010)
	;	bgVerticalBufferVramLocation = METATILES_BG1_MAP + a * 2 
	;
	;	updateBgBuffer |= METATILE16_UPDATE_VERTICAL_BUFFER
	;
	; displayXoffset = xPos - displayScreenDeltaX
	;
	;
	; if yPos - visibleTopLeftMapYpos > 0
	;	if yPos - visibleTopLeftMapYpos > 16
	;		if yPos - visibleTopLeftMapYpos > 16 * 2
	;			DrawEntireScreen()
	;			return
	; 		visibleTopLeftMapYpos += 16
	;		visibleTopLeftMapIndex += sizeOfMapRow
	;		_ProcessHorizontalBuffer(visibleTopLeftMapIndex + sizeOfMapRowTimesFourteen)
	;
	;		columnBufferIndex += 4
	;		rowVramMetaTileOffset += 32 * 2
	;		a = (columnVramMetaTileOffset + 14 * 32 * 2) & $03FF
	;		bgHorizontalBufferVramLocation1 = a + METATILES_BG1_MAP 
	;		bgHorizontalBufferVramLocation2 = a + METATILES_BG1_MAP + 32 * 32
	;
	;		updateBgBuffer |= METATILE16_UPDATE_HORIZONAL_BUFFER
	;
	;	displayYoffset = yPos - displayScreenDeltaY
	;	updateBgBuffer |= METATILE16_UPDATE_POSITION
	;
	; else
	;	if yPos - visibleTopLeftMapYpos < -16
	;		DrawEntireScreen()
	;		return
	;	visibleTopLeftMapYpos -= 16
	;	visibleTopLeftMapIndex -= sizeOfMapRow
	;	_ProcessHorizontalBuffer(visibleTopLeftMapIndex - sizeOfMapRow)
	;
	;	columnBufferIndex -= 4
	;	rowVramMetaTileOffset -= 32 * 2
	;	a = (columnVramMetaTileOffset - 32 * 2) & $03FF
	;	bgHorizontalBufferVramLocation1 = a + METATILES_BG1_MAP 
	;	bgHorizontalBufferVramLocation2 = a + METATILES_BG1_MAP + 32 * 32
	;
	;	updateBgBuffer |= METATILE16_UPDATE_HORIZONAL_BUFFER
	;
	; displayYoffset = yPos - displayScreenDeltaY
	; updateBgBuffer |= METATILE16_UPDATE_POSITION

	PHB

	LDA	#$7E
	PHA
	PLB

	REP	#$30
.A16

	LDA	xPos
	SUB	visibleTopLeftMapXpos
	IF_GE
		CMP	#16
		IF_GE
			CMP	#16 * 2
			JGE	_DrawEntireScreen_Bank7E

			; ::TODO check to see if yPos is out of scope::

			; c clear from branch.
			LDA	visibleTopLeftMapXpos
			ADC	#16
			STA	visibleTopLeftMapXpos

			LDA	visibleTopLeftMapIndex
			INC
			INC
			STA	visibleTopLeftMapIndex
			ADD	#17 * 2
			JSR	_ProcessVerticalBuffer


			LDA	rowBufferIndex
			ADD	#4
			STA	rowBufferIndex

			LDA	columnVramMetaTileOffset
			INC
			STA	columnVramMetaTileOffset

			AND	#$001F
			EOR	#$0010
			BIT	#$0010
			IF_NOT_ZERO
				EOR	#$0210
			ENDIF
			ASL
			ADD	#METATILES_BG1_MAP
			STA	bgVerticalBufferVramLocation

			SEP	#$20
.A8
			LDA	#METATILE16_UPDATE_VERTICAL_BUFFER
			TSB	updateBgBuffer

			REP	#$20
		ENDIF
	ELSE
.A16
		; A = xPos - visibleTopLeftMapXpos
		CMP	#.loword(-16)
		JSLT	_DrawEntireScreen_Bank7E

		; ::TODO check to see if yPos is out of scope::

		LDA	visibleTopLeftMapXpos
		SUB	#16
		STA	visibleTopLeftMapXpos

		LDA	visibleTopLeftMapIndex
		DEC
		DEC
		STA	visibleTopLeftMapIndex
		INC
		INC
		JSR	_ProcessVerticalBuffer

		LDA	rowBufferIndex
		SUB	#4
		STA	rowBufferIndex

		LDA	columnVramMetaTileOffset
		DEC
		STA	columnVramMetaTileOffset
		AND	#$001F

		BIT	#$0010
		IF_NOT_ZERO
			EOR	#$0210
		ENDIF
		ASL
		ADD	#METATILES_BG1_MAP
		STA	bgVerticalBufferVramLocation

		SEP	#$20
.A8
		LDA	#METATILE16_UPDATE_VERTICAL_BUFFER
		TSB	updateBgBuffer

		REP	#$20
	ENDIF
.A16
	LDA	xPos
	SUB	displayScreenDeltaX
	STA	displayXoffset



	LDA	yPos
	SUB	visibleTopLeftMapYpos
	IF_GE
		CMP	#16
		IF_GE
			CMP	#16
			JGE	_DrawEntireScreen_Bank7E

			; c clear from branch.
			LDA	visibleTopLeftMapYpos
			ADC	#16
			STA	visibleTopLeftMapYpos

			LDA	visibleTopLeftMapIndex
			ADD	sizeOfMapRow
			STA	visibleTopLeftMapIndex
			ADD	sizeOfMapRowTimesFourteen
			JSR	_ProcessHorizontalBuffer


			LDA	columnBufferIndex
			ADD	#4
			STA	columnBufferIndex

			LDA	rowVramMetaTileOffset
			ADD	#32 * 2
			STA	rowVramMetaTileOffset

			ADD	#14 * 64
			AND	#$03FF

			ADD	#METATILES_BG1_MAP
			STA	bgHorizontalBufferVramLocation1
			ADD	#32 * 32
			STA	bgHorizontalBufferVramLocation2

			SEP	#$20
.A8
			LDA	#METATILE16_UPDATE_HORIZONAL_BUFFER
			TSB	updateBgBuffer

			REP	#$30
.A16
		ENDIF
	ELSE
.A16
		; A = yPos - visibleTopLeftMapXpos
		CMP	#.loword(-16 * 2)
		JSLT	_DrawEntireScreen_Bank7E

		; c clear from branch.
		LDA	visibleTopLeftMapYpos
		SUB	#16
		STA	visibleTopLeftMapYpos

		LDA	visibleTopLeftMapIndex
		SUB	sizeOfMapRow
		STA	visibleTopLeftMapIndex
		JSR	_ProcessHorizontalBuffer


		LDA	columnBufferIndex
		SUB	#4
		STA	columnBufferIndex

		LDA	rowVramMetaTileOffset
		SUB	#32 * 2
		STA	rowVramMetaTileOffset

		AND	#$03FF
		ADD	#METATILES_BG1_MAP
		STA	bgHorizontalBufferVramLocation1
		ADD	#32 * 32
		STA	bgHorizontalBufferVramLocation2

		SEP	#$20
.A8
		LDA	#METATILE16_UPDATE_HORIZONAL_BUFFER
		TSB	updateBgBuffer

		REP	#$20
	ENDIF
.A16

	LDA	yPos
	SUB	displayScreenDeltaY
	STA	displayYoffset

	SEP	#$20
.A8
	LDA	#METATILE16_UPDATE_POSITION
	TSB	updateBgBuffer

	PLB	
	RTS



;; Builds bgVerticalBufferLeft and bgVerticalBufferRight depending on the tile selected.
;; You will need to set `bgVerticalBufferVramLocation` and `updateBgBuffer` afterwards
;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
;; INPUT: A = tile index of the topmost displayed tile.
.A16
.I16
ROUTINE _ProcessVerticalBuffer
	; endOfLoop = tileIndex - sizeOfMapRow * 2
	; x = tileIndex + sizeOfMapRowTimesFourteen - 2
	; y = (columnBufferIndex + 14 * 2 * 2 - 2) MOD 64
	;
	; repeat
	;	bgVerticalBufferRight[y] = metaTiles[map[x]].bottomRight
	;	bgVerticalBufferLeft[y] = metaTiles[map[x]].bottomLeft
	;	bgVerticalBufferRight[y - 2] = metaTiles[map[x]].topRight
	;	bgVerticalBufferLeft[y - 2] = metaTiles[map[x]].topLeft
	;	x -= sizeOfMapRow
	;	y -= 4
	;	if y < 0
	;		y = 32 * 2 - 2
	; until x < endOfLoop

	TAY
	SUB	sizeOfMapRow
	SUB	sizeOfMapRow		; ::HACK::
	STA	endOfLoop
	TYA

	ADD	sizeOfMapRowTimesFourteen
	DEC
	DEC
	TAX

	LDA	columnBufferIndex
	ADD	#15 * 2 * 2 - 2
	AND	#$3F
	TAY

	REPEAT
		PHX

		LDA	map, X
		TAX

		LDA	a:metaTiles + MetaTile16Struct::bottomRight, X
		STA	a:bgVerticalBufferRight, Y

		LDA	a:metaTiles + MetaTile16Struct::bottomLeft, X
		STA	a:bgVerticalBufferLeft, Y

		LDA	a:metaTiles + MetaTile16Struct::topRight, X
		STA	a:bgVerticalBufferRight - 2, Y

		LDA	a:metaTiles + MetaTile16Struct::topLeft, X
		STA	a:bgVerticalBufferLeft - 2, Y

		PLA
		SUB	sizeOfMapRow
		TAX

		DEY
		DEY
		DEY
		DEY
		IF_MINUS
			LDY	#32 * 2 - 2
		ENDIF

		CPX	endOfLoop
	UNTIL_SLT

	RTS



;; Builds bgHorizontalBuffer depending on the tile selected.
;; You will need to set `bgHorizontalBufferVramLocation` and `updateBgBuffer` afterwards
;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
;; INPUT: A = tile index of the leftmost displayed tile.
.A16
.I16
ROUTINE _ProcessHorizontalBuffer
	; endOfLoop = tileIndex
	; x = tileIndex + 17 * 2
	; y = (rowBufferIndex + 17 * 4 - 2) MOD 128
	;
	; repeat
	;	x -= 2
	;	bgHorizontalBuffer[y] = metaTiles[map[x]].topRight
	;	bgHorizontalBuffer[y - 2] = metaTiles[map[x]].topLeft
	;	bgHorizontalBuffer[y + 64 * 2] = metaTiles[map[x]].bottomRight
	;	bgHorizontalBuffer[y + 64 * 2 - 2] = metaTiles[map[x]].bottomLeft
	;	y -= 4
	;	if y < 0
	;		y = 32 * 4 - 2
	; until x < endOfLoop

	STA	endOfLoop
	ADD	#17 * 2
	TAX

	LDA	rowBufferIndex
	ADD	#17 * 4 - 2
	AND	#$7F
	TAY

	REPEAT
		DEX
		DEX
		PHX

		LDA	map, X
		TAX

		LDA	a:metaTiles + MetaTile16Struct::topRight, X
		STA	a:bgHorizontalBuffer, Y

		LDA	a:metaTiles + MetaTile16Struct::topLeft, X
		STA	a:bgHorizontalBuffer - 2, Y

		LDA	a:metaTiles + MetaTile16Struct::bottomRight, X
		STA	a:bgHorizontalBuffer + 64 * 2, Y

		LDA	a:metaTiles + MetaTile16Struct::bottomLeft, X
		STA	a:bgHorizontalBuffer + 64 * 2 - 2, Y

		PLX

		DEY
		DEY
		DEY
		DEY
		IF_MINUS
			LDY	#32 * 4 - 2
		ENDIF

		CPX	endOfLoop
	UNTIL_SLT

	RTS

ENDMODULE

