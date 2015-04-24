
.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/synthetic.inc"
.include "includes/structure.inc"
.include "includes/registers.inc"

MODULE Block

.code

.A8
.I16
ROUTINE MemClear
	STX	WMADD
	STA	WMADD + 2

	LDX	#DMAP_DIRECTION_TO_PPU | DMAP_ADDRESS_FIXED | DMAP_TRANSFER_1REG | (.lobyte(WMDATA) << 8)
	STX	DMAP0			; also sets BBAD0

	LDX	#$FFB6 ; 0 byte in SNES header
	STX	A1T0
	STZ	A1B0

	STY	DAS0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN

	RTS



.A8
.I16
ROUTINE CopyToWmdata
	STX	A1T0
	STA	A1B0

	LDX	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_1REG | (.lobyte(WMDATA) << 8)
	STX	DMAP0			; also sets BBAD0

	STY	DAS0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN

	RTS



.A8
.I16
ROUTINE ClearVramLocation
	STX	VMADD
	STY	DAS0

	LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
	STA	VMAIN

	LDX	#DMAP_DIRECTION_TO_PPU | DMAP_ADDRESS_FIXED | DMAP_TRANSFER_2REGS | (.lobyte(VMDATA) << 8)
	STX	DMAP0			; also sets BBAD0

	LDX	#$FFB6 ; 0 byte in SNES header
	STX	A1T0
	STZ	A1B0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN

	RTS


.A8
.I16
ROUTINE TransferToVram
	STX	A1T0
	STA	A1B0

	STY	DAS0

	LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
	STA	VMAIN

	LDX	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_2REGS | (.lobyte(VMDATA) << 8)
	STX	DMAP0			; also sets BBAD0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN

	RTS


.A8
.I16
ROUTINE TransferToVramDataLow
	STX	A1T0
	STA	A1B0

	STY	DAS0

	LDA	#VMAIN_INCREMENT_LOW | VMAIN_INCREMENT_1
	STA	VMAIN

	LDX	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_1REG | (.lobyte(VMDATAL) << 8)
	STX	DMAP0			; also sets BBAD0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN

	RTS


.A8
.I16
ROUTINE TransferToVramDataHigh
	STX	A1T0
	STA	A1B0

	STY	DAS0

	LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
	STA	VMAIN

	LDX	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_1REG | (.lobyte(VMDATAH) << 8)
	STX	DMAP0			; also sets BBAD0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN

	RTS


.A8
.I16
ROUTINE TransferToCgram
	STX	A1T0
	STA	A1B0

	STY	DAS0

	LDX	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_WRITE_TWICE | (.lobyte(CGDATA) << 8)
	STX	DMAP0			; also sets BBAD0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN

	RTS



.A8
.I16
ROUTINE TransferToOam
	STX	A1T0
	STA	A1B0

	STY	DAS0

	LDX	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_WRITE_TWICE | (.lobyte(OAMDATA) << 8)
	STX	DMAP0			; also sets BBAD0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN

	RTS



.A8
.I16
ROUTINE Checksum
	PHB
	PHP

	; Set Bank
	PLA
	PHA

	REP	#$30
.A16

	LDA	#$FFFF

	REPEAT
		SEP	#$20
.A8
		EOR	0, X

		REP	#$30
.A16
		ASL
		IF_C_SET
			EOR	#$1EE7
		ENDIF

		INX
		DEY
	UNTIL_ZERO

	TAY

	PLP
	PLB
	RTS



ENDMODULE

