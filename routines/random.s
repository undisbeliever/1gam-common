; Randomizer module

.include "random.h"
.include "includes/registers.inc"
.include "routines/math.h"

MODULE Random

.segment "SHADOW"
	UINT32	Seed
	WORD	prevJoypadState
	WORD	tmp
.code


.A8
.I16
ROUTINE AddJoypadEntropy
	LDX	JOY1
	CPX	prevJoypadState
	IF_NE
		STX	prevJoypadState
		JSR	Rnd
	ENDIF

	.assert * = Rnd, lderror, "Bad flow"


.A8
.I16
ROUTINE Rnd
	; Seed = Seed * MTH_A + MTH_C

	LDXY	Seed
	STXY	Math__factor32
	LDY	#Random__MTH_A
	JSR	Math__Multiply_U32_U16Y_U32XY

	REP	#$21	; include carry
.A16
	TYA
	ADC	#.loword(Random__MTH_C)
	STA	Seed
	TXA
	ADC	#.hiword(Random__MTH_C)
	STA	Seed + 2

	SEP	#$20
.A8
	RTS


.A8
.I16
ROUTINE Rnd_4
	JSR	Rnd
	LDA	Seed + 2
	LSR
	LSR
	LSR
	LSR
	AND	#$03
	RTS


.A8
.I16
ROUTINE Rnd_3
	JSR	Rnd
	LDA	Seed + 1
	LSR
	LSR
	LSR
	AND	#$03
	IF_ZERO
		LDA	Seed + 2
		LSR
		LSR
		AND	#$03
		IF_ZERO
			LDA	#2
		ENDIF
	ENDIF
	DEC	; faster than CMP

	RTS


.A8
.I16
ROUTINE Rnd_2
	JSR	Rnd
	LDA	Seed
	ASL

	LDA	#0
	ROL

	RTS


; Y = number of probabilities
.A8
.I16
ROUTINE	Rnd_U16Y
	PHY

	JSR	Rnd

	PLX
	LDY	Seed + 1
	JSR	Math__Divide_U16Y_U16X

	TXY
	RTS




; X = min
; Y = max
.A8
.I16
ROUTINE	Rnd_U16X_U16Y
	STX	tmp
	PHY

	JSR	Rnd

	REP	#$30
.A16
	PLA
	SUB	tmp
	TAX

	LDY	Seed + 1
	JSR	Math__Divide_U16Y_U16X

	TXA
	ADD	tmp
	TAY

	SEP	#$20
.A8
	RTS

ENDMODULE

; vim: set ft=asm:

