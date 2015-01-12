; Test of Math routines
.include "routines/math.h"


PAGE_ROUTINE Math_Multiply_1
	Text_SetColor	4
	Text_PrintString "Multiply_U8Y_U8X_UY"
	
	.macro Test_Multiply_U8Y_U8X_UY factorY, factorX
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%10u * %3u = ", factorY, factorX)

		LDY	#factorY
		LDX	#factorX
		JSR	Math__Multiply_U8Y_U8X_UY

		Check_16Y (factorY * factorX)
		JSR	Text__PrintDecimal_U16Y
	.endmacro

	Test_Multiply_U8Y_U8X_UY	2, 2
	Test_Multiply_U8Y_U8X_UY	123, 56

	Text_SetColor	4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Multiply_U16Y_U8A_U16Y"

	.macro Test_Multiply_U16Y_U8A_U16Y factorY, factorA
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%10u * %3u = ", factorY, factorA)

		LDY	#factorY
		LDA	#factorA
		JSR	Math__Multiply_U16Y_U8A_U16Y
		LDXY	Math__product32

		Check_16Y (factorY * factorA)
		JSR	Text__PrintDecimal_U16Y
	.endmacro

	Test_Multiply_U16Y_U8A_U16Y	12345, 67
	Test_Multiply_U16Y_U8A_U16Y	$FEFE, $FE


	Text_SetColor	4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Multiply_S16Y_U8A_S16Y"

	.macro Test_Multiply_S16Y_U8A_S16Y factorY, factorA
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%10u * %3u = ", factorY, factorA)

		LDY	#.loword(factorY)
		LDA	#factorA
		JSR	Math__Multiply_S16Y_U8A_S16Y
		LDXY	Math__product32

		Check_16Y (factorY * factorA)
		JSR	Text__PrintDecimal_U16Y
	.endmacro

	Test_Multiply_S16Y_U8A_S16Y	12345, 67
	Test_Multiply_S16Y_U8A_S16Y	-12345, 67

	RTS



PAGE_ROUTINE Math_Multiply_2
	Text_SetColor	4
	Text_PrintString "Multiply_U16Y_U8A_U32XY"

	.macro Test_Multiply_U16Y_U8A_U32XY factorY, factorA
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%10u * %3u = ", factorY, factorA)

		LDY	#factorY
		LDA	#factorA
		JSR	Math__Multiply_U16Y_U8A_U16Y
		LDXY	Math__product32

		Check_32XY (factorY * factorA)
		JSR	Text__PrintDecimal_U32XY
	.endmacro

	Test_Multiply_U16Y_U8A_U32XY	12345, 67
	Test_Multiply_U16Y_U8A_U32XY	$FEFE, $FE



	Text_SetColor	4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Multiply_U16Y_U16X_U16Y"

	.macro Test_Multiply_U16Y_U16X_U16Y factorY, factorX
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%7i * %6i = ", factorY, factorX)

		LDY	#.loword(factorY)
		LDX	#.loword(factorX)
		JSR	Math__Multiply_U16Y_U16X_U16Y

		Check_16Y (factorY * factorX)
		JSR	Text__PrintDecimal_U16Y
	.endmacro

	Test_Multiply_U16Y_U16X_U16Y	1234, 5678
	Test_Multiply_U16Y_U16X_U16Y	987, 654


	Text_SetColor	4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Multiply_U16Y_U16X_U32XY"

	.macro Test_Multiply_U16Y_U16X_U32XY factorY, factorX
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%7u * %6u = ", factorY, factorX)

		LDY	#factorY
		LDX	#factorX
		JSR	Math__Multiply_U16Y_U16X_U32XY

		Check_32XY (factorY * factorX)
		JSR	Text__PrintDecimal_U32XY
	.endmacro

	Test_Multiply_U16Y_U16X_U32XY	123, 456
	Test_Multiply_U16Y_U16X_U32XY	9876, 54321
	Test_Multiply_U16Y_U16X_U32XY	12345, 6789
	Test_Multiply_U16Y_U16X_U32XY	$FEFE, $FEFE

	RTS



PAGE_ROUTINE Math_Multiply_3
	Text_SetColor	4
	Text_PrintString "Multiply_S16Y_S16X_S16Y"

	.macro Test_Multiply_S16Y_S16X_S16Y factorY, factorX
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%7i * %6i = ", factorY, factorX)

		LDY	#.loword(factorY)
		LDX	#.loword(factorX)
		JSR	Math__Multiply_S16Y_S16X_S16Y

		Check_16Y (factorY * factorX)
		JSR	Text__PrintDecimal_S16Y
	.endmacro

	Test_Multiply_S16Y_S16X_S16Y	12, 345
	Test_Multiply_S16Y_S16X_S16Y	-12, 345
	Test_Multiply_S16Y_S16X_S16Y	987, -6
	Test_Multiply_S16Y_S16X_S16Y	-987, -6

	Text_SetColor	4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Multiply_S16Y_S16X_S32XY"

	.macro Test_Multiply_S16Y_S16X_S32XY factorY, factorX
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%7i * %6i = ", factorY, factorX)

		LDY	#.loword(factorY)
		LDX	#.loword(factorX)
		JSR	Math__Multiply_S16Y_S16X_S32XY

		Check_32XY (factorY * factorX)
		JSR	Text__PrintDecimal_S32XY
	.endmacro

	Test_Multiply_S16Y_S16X_S32XY	1234, 5678
	Test_Multiply_S16Y_S16X_S32XY	-1234, 5678
	Test_Multiply_S16Y_S16X_S32XY	9876, -5432
	Test_Multiply_S16Y_S16X_S32XY	-9876, -5432

	RTS



PAGE_ROUTINE Math_Multiply_4
	Text_SetColor	4
	Text_PrintString "Multiply_U32XY_U8A_U32XY"

	.macro Test_Multiply_U32XY_U8A_U32XY factor32, factorA
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%10u * %3u = ", factor32, factorA)

		LDXY	#factor32
		LDA	#factorA
		JSR	Math__Multiply_U32XY_U8A_U32XY

		Check_32XY (factor32 * factorA)
		JSR	Text__PrintDecimal_U32XY
	.endmacro

	Test_Multiply_U32XY_U8A_U32XY	1234567, 89
	Test_Multiply_U32XY_U8A_U32XY	9876543, 21
	Test_Multiply_U32XY_U8A_U32XY	1984, 0
	Test_Multiply_U32XY_U8A_U32XY	$FEFEFEFE, $FE


	Text_SetColor	4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Multiply_S32XY_U8A_S32XY"

	.macro Test_Multiply_S32XY_U8A_S32XY factor32, factorA
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%10i * %3u = ", factor32, factorA)

		LDXY	#factor32
		LDA	#factorA
		JSR	Math__Multiply_S32XY_U8A_S32XY

		Check_32XY (factor32 * factorA)
		JSR	Text__PrintDecimal_U32XY
	.endmacro

	Test_Multiply_S32XY_U8A_S32XY	1234567, 89
	Test_Multiply_S32XY_U8A_S32XY	9876543, 21
	Test_Multiply_S32XY_U8A_S32XY	-1234567, 89
	Test_Multiply_S32XY_U8A_S32XY	-9876543, 21
	Test_Multiply_S32XY_U8A_S32XY	$FEFEFEFE, $FE

	RTS


PAGE_ROUTINE Math_Multiply_5
	Text_SetColor	4
	Text_PrintString "Multiply_U32_U16Y_U32XY"

	.macro Test_Multiply_U32_U16Y_U32XY factor32, factorY
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%8u * %5u = ", factor32, factorY)

		LDXY	#factor32
		STXY	Math__factor32
		LDY	#factorY
		JSR	Math__Multiply_U32_U16Y_U32XY

		Check_32XY (factor32 * factorY)
		JSR	Text__PrintDecimal_U32XY
	.endmacro

	Test_Multiply_U32_U16Y_U32XY	123, 456
	Test_Multiply_U32_U16Y_U32XY	9876, 54321
	Test_Multiply_U32_U16Y_U32XY	$FEFE, $FEFE
	Test_Multiply_U32_U16Y_U32XY	$FEFEFE, $FEFE


	Text_SetColor	4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Multiply_S32_U16Y_S32XY"

	.macro Test_Multiply_S32_U16Y_S32XY factor32, factorY
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%8i * %5i = ", factor32, factorY)

		LDXY	#factor32
		STXY	Math__factor32
		LDY	#factorY
		JSR	Math__Multiply_S32_U16Y_S32XY

		Check_32XY (factor32 * factorY)
		JSR	Text__PrintDecimal_S32XY
	.endmacro

	Test_Multiply_S32_U16Y_S32XY	98765, 4321
	Test_Multiply_S32_U16Y_S32XY	-98765, 4321

	RTS


PAGE_ROUTINE Math_Multiply_6
	Text_SetColor	4
	Text_PrintString "Multiply_U32_S16Y_32XY"

	.macro Test_Multiply_U32_S16Y_32XY factor32, factorY
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%8i * %5i = ", factor32, factorY)

		LDXY	#factor32
		STXY	Math__factor32
		LDY	#.loword(factorY)
		JSR	Math__Multiply_U32_S16Y_32XY

		Check_32XY (factor32 * factorY)
		JSR	Text__PrintDecimal_S32XY
	.endmacro

	Test_Multiply_U32_S16Y_32XY	1234567, 890
	Test_Multiply_U32_S16Y_32XY	1234567, -890


	Text_SetColor	4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Multiply_S32_S16Y_S32XY"

	.macro Test_Multiply_S32_S16Y_S32XY factor32, factorY
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%8i * %5i = ", factor32, factorY)

		LDXY	#factor32
		STXY	Math__factor32
		LDY	#.loword(factorY)
		JSR	Math__Multiply_S32_S16Y_S32XY

		Check_32XY (factor32 * factorY)
		JSR	Text__PrintDecimal_S32XY
	.endmacro

	Test_Multiply_S32_S16Y_S32XY	987654, 321
	Test_Multiply_S32_S16Y_S32XY	-987654, 321
	Test_Multiply_S32_S16Y_S32XY	987654, -321
	Test_Multiply_S32_S16Y_S32XY	-987654, -321

	RTS



PAGE_ROUTINE Math_Multiply_7
	Text_SetColor	4
	Text_PrintString "Multiply_U32_U32XY_U32XY (hex)"

	.macro Test_Multiply_U32_U32XY_U32XY factor32, factorXY
		; no new line, due to overflow.
		Text_SetColor	0
		Text_PrintString .sprintf("%8X * %8X = ", factor32, factorXY)

		LDXY	#factor32
		STXY	Math__factor32
		LDXY	#factorXY
		JSR	Math__Multiply_U32_U32XY_U32XY

		Check_32XY (factor32 * factorXY)
		Text_PrintHex	Math__product32
	.endmacro

	Test_Multiply_U32_U32XY_U32XY	$01234567, $89ABCDEF
	Test_Multiply_U32_U32XY_U32XY	$FEDCBA98, $76543210
	Test_Multiply_U32_U32XY_U32XY	$12343457, 0
	Test_Multiply_U32_U32XY_U32XY	$FEFEFE, $FEFEFE
	Test_Multiply_U32_U32XY_U32XY	$FEFEFEFE, $FEFEFEFE


	Text_SetColor	4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Multiply_S32_S32XY_S32XY"

	.macro Test_Multiply_S32_S32XY_S32XY factor32, factorXY
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%8i * %8i = ", factor32, factorXY)

		LDXY	#factor32
		STXY	Math__factor32
		LDXY	#factorXY
		JSR	Math__Multiply_S32_S32XY_S32XY

		Check_32XY (factor32 * factorXY)

		LDXY	Math__product32
		JSR	Text__PrintDecimal_S32XY
	.endmacro

	Test_Multiply_S32_S32XY_S32XY	123, -456
	Test_Multiply_S32_S32XY_S32XY	-987, 654 
	Test_Multiply_S32_S32XY_S32XY	-2014, -1201

	RTS



PAGE_ROUTINE Math_Divide_1
	Text_SetColor	4
	Text_PrintString "Divide_U16Y_U16X"

	.macro Test_Divide_U16Y_U16X dividend, divisor
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%8u / %5u = ", dividend, divisor)

		LDY	#dividend
		LDX	#divisor
		JSR	Math__Divide_U16Y_U16X

		PHX
		Check_16Y (dividend / divisor)
		JSR	Text__PrintDecimal_U16Y

		Text_SetColor	0
		Text_PrintString " r "

		PLY
		Check_16Y (dividend .mod divisor)
		JSR	Text__PrintDecimal_U16Y
	.endmacro


	Test_Divide_U16Y_U16X 12345, 6789
	Test_Divide_U16Y_U16X 9876, 54321
	; Divisor is one byte test.
	Test_Divide_U16Y_U16X 12345, 67
	Test_Divide_U16Y_U16X 9876, 5


	Text_SetColor	4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Divide_S16Y_U16X"

	.macro Test_Divide_S16Y_U16X dividend, divisor
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%8i / %5i = ", dividend, divisor)

		LDY	#.loword(dividend)
		LDX	#.loword(divisor)
		JSR	Math__Divide_S16Y_U16X

		PHX
		Check_16Y (dividend / divisor)
		JSR	Text__PrintDecimal_S16Y

		Text_SetColor	0
		Text_PrintString " r "

		PLY
		.if dividend .mod divisor > 0
			Check_16Y (dividend .mod divisor)
		.else
			Check_16Y -(dividend .mod divisor)
		.endif 
		JSR	Text__PrintDecimal_S16Y
	.endmacro

	Test_Divide_S16Y_U16X 12345, 6789
	Test_Divide_S16Y_U16X -12345, 6789


	Text_SetColor	4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Divide_U16Y_S16X"

	.macro Test_Divide_U16Y_S16X dividend, divisor
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%8i / %5i = ", dividend, divisor)

		LDY	#.loword(dividend)
		LDX	#.loword(divisor)
		JSR	Math__Divide_U16Y_S16X

		PHX
		Check_16Y (dividend / divisor)
		JSR	Text__PrintDecimal_S16Y

		Text_SetColor	0
		Text_PrintString " r "

		PLY
		.if dividend .mod divisor > 0
			Check_16Y (dividend .mod divisor)
		.else
			Check_16Y -(dividend .mod divisor)
		.endif 
		JSR	Text__PrintDecimal_S16Y
	.endmacro


	Test_Divide_U16Y_S16X 12345, 678
	Test_Divide_U16Y_S16X 12345, -678

	RTS


PAGE_ROUTINE Math_Divide_2
	Text_SetColor	4
	Text_PrintString "Divide_S16Y_S16X"

	.macro Test_Divide_S16Y_S16X dividend, divisor
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%8i /%5i = ", dividend, divisor)

		LDY	#.loword(dividend)
		LDX	#.loword(divisor)
		JSR	Math__Divide_S16Y_S16X

		PHX
		Check_16Y (dividend / divisor)
		JSR	Text__PrintDecimal_S16Y

		Text_SetColor	0
		Text_PrintString " r "

		PLY
		.if dividend .mod divisor > 0
			Check_16Y (dividend .mod divisor)
		.else
			Check_16Y -(dividend .mod divisor)
		.endif 
		JSR	Text__PrintDecimal_S16Y
	.endmacro


	Test_Divide_S16Y_S16X 12345, 6789
	Test_Divide_S16Y_S16X 12345, -6789
	Test_Divide_S16Y_S16X -9876, 54
	Test_Divide_S16Y_S16X -12345, -67



	Text_SetColor	4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Divide_U16Y_U8A"

	.macro Test_Divide_U16Y_U8A dividend, divisor
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%8u / %4u = ", dividend, divisor)

		LDY	#dividend
		LDA	#divisor
		JSR	Math__Divide_U16Y_U8A
		PHX

		Check_16Y (dividend / divisor)
		JSR	Text__PrintDecimal_U16Y

		Text_SetColor	0
		Text_PrintString " r "

		PLY
		Check_16Y (dividend .mod divisor)
		JSR	Text__PrintDecimal_U16Y
	.endmacro

	Test_Divide_U16Y_U8A 9876, 5
	Test_Divide_U16Y_U8A 12345, 67


	Text_SetColor	4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Divide_U32_U8A"

	.macro Test_Divide_U32_U8A dividend, divisor
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%8u / %4u = ", dividend, divisor)

		LDXY	#dividend
		STXY	Math__dividend32
		LDA	#divisor
		JSR	Math__Divide_U32_U8A

		PHA
		LDXY	Math__result32
		Check_32XY (dividend / divisor)
		JSR	Text__PrintDecimal_U32XY

		Text_SetColor	0
		Text_PrintString " r "

		PLA
		Check_U8A (dividend .mod divisor)
		JSR	Text__PrintDecimal_U8A
	.endmacro

	Test_Divide_U32_U8A 9876543, 21
	Test_Divide_U32_U8A 12345678, 90

	RTS


PAGE_ROUTINE Math_Divide_3
	Text_SetColor	4
	Text_PrintString "Divide_U32_U32"
	.macro Test_Divide_U32_U32 dividend, divisor
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%7u / %6u = ", dividend, divisor)

		LDXY	#dividend
		STXY	Math__dividend32
		LDXY	#divisor
		STXY	Math__divisor32
		JSR	Math__Divide_U32_U32

		LDXY	Math__result32
		Check_32XY (dividend / divisor)
		JSR	Text__PrintDecimal_U32XY

		Text_SetColor	0
		Text_PrintString " r "

		LDXY	Math__remainder32
		Check_32XY (dividend .mod divisor)
		JSR	Text__PrintDecimal_U32XY
	.endmacro

	Test_Divide_U32_U32 123456, 789
	Test_Divide_U32_U32 987654, 321
	Test_Divide_U32_U32 987, 654321
	Test_Divide_U32_U32 0, 123456


	Text_SetColor	4
	Text_NewLine
	Text_NewLine
	Text_PrintString "Divide_S32_S32"
	.macro Test_Divide_S32_S32 dividend, divisor
		Text_NewLine
		Text_SetColor	0
		Text_PrintString .sprintf("%7i / %6i = ", dividend, divisor)

		LDXY	#dividend
		STXY	Math__dividend32
		LDXY	#divisor
		STXY	Math__divisor32
		JSR	Math__Divide_S32_S32

		LDXY	Math__result32
		Check_32XY (dividend / divisor)
		JSR	Text__PrintDecimal_S32XY

		Text_SetColor	0
		Text_PrintString " r "

		LDXY	Math__remainder32
		.if dividend .mod divisor > 0
			Check_32XY (dividend .mod divisor)
		.else
			Check_32XY -(dividend .mod divisor)
		.endif 
		JSR	Text__PrintDecimal_S32XY
	.endmacro

	Test_Divide_S32_S32 987654, 321
	Test_Divide_S32_S32 123456, -789
	Test_Divide_S32_S32 -987, 654321
	Test_Divide_S32_S32 -123456, -789

	RTS

