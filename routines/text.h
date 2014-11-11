;;
;; Generic Fixed width Text
;; ========================
;;
;;

; Layout idea from: http://forums.nesdev.com/viewtopic.php?p=49694#p49694

.ifndef ::_TEXT_H_
::_TEXT_H_ = 1

.include "includes/import_export.inc"


IMPORT_MODULE Text
	;; The text buffer
	;; In $7E so shadow RAM can also be accessed.
	WORD	buffer, 32*32

	;; If zero, then update buffer to VRAM on VBlank
	BYTE updateBufferIfZero

	;; Index position of the buffer
	WORD bufferPos
	
	;; Word address of the tilemap in VRAM
	WORD vramMapAddr

	;; This word is added to each character to convert to a tileset
	;; Combines tile offset with palettes
	WORD tilemapOffset

	;; Number of tiles inbetween lines.
	;; (2 = double spacing or 8x16 font)
	BYTE lineSpacing

	;; Window Flags
	BYTE flags

		;;; Has a border
		CONST BORDER, $01

		;;; Has no border
		CONST NO_BORDER, $00

	;; Sets the color of the text
	;;
	;; REQUIRES: 8 bit A, 16 bit Index
	;; MODIFIES: A
	;;
	;; INPUT: A the color of the text
	ROUTINE SetColor

	;; Prints a string to the buffer
	;;
	;; REQUIRES: 8 bit A, 16 bit Index
	;; MODIFIES: A, X, Y
	;;
	;; INPUT: A:X the location of the string
	ROUTINE PrintString

	;; Prints a string to the buffer, with word wrap
	;;
	;; This routine only wraps spaces
	;; If word is longer than (lineWidth / 2) it will not be wrapped.
	;;
	;; REQUIRES: 8 bit A, 16 bit Index
	;; MODIFIES: A, X, Y
	;;
	;; INPUT: A:X the location of the string
	ROUTINE PrintStringWrap

	;; Prints a single character onto the buffer
	;;
	;; REQUIRES: 8 bit A, 16 bit Index
	;; MODIFIES: A, X
	;;
	;; INPUT: A = the character to print
	ROUTINE PrintChar

	;; Moves the cursor to the next line.
	;;
	;; If new line is outside the text boundry, Text::OutOfBounds is called.
	;;
	;; REQUIRES: DB in Shadow 
	;; MODIFIES: A, X
	ROUTINE NewLine

	;; Sets up a window at a given location.
	;;
	;; REQUIRES: 8 bit A, 16 bit Index.
	;;
	;; Your better off calling the Text_SetupWindow Macro
	;;
	;; INPUT:
	;;	A = Window Flags (see the constants above)
	;;	X = startYPos * 64 + startXPos * 2
	;;	Y = endYPos * 64 + endXPos * 2
	;;
	;; WARNING: If using a border X must be > 32*2+2 and Y must be < 32*32*2-66
	;;
	;; MODIFIES: A, X, Y
	ROUTINE SetupWindow

	;; Draws a border *outside* the Window area.
	;;
	;; Also clears the inside of the Window.
	;;
	;; The window area is defined by `windowStart` and `windowEnd`
	;;
	;; REQUIRES 8 bit A, 16 bit Index, DB shadow
	;; MODIFIES: A, X, Y
	ROUTINE DrawBorder

	;; Clears the inside of the Window.
	;;
	;; The window area is defined by `windowStart` and `windowEnd`
	;;
	;; REQUIRES DB shadow
	;; MODIFIES: A, X, Y
	ROUTINE ClearWindow

	;; Removes the window (resets tiles to 0)
	;;
	;; REQUIRES: DB shadow
	;; MODIFIES: A, X, Y
	;; CAVATS: may modify the window area, causing issues if called again
	ROUTINE RemoveWindow

	;; Resets the entire Text Buffer (to tile 0)
	;;
	;; REQUIRES: DB shadow
	ROUTINE ClearBuffer

ENDMODULE

;; Sets up a window with no border with a given dimensions.
;;
;; REQUIRES: 8 bit A, 16 bit Index
.macro Text_SetupWindow startXPos, startYPos, endXPos, endYPos, flags, spacing
	.if startXPos < 0 .or startXPos > 31
		.error "startXPos must be between 0 and 31"
	.endif
	.if endXPos < 0 .or endXPos > 31
		.error "endXPos must be between 0 and 31"
	.endif
	.if startYPos < 0 .or startYPos > 31
		.error "startYPos must be between 0 and 31"
	.endif
	.if endYPos < 0 .or endYPos > 31
		.error "endYpos must be between 0 and 31"
	.endif

	.if spacing < 1
		.error "spacing must be > 1"
	.endif

	LDA	#spacing
	STA	::Text::lineSpacing

	LDX	#startYPos * 64 + startXPos * 2
	LDY	#endYPos * 64 + endXPos * 2
	LDA	#flags
	JSR	::Text::SetupWindow
