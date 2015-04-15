;;
;; 1 layer of 16x16 MetaTiles
;; ==========================
;;
;; This module manages a sigle layer of 16x16 pixel Metatile map
;; with scroll support.
;;
;; In order to simplify the system, both the map and the metatile
;; set are stored in RAM. This allows the data to be compressed
;; and loaded by the loading module to save ROM space.
;;
;; The map data is stored as the offsets within the metatile table
;; (that is `tile * 8`). This is done for speed purposes.
;;
;; The module is configured by setting the `METATILES_BG1_MAP`
;; global that indicates the *word* address of the SNES tilemap
;; within VRAM.
;;
;; This module also uses DMA channels 0 and 1 during the VBlank routine.

.ifndef ::_METATILES_1x16_H_
::_METATILES_1x16_H_ = 1

.include "includes/import_export.inc"
.include "includes/structure.inc"
.include "includes/synthetic.inc"
.include "includes/registers.inc"


;; Maximum number of tiles in map.
; Enough to fit a single Illusion of Gaia map.
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
	;; x Position of the screen
	UINT16	xPos
	;; y Position of the screen
	UINT16	yPos

	;; Width of the map in pixels
	;; Must be a multiple of 256.
	UINT16	mapWidth

	;; Height of the map in pixels 
	UINT16	mapHeight

	;; Number of bytes in a single map row.
	WORD	sizeOfMapRow
	;; sizeOfMapRow / 16, used as a speedup to convert xPos/yPos to tile.
	;; See `MetaTiles1x16_LocationToTile` macro.
	WORD	sizeOfMapRowDiviedBy16

	;; Metatile table, mapping of metatiles to their inner tiles.
	STRUCT	metaTiles, MetaTile16Struct, N_METATILES

	;; The map data.
	;; Stored as a multidimensional array[y][x], with a width of
	;; `mapWidth / 16` and a height of `mapHeight / 16`.
	;;
	;; Each cell contains the word address within the metaTile table
	;; (`tile * 8`), for speed purposes.
	ADDR	map, METATILES_MAP_TILE_ALLOCATION


	;; Initialize the metatile system. 
	;; REQUIRES: 8 bit A, 16 bit Index
	;;
	;; There is no bounds checking. xPos and yPos MUST be < (mapWidth - 256)
	;; and (mapHeight - 224) respectivly. mapWidth MUST be a multiple of 256.
	;;
	;; INPUT:
	;;	xPos - screen position
	;;	yPos - screen position
	;;	mapWidth - the width of the map in pixels
	;;	mapHeight - the height of the map in pixels (MUST be a multiple of 256)
	;;	metaTiles - the metaTile data to use (loaded into memory)
	;;	map	- the map data to use (loaded into memory)
	ROUTINE	MapInit

	;; Updates the position of the screen, loading new tiles as necessary.
	;;
	;; There are 3 types of tile updates.
	;;	* Horizonatal
	;;	* Vertical
	;;	* Whole Screen
	;;
	;; And will fill the various buffers as necessary.
	;;
	;; So long as the screen only moves < 16 pixels per update only
	;; horizontal and vertical updates will be preformed.
	;;
	;; There is no bounds checking, xPos and yPos MUST be < (mapWidth - 256)
	;; and (mapHeight - 224) respectivly.
	;;
	;; REQUIRES: 8 bit A, 16 bit Index
	;; INPUT:
	;;	xPos - screen position
	;;	yPos - screen position
	ROUTINE	Update

	;; Loads the buffers into VRAM
	;;
	;; REQUIRES: 8 bit A, 16 bit Index, DB=0, DMA channels 0 and 1 free.
	.macro MetaTiles1x16_VBlank
		.export _MetaTiles1x16_VBlank__Called = 1
		.import METATILES_BG1_MAP

		.global MetaTiles1x16__displayXoffset
		.global MetaTiles1x16__displayYoffset
		.global MetaTiles1x16__bgBuffer
		.global MetaTiles1x16__bgVerticalBufferLeft
		.global MetaTiles1x16__bgVerticalBufferRight
		.global MetaTiles1x16__bgVerticalBufferVramLocation
		.global MetaTiles1x16__bgHorizontalBuffer
		.global MetaTiles1x16__bgHorizontalBufferVramLocation1
		.global MetaTiles1x16__bgHorizontalBufferVramLocation2
		.global MetaTiles1x16__updateBgBuffer

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
				LDY	#32 * 2
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
				; As the vertical buffer is already updated, DMA registers are already set.

				LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
				STA	VMAIN

				LDX	#.loword(MetaTiles1x16__bgBuffer)
				STX	A1T0

				LDX	#METATILES_BG1_MAP
				STX	VMADD

				LDY	#30 * 32 * 2
				STY	DAS0

				LDA	#MDMAEN_DMA0
				STA	MDMAEN
			ELSE
				LSR
				IF_C_SET
					; Update Horizontal Buffer
					; Need to use 2 DMA channels to handle the split tilemap.
					; ::KUDOS Secret of Mana dynamic tile DMA code::

					LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
					STA	VMAIN

					LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_2REGS
					STA	DMAP0
					STA	DMAP1

					LDA	#.lobyte(VMDATA)
					STA	BBAD0
					STA	BBAD1

					LDX	#.loword(MetaTiles1x16__bgHorizontalBuffer)
					STX	A1T0
					LDX	#.loword(MetaTiles1x16__bgHorizontalBuffer + 64 * 2)
					STX	A1T1

					LDA	#.bankbyte(MetaTiles1x16__bgHorizontalBuffer)
					STA	A1B0
					STA	A1B1

					LDY	#2 * 32
					LDA	#MDMAEN_DMA0 | MDMAEN_DMA1

					LDX	MetaTiles1x16__bgHorizontalBufferVramLocation1
					STX	VMADD
					STY	DAS0
					STY	DAS1
					STA	MDMAEN

					LDX	MetaTiles1x16__bgHorizontalBufferVramLocation2
					STX	VMADD
					STY	DAS0
					STY	DAS1
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

	;; Converts xPos/yPos coordinates into a tile index.
	;;
	;; REQUIRES: 16 bit A, 16 bit Index , DB access registers
	;; PARAM:
	;;	xPos - the xPos variable address
	;;	yPos - the yPos variable address
	;;	index - (optional) the index of the xPos/yPos
	;; MODIFIES: A, X, Y (unless index == X or index == Y)
	;; OUTPUT: A - The index of the tile within `map`
	.macro MetaTiles1x16_LocationToTile xPos, yPos, index
		; tmp = (yPos & 0xFFF0) * sizeOfMapRowDiviedBy16	// equivalent of (yPos / 16) * sizeOfMapRow
		; visibleTopLeftMapIndex = tmp + xPos / 16 * 2

		.ifblank index
			LDA	yPos
			AND	#$FFF0
			TAY
			LDX	sizeOfMapRowDiviedBy16
			; ::SHOULDDO have multiply set DB::
			JSR	Math__Multiply_U16Y_U16X_U16Y
			LDA	xPos
			LSR
			LSR
			LSR
			AND	#$FFFE
			CLC
			ADC	Math__product16
		.else
			.if .xmatch(index, X)
				PHX
			.elseif .xmatch(index, Y)
				PHY
			.else
				.fatal .sprintf("unknown index: %s", index)
			.endif
			LDA	yPos, index
			AND	#$FFF0
			TAY
			LDX	sizeOfMapRowDiviedBy16
			; ::SHOULDDO have multiply set DB::
			JSR	Math__Multiply_U16Y_U16X_U16Y

			.if .xmatch(index, X)
				PLX
			.elseif .xmatch(index, Y)
				PLY
			.endif

			LDA	xPos, index
			LSR
			LSR
			LSR
			LSR
			AND	#$FFFE
			CLC
			ADC	Math__product16
		.endif
	.endmacro

ENDMODULE

.endif ; ::_METATILES_1x16_H_

; vim: ft=asm:

