;;
;; 8x8 tiled Text
;; ==============
;;
;;

.ifndef ::_TEXT8X8_H_
::_TEXT8X8_H_ = 1

.include "includes/import_export.inc"
.include "routines/text.h"


IMPORT_MODULE Text8x8
	STRUCT	SingleSpacingInterface, TextInterface
	STRUCT	DoubleSpacingInterface, TextInterface
ENDMODULE

.endif ; ::_TEXT_H_

