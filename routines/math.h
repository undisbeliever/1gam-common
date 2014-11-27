
.ifndef ::_MATH_H_
::_MATH_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"

IMPORT_MODULE Math

;; Division
;; ========

	UINT32 dividend32
	UINT32 divisor32
	UINT32 remainder32

	result32 := dividend32
	result32__type := TYPE_UINT32


	;; Optimised Unsigned 16 / 16 bit Integer Division.
	;;
	;; Inspiration: <http://codebase64.org/doku.php?id=base:16bit_division_16-bit_result>
	;;
	;; REQUIRES: 16 bit Index
	;;
	;; INPUT:
	;;	X: 16 bit unsigned Dividend
	;;	Y: 16 bit unsigned Divisor
	;;
	;; OUTPUT:
	;;	X: 16 bit unsigned Result
	;;	Y: 16 bit unsigned Remainder
	;;
	;;
	;; Uses SNES Registers if Y < 256.
	;;
	;;
	;; Uses 4 bytes of temporary variables.
	;;   * uint16 divisor
	;;   * uint16 counter
	ROUTINE DIVIDE_U16X_U16Y

	;; Unsigned 16 / 8 bit Integer Division
	;;
	;; REQUIRES: 8 bit A, 16 bit Index
	;;
	;; INPUT:
	;;	X: 16 bit unsigned Dividend
	;;	A: 8 bit unsigned Divisor
	;;
	;; OUTPUT:
	;;	X: 16 bit unsigned Result
	;;	Y: 16 bit unsigned Remainder
	ROUTINE DIVIDE_U16X_U8A

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
	ROUTINE DIVIDE_U32_U32

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
	ROUTINE DIVIDE_U32_U8A
ENDMODULE

.endif ; ::_MATH_H_

