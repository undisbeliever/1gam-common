;;
;; Pixel Buffer
;; ============
;;
;; This module contains a 2bpp pixel buffer in WRAM.
;;
;; ::TODO determine how to send the buffer to WRAM::
;;

.ifndef ::_PIXELBUFFER_H_
::_PIXELBUFFER_H_ = 1

.include "includes/import_export.inc"
.include "includes/config.inc"

;; Width of the buffer in log2 tiles. (ie, 5=32 tiles, 4 = 16 tiles, 3 = 8 tiles)
;; MUST be between 1 and 6
CONFIG_DEFINE PIXELBUFFER_WIDTH_LOG2, 5
;; Height of the buffer in rows.
;; MUST be between 1 and 64
CONFIG_DEFINE PIXELBUFFER_HEIGHT, 28

.define PIXELBUFFER_WIDTH 1 << (PIXELBUFFER_WIDTH_LOG2)

;; The bank the buffers are stored in. Fastest if bank == WRAM7E
;; Options: WRAM7E, WRAM7F
CONFIG_DEFINE PIXELBUFFER_BANK, "WRAM7E"

IMPORT_MODULE PixelBuffer

	.define PixelBuffer_TILE_SIZE 16

	;; The pixel buffer
	;; ACCESS: PIXELBUFFER_BANK bank
	BYTE	buffer, PIXELBUFFER_WIDTH * PIXELBUFFER_HEIGHT * PixelBuffer_TILE_SIZE

	;; The bank ($7E or $7F) that the buffer is stored in.
	.globalzp PixelBuffer__bufferBank

	;; This variable represents the color of the pixels to set/unset.
	;; As the SNES uses a packed-pixel format, all the bits of lobyte
	;; represents the lobit of the color. Same goes for hibyte.
	;;
	;; This variable SHOULD only consist of the following values:
	;; 	* Color 0 - $0000
	;; 	* Color 1 - $00FF
	;; 	* Color 2 - $FF00
	;; 	* Color 3 - $FFFF
	;;
	;; ACCESS: PIXELBUFFER_BANK bank
	WORD	colorBits


	;; Retrieves the value of a pixel within the buffer.
	;; REQUIRES: 16 bit A, 16 bit X, DB = PixelBuffer__bufferBank
	;;
	;; INPUT:
	;;	X - xpos (MUST be < PIXELBUFFER_WIDTH * 8)
	;;	Y - ypos (MUST be < PIXELBUFFER_HEIGHT * 8)
	;;
	;; RETURNS: A - the color of the pixel.
	ROUTINE GetPixel

	;; Sets the pixel within the buffer.
	;; REQUIRES: 16 bit A, 16 bit X, DB = PixelBuffer__bufferBank
	;;
	;; WARNING: there is no input validation on this function
	;;	    This function WILL NOT mark the buffer as dirty.
	;;
	;; INPUT:
	;;	X - xpos (MUST be < PIXELBUFFER_WIDTH * 8)
	;;	Y - ypos (MUST be < PIXELBUFFER_HEIGHT * 8)
	;;	colorBits - color to set.
	ROUTINE SetPixel

	;; Draws a verical line in the buffer
	;; REQUIRES: 16 bit A, 16 bit X, DB = PixelBuffer__bufferBank
	;;
	;; WARNING: there is no input validation on this function
	;;	    This function WILL NOT mark the buffer as dirty.
	;;
	;; INPUT:
	;;	X - xpos (MUST be < PIXELBUFFER_WIDTH * 8)
	;;	Y - ypos (MUST be < PIXELBUFFER_HEIGHT * 8)
	;;	A - height (MUST be < PIXELBUFFER_WIDTH * 8 - Y)
	;;	colorBits - color to set.
	ROUTINE DrawVerticalLine

	;; Draws a verical line in the buffer
	;;
	;; This method is a lot faster than DrawVerticalLine
	;;
	;; REQUIRES: 16 bit A, 16 bit X, DB = PixelBuffer__bufferBank
	;;
	;; WARNING: there is no input validation on this function
	;;	    This function WILL NOT mark the buffer as dirty.
	;;
	;; INPUT:
	;;	X - xpos (MUST be < PIXELBUFFER_WIDTH * 8)
	;;	Y - ypos (MUST be < PIXELBUFFER_HEIGHT * 8)
	;;	A - width (MUST be < PIXELBUFFER_WIDTH * 8 - X)
	;;	colorBits - color to set.
	ROUTINE DrawHorizontalLine

ENDMODULE

.endif ; ::_PIXELBUFFER_H_

; vim: ft=asm:

