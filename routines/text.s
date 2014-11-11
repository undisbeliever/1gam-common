
.include "text.h"
.include "includes/import_export.inc"
.include "includes/structure.inc"
.include "includes/synthetic.inc"
.include "includes/registers.inc"

.setcpu "65816"

.globalzp tmp
.globalzp tmp2

MODULE Text

.define LAST_CHARACTER		144

; ::TODO SetCursor::

.zeropage
	;; The position of the string
	LONG	stringPtr


.segment "WRAM7E"
	;; The text buffer
	;; In $7E so shadow RAM can also be accessed.
	WORD	buffer, 32*32

.segment "SHADOW"
	;; If zero, then update buffer to VRAM on VBlank
	BYTE updateBufferIfZero

	;; Word address of the tilemap in VRAM
	WORD vramMapAddr

	;; This word is added to each character to convert to a tileset
	;; Also used to set text color (palette)
	WORD tilemapOffset

	;; Index position of the buffer
	WORD bufferPos

	;; When bufferPos >= bufferLineEnd goto next line
	WORD bufferPosLineEnd

	;; Number of tiles inbetween lines.
	;; (2 = double spacing or 8x16 font)
	BYTE lineSpacing

	;; Index of Text window Starting byte (Ypos * 64 + XPos * 2)
	WORD windowStart

	;; Index of Text window Ending byte (Ypos * 64 + XPos * 2)
	WORD windowEnd

	;; Window Flags
	BYTE flags

		;;; Has a border
		CONST BORDER, $01

		;;; Has no border
		CONST NO_BORDER, $00

	;; The length of the line.
	WORD lineWidth


.code
.A8
.I16
ROUTINE SetColor
	; tilemapOffset = (tilemapOffset & $E3FF) | ((A & $7) << 10)
	AND	#$7
	ASL
	ASL

	STA	tmp

	LDA	tilemapOffset+1
	AND	#$E3
	ORA	tmp
	STA	tilemapOffset+1

	RTS


.A8
.I16
ROUTINE PrintString
	STX	stringPtr
	STA	stringPtr + 2

	LDY	#0

	REPEAT
		LDA	[stringPtr], Y
	WHILE_NOT_ZERO
		INY

		JSR PrintChar
	WEND

	RTS



.A8
.I16
ROUTINE PrintStringWrap
.scope

startWord := <tmp2
endWord := <tmp4

	STX	stringPtr
	STA	stringPtr + 2

	; startWord = 0
	; while
	;	endWord = get_word_ending(string, startWord);
	;	if endWord == startWord
	;		if string[startWord] == 0
	;			break
	;		else if string[startWord] == EOL
	;			NewLine()
	;			continue
	;
	;	len = endWord - startWord
	;	if len < lineWidth / 2
	;		if bufferPos + (len - 1 * 2) > bufferPosLineEnd
	;			NewLine()
	;
	;	; Ensure spaces after word are printed
	;	while string[endWord] == ' '
	;		endWord++
	;
	;	print string[wordStart - wordEnd]
	LDY	#0

	REPEAT
_StartPrintWord:
		STY	startWord

		REPEAT
			LDA	[stringPtr], Y
		WHILE_NOT_ZERO
			CMP	#' '
			BEQ	BREAK_LABEL

			CMP	#EOL
			BEQ	BREAK_LABEL

			INY
		WEND

		CPY	startWord
		IF_EQ
			LDA	[stringPtr], Y
			BEQ	BREAK_LABEL

			CMP	#EOL
			IF_EQ
				JSR	NewLine
				INY
				CONTINUE
			ENDIF
		ENDIF

		STY	endWord

		REP	#$20
.A16
			TYA
			CLC			; Adds an extra - 1
			SBC	startWord
			ASL
			CMP	lineWidth
			IF_LT
				ADD	bufferPos
				DEC			; Faster than IF_GT
				CMP	bufferPosLineEnd
				IF_GE
					JSR	NewLine
					LDX	bufferPos
				ENDIF
			ENDIF

		SEP	#$20
.A8

		REPEAT
			LDA	[stringPtr], Y
			CMP	#' '
		WHILE_EQ
			INY
		WEND
		STY	endWord

		REP	#$30
.A16

		; Print stringPtr[wordStart - wordEnd]
		LDX	bufferPos
		LDY	startWord
		REPEAT
			LDA	[stringPtr], Y
			INY

			AND	#$00FF

			; if A in range FIRST_CHARACTER to LAST_CHARACTER
			;     A = A - TEXT_DELTA
			; else
			;     A = INVALID_CHARACTER
			SUB	#TEXT_DELTA
			CMP	#LAST_CHARACTER - TEXT_DELTA
			IF_GE
				LDA	#TEXT_INVALID
			ENDIF

			; But to buffer
			ADD	tilemapOffset
			STA	f:buffer, X


			; If bufferpos >= byfferPosLineEnd
			;   NewLine()
			;   get new bufferPos
			;   skip spaces
			;   break
			; Else
			;   bufferpos += 2
			CPX	bufferPosLineEnd
			IF_GE
				STX	bufferPos
				JSR	NewLine

				SEP	#$20
.A8

				REPEAT
					LDA	[stringPtr], Y
					CMP	#' '
				WHILE_EQ
					INY
				WEND

				JRA	_StartPrintWord
			ENDIF

			INX
			INX

			; Loop until entire word printed
			CPY	endWord
		UNTIL_GE

		SEP	#$20
.A8

		STX	bufferPos
	FOREVER

	STZ	updateBufferIfZero

	RTS
.endscope



.A8
.I16
; INPUT: A - the character to print
; MODIFIES: A, X
; MUST NOT USE Y
ROUTINE PrintChar
	; If character is newline call NewLine
	CMP	#EOL
	BEQ	NewLine

	LDX	bufferPos

	; if A in range FIRST_CHARACTER to LAST_CHARACTER
	;     A = A - TEXT_DELTA
	; else
	;     A = INVALID_CHARACTER
	SUB	#TEXT_DELTA
	CMP	#LAST_CHARACTER - TEXT_DELTA
	IF_GE
		LDA	#TEXT_INVALID - TEXT_DELTA
	ENDIF

	; Show character
	REP	#$30
.A16
		AND	#$00FF
		ADD	tilemapOffset
		STA	f:buffer, X

	SEP	#$20
.A8

	STZ	updateBufferIfZero

	; If ++bufferpos >= byfferPosLineEnd
	;   call NewLine
	; Else
	;   bufferpos += 2
	CPX	bufferPosLineEnd
	BGE	NewLine

	INX
	INX

	STX	bufferPos

	RTS



ROUTINE NewLine
	PHP
	REP	#$30
.A16

	; bufferPos = (Bufferpos & $FFC0) + (64 * lineSpacing) + (windowStart & $3F)
	LDA	bufferPos
	AND	#$FFC0
	STA	tmp

	LDA	lineSpacing - 1
	AND	#$FF00
	LSR
	LSR
	ADD	tmp
	STA	tmp

	LDA	windowStart
	AND	#$003F
	ORA	tmp
	STA	bufferPos
	
	; If out of bounds
	CMP	windowEnd
	IF_GT
		; ::TODO Check settings and move text up one line::

		LDA	windowStart
		STA	bufferPos
		AND	#$FFC0
		STA	tmp
	ENDIF

	; bufferPosLineEnd = (bufferPos & $FFC0) + (windowEnd  & $3F)
	LDA	windowEnd
	AND	#$003F
	ORA	tmp
	STA	bufferPosLineEnd

	; ::TODO Check settings and Clear line::

	PLP
	RTS



.A8
.I16
ROUTINE SetupWindow
.scope
startXPos := <tmp

	STX	windowStart
	STY	windowEnd
	STA	flags

	REP	#$30
.A16
	; lineWidth = ((windowEnd & $3F) - (windowStart & $3F)) / 2 + 1
	TXA
	AND	#$003F
	STA	startXPos
	TYA
	AND	#$003F
	SUB	startXPos
	LSR
	INC
	STA	lineWidth

	SEP	#$20
.A8
	LDA	flags
	BIT	#BORDER
	BNE	DrawBorder

	JMP	ClearWindow
.endscope



ROUTINE DrawBorder
.scope
	PHP
	REP	#$30
.A16
.I16

topLeft  := windowStart
topRight := <tmp
bottomLeft  := <tmp2
bottomRight := windowEnd

	LDA	windowStart
	AND	#$003F
	STA	bottomLeft
	LDA	windowEnd
	AND	#$FFC0
	ORA	bottomLeft
	STA	bottomLeft

	LDA	windowEnd
	AND	#$003F
	STA	topRight
	LDA	windowStart
	AND	#$FFC0
	ORA	topRight
	STA	topRight

	; Draw four corners
	LDA	tilemapOffset
	ADD	#BORDER_TOP_LEFT - TEXT_DELTA
	LDX	topLeft
	STA	f:buffer - 66, X

	LDA	tilemapOffset
	ADD	#BORDER_TOP_RIGHT - TEXT_DELTA
	LDX	topRight
	STA	f:buffer - 62, X

	LDA	tilemapOffset
	ADD	#BORDER_BOTTOM_LEFT - TEXT_DELTA
	LDX	bottomLeft
	STA	f:buffer + 62, X

	LDA	tilemapOffset
	ADD	#BORDER_BOTTOM_RIGHT - TEXT_DELTA
	LDX	bottomRight
	STA	f:buffer + 66, X

	LDA	tilemapOffset
	ADD	#BORDER_TOP - TEXT_DELTA
	LDX	topLeft
	REPEAT
		STA	f:buffer - 64, X
		CPX	topRight
	WHILE_LT
		INX
		INX
	WEND

	LDA	tilemapOffset
	ADD	#BORDER_BOTTOM - TEXT_DELTA
	LDX	bottomLeft
	REPEAT
		STA	f:buffer + 64, X
		CPX	bottomRight
	WHILE_LT
		INX
		INX
	WEND

	LDA	tilemapOffset
	ADD	#BORDER_LEFT - TEXT_DELTA
	LDX	topLeft
	REPEAT
		STA	f:buffer - 2, X

		CPX	bottomLeft
	WHILE_LT
		TAY
			TXA
			ADD	#64
			TAX
		TYA
	WEND

	LDA	tilemapOffset
	ADD	#BORDER_RIGHT - TEXT_DELTA
	LDX	topRight
	REPEAT
		STA	f:buffer + 2, X

		CPX	bottomRight
	WHILE_LT
		TAY
			TXA
			ADD	#64
			TAX
		TYA
	WEND

	BRA	_ClearWindow_skip_php
.endscope



ROUTINE ClearWindow
	PHP
	REP	#$30
.A16
.I16
_ClearWindow_skip_php:

	LDA	#TEXT_CLEAR - TEXT_DELTA
	ADD	tilemapOffset
	TAY

	BRA	_FillWindow_p_on_stack



ROUTINE RemoveWindow
	PHP

	REP	#$30
.A16
.I16
	LDA	flags
	IF_BIT	#BORDER
		; if has a border, then ensure that gets cleaned too
		LDA	windowStart
		SUB	#66
		STA	windowStart
		LDA	windowEnd
		ADD	#66
		STA	windowEnd
	ENDIF

	LDY	#0
	BRA	_FillWindow_p_on_stack



; A helper function to fill the entirety of the window.
; REQUIRES: 16 bit A, 16 bit Index, P on stack
; INPUT: Y = the Tile to copy
.A16
.I16
_FillWindow_p_on_stack:
.scope

startLine := <tmp
endLine	  := <tmp2

	; startLine = windowStart
	; endLine = (windowStart & $FFC0) + (windowEnd & $3F)
	; A = Y
	; repeat
	;    buffer[x] = A
	;    if (x >= windowEnd)
	;       break loop
	;    elseif x >= endLine
	;       startLine += 64
	;       endLine += 64
	;       x = startLine
	;    else
	;       x += 2
	LDA	windowStart
	STA	startLine

	AND	#$FFC0
	STA	endLine
	LDA	windowEnd
	AND	#$003F
	ORA	endLine
	STA	endLine

	TYA

	LDX	windowStart
	REPEAT
		STA	f:buffer, X

		CPX	windowEnd
	WHILE_LT
		CPX	endLine
		IF_EQ
			LDA	startLine
			ADD	#64
			STA	startLine
			TAX

			LDA	endLine
			ADD	#64
			STA	endLine

			TYA
			CONTINUE
		ENDIF

		INX
		INX
	WEND


	; bufferPos = windowStart
	; bufferPosLineEnd = (windowStart & $FFC0) + ((windowEnd + 2) & $3F)
	LDA	windowStart
	STA	bufferPos

	AND	#$FFC0
	STA	tmp

	LDA	windowEnd
	AND	#$003F
	ORA	tmp
	STA	bufferPosLineEnd

	SEP	#$20
.A8
	; update on VBlank flag
	STZ	updateBufferIfZero

	PLP
	RTS
.endscope


; ::MAYDO replace with call to routine (ClearWRAM7E X = destination, Y = size)::.
ROUTINE ClearBuffer
	PHP
	PHB
	REP	#$30
.A16
.I16
	LDA	#0
	STA	f:buffer

	LDX	#.loword(buffer)
	LDY	#.loword(buffer) + 2 
	LDA	#.sizeof(buffer) - 3
	MVN	.bankbyte(buffer), .bankbyte(buffer)

	SEP	#$20
.A8
	STZ	updateBufferIfZero

	PLB
	PLP
	RTS

ENDMODULE


