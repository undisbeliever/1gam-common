;; Synthetic Instructions.
;;
;; Inspiration: <http://forums.nesdev.com/viewtopic.php?p=87209#p87209>

.ifndef ::_SYNTHETIC_INC_
::_SYNTHETIC_INC_ = 1

;; Add to accumulator
;;
;; CLC : ADC
.macro ADD param
	CLC
	ADC	param
.endmacro

;; Subtract from accumulator
;;
;; SEC : SBC
.macro SUB param
	SEC
	SBC	param
.endmacro

;; Reverse Subract
;;
;; REQUIRES: 8 bit A
.macro RSB param
	// ::TODO test 8/16 bit A::
	.if
		EOR	#$FF
		SEC
		ADC	param
	.else
		EOR	#$FFFF
		SEC
		ADC	param
	.endif
.endmacro

;; Reverse Subract with carry
.macro RSC param
	// ::TODO test 8/16 bit A::
	.if 
		EOR	#$FF
		SEC
		ADC	param
	.else
		EOR	#$FFFF
		SEC
		ADC	param
	.endif
.endmacro

;; Arithmetic Shift Right
.macro ASR param
	.if 
		CMP	#$80		; carry set to the sign bit
		ROR
	.else
		CMP	#$8000		; carry set to the sign bit
		ROR
	.endif
.endmacro


;; 8/16 bit rotate right
.macro ROTATEL
	ASL A
	ADC	#0
.endmacro


;; 8/16 bit rotate right
.macro ROTATER
	PHA
	LSR A
	PLA
	ROR
.endmacro


;; 32 bit increment
;; REQUIRES: 16 bit A
.macro INC32 param
	// ::TODO enforce 16 bit A::
	.local skip

	INC	param
	BNE	skip
	INC	param + 2
skip:
.endmacro


;; 32 bit decrement
;; REQUIRES: 16 bit A
.macro DEC32 param
	// ::TODO enforce 16 bit A::
	.local skip

	LDA	param
	BNE	skip
	DEC	param + 2

skip:
	DEC	param
.endmacro


;
; Branching
; ---------
;

;; Branch less than after CMP
.macro BLT target
	BCC	target
.endmacro

;; Branch greater than or equal after CMP
.macro BGE target
	BCS	target
.endmacro

;; Branch greater than after CMP
.macro BGT target
	.local here

	BEQ	here
	BCS	target
here:
.endmacro

;; Branch less than or equal after CMP
.macro BLE target
	BCC	target
	BEQ	target
.endmacro

;; Branch signed less than after CMP
.macro BSLT target
	BMI	target
.endmacro

;; Branch signed equal after CMP
.macro BSEQ target
	BEQ	target
.endmacro

;; Branch signed not equal after CMP
.macro BSNE target
	BNE	target
.endmacro

;; Branch signed greater than after CMP
.macro BSGT target
	.local here

	BEQ	here
	BPL	target
here:
.endmacro

;; Branch signed less than or equal after CMP
.macro BSLE target
	BMI	target
	BEQ	target
.endmacro

;; Branch greater than or equal after CMP
.macro BSGE target
	BPL	target
.endmacro


;
; Long branches
; -------------

;; Long branch always
;; Uses branch is possible (save 1 byte, same cycles)
.macro JRA target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BRA	target
	.else
		.local skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch if z set
.macro JEQ target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BEQ	target
	.else
		.local skip
		BNE	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch if z clear
.macro JNE target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BNE	target
	.else
		.local skip
		BEQ	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch if c clear
.macro JCC target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BCC	target
	.else
		.local skip
		BCS	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch if c set
.macro JCS target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BCS	target
	.else
		.local skip
		BCC	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch if n set 
.macro JMI target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BMI	target
	.else
		.local skip
		BPL	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch if n clear
.macro JPL target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BPL	target
	.else
		.local skip
		BMI	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch if v set 
.macro JVS target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BVS	target
	.else
		.local skip
		BVC	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch if v clear
.macro JVC target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BVC	target
	.else
		.local skip
		BVS	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch less than after CMP
.macro JLT target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BLT	target
	.else
		.local skip
		BGE	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch greater than or equal after CMP
.macro JGE target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BGE	target
	.else
		.local skip
		BLT	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch greater than after CMP
.macro JGT target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BGT	target
	.else
		.local skip
		BLE	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch less than or equal after CMP
.macro JLE target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BLE	target
	.else
		.local skip
		BGT	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch signed less than after CMP
.macro JSLT target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BSLT	target
	.else
		.local skip
		BSGE	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch signed equal after CMP
.macro JSEQ target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BSEQ	target
	.else
		.local skip
		BSNE	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch signed not equal after CMP
.macro JSNE target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BSNE	target
	.else
		.local skip
		BSEQ	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch signed greater than after CMP
.macro JSGT target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BSGT	target
	.else
		.local skip
		BSLE	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch signed less than or equal after CMP
.macro JSLE target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BSLE	target
	.else
		.local skip
		BSGT	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch greater than or equal after CMP
.macro JSGE target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BSGE	target
	.else
		.local skip
		BSLT	skip
		JMP	target
skip:
	.endif
.endmacro

.endif ; ::_SYNTHETIC_INC_

