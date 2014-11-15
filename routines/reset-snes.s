
.include "reset-snes.h"
.include "includes/synthetic.inc"
.include "includes/structure.inc"
.include "includes/registers.inc"

.setcpu "65816"

.import Main
.import __STACK_TOP

;; Memory location contains a zero word.
;; From SNES Header (which has 7 consecutive zero bytes)
ZeroWord = $00FFB6

.code

; ROUTINE Reset Handler
Reset:
	SEI
	CLC
	XCE				; Switch to native mode

	REP 	#$38			; 16 bit A, 16 bit Index, Decimal mode off

.I16
	LDX	#__STACK_TOP
	TXS				; Setup stack (top of Shadow RAM)

	LDA 	#$0000
	TCD				; Setup Direct Page = $0000

	SEP	#$20
.A8

	; Clear the WRAM
	; Setup DMA Channel 0 for WRAM
	LDX	#0
	STX	WMADD
	STZ	WMADDH

	LDA	#DMAP_DIRECTION_TO_PPU | DMAP_ADDRESS_FIXED | DMAP_TRANSFER_1REG
	STA	DMAP0

	LDA	#.lobyte(WMDATA)
	STA	BBAD0

	LDX	#ZeroWord
	STX	A1T0
	LDA	#.bankbyte(ZeroWord)
	STA	A1B0

	LDX	#0
	STX	DAS0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN

	; DSA0 is 0, no need to set it again
	LDA	#MDMAEN_DMA0
	STA	MDMAEN


	JSR	ClearVRAM
	JSR	ClearOAM
	JSR	ClearCGRAM
	JSR	Reset_Registers
	JML	Main


; ROUTINE Resets most of the Registers in the SNES to their reccomended defaults.
Reset_Registers:
	PHP
	SEP	#$30
.A8
.I8

	PHK
	PLB				; Data Bank = Program Bank

	; Disable All interrupts
	; Prevent interruptions
	STZ	NMITIMEN

	LDA	#INIDISP_FORCE
	STA	INIDISP			; Force Screen Blank

	STZ	OBSEL

	; Registers $2105 - $210C
	; BG settings and VRAM base addresses
	FOR_X #$05, INC, #$0C + 1
		STZ	$2100, X
	NEXT

	; Registers $210D - $2114
	; BG Scroll Locations - Write twice
	FOR_X #$0D, INC, #$14 + 1
		STZ	$2100, X
		STZ	$2100, X
	NEXT

	; Skipping Mode 7 as any programmer using that mode
	; will set them anyway.

	; Increment VRAM by 1 word on reading/writing the high byte of VRAM
	LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
	STA	VMAIN

	; Registers $2123 - $2133
	; Window Settings, BG/OBJ designation, Color Math, Screen Mode
	; All disabled
	FOR_X #$23, INC, #$33 + 1
		STZ	$2100, X
	NEXT

	; Disable HDMA
	STZ	HDMAEN

	; ROM access time to slow
	STZ	MEMSEL

	PLP
	RTS


; ROUTINE Transfers 0x10000 0 bytes to VRAM
.A8
.I16
ClearVRAM:
	LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
	STA	VMAIN

	LDX	#0
	STX	VMADD

	LDA	#DMAP_DIRECTION_TO_PPU | DMAP_ADDRESS_FIXED | DMAP_TRANSFER_2REGS
	STA	DMAP0

	LDA	#.lobyte(VMDATA)
	STA	BBAD0

	LDX	#0
	STX	DAS0

	LDX	#ZeroWord
	STX	A1T0
	LDA	#.bankbyte(ZeroWord)
	STA	A1B0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN

	RTS



; ROUTINE Clears the Sprites off the screen.
ClearOAM:
	PHP
	SEP	#$30
.A8
.I8

	STZ	OAMADDL
	STZ	OAMADDH

	LDA	#240
	LDX	#$80

	FOR_Y	#128, DEC, #0
		STX	OAMDATA		; X
		STA	OAMDATA		; Y
		STZ	OAMDATA
		STZ	OAMDATA		; Character + Flags
	NEXT

	LDA	#%01010101
	FOR_X	#128/4, DEC, #0
		STA	OAMDATA		; Data table
	NEXT

	PLP
	RTS



; ROUTINE Clears the CGRAM
.A8
.I16
ClearCGRAM:
	STZ	CGADD

	FOR_X	#512, DEC, #0
		STZ CGDATA
	NEXT

	RTS


