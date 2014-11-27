;; import_export.inc
;;
;; Simplifies the automation of importing and exporting variables
;; and functions between modules.
;;
;; To use this file, you need two files, a source and a header.
;;
;; The source file should start the module with
;;
;;	MODULE <name>
;;
;; And end with
;;
;;	END_MODULE
;;
;;
;; You can then define a variable, label or a routine with the following macros
;; 
;;	BYTE, WORD, ADDR, LONG, STRUCT
;;	UINT8, UINT16, SINT16, UINT32, SINT32
;;
;; Which will define a variable of a known size and (optional) count.
;;
;; It will also
;;
;;	* Export a variable called `_MODULE_name`
;;	* Also creates:
;;		* `_MODULE_name__type` which matches the `TYPE_*` enum symbols
;;		* `_MODULE_name__size` containg the total size of the variable in bytes
;;		* `_MODULE_name__elsize` containing the size of each element in bytes (if count is used)
;;		* `_MODULE_name__count` containing the number of elements
;;
;; Any variables defined inside a `ZEROPAGE` ... `ENDZEROPAGE` block will be 
;; imported/exported within the zero page. 
;;
;; It is also possible to declare a label/routine with the following macros
;;
;;	LABEL, ROUTINE
;;
;;
;; Declaring a module interface using inside the header file is the same as
;; Defineing variables, routines and labels. Except you use the 
;;
;;	IMPORT_MODULE <name>
;;
;; instead.
;; This will cause use the same symbols as the source code, but it will be scoped into the module name.
;;
;; For example:
;;
;; Source:
;;	MODULE Test
;;	.segment "WRAM"
;;		WORD variable
;;		WORD local Variable
;;	.code
;;
;;	ROUTINE Routine
;;		RTS
;;
;;	ENDMODULE
;;
;; Header:
;;	IMPORT_MODULE Test
;;		WORD variable
;;		ROUTINE Routine
;;	ENDMODULE
;;
;; Will create the following symbols in all files that include the header
;;
;;	Test::variable
;;	Test::Routine
;;	Test::variable__size
;;	Test::variable__type
;;	Test::Routine__type
;;

;; ::TODO add accumulator/index check to ROUTINE::
;; ::TODO add CALL macro that uses assert on accumulator/index and then JSR::
;; ::TODO macros for setting accumulator/index sizes::

.ifndef ::_IMPORT_EXPORT_H_
::_IMPORT_EXPORT_H_ = 1

.enum 
	TYPE_BYTE = 1
	TYPE_WORD
	TYPE_ADDR
	TYPE_LONG
	TYPE_UINT8
	TYPE_SINT8
	TYPE_UINT16
	TYPE_SINT16
	TYPE_UINT32
	TYPE_SINT32
	TYPE_STRUCT
	TYPE_ROUTINE
	TYPE_LABEL
	TYPE_CONST
.endenum

.define __MODULE_TYPE_NONE   0
.define __MODULE_TYPE_EXPORT 1
.define __MODULE_TYPE_IMPORT 2

::__MODULE_TYPE .set 0


;; Defines a module.
;; Must be called at the start of a module file.
.macro MODULE name
	::__MODULE_TYPE .set __MODULE_TYPE_EXPORT
	::__MODULE_ZEROPAGE .set 0

	.define __MODULE_NAME .string(name)
.endmacro

.macro IMPORT_MODULE name
	::__MODULE_TYPE .set __MODULE_TYPE_IMPORT
	::__MODULE_ZEROPAGE .set 0

	.define __MODULE_NAME .string(name)
	.scope name
.endmacro

;; Cleans up the end of a module.
.macro ENDMODULE
	.if ::__MODULE_TYPE = __MODULE_TYPE_IMPORT
		.endscope
	.endif

	::__MODULE_TYPE .set __MODULE_TYPE_NONE
	.undefine __MODULE_NAME
.endmacro


.macro ZEROPAGE
	::__MODULE_ZEROPAGE .set 1
.endmacro

.macro ENDZEROPAGE
	::__MODULE_ZEROPAGE .set 0
.endmacro



