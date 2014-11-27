;; Division routines
;; -----------------
;;
;; included by `routines/math.s`


.segment "SHADOW"
	UINT32 dividend32
	UINT32 divisor32
	UINT32 remainder32
	SAME_VARIABLE result32, dividend32


.code

; INPUT:
;	X: 16 bit unsigned Dividend
;	Y: 16 bit unsigned Divisor
;
; OUTPUT:
;	X: 16 bit unsigned Result
;	Y: 16 bit unsigned Remainder
;
; Timings:
;  Y < 256:   44 cycles 
;  tmp dp:    474 - 517 cycles
;  tmp addr:  508 - 572 cycles
;
; You could save 152 (dp) or 169 (addr) cycles if the loop is unfolded
; But increases size by 186 (dp) or 199 (addr) bytes.
;
; if divisor < 256
;	calculate using SNES registers
; else
; 	remainder = 0
; 	repeat 16 times 
; 		remainder << 1 | MSB(dividend)
; 		dividend << 1
; 		if (remainder >= divisor)
;			remainder -= divisor
;			result++

.I16
ROUTINE DIVIDE_U16X_U16Y
.scope
counter := mathTmp1
divisor := mathTmp3

	PHP
	CPY	#$0100
	IF_GE
		REP	#$20
.A16
		STY	divisor
		LDY	#0			; Remainder
		LDA	#16
		STA	counter

		REPEAT
			TXA			; Dividend / result
			ASL A
			TAX
			TYA 			; Remainder
			ROL A
			TAY

			SUB	divisor
			IF_C_SET		; C set if positive
				TAY
				INX 		; Result
			ENDIF

			DEC	counter
		UNTIL_ZERO

		PLP
		RTS
	ENDIF

	; Otherwise Use registers instead
		STX	WRDIV
		SEP	#$30			; 8 bit Index
.A8
.I8
		STY	WRDIVB

		; Wait 16 Cycles
		PHD				; 4
		PLD				; 5
		PLP				; 4
.I16
		BRA	DIVIDE_U16X_U8A_Result  ; 3

	; Endif
.endscope



; INPUT:
;	X: 16 bit unsigned Dividend
;	A: 8 bit unsigned Divisor
;
; OUTPUT:
;	X: 16 bit unsigned Result
;	Y: 16 bit unsigned Remainder
.A8
.I16
ROUTINE DIVIDE_U16X_U8A

	STX	WRDIV
	STA	WRDIVB			; Load to SNES division registers

	; Wait 16 Cycles
	PHD				; 4
	PLD				; 5
	PHB				; 3
	PLB				; 4

DIVIDE_U16X_U8A_Result:

	LDX	RDDIV			; result
	LDY	RDMPY			; remainder

	RTS



; remainder = 0
; Repeat 32 times:
; 	remainder << 1 | MSB(dividend)
; 	dividend << 1
; 	if (remainder >= divisor)
;		remainder -= divisor
;		result++
.A16
.I16
ROUTINE DIVIDE_U32_U32
	PHP
	REP	#$30
.A16
.I16

	STZ	remainder32
	STZ	remainder32 + 2

	FOR_X #32, DEC, #0
		ASL	dividend32
		ROL	dividend32 + 2
		ROL	remainder32
		ROL	remainder32 + 2

		LDA	remainder32
		SEC
		SBC	divisor32
		TAY
		LDA	remainder32 + 2
		SBC	divisor32 + 2
		IF_C_SET
			STY	remainder32
			STA	remainder32 + 2
			INC	result32	; result32 = dividend32, no overflow possible
		ENDIF
	NEXT

	PLP
	RTS



; INPUT:
;	dividend32: uint32 dividend
;	A : 8 bit divisor
;
; OUTPUT:
;	result32: uint32 result
;       A: uint8 remainder
ROUTINE DIVIDE_U32_U8A
	PHP
	SEP	#$30			; 8 bit A, 8 bit Index
.A8
.I8

	TAY				; divisor
	LDA	#0			; remainder

	LDX	#3			; loop bytes 3 to (including) 0
	REPEAT
		STA	WRDIVH		; remainder from previous division (always < divisor)
		LDA	dividend32, X
		STA	WRDIVL

		STY	WRDIVB		; Load to SNES division registers

		; Wait 16 Cycles
		PHD			; 4
		PLD			; 5
		PHB			; 3
		PLB			; 4

		LDA	RDDIV
		STA	result32, X	; store result (8 bit as remainder < divisor)
		LDA	RDMPY		; remainder (also 8 bit)

		DEX
	UNTIL_MINUS

	PLP
	RTS