.endmacro



;; Prints a string (with word wrapping)
;;
;; A Label called `$tileset_End` must be defined marking the end of the
;; tileset.
;;
;; REQUIRES: 8 bit A, 16 bit X, DB in shadow, Force or V-Blank
.macro Text_LoadFont tileset, vramTilesetAddr, mapAddr, tileOffset
	LDX	#mapAddr
	STX	::Text::vramMapAddr

	LDX	#tileOffset
	STX	::Text::tilemapOffset

; ::TODO VRAM DMA macro::

	LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
	STA	VMAIN

	LDX	#vramTilesetAddr
	STX	VMADD

	LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_2REGS
	STA	DMAP0

	LDA	#.lobyte(VMDATA)
	STA	BBAD0

	LDX	#.ident(.sprintf("%s_End", .string(tileset))) - tileset
	STX	DAS0

	LDX	#.loword(tileset)
	STX	A1T0
	LDA	#.bankbyte(tileset)
	STA	A1B0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN

.endmacro


;; Updates the text buffer in VRAM
;;
;; REQUIRES: 8 bit A
; ::SHOULDDO dedicated VBlank channel::
.macro Text_VBlank
	LDA	::Text::updateBufferIfZero
	IF_ZERO
		LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
		STA	VMAIN

		LDX	Text::vramMapAddr
		STX	VMADD

		LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_2REGS
		STA	DMAP0

		LDA	#.lobyte(VMDATA)
		STA	BBAD0

		LDX	#Text::buffer__size
		STX	DAS0

		LDX	#.loword(Text::buffer)
		STX	A1T0
		LDA	#.bankbyte(Text::buffer)
		STA	A1B0

		LDA	#MDMAEN_DMA0
		STA	MDMAEN

		STA	::Text::updateBufferIfZero
	ENDIF
.endmacro


;; Prints a string
;;
;; REQUIRES: 8 bit A, 16 bit X, DB in shadow
.macro Text_PrintString param
	.if .match(param, "")
		.local check, skip, string

		check:
		.rodata
		string:
			.asciiz param
		.code
			.assert check = skip, lderror, "Bad flow in Text_PrintString"
		skip:
			LDX	#.loword(string)
			LDA	#.bankbyte(string)

			JSR	::Text::PrintString
	.else
		LDX	#.loword(param)
		LDA	#.bankbyte(param)

		JSR	::Text::PrintString
	.endif
.endmacro


;; Prints a string (with word wrapping)
;;
;; REQUIRES: 8 bit A, 16 bit X, DB in shadow
.macro Text_PrintStringWrap param
	.if .match(param, "")
		.local check, skip, string

		check:
		.rodata
		string:
			.asciiz param
		.code
			.assert check = skip, lderror, "Bad flow in Text_PrintString"
		skip:
			LDX	#.loword(string)
			LDA	#.bankbyte(string)

			JSR	::Text::PrintStringWrap
	.else
		LDX	#.loword(param)
		LDA	#.bankbyte(param)

		JSR	::Text::PrintStringWrap
	.endif
.endmacro

;; End of line character
.define EOL 13


; Extended characters
.define TEXT_DOT		127
.define UP_ARROW		128
.define DOWN_ARROW		129
.define LEFT_ARROW		130
.define RIGHT_ARROW		131
.define SELECT_CHARACTER	132
.define SELECT_CHARACTER_SMALL	133
.define MORE_CHARACTER		134
.define MORE_CHARACTER_SMALL	135
.define BORDER_TOP_LEFT		136
.define BORDER_TOP		137
.define BORDER_TOP_RIGHT	138
.define BORDER_LEFT		139
.define BORDER_RIGHT		140
.define BORDER_BOTTOM_LEFT	141
.define BORDER_BOTTOM		142
.define BORDER_BOTTOM_RIGHT	143

;; Empty filled square
.define TEXT_CLEAR		' '
.define TEXT_INVALID		TEXT_DOT


;; conversion between ASCII and the tileset
.define TEXT_DELTA		' '

.endif ; ::_TEXT_H_

