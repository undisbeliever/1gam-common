;;
;; 1 layer of 16x16 MetaTiles
;; ==========================
;;


.ifndef ::_METATILES_1x16_H_
::_METATILES_1x16_H_ = 1

.include "includes/import_export.inc"
.include "includes/structure.inc"
.include "includes/synthetic.inc"

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

METATILE16_DONT_UPDATE_BUFFER		= 0
METATILE16_UPDATE_WHOLE_BUFFER		= $FF
METATILE16_UPDATE_HORIZONAL_BUFFER	= $01
METATILE16_UPDATE_VERTICAL_BUFFER	= $02


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
	WORD	bgColumnBuffer1, 32
	WORD	bgColumnBuffer2, 32

	BYTE	updateBgBuffer


	ROUTINE	MapInit
ENDMODULE

.endif ; ::_METATILES_1x16_H_

; vim: ft=asm:

