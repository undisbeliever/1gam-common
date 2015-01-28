;;
;; Screen control macros
;; =====================
;;
;;

.ifndef ::_SCREEN_H_
::_SCREEN_H_ = 1

.include "includes/import_export.inc"

IMPORT_MODULE Screen

	;; Sets the VRAM size and position registers.
	;;
	;; The sizes are taken from the variables BGx_MAP (word adress in VRAM), BGx_SIZE (matches the values BGXSC_SIZE_*),
	;; BGx_TILES (word address in VRAM), OAM_TILES (word adress in VRAM), OAM_NAME (matches the values OBSEL_NAME_*)
	;; and OAM_SIZE (matches the values OBSEL_SIZE_*). Where BGx represents optional BG1 - BG4.
	;;
	;; Alternativly a *prefix* may be supplied, in which the variables used are
	;; <prefix>_BGx_MAP, <prefix>_BGx_SIZE, <prefix>_BGx_TILES, <prefix>_OAM_TILES, and <prefix>_OAM_SIZE.
	;; Where BGx represents the optional BG1 - BG4.
	;;
	;; If a BGx_MAP or BGx_TILES is missing then the register will not be set.
	;; 
	;; As the `BG12NBA` and `BG34NBA` registers handle 2 layers, if one layer's tile address variable is missing its word address is 0.
	;;
	;; REQUIRES: 8 bit A, 16 bit Index
	;; MODIFIES: A, Y
	.macro Screen_SetVramBaseAndSize prefix

		.ifblank prefix
			_Screen_SetVramBaseAndSize_map BG1_MAP, BG1_SIZE, BG2_MAP, BG2_SIZE, BG1SC
			_Screen_SetVramBaseAndSize_map BG3_MAP, BG3_SIZE, BG4_MAP, BG4_SIZE, BG3SC
			_Screen_SetVramBaseAndSize_oam OAM_SIZE, OAM_NAME, OAM_TILES
			_Screen_SetVramBaseAndSize_tiles BG1_TILES, BG2_TILES, BG3_TILES, BG4_TILES
		.else
			_Screen_SetVramBaseAndSize_map .ident(.sprintf("%s_BG1_MAP", .string(prefix))), .ident(.sprintf("%s_BG1_SIZE", .string(prefix))), .ident(.sprintf("%s_BG2_MAP", .string(prefix))), .ident(.sprintf("%s_BG2_SIZE", .string(prefix))), BG1SC
			_Screen_SetVramBaseAndSize_map .ident(.sprintf("%s_BG3_MAP", .string(prefix))), .ident(.sprintf("%s_BG3_SIZE", .string(prefix))), .ident(.sprintf("%s_BG4_MAP", .string(prefix))), .ident(.sprintf("%s_BG4_SIZE", .string(prefix))), BG3SC
			_Screen_SetVramBaseAndSize_oam .ident(.sprintf("%s_OAM_SIZE", .string(prefix))), .ident(.sprintf("%s_OAM_NAME", .string(prefix))), .ident(.sprintf("%s_OAM_TILES", .string(prefix)))
			_Screen_SetVramBaseAndSize_tiles .ident(.sprintf("%s_BG1_TILES", .string(prefix))), .ident(.sprintf("%s_BG2_TILES", .string(prefix))), .ident(.sprintf("%s_BG3_TILES", .string(prefix))), .ident(.sprintf("%s_BG4_TILES", .string(prefix)))
		.endif
	.endmacro

		.macro _Screen_SetVramBaseAndSize_map mapWordAddress1, size1, mapWordAddress2, size2, register
			.ifdef mapWordAddress1
				.ifdef mapWordAddress2
					LDY	#((mapWordAddress1 / BGXSC_BASE_WALIGN) << BGXSC_BASE_SHIFT | (size1 & BGXSC_MAP_SIZE_MASK)) | ((mapWordAddress2 / BGXSC_BASE_WALIGN) << BGXSC_BASE_SHIFT | (size2 & BGXSC_MAP_SIZE_MASK)) << 8
					STY	register
				.else
					LDA	#(mapWordAddress1 / BGXSC_BASE_WALIGN) << BGXSC_BASE_SHIFT | (size1 & BGXSC_MAP_SIZE_MASK)
					STA	register
				.endif
			.else
				.ifdef mapWordAddress2
					LDA	#(mapWordAddress2 / BGXSC_BASE_WALIGN) << BGXSC_BASE_SHIFT | (size2 & BGXSC_MAP_SIZE_MASK)
					STA	register + 1
				.endif
			.endif
		.endmacro

		.macro _Screen_SetVramBaseAndSize_oam size, name, oamTileWordAddress
			LDA	#(size << OBSEL_SIZE_SHIFT) | ((name << OBSEL_NAME_SHIFT) & OBSEL_NAME_MASK) | (oamTileWordAddress / OBSEL_BASE_WALIGN) & OBSEL_BASE_MASK
			STA	OBSEL
		.endmacro

		.macro _Screen_SetVramBaseAndSize_tiles bg1, bg2, bg3, bg4
			.ifndef bg1
				bg1 = 0
			.endif
			.ifndef bg2
				bg2 = 0
			.endif
			.ifndef bg3
				bg3 = 0
			.endif
			.ifndef bg4
				bg4 = 0
			.endif

			LDY	#(((bg2 / BG12NBA_BASE_WALIGN) << BG12NBA_BG2_SHIFT) & BG12NBA_BG2_MASK) | ((bg1 / BG12NBA_BASE_WALIGN) & BG12NBA_BG1_MASK) | ((((bg4 / BG12NBA_BASE_WALIGN) << BG34NBA_BG4_SHIFT) & BG34NBA_BG4_MASK) | ((bg3 / BG34NBA_BASE_WALIGN) & BG34NBA_BG3_MASK)) << 8
			STY	BG12NBA
		.endmacro
ENDMODULE


.endif ; ::_SCREEN_H_

; vim: set ft=asm:

