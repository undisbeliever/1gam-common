
.ifndef ::_MATH_H_
::_MATH_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"

IMPORT_MODULE Math

	UINT32	factor32
	UINT32	product32

	UINT32	dividend32
	UINT32	divisor32
	UINT32	remainder32
	SAME_VARIABLE result32, dividend32

;; Multiplication
;; ==============
	;; Mutliply an 8 bit unsigned integer by an 8 bit unsigned integer
	;;
	;; REQUIRE: 8 bit A, DB Shadow
	;; MODIFIES: Y
	;;
	;; INPUT:
	;;	Y: unsigned integer (only low 8 bits are used)
	;;	X: unsigned integer (only low 8 bit are used)
	;;
	;; OUTPUT:
	;;	Y: result (8 or 16 bits depending on Index size)
	ROUTINE Multiply_U8Y_U8X

	;; Mutliply a 16 bit unsigned integer by an 8 bit unsigned integer
	;;
	;; REQUIRE: 8 bit A, 16 bit Index, DB Shadow
	;; MODIFIES: A, Y, X
	;;
	;; INPUT:
	;;	Y: 16 bit unsigned integer
	;;	A: 8 bit unsigned integer
	;;
	;; OUTPUT:
	;;	Y: 32 bit unsigned integer
	;;	product32: 32 bit unsigned product
	ROUTINE Multiply_U16Y_U8A

	;; Multiply two 16 bit unsigned integers.
	;;
	;; REQUIRE: 16 bit Index, DB Shadow
	;; MODIFIES: A, X, Y
	;;
	;; INPUT:
	;;	Y: 16 bit unsigned integer
	;;	X: 16 bit unsigned integer
	;;
	;; OUTPUT:
	;;	XY: 32 bit unsigned integer
	;;	product32: 32 bit unsigned product
	ROUTINE Multiply_U16Y_U16X

	;; Mutliply a 32 bit unsigned integer by an 8 bit unsigned integer
	;;
	;; REQUIRE: 8 bit A, 16 bit Index, DB Shadow
	;; MODIFIES: A, X, Y
	;;
	;; INPUT:
	;;	XY: 32 bit unsigned integer (Y loword)
	;;	A: 8 bit unsigned integer
	;;
	;; OUTPUT:
	;;	XY: 32 bit unsigned integer
	;;	product32: 32 bit unsigned product
	;;	c: 33rd bit of result
	ROUTINE Multiply_U32XY_U8A

	;; Multiply a 32 bit unsigned Integer by a 16 bit unsigned integer.
	;;
	;; REQUIRE: 8 bit A, 16 bit Index, DB Shadow
	;;
	;; INPUT:
	;;	factor32: 16 bit unsigned integer
	;;	Y: 16 bit unsigned integer
	;;
	;; OUTPUT:
	;;	XY: 32 bit unsigned integer
	;;	product32: 32 bit unsigned product
	ROUTINE Multiply_U32_U16Y

	;; Multiply a 32 bit unsigned Integer by a 32 bit unsigned integer.
	;;
	;; REQUIRE: 8 bit A, 16 bit Index, DB Shadow
	;;
	;; INPUT:
	;;	factor32: 16 bit unsigned integer
	;;	XY: 32 bit unsigned integer (Y = loword)
	;;
	;; OUTPUT:
	;;	XY: 32 bit unsigned integer
	;;	product32: 32 bit unsigned product
	ROUTINE Multiply_U32_U32XY

;; Division
;; ========

	;; Optimised Unsigned 16 / 16 bit Integer Division.
	;;
	;; Inspiration: <http://codebase64.org/doku.php?id=base:16bit_division_16-bit_result>
	;;
	;; REQUIRES: 16 bit Index
	;;
	;; INPUT:
	;;	Y: 16 bit unsigned Dividend
	;;	X: 16 bit unsigned Divisor
	;;
	;; OUTPUT:
	;;	Y: 16 bit unsigned Result
	;;	X: 16 bit unsigned Remainder
	;;
	;;
	;; Uses SNES Registers if Y < 256.
	;;
	;;
	;; Uses 4 bytes of temporary variables.
	;;   * uint16 divisor
	;;   * uint16 counter
	ROUTINE Divide_U16Y_U16X

	;; Unsigned 16 / 8 bit Integer Division
	;;
	;; REQUIRES: 8 bit A, 16 bit Index
	;;
	;; INPUT:
	;;	Y: 16 bit unsigned Dividend
	;;	A: 8 bit unsigned Divisor
	;;
	;; OUTPUT:
	;;	Y: 16 bit unsigned Result
	;;	X: 16 bit unsigned Remainder
	ROUTINE Divide_U16Y_U8A

	;; Unsigned 32 / 32 bit Integer Division
	;;
	;; Inspiration: <http://codebase64.org/doku.php?id=base:16bit_division_16-bit_result>
	;;
	;; INPUT:
	;;	dividend32: uint32
	;;	divisor32: uint32
	;;
	;; OUTPUT:
	;;	result32: uint32
	;;      remainder32: uint32
	;;
	;; NOTES:
	;;	`result32` and `dividend32` share the same memory location
	ROUTINE Divide_U32_U32

	;; Unsigned 32 / 8 bit Integer Division
	;;
	;; INPUT:
	;;	dividend32: uint32 dividend
	;;	A : 8 bit divisor
	;;
	;; OUTPUT:
	;;	result32: uint32 result
	;;      A: uint8 remainder
	;;
	;; NOTES:
	;;	`result32` and `dividend32` share the same memory location
	ROUTINE Divide_U32_U8A
ENDMODULE

.endif ; ::_MATH_H_

