.ifndef ::_RANDOM_H_
::_RANDOM_H_ = 1

.setcpu "65816"

.include "includes/import_export.inc"
.include "includes/synthetic.inc"
.include "includes/structure.inc"


;; This module is a Linear congruential psudeo random number generator.
;;
;; It uses the following algorithm
;;
;; 	Seed = (A * SEED +C) MOD M
;;
;; NOTES: A must be a multiplier of 4 plus one
;;        C should be psudeoprime (or at least odd)
;;
;;
;; To generate a random number between 1 and ?
;; RndNum = {Seed+2} MOD ? + 1
;;
;; In order to increase the observed randomness of this module,
;; the function `AddJoypadEntropy` should be called once every frame.
;; This will cycle the random number generator once or twice, depending
;; on the state of JOY1.

IMPORT_MODULE Random

	; These numbers were selected at random, following the rules
	; listed above, I'm not 100% sure about them.
	CONST	MTH_A,	59069
	CONST	MTH_C,	739967

	UINT32	Seed

	;; Runs the random seed through a single pass of the seed
	;; REQUIRE: 8 bit A, 16 bit Index
	ROUTINE Rnd

	;; Adds entropy to the random seed by calling `Rnd`
	;;	* twice if the state of JOY1 has changed since the last call.
	;;	* once if the joypad hasn't changed.
	;;
	;; This can add a bit of variety to the random number generator.
	;;
	;; REQUIRE: 8 bit A, 16 bit Index, AutoJoy Enbled
	ROUTINE AddJoypadEntropy

	;; Generates a random number between 0 and 3 (inclusive)
	;; REQUIRE: 8 bit A, 16 bit Index
	;; RETURN: A = random number between 0 and 3 (inclusive)
	ROUTINE	Rnd_4

	;; Generates a random number between 0 and 2 (inclusive)
	;;
	;; It is skewed towards 1.
	;;
	;; REQUIRE: 8 bit A, 16 bit Index
	;; RETURN: A = random number between 0 and 2 (inclusive)
	ROUTINE	Rnd_3

	;; Generates a random number between 0 and 1 (inclusive)
	;;
	;; REQUIRE: 8 bit A, 16 bit Index
	;; RETURN:
	;;	A: random number between 0 and 1 (inclusive)
	;;	z: set if A is 0
	ROUTINE	Rnd_2

	;; Generates a 16 bit random number between 0 and Y (non-inclusive)
	;;
	;; Skewed towards smaller numbers
	;;
	;; REQUIRE: 8 bit A, 16 bit Index
	;; INPUT:
	;;	Y: unsigned 16 bit value.
	;; OUTPUT:
	;;	Y: unsigned 16 bit value between 0 and (Y-1) (inlusive).
	ROUTINE	Rnd_U16Y

	;; Generates a 16 bit random number between X and Y
	;;
	;; Skewed towards smaller numbers
	;;
	;; REQUIRE: 8 bit A, 16 bit Index
	;; INPUT:
	;;	X: unsigned 16 bit min
	;;	Y: unsigned 16 bit max
	;; OUTPUT:
	;;	Y: unsigned 16 bit value.
	ROUTINE	Rnd_U16X_U16Y

ENDMODULE

.endif ; ::_RANDOM_H_

; vim: set ft=asm:

