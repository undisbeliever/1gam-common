
.include "includes/import_export.inc"
.include "includes/structure.inc"
.include "includes/synthetic.inc"
.include "includes/registers.inc"
.include "routines/text.h"
.include "routines/text8x8.h"

.setcpu "65816"


MODULE Text8x16

CONST	SECOND_HALF_TILE, 112

.rodata

LABEL Interface
	.addr	Text8x8::NewLine_DoubleSpacing	; NewLine
	.addr	PrintChar			; PrintChar
	.addr	Text8x8::CursorMoved		; CursorMoved
	.addr	Text8x8::GetWordLength		; GetWordLength
	.addr	Text8x8::SpecialCharacter	; SpecialCharacter


.code

.A8
.I16
ROUTINE PrintChar
	; If character is newline call NewLine
	CMP	#EOL
	IF_EQ
		LDX	Text::window + TextWindow::textInterfaceAddr
		JMP	(TextInterface::NewLine, X)
	ENDIF

	; if A in range FIRST_CHARACTER to LAST_CHARACTER
	;     A = A - ASCII_DELTA
	; else
	;     A = INVALID_CHARACTER

	SUB	#Text::ASCII_DELTA
	CMP	#Text::LAST_CHARACTER - Text::ASCII_DELTA
	IF_GE
		LDA	#TEXT_INVALID - Text::ASCII_DELTA
	ENDIF

	; Show character
	REP	#$30
.A16
	LDX	Text::window + TextWindow::bufferPos

	AND	#$00FF
	ADD	Text::window + TextWindow::tilemapOffset
	STA	f:Text::buffer, X

	ADD	#SECOND_HALF_TILE
	STA	f:Text::buffer + 64, X

	INX
	INX
	STX	Text::window + TextWindow::bufferPos

	SEP	#$20
.A8

	DEC	Text::window + TextWindow::tilesLeftInLine
	IF_ZERO
		LDX	Text::window + TextWindow::textInterfaceAddr
		JSR	(TextInterface::NewLine, X)	
	ENDIF

	RTS



