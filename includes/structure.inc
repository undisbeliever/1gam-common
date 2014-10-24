;; structure.inc
;;
;; Macros to handle structure.
;;
;; Inspired by:
;; 	* [Adventures in NESDEV - HL macros technical](http://mynesdev.blogspot.ca/2012/10/hl-macros-technical.html)
;;	* [Wilson Mines Company - Structure Macros](http://wilsonminesco.com/StructureMacros/index.html)
;;
;; I first tried using the HL macros for 65816 code, but they kept mixing
;; 8/16 bit state and failing to generate correct code and thus tried to
;; look for something simpler.
;; I was looking at the [6502 forum](http://forum.6502.org/) and found
;; [Wilson Mines Company's Structure macros](http://wilsonminesco.com/StructureMacros/index.html).
;;
;; After understanding how the structure macros are made, I crated my own.
;;
;; These macros allow for status flag checking to be used in conditional code.
;; The actual branch that is used is the opposite of what is indicated by
;; macro name (it improves readability).
;;
;; These macros provide the following functionaity:
;;
;;   * An 8 level stack. Up to 8 IFs and REPEATs can be nested in one code.
;;     An.fatal will be emmited if the stack is overrun or underrun.
;;
;;   * A fatal will be emmited if a ENDIF / ELSE / UNTIL / NEXT
;;	 is used without the matching IF / REPEAT / FOR on the stack.
;;
;;   * Long branches will be used on REPEAT / FOR if necessary.
;;
;;   * BREAK / CONTINUE for loops (can be used inside IFs)
;;
;;   * Generates the minimum code needed as all testing is done outside the
;;     structure macros (usually with CMP, CPX, XPY, AND, EOR, BIT, etc).
;;
;; Cavats:
;;
;;   * If a NEXT / UNTIL is missing, no error will be produced.
;;     There is no way for ca65 to automatically call a macro at end of file.
;;

.ifndef ::_STRUCTURE_INC_
::_STRUCTURE_INC_ = 1

; ::TODO REPEAT ... WHILE ... WEND ::

; ::SHOULDDO FUNCION, ENDFUNCION ::
; http://mynesdev.blogspot.ca/2013/09/getting-most-out-of-ca65-part-1.html
;  * Ensures that stack is empty
;
; ::TODO CALL::
;  * Create defines for Acc, Index 8/16 state ?
;  * Check that Bank is correct


.define __STRUCTURE_TYPE_IF	 2
.define __STRUCTURE_TYPE_REPEAT  3
.define __STRUCTURE_TYPE_FOR     4


::__STRUCTURE_STACK_TYPE_08 .set 0
::__STRUCTURE_STACK_TYPE_07 .set 0
::__STRUCTURE_STACK_TYPE_06 .set 0
::__STRUCTURE_STACK_TYPE_05 .set 0
::__STRUCTURE_STACK_TYPE_04 .set 0
::__STRUCTURE_STACK_TYPE_03 .set 0
::__STRUCTURE_STACK_TYPE_02 .set 0
::__STRUCTURE_STACK_TYPE_01 .set 0

::__STRUCTURE_STACK_LOOP_08 .set 0
::__STRUCTURE_STACK_LOOP_07 .set 0
::__STRUCTURE_STACK_LOOP_06 .set 0
::__STRUCTURE_STACK_LOOP_05 .set 0
::__STRUCTURE_STACK_LOOP_04 .set 0
::__STRUCTURE_STACK_LOOP_03 .set 0
::__STRUCTURE_STACK_LOOP_02 .set 0
::__STRUCTURE_STACK_LOOP_01 .set 0

::__STRUCTURE_STACK_ID_08 .set 0
::__STRUCTURE_STACK_ID_07 .set 0
::__STRUCTURE_STACK_ID_06 .set 0
::__STRUCTURE_STACK_ID_05 .set 0
::__STRUCTURE_STACK_ID_04 .set 0
::__STRUCTURE_STACK_ID_03 .set 0
::__STRUCTURE_STACK_ID_02 .set 0
::__STRUCTURE_STACK_ID_01 .set 0

::__STRUCTURE_STACK_PREV  .set 0

::__STRUCTURE_STACK_COUNT .set 0

; ::TODO add BREAK to structure::
; need to setup new stack


.define __STRUCTURE_STACK_LABEL .ident(.sprintf("__STRUCTURE_%04X", ::__STRUCTURE_STACK_ID_01))
.define __STRUCTURE_STACK_PREV_LABEL .ident(.sprintf("__STRUCTURE_%04X", ::__STRUCTURE_STACK_PREV))
.define __STRUCTURE_STACK_LOOP_BREAK_LABEL .ident(.sprintf("__STRUCTURE_BREAK_%04X", ::__STRUCTURE_STACK_LOOP_01))
.define __STRUCTURE_STACK_LOOP_CONTINUE_LABEL .ident(.sprintf("__STRUCTURE_CONTINUE_%04X", ::__STRUCTURE_STACK_LOOP_01))


; creates a new label name and adds it to the if stack
.macro __STRUCTURE_STACK_PUSH_NEW type
	::__STRUCTURE_STACK_COUNT .set ::__STRUCTURE_STACK_COUNT + 1

	.if (::__STRUCTURE_STACK_TYPE_08 <> 0)
		.fatal "Too many structures"
	.endif

	; Push to loop stack only if it is a looping structure
	.if (type = __STRUCTURE_TYPE_REPEAT .or type = __STRUCTURE_TYPE_FOR)
		::__STRUCTURE_STACK_LOOP_08 .set ::__STRUCTURE_STACK_LOOP_07
		::__STRUCTURE_STACK_LOOP_07 .set ::__STRUCTURE_STACK_LOOP_06
		::__STRUCTURE_STACK_LOOP_06 .set ::__STRUCTURE_STACK_LOOP_05
		::__STRUCTURE_STACK_LOOP_05 .set ::__STRUCTURE_STACK_LOOP_04
		::__STRUCTURE_STACK_LOOP_04 .set ::__STRUCTURE_STACK_LOOP_03
		::__STRUCTURE_STACK_LOOP_03 .set ::__STRUCTURE_STACK_LOOP_02
		::__STRUCTURE_STACK_LOOP_02 .set ::__STRUCTURE_STACK_LOOP_01
		::__STRUCTURE_STACK_LOOP_01 .set ::__STRUCTURE_STACK_COUNT 
	.endif

	::__STRUCTURE_STACK_TYPE_08 .set ::__STRUCTURE_STACK_TYPE_07
	::__STRUCTURE_STACK_TYPE_07 .set ::__STRUCTURE_STACK_TYPE_06
	::__STRUCTURE_STACK_TYPE_06 .set ::__STRUCTURE_STACK_TYPE_05
	::__STRUCTURE_STACK_TYPE_05 .set ::__STRUCTURE_STACK_TYPE_04
	::__STRUCTURE_STACK_TYPE_04 .set ::__STRUCTURE_STACK_TYPE_03
	::__STRUCTURE_STACK_TYPE_03 .set ::__STRUCTURE_STACK_TYPE_02
	::__STRUCTURE_STACK_TYPE_02 .set ::__STRUCTURE_STACK_TYPE_01
	::__STRUCTURE_STACK_TYPE_01 .set type


	::__STRUCTURE_STACK_ID_08 .set ::__STRUCTURE_STACK_ID_07
	::__STRUCTURE_STACK_ID_07 .set ::__STRUCTURE_STACK_ID_06
	::__STRUCTURE_STACK_ID_06 .set ::__STRUCTURE_STACK_ID_05
	::__STRUCTURE_STACK_ID_05 .set ::__STRUCTURE_STACK_ID_04
	::__STRUCTURE_STACK_ID_04 .set ::__STRUCTURE_STACK_ID_03
	::__STRUCTURE_STACK_ID_03 .set ::__STRUCTURE_STACK_ID_02
	::__STRUCTURE_STACK_ID_02 .set ::__STRUCTURE_STACK_ID_01
	::__STRUCTURE_STACK_ID_01 .set ::__STRUCTURE_STACK_COUNT
.endmacro

; emits the current name as a label and removes it from the stack
; also checks to ensure this is the proper type
.macro __STRUCTURE_STACK_POP_CHECK type
	; Ensure current label is of type
	.if ::__STRUCTURE_STACK_TYPE_01 <> type
		.if type = __STRUCTURE_TYPE_IF
			.fatal "Missing IF"
		.elseif type = __STRUCTURE_TYPE_REPEAT
			.fatal "Missing REPEAT"
		.elseif type = __STRUCTURE_TYPE_FOR
			.fatal "Missing FOR_X or FOR_Y"
		.else
			.fatal "Missing statement of unkown type"
		.endif
	.endif

	; Pop from loop stack only if it is a looping structure
	.if (type = __STRUCTURE_TYPE_REPEAT .or type = __STRUCTURE_TYPE_FOR)
		::__STRUCTURE_STACK_LOOP_01 .set ::__STRUCTURE_STACK_LOOP_02
		::__STRUCTURE_STACK_LOOP_02 .set ::__STRUCTURE_STACK_LOOP_03
		::__STRUCTURE_STACK_LOOP_03 .set ::__STRUCTURE_STACK_LOOP_04
		::__STRUCTURE_STACK_LOOP_04 .set ::__STRUCTURE_STACK_LOOP_05
		::__STRUCTURE_STACK_LOOP_05 .set ::__STRUCTURE_STACK_LOOP_06
		::__STRUCTURE_STACK_LOOP_06 .set ::__STRUCTURE_STACK_LOOP_07
		::__STRUCTURE_STACK_LOOP_07 .set ::__STRUCTURE_STACK_LOOP_08
		::__STRUCTURE_STACK_LOOP_08 .set 0
	.endif

	; ELSE statements need this after pop&push.
	; Save it so it can be used after the branch
	::__STRUCTURE_STACK_PREV  .set ::__STRUCTURE_STACK_ID_01

	::__STRUCTURE_STACK_TYPE_01 .set ::__STRUCTURE_STACK_TYPE_02
	::__STRUCTURE_STACK_TYPE_02 .set ::__STRUCTURE_STACK_TYPE_03
	::__STRUCTURE_STACK_TYPE_03 .set ::__STRUCTURE_STACK_TYPE_04
	::__STRUCTURE_STACK_TYPE_04 .set ::__STRUCTURE_STACK_TYPE_05
	::__STRUCTURE_STACK_TYPE_05 .set ::__STRUCTURE_STACK_TYPE_06
	::__STRUCTURE_STACK_TYPE_06 .set ::__STRUCTURE_STACK_TYPE_07
	::__STRUCTURE_STACK_TYPE_07 .set ::__STRUCTURE_STACK_TYPE_08
	::__STRUCTURE_STACK_TYPE_08 .set 0

	::__STRUCTURE_STACK_ID_01 .set ::__STRUCTURE_STACK_ID_02
	::__STRUCTURE_STACK_ID_02 .set ::__STRUCTURE_STACK_ID_03
	::__STRUCTURE_STACK_ID_03 .set ::__STRUCTURE_STACK_ID_04
	::__STRUCTURE_STACK_ID_04 .set ::__STRUCTURE_STACK_ID_05
	::__STRUCTURE_STACK_ID_05 .set ::__STRUCTURE_STACK_ID_06
	::__STRUCTURE_STACK_ID_06 .set ::__STRUCTURE_STACK_ID_07
	::__STRUCTURE_STACK_ID_07 .set ::__STRUCTURE_STACK_ID_08
	::__STRUCTURE_STACK_ID_08 .set 0
.endmacro


; ::TODO IFL (if long) ::

;; Tests z flag
.macro IF_ZERO
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BNE __STRUCTURE_STACK_LABEL
.endmacro

;; Tests z flag
.macro IF_NOT_ZERO
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BEQ __STRUCTURE_STACK_LABEL
.endmacro

;; Tests n Flag
.macro IF_PLUS
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BMI __STRUCTURE_STACK_LABEL
.endmacro

;; Tests n Flag
.macro IF_MINUS
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BPL __STRUCTURE_STACK_LABEL
.endmacro

;; Tests c Flag
.macro IF_C_CLEAR
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BCS __STRUCTURE_STACK_LABEL
.endmacro

;; Tests c Flag
.macro IF_C_SET
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BCC __STRUCTURE_STACK_LABEL
.endmacro


;; Tests z Flag
.macro IF_Z_CLEAR
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BEQ __STRUCTURE_STACK_LABEL
.endmacro

;; Tests z Flag
.macro IF_Z_SET
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BNE __STRUCTURE_STACK_LABEL
.endmacro

;; Tests v Flag
.macro IF_V_CLEAR
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BVS __STRUCTURE_STACK_LABEL
.endmacro

;; Tests v Flag
.macro IF_V_SET
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BVC __STRUCTURE_STACK_LABEL
.endmacro

;; Tests n Flag
.macro IF_N_CLEAR
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BMI __STRUCTURE_STACK_LABEL
.endmacro

;; Tests n Flag
.macro IF_N_SET
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BPL __STRUCTURE_STACK_LABEL
.endmacro


;; Equals after CMP
.macro IF_EQ
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF
	BNE __STRUCTURE_STACK_LABEL
.endmacro

;; Not equals after CMP
.macro IF_NE
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF
	BEQ __STRUCTURE_STACK_LABEL
.endmacro

;; Unsigned Greater than or equal after CMP
.macro IF_GE
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BLT __STRUCTURE_STACK_LABEL
.endmacro

;; Unsigned Greater than after CMP
.macro IF_GT
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BLE __STRUCTURE_STACK_LABEL
.endmacro

;; Unsigned Less than after CMP
.macro IF_LT
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BGE __STRUCTURE_STACK_LABEL
.endmacro

;; Unsigned Less than or equal after CMP
.macro IF_LE
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BGT __STRUCTURE_STACK_LABEL
.endmacro


;; Signed Greater than or equal after CMP
.macro IF_SGE
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BSLT __STRUCTURE_STACK_LABEL
.endmacro

;; Signed Greater than after CMP
.macro IF_SGT
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BSLE __STRUCTURE_STACK_LABEL
.endmacro

;; Signed less than after CMP
.macro IF_SLT
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BSGE __STRUCTURE_STACK_LABEL
.endmacro

;; Signed Less than or equal after CMP
.macro IF_SLE
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF

	BSGT __STRUCTURE_STACK_LABEL
.endmacro

;; Else
.macro ELSE
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_IF

	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_IF
	BRA __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_PREV_LABEL:

.endmacro

; ::TODO else if::

;; End if
.macro ENDIF
__STRUCTURE_STACK_LABEL:

	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_IF
.endmacro





;; REPEAT structure, expects a FOREVER or a UNTIL_*
.macro REPEAT
	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_REPEAT

__STRUCTURE_STACK_LABEL:
.endmacro

;; Loops a REPEAT forever
.macro FOREVER
	JMP __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Tests z flag
.macro UNTIL_ZERO
	JNE __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Tests z flah
.macro UNTIL_NOT_ZERO
	JEQ __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Tests n Flag
.macro UNTIL_PLUS
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	JMI __STRUCTURE_STACK_LABEL
.endmacro

;; Tests n Flag
.macro UNTIL_MINUS
	JPL __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Tests c Flag
.macro UNTIL_C_CLEAR
	JCS __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Tests c Flag
.macro UNTIL_C_SET
	JCC __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro


;; Tests z Flag
.macro UNTIL_Z_CLEAR
	JEQ __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Tests z Flag
.macro UNTIL_Z_SET
	JNE __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Tests v Flag
.macro UNTIL_V_CLEAR
	JVS __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Tests v Flag
.macro UNTIL_V_SET
	JVC __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Tests n Flag
.macro UNTIL_N_CLEAR
	JMI __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Tests n Flag
.macro UNTIL_N_SET
	JPL __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro


;; Equals after CMP
.macro UNTIL_EQ
	JNE __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Not equals after CMP
.macro UNTIL_NE
	JEQ __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Unsigned Greater than or equal after CMP
.macro UNTIL_GE
	JLT __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Unsigned Greater than after CMP
.macro UNTIL_GT
	JLE __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Unsigned Less than after CMP
.macro UNTIL_LT
	JGE __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Unsigned Less than or equal after CMP
.macro UNTIL_LE
	JGT __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro


;; Signed Greater than or equal after CMP
.macro UNTIL_SGE
	JSLT __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Signed Greater than after CMP
.macro UNTIL_SGT
	JSLE __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Signed Less than after CMP
.macro UNTIL_SLT
	JSGE __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro

;; Signed Less than or equal after CMP
.macro UNTIL_SLE
	JSGT __STRUCTURE_STACK_LABEL

__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_REPEAT
.endmacro



; ::TODO REPEAT ... WHILE_COND ... WEND ::



;; For Loops
;;
;; Usage:
;;
;;	FOR_X #0, INC, #6
;;		<code>
;;	NEXT
;;
;;	FOR_Y count, DEC, #0
;;		<code>
;;	NEXT

::__FOR_TYPE      .set 0
::__FOR_EXIT      .set 0

.define __FOR_TYPE_INX 10
.define __FOR_TYPE_DEX 11
.define __FOR_TYPE_INY 20
.define __FOR_TYPE_DEY 21


.macro FOR_X start, direction, exit
	.if ::__FOR_TYPE <> 0
		.fatal "Only 1 FOR loop at a time"
	.endif

	.if .xmatch(.left(1, {exit}), #)
		::__FOR_EXIT .set .mid(1, .tcount({exit}) - 1, {exit})
	.else
		.fatal .sprintf("FOR_X: exit must be constant")
	.endif

	.if .xmatch(direction, INC)
		::__FOR_TYPE .set __FOR_TYPE_INX
	.elseif .xmatch(direction, DEC)
		::__FOR_TYPE .set __FOR_TYPE_DEX
	.else
		.fatal "Unkown direction (expect DEC or INC)"
	.endif

	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_FOR

	LDX start

__STRUCTURE_STACK_LABEL:
.endmacro

.macro FOR_Y start, direction, exit
	.if ::__FOR_TYPE <> 0
		.fatal "Only 1 FOR loop at a time"
	.endif

	.if .xmatch(.left(1, {exit}), #)
		::__FOR_EXIT .set .mid(1, .tcount({exit}) - 1, {exit})
	.else
		.fatal .sprintf("FOR_Y: exit must be constant")
	.endif

	.if .xmatch(direction, INC)
		::__FOR_TYPE .set __FOR_TYPE_INY
	.elseif .xmatch(direction, DEC)
		::__FOR_TYPE .set __FOR_TYPE_DEY
	.else
		.fatal "Unkown direction (expect DEC or INC)"
	.endif

	__STRUCTURE_STACK_PUSH_NEW __STRUCTURE_TYPE_FOR

	LDY start

__STRUCTURE_STACK_LABEL:
.endmacro

.macro NEXT
__STRUCTURE_STACK_LOOP_CONTINUE_LABEL:

	.if ::__FOR_TYPE = __FOR_TYPE_DEX
		DEX
		.if ::__FOR_EXIT <> 0
			CPX	#::__FOR_EXIT
		.endif 
	.elseif ::__FOR_TYPE = __FOR_TYPE_INX
		INX
		.if ::__FOR_EXIT <> 0
			CPX	#::__FOR_EXIT
		.endif 
	.elseif ::__FOR_TYPE = __FOR_TYPE_DEY
		DEY
		.if ::__FOR_EXIT <> 0
			CPY	#::__FOR_EXIT
		.endif 
	.elseif ::__FOR_TYPE = __FOR_TYPE_INY
		INY
		.if ::__FOR_EXIT <> 0
			CPY	#::__FOR_EXIT
		.endif 
	.else
		.fatal "Unknown FOR type"
	.endif

	JNE __STRUCTURE_STACK_LABEL


__STRUCTURE_STACK_LOOP_BREAK_LABEL:
	__STRUCTURE_STACK_POP_CHECK __STRUCTURE_TYPE_FOR

	; Free the FOR variables
	::__FOR_TYPE .set 0
	::__FOR_EXIT .set 0

.endmacro


;; Break a loop
.macro BREAK
	JMP __STRUCTURE_STACK_LOOP_BREAK_LABEL
.endmacro

;; Continue a loop
.macro CONTINUE
	.if ::__STRUCTURE_STACK_TYPE_01 <> __STRUCTURE_TYPE_FOR
		.fatal "Continues only allowed in FOR loop"
	.endif

	JMP __STRUCTURE_STACK_LOOP_CONTINUE_LABEL
.endmacro

.endif ; ::_STRUCTURE_INC_

