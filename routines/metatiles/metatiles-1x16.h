;;
;; 1 layer of 16x16 MetaTiles
;; ==========================
;;


.ifndef ::_METATILES_1x16_H_
::_METATILES_1x16_H_ = 1

.include "includes/import_export.inc"
.include "includes/structure.inc"
.include "includes/synthetic.inc"
.include "includes/registers.inc"


;; Maximum number of tiles in map.
; Enough to fit one Illusion of Gaia map.
; Uses 12.5 KiB of space.
METATILES_MAP_TILE_ALLOCATION = 80 * 80

;; Number of metatiles per map
N_METATILES	= 512

.struct MetaTile16Struct
	topLeft		.word
	topRight	.word
	bottomLeft	.word
	bottomRight	.word
.endstruct

METATILE16_DONT_UPDATE_BUFFER		= $00
METATILE16_UPDATE_HORIZONAL_BUFFER	= $01
METATILE16_UPDATE_POSITION		= $02
METATILE16_UPDATE_VERTICAL_BUFFER	= $80
METATILE16_UPDATE_WHOLE_BUFFER		= $FF


IMPORT_MODULE MetaTiles1x16
	UINT16	xPos
	UINT16	yPos

	;; Buffer of BGxHOFS
	UINT16	displayXoffset
	;; Buffer of BGxVOFS
	UINT16	displayYoffset

	UINT16	mapWidth
	UINT16	mapHeight

	STRUCT	metaTiles, MetaTile16Struct, N_METATILES
	WORD	map, METATILES_MAP_TILE_ALLOCATION

	WORD	bgBuffer, 32 * 32
	WORD	bgVerticalBufferLeft, 32
	WORD	bgVerticalBufferRight, 32
	ADDR	bgVerticalBufferVramLocation
	ADDR	bgHorizontalBufferVramLocation

	BYTE	updateBgBuffer


	;; REQUIRES: 8 bit A, 16 bit Index
	;; INPUT:
	;;	xPos - screen position
	;;	yPos - screen position
	;;	mapWidth - the width of the map in pixels
	;;	mapHeight - the height of the map in pixels
	;;	metaTiles - the metaTile data to use (loaded into memory)
	;;	map	- the map data to use (loaded into memory)
	ROUTINE	MapInit


	;; REQUIRES: 8 bit A, 16 bit Index
	;; INPUT:
	;;	xPos - screen position
	;;	yPos - screen position
	ROUTINE	Update

	.macro MetaTiles1x16_VBlank
		.export _MetaTiles1x16_VBlank__Called = 1
		.import METATILES_BG1_MAP

		LDA	MetaTiles1x16__updateBgBuffer
		IFL_NOT_ZERO
			IF_MINUS
				; Update Vertical Buffer
				LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_32
				STA	VMAIN

				LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_2REGS
				STA	DMAP0

				LDA	#.lobyte(VMDATA)
				STA	BBAD0

				LDX	#.loword(MetaTiles1x16__bgVerticalBufferLeft)
				STX	A1T0
				LDA	#.bankbyte(MetaTiles1x16__bgVerticalBufferLeft)
				STA	A1B0

				LDX	MetaTiles1x16__bgVerticalBufferVramLocation
				LDY	#MetaTiles1x16__bgVerticalBufferLeft__size
				LDA	#MDMAEN_DMA0

				STX	VMADD
				STY	DAS0
				STA	MDMAEN

				.assert MetaTiles1x16__bgVerticalBufferLeft + 32 * 2 = MetaTiles1x16__bgVerticalBufferRight, error, "MetaTiles1x16__bgVerticalBufferRight must be after MetaTiles1x16__bgVerticalBufferLeft"

				INX
				STX	VMADD
				STY	DAS0
				STA	MDMAEN

				LDA	MetaTiles1x16__updateBgBuffer
			ENDIF

			CMP	#$FF
			IF_EQ
				; Update Whole Buffer
				LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
				STA	VMAIN

				LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_2REGS
				STA	DMAP0

				LDA	#.lobyte(VMDATA)
				STA	BBAD0

				LDX	#.loword(MetaTiles1x16__bgBuffer)
				STX	A1T0
				LDA	#.bankbyte(MetaTiles1x16__bgBuffer)
				STA	A1B0

				LDX	#METATILES_BG1_MAP
				STX	VMADD

				LDY	#30 * 32 * 2
				STY	DAS0

				LDA	#MDMAEN_DMA0
				STA	MDMAEN
			ELSE
				ASL
				IF_C_SET
					; Update Horizontal Buffer
					LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
					STA	VMAIN

					LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_2REGS
					STA	DMAP0

					LDA	#.lobyte(VMDATA)
					STA	BBAD0

					LDX	#.loword(MetaTiles1x16__bgBuffer)
					STX	A1T0
					LDA	#.bankbyte(MetaTiles1x16__bgBuffer)
					STA	A1B0

					LDX	MetaTiles1x16__bgHorizontalBufferVramLocation
					STX	VMADD

					LDY	#2 * 32 * 2
					STY	DAS0

					LDA	#MDMAEN_DMA0
					STA	MDMAEN
				ENDIF
			ENDIF

			LDA	MetaTiles1x16__displayXoffset
			STA	BG1HOFS
			LDA	MetaTiles1x16__displayXoffset + 1
			STA	BG1HOFS

			LDA	MetaTiles1x16__displayYoffset
			STA	BG1VOFS
			LDA	MetaTiles1x16__displayYoffset + 1
			STA	BG1VOFS

			STZ	MetaTiles1x16__updateBgBuffer
		ENDIF
	.endmacro

ENDMODULE

.endif ; ::_METATILES_1x16_H_

; vim: ft=asm:

