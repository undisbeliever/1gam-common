
.include "includes/import_export.inc"
.include "includes/structure.inc"
.include "includes/synthetic.inc"
.include "includes/registers.inc"
.include "routines/math.h"
.include "routines/text.h"

.setcpu "65816"

MODULE Text

.define LAST_CHARACTER		144

; ::TODO SetCursor::

.zeropage
	;; The position of the string
	LONG	stringPtr

	; Temporry values used by3this module
	WORD	tmp
	WORD	tmp2
	WORD	tmp3




.segment "WRAM7E"
	;; The text buffer
	;; In $7E so shadow RAM can also be accessed.
	WORD buffer, 32*32

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

	;; The width of the line.
	WORD lineWidth

	;; Storage area to store decoded string.
	;; Long enough to cover the enture word.
	BYTE decimalString, 11


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


; INPUT: XY = value
.A8
.I16
ROUTINE PrintDecimal_U32XY
	LDA	#0
	.assert * = PrintDecimalPadded_U32XY, lderror, "Bad Flow Control"

ROUTINE PrintDecimalPadded_U32XY
	JSR	ConvertDecimalString_U32XY
	BRA	PrintString

.A8
.I16
ROUTINE PrintDecimal_U8A
	STA	tmp
	STZ	tmp + 1
	LDY	tmp
	BRA	PrintDecimal_U16Y

.A8
.I16
ROUTINE PrintDecimal_U16X
	TXY
	.assert * = PrintDecimal_U16Y, lderror, "Bad Flow Control"

.A8
.I16
ROUTINE PrintDecimal_U16Y
	JSR	ConvertDecimalString_U16Y
	.assert * = PrintString, lderror, "Bad Flow Control"


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



padding := tmp

ROUTINE PrintDecimalFixed_U8A_3
	STA	tmp
	STZ	tmp + 1
	LDX	tmp
	LDA	#2
	STA	padding
	BRA	_PrintDecimalFixed_U16X_AfterCheck

ROUTINE PrintDecimalFixed_U8A_2
	STA	tmp
	STZ	tmp + 1
	LDX	tmp
	LDA	#1
	STA	padding
	BRA	_PrintDecimalFixed_U16X_AfterCheck

ROUTINE PrintDecimalFixed_U8A_1
	STA	tmp
	STZ	tmp + 1
	LDX	tmp
	LDA	#0
	STA	padding
	BRA	_PrintDecimalFixed_U16X_AfterCheck


; INPUT: A = Padding
.A8
.I16
ROUTINE PrintDecimalFixed_U16Y
	TYX
	.assert * = PrintDecimalFixed_U16X, lderror, "Bad Flow Control"

.A8
.I16
ROUTINE PrintDecimalFixed_U16X
	DEC
	CMP	#.sizeof(decimalString) - 2
	IF_GE
		LDA	#.sizeof(decimalString) - 2
	ENDIF

	STA	padding
	STZ	padding + 1

_PrintDecimalFixed_U16X_AfterCheck:
	LDY	tmp
	REPEAT
		STX	WRDIVL

		LDA	#10
		STA	WRDIVB

		; Wait 16 Cycles
		PHD			; 4
		PLD			; 5
		PHB			; 3
		PLB			; 4

		LDA	RDMPY		; remainder
		STA	decimalString, Y

		LDX	RDDIV		; result

		DEY
	UNTIL_MINUS

	LDY	#0
	REPEAT
		LDA	decimalString, Y
		ADD	#'0' - TEXT_DELTA

		JSR	_PrintChar_After_Check

		INY
		CPY	padding
	UNTIL_GT

	RTS

.A8
.I16
ROUTINE PrintDecimalWrap_U8A
	STA	tmp
	STA	tmp + 1
	LDY	tmp
	BRA	PrintDecimalWrap_U16Y

.A8
.I16
ROUTINE PrintDecimalWrap_U16X
	TXY
	.assert * = PrintDecimalWrap_U16Y, lderror, "Bad Flow Control"

.A8
.I16
ROUTINE PrintDecimalWrap_U16Y
	JSR	ConvertDecimalString_U16Y
	.assert * = PrintStringWrap, lderror, "Bad Flow Control"

.A8
.I16
ROUTINE PrintStringWrap
startWord := tmp2
endWord := tmp3

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



.A8
.I16
; INPUT: A - the character to print
; MODIFIES: A, X
; MUST NOT USE Y
ROUTINE PrintChar
	; If character is newline call NewLine
	CMP	#EOL
	BEQ	NewLine

	; if A in range FIRST_CHARACTER to LAST_CHARACTER
	;     A = A - TEXT_DELTA
	; else
	;     A = INVALID_CHARACTER
	SUB	#TEXT_DELTA
	CMP	#LAST_CHARACTER - TEXT_DELTA
	IF_GE
		LDA	#TEXT_INVALID - TEXT_DELTA
	ENDIF

_PrintChar_After_Check:
	LDX	bufferPos

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



.A8
.I16
ROUTINE PrintHex_U8A
	PHA

	LSR
	LSR
	LSR
	LSR
	CMP	#10
	IF_GE
		CLC
		ADC	#'A' - 10 - TEXT_DELTA
	ELSE
		ADC	#'0' - TEXT_DELTA
	ENDIF
	JSR	_PrintChar_After_Check

	PLA
	AND	#$0F
	CMP	#10
	IF_GE
		CLC
		ADC	#'A' - 10 - TEXT_DELTA
	ELSE
		ADC	#'0' - TEXT_DELTA
	ENDIF
	BRA	_PrintChar_After_Check



.I16
ROUTINE PrintHex_U16Y
	TYX

	.assert * = PrintHex_U16X, lderror, "Bad Flow"


.I16
ROUTINE PrintHex_U16X
	PHP
	REP	#$20
.A16
	TXA
	SEP	#$20
.A8
	PHA
	XBA
	JSR	PrintHex_U8A

	PLA
	JSR	PrintHex_U8A
	
	PLP
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



ROUTINE SetCursor
	PHP
	REP	#$30
.A16
.I16
	CPX	lineWidth
	IF_GE
		LDX	#0
	ENDIF

	; lineStart = windowStart + Y * 64
	; if lineStart > windowEnd
	;	linestart = windowStart & $FFC0
	; bufferPos = lineStart + X * 2
	; bufferPosLineEnd = lineStart + (lineWidth - 1) * 2
	TYA
	XBA
	AND	#$FF00
	LSR
	LSR
	ADD	windowStart
	STA	tmp

	CMP	windowEnd
	IF_GE
		LDA	windowStart
		AND	#$FFC0
	ENDIF

	TXA
	ASL
	ADD	tmp
	STA	bufferPos

	LDA	lineWidth
	DEC
	ASL
	ADD	tmp
	STA	bufferPosLineEnd

	PLP
	RTS


.A8
.I16
ROUTINE SetupWindow
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



ROUTINE DrawBorder
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


; A helper function to fill the entirety of the window.
; REQUIRES: 16 bit A, 16 bit Index, P on stack
; INPUT: Y = the Tile to copy
.A16
.I16
ROUTINE _FillWindow_p_on_stack
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



;; Converts the value in the 16 bit X to a string stores in `decimalString`
;;
;; REQUIRES: 8 bit A, 16 bit Index
;; INPUT: X = the number to display
;; OUTPUT: A the bank of the string to print
;;         X the location of the string to print 
.A8
.I16
ROUTINE ConvertDecimalString_U16Y
	LDX	#decimalString + .sizeof(decimalString) - 1

	REPEAT
		STY	WRDIVL

		LDA	#10
		STA	WRDIVB

		; Wait 16 Cycles
		PHD			; 4
		PLD			; 5
		PHB			; 3
		PLB			; 4

		LDA	RDMPY		; remainder
		ADD	#'0'
		DEX
		STA	0, X

		LDY	RDDIV		; result
	UNTIL_ZERO

	STZ	decimalString + .sizeof(decimalString) - 1

	LDA	#.bankbyte(decimalString)
	RTS

;; Converts the value in the 32 but XY to a string stored in `decimalString`
;;
;; REQUIRES: 8 bit A, 16 bit Index
;; INPUT: XY = value, A = number of characters to print
;;	   A = the number of padding characters (if 0 then show entire string)
;; OUTPUT: A the bank of the string to print
;;         X the location of the string to print 
.A8
.I16
ROUTINE ConvertDecimalString_U32XY
position := tmp2
	STX	Math::dividend32
	STY	Math::dividend32 + 2

	STA	padding
	STZ	padding + 1

	LDX	#.sizeof(decimalString) - 2
	STX	position

	REPEAT
		LDA	#10
		JSR	Math::DIVIDE_U32_U8A

		LDX	position

		ADD	#'0'
		STA	decimalString, X

		DEC	position
	UNTIL_MINUS

	STZ	decimalString + .sizeof(decimalString) - 1

	REP	#$20
.A16
	; no need for range checking, that is what the BMI is for
	LDA	#.sizeof(decimalString) - 1 
	SUB	padding
	TAY
	SEP	#$20
.A8

	LDX	#decimalString
	REPEAT
		LDA	0, X
		CMP	#'0'
	WHILE_EQ
		DEY
		BMI	BREAK_LABEL

		INX
	WEND
	
	LDA	#.bankbyte(decimalString)
	RTS

ENDMODULE