.macro _VARIABLE_HELPER name, type, size, count
	.if ::__MODULE_TYPE = __MODULE_TYPE_EXPORT .or ::__MODULE_TYPE = __MODULE_TYPE_NONE
		.ifblank count
			name:	.res size
			.ident(.sprintf("%s__size", .string(name))) .set size
		.else
			name:	.res size * (count)
			.ident(.sprintf("%s__elsize", .string(name))) .set size
			.ident(.sprintf("%s__size", .string(name))) .set size * (count)
			.ident(.sprintf("%s__count", .string(name))) .set count
		.endif

		.ident(.sprintf("%s__type", .string(name))) := type

		.if ::__MODULE_TYPE = __MODULE_TYPE_EXPORT
			.if ::__MODULE_ZEROPAGE
				.exportzp .ident(.sprintf("_%s__%s", __MODULE_NAME, .string(name))) := name
			.else
				.export .ident(.sprintf("_%s__%s", __MODULE_NAME, .string(name))) := name
			.endif
		.else
			.if ::__MODULE_ZEROPAGE
				.exportzp name
			.else
				.export name
			.endif
		.endif
	.endif

	.if ::__MODULE_TYPE = __MODULE_TYPE_IMPORT
		.ifblank count
			.ident(.sprintf("%s__size", .string(name))) .set size
		.else
			.ident(.sprintf("%s__elsize", .string(name))) .set size
			.ident(.sprintf("%s__size", .string(name))) .set size * count
			.ident(.sprintf("%s__count", .string(name))) .set count
		.endif

		.ident(.sprintf("%s__type", .string(name))) := type

		.if ::__MODULE_ZEROPAGE
			.globalzp .ident(.sprintf("_%s__%s", __MODULE_NAME, .string(name)))
		.else
			.global .ident(.sprintf("_%s__%s", __MODULE_NAME, .string(name)))
		.endif
		name := .ident(.sprintf("_%s__%s", __MODULE_NAME, .string(name)))
	.endif
.endmacro


.macro _SYMBOL_HELPER name, type
	.if ::__MODULE_TYPE = __MODULE_TYPE_EXPORT .or ::__MODULE_TYPE = __MODULE_TYPE_NONE
		.ident(.sprintf("%s__type", .string(name))) = type

		.if ::__MODULE_TYPE = __MODULE_TYPE_EXPORT
			.export .ident(.sprintf("_%s__%s", __MODULE_NAME, .string(name))) := name
		.else
				.export name
		.endif
		name:
	.endif

	.if ::__MODULE_TYPE = __MODULE_TYPE_IMPORT
		.ident(.sprintf("%s__type", .string(name))) := type

		.global .ident(.sprintf("_%s__%s", __MODULE_NAME, .string(name)))
		name := .ident(.sprintf("_%s__%s", __MODULE_NAME, .string(name)))
	.endif
.endmacro

.macro _IMPORT_SYMBOL_HELPER name, type
	.ident(.sprintf("%s__type", .string(name))) := type

	.global .ident(.sprintf("%s__%s", __MODULE_NAME, .string(name)))
.endmacro

.macro CONST name, value
	.if ::__MODULE_TYPE = __MODULE_TYPE_NONE
		.fatal "Require MODULE or IMPORT_MODULE"
	.endif

	.if ::__MODULE_TYPE = __MODULE_TYPE_EXPORT
		.ident(.sprintf("%s__type", .string(name))) = TYPE_CONST
		name := value
	.endif

	.if ::__MODULE_TYPE = __MODULE_TYPE_IMPORT
		.ident(.sprintf("%s__type", .string(name))) := TYPE_CONST
		name := value
	.endif
.endmacro


.macro STRUCT name, struct, count
	_VARIABLE_HELPER name, TYPE_STRUCT, .sizeof(struct), count
.endmacro

.macro BYTE name, count
	_VARIABLE_HELPER name, TYPE_BYTE, 1, count
.endmacro

.macro WORD name, count
	_VARIABLE_HELPER name, TYPE_WORD, 2, count
.endmacro

.macro ADDR name, count
	_VARIABLE_HELPER name, TYPE_ADDR, 2, count
.endmacro

.macro LONG name, count
	_VARIABLE_HELPER name, TYPE_LONG, 3, count
.endmacro

.macro UINT8 name, count
	_VARIABLE_HELPER name, TYPE_UINT8, 1, count
.endmacro

.macro SINT8 name, count
	_VARIABLE_HELPER name, TYPE_SINT8, 1, count
.endmacro

.macro UINT16 name, count
	_VARIABLE_HELPER name, TYPE_UINT16, 2, count
.endmacro

.macro SINT16 name, count
	_VARIABLE_HELPER name, TYPE_SINT16, 2, count
.endmacro

.macro UINT32 name, count
	_VARIABLE_HELPER name, TYPE_UINT32, 4, count
.endmacro

.macro SINT32 name, count
	_VARIABLE_HELPER name, TYPE_SINT32, 4, count
.endmacro

.macro ROUTINE name
	_SYMBOL_HELPER name, TYPE_ROUTINE
.endmacro

.macro LABEL name
	_SYMBOL_HELPER name, TYPE_LABEL
.endmacro

.macro IMPORT_ROUTINE name
	_IMPORT_SYMBOL_HELPER name, TYPE_ROUTINE
.endmacro

.macro IMPORT_LABEL name
	_IMPORT_SYMBOL_HELPER name, TYPE_LABEL
.endmacro

.macro BREAKPOINT
	.global BREAKPOINT_
	BREAKPOINT_:
.endmacro


.endif ; ::_IMPORT_EXPORT_H_

