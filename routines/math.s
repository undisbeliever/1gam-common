;; Math Routines

.include "routines/math.h"
.include "includes/import_export.inc"
.include "includes/structure.inc"
.include "includes/synthetic.inc"
.include "includes/registers.inc"

.setcpu "65816"

MODULE Math

.segment "SHADOW"
	BYTE	mathTmp1
	BYTE	mathTmp2
	BYTE	mathTmp3
	BYTE	mathTmp4

	UINT32	factor32
	UINT32	product32

	UINT32	dividend32
	UINT32	divisor32
	UINT32	remainder32
	; major optimisation in Division routines
	; Allows me to ASL both dividend and result together
	SAME_VARIABLE result32, dividend32

.code

.include "routines/math/multiplication.asm"
.include "routines/math/division.asm"

ENDMODULE

