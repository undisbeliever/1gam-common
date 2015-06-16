;; DB unknown routines
;; Will set DB to $80, call the math routine and exit.

.macro JSR_DB	routine
	PHB
	PHK
	PLB

	JSR	routine
	PLB
.endmacro

ROUTINE Multiply_U8Y_U8X_UY_DB
	JSR_DB	Multiply_U8Y_U8X_UY
	RTS

ROUTINE Multiply_U16Y_U8A_U16Y_DB
ROUTINE Multiply_S16Y_U8A_S16Y_DB
ROUTINE Multiply_U16Y_U8A_U32_DB
	JSR_DB	Multiply_U16Y_U8A_U16Y
	RTS

ROUTINE Multiply_U16Y_U16X_U16Y_DB
ROUTINE Multiply_U16Y_S16X_16Y_DB
ROUTINE Multiply_S16Y_U16X_16Y_DB
ROUTINE Multiply_S16Y_S16X_S16Y_DB
	JSR_DB	Multiply_S16Y_S16X_S16Y
	RTS

ROUTINE Multiply_U16Y_U16X_U32XY_DB
ROUTINE Multiply_U16Y_S16X_32XY_DB
ROUTINE Multiply_S16Y_U16X_32XY_DB
	JSR_DB	Multiply_U16Y_U16X_U32XY
	RTS

ROUTINE Multiply_S16Y_S16X_S32XY_DB
	JSR_DB	Multiply_S16Y_S16X_S32XY
	RTS

ROUTINE Multiply_U32_S16Y_32XY_DB
ROUTINE Multiply_S32_S16Y_S32XY_DB
	JSR_DB	Multiply_U32_S16Y_32XY
	RTS

ROUTINE Multiply_U32_U16Y_U32XY_DB
ROUTINE Multiply_S32_U16Y_S32XY_DB
	JSR_DB	Multiply_U32_U16Y_U32XY
	RTS

ROUTINE Multiply_U32_U32XY_U32XY_DB
ROUTINE Multiply_U32_S32XY_32XY_DB
ROUTINE Multiply_S32_U32XY_32XY_DB
ROUTINE Multiply_S32_S32XY_S32XY_DB
	JSR_DB	Multiply_U32_U32XY_U32XY
	RTS

ROUTINE Multiply_U32XY_U8A_U32XY_DB
ROUTINE Multiply_S32XY_U8A_S32XY_DB
	JSR_DB	Multiply_U32XY_U8A_U32XY
	RTS


ROUTINE Divide_S16Y_U16X_DB
	JSR_DB	Divide_S16Y_U16X
	RTS

ROUTINE Divide_U16Y_S16X_DB
	JSR_DB	Divide_U16Y_S16X
	RTS

ROUTINE Divide_S16Y_S16X_DB
	JSR_DB	Divide_S16Y_S16X
	RTS

ROUTINE Divide_U16Y_U16X_DB
	JSR_DB	Divide_U16Y_U16X
	RTS

ROUTINE Divide_U16Y_U8A_DB
	JSR_DB	Divide_U16Y_U8A
	RTS

ROUTINE Divide_S32_S32_DB
	JSR_DB	Divide_S32_S32
	RTS

ROUTINE Divide_U32_U32_DB
	JSR_DB	Divide_U32_U32
	RTS

ROUTINE Divide_U32_U8A_DB
	JSR_DB	Divide_U32_U8A
	RTS

