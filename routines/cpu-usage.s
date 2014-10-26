
.include "cpu-usage.h"
.include "includes/structure.inc"
.include "includes/registers.inc"


;; ::TODO helper function to clean these variables up::


.proc CPU_Usage


.segment "SHADOW"
	VBlankCounter:	.res 1
	MissedFrames:	.res 1
	ReferenceBogo:	.res 2
	CurrentBogo:	.res 2

; Variables accessable outside this file
::CPU_Usage__MissedFrames = MissedFrames
::CPU_Usage__VBlankCounter = VBlankCounter
::CPU_Usage__ReferenceBogo = ReferenceBogo
::CPU_Usage__CurrentBogo = CurrentBogo

.code

; ROUTINE Calculate `CPU_Usage__ReferenceBogo` 
.A8
.I16
Calc_Reference:
::CPU_Usage__Calc_Reference:
	; Enable VBlank
	LDA	#NMITIMEN_VBLANK_FLAG
	STA	NMITIMEN

	; Wait until the start of the frame
	STZ	VBlankCounter
	REPEAT
		WAI
		LDA VBlankCounter
	UNTIL_NOT_ZERO

	STZ	MissedFrames

	JSR	Wait_Frame

	LDY	CurrentBogo
	STY	ReferenceBogo

	; Disable VBlank
	STZ	NMITIMEN	

	RTS


; ROUTINE Wait until the next frame, calculating the number of bogos to the
; start of the next frame.
Wait_Frame:
::CPU_Usage__Wait_Frame:
	; Save state
	PHP
	REP	#$30
	PHA
	PHX

	SEP	#$20
.A8
.I16

	LDA	VBlankCounter
	STA	MissedFrames

	LDX	#0
	REPEAT
		INX
		LDA	VBlankCounter
		CMP	MissedFrames
	UNTIL_NE

	STX	CurrentBogo

	; Reset the counter
	STZ	VBlankCounter

	; Load State
	REP	#$30
	PLX
	PLA
	PLP

	RTS


; ROUTUNE  Wait until a given number of frames has passed since the last
; `CPU_Usage__Wait_Frame` or `CPU_Usage__Wait_Limited` call.
Wait_Limited:
::CPU_Usage__Wait_Limited:
	; A contains the number of frames since the last
	; `CPU_Usage_Wait_Clipped` or `CPU_Usage__Wait_Frame` call.

	DEC
	JSR	Wait_Frame
	CMP	MissedFrames
	IF_GT
		PHY
		PHA			; Save MissedFrames
		LDY	CurrentBogo

		SUB	MissedFrames
		REPEAT
			JSR	Wait_Frame

			; Increment CurrentBogo to handle next frames
			PHA
			REP	#$20
				TYA
				ADD	CurrentBogo
				TYA
			SEP	#$20
			PLA

			DEC
		UNTIL_ZERO

		PLA
		STA	MissedFrames

		STY	CurrentBogo
		PLY
	ENDIF

	RTS

.endproc

