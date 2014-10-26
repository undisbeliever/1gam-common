;;
;; CPU Usage calculator.
;;
;; This module allows for an estimation of the CPU usage.
;;
;; It uses a bogo counter that is incremented on idle (waiting
;; for next frame) and comparing it to a reference we can
;; calculate the CPU usage.
;;
;; The formula to calculate the CPU usage is:
;;
;;       1 - (CurrentBogo) / (ReferenceBogo * (MissedFrames + 1))
;;
;; It also alerts you to missed frames. If 
;;
;; In order to use this module, the following must occour.
;;
;;  * `CPU_Usage__NMI` must active on every VBlank Inturrupt.
;;
;;  * `CPU_Usage__Calc_Idle` must be called once.
;;
;;  * `CPU_Usage__Wait_Frame` must be called instead of `WAI`
;;

; ::TODO clip frames function (ie, 2 cycles)::
; ::SHOULDDO Calculate Usage percentage ::

.ifndef ::_CPU_USAGE_H_
::__CPU_USAGE_H_ = 1

.setcpu "65816"

;; Number of frames that were missed inbetween `Wait_Frame`s
;; (byte)
.global CPU_Usage__MissedFrames

;; Number of VBlanks passed 
;; (byte)
.global CPU_Usage__VBlankCounter

;; Reference Bogo taken from an empty frame, used
;; for calculations
;; (word)
.global CPU_Usage__ReferenceBogo

;; Current Bogo for previous frame
;; (word)
.global CPU_Usage__CurrentBogo


;; Calculate `CPU_Usage__ReferenceBogo`
;;
;; REQUIRES: 8 bit A, 16 bit Index, DB Access Shadow RAM
;;
;; This routine will disable Inturrputs and must be called:
;;   * staright after Initialisation.
;;   * After FASTROM is set (if using FASTROM)
;;   * When VBlank is not doing anything
.global CPU_Usage__Calc_Reference


;; Wait until the next frame, calculating the number of bogos to the
;; start of the next frame.
;;
;; REQUIRES: DB Access Shadow RAM
;;
;; This routine calculates:
;;    * `CPU_Usage__FramesMised`
;;    * `CPU_Usage__CurrentBogo`
;;
;; This routine saves the CPU state.
.global CPU_Usage__Wait_Frame


;; Wait until a given number of frames has passed since the last
;; `CPU_Usage__Wait_Frame` or `CPU_Usage__Wait_Limited` call.
;;
;; REQUIRES: DB Access Shadow RAM
;;
;; INPUT: A = number of frames to wait
;;
;; MODIFIES: Decrements A by one
;;
;; This routine calculates:
;;    * `CPU_Usage__FramesMised`
;;    * `CPU_Usage__CurrentBogo`
;;
;; This routine saves the CPU state.
; ::SHOULDDO think of better name::
.global CPU_Usage__Wait_Limited


;; Sets Frame Increment Counter
;;
;; REQUIRE 8 bit A
.macro CPU_Usage__NMI
	INC CPU_Usage__VBlankCounter
.endmacro

.endif ; __CPU_USAGE_H_

