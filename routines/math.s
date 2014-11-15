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

.code

.include "routines/math/division.asm"

ENDMODULE

