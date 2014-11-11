;
; Header for Reset SNES
;
.setcpu "65816"

;; TODO import_export.inc::

;; Reset Handler
;;
;;
;; Resets
;;    * WRAM
;;    * SNES Registers to a basic default (except mode 7 Matrix)
;;    * VRAM
;;    * OAM
;;    * CGRAM
.global Reset

;; Resets most of the Registers in the SNES to their reccomended defaults.
;;
;; Defaults:
;;     * Forced Screen Blank
;;     * Mode 0
;;     * OAM Size 8x8, 16x16, base address 0
;;     * BG Base address 0, size = 8x8
;;     * No Mosaic
;;     * No BG Scrolling
;;     * VRAM Increment on High Byte
;;     * No Windows
;;     * No Color Math
;;     * No Backgrounds
;;     * No HDMA
;;     * ROM access to slow
;;
;; This routine does not set the following as any programer need to set them anyway:
;;     * the Mode 7 Matrix
;;     * VRAM/CGRAM/OAM data address registers
;;
;; Also sets:
;;  * Program Bank = Data Bank
.global Reset_Registers


;; Transfers 0x10000 0 bytes to VRAM
;;
;; REQUIRES: 8 bit A, 16 bit Index
;;
;; Uses DMA Channel 0 to do so.
.global ClearVRAM


;; Clears the Sprites off the screen.
;;
;; Sets:
;;	* X position to -128 (can't use -256, as it would be counted in the scanlines)
;;	* Y position to 240 (outside rendering area for 8x8 and 16x16 sprites)
;;	* Character 0
;;	* No Priority, no flips
;;	* Small Size
;;
;; NOTICE: This sets both OAM tables.
.global ClearOAM


;; Clears the CGRAM
;;
;; REQUIRES: 8 bit A, 16 bit Index
.global ClearCGRAM


