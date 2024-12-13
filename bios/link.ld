OUTPUT_FORMAT("elf32-i386")
ENTRY(_start)
SECTIONS
{
	/* segelf segment start markers for target text section. */
	".text!" 0xF0000 (NOLOAD) :
	{
		"__text_start!" = .;
		KEEP(*(".header!"))
		KEEP(*(".start!"))
		*(".text!*" ".text.*!")
		*(".fartext!*" ".fartext.*!")
		*(".farrodata!*" ".farrodata.*!")
		"__text_end!" = .;
	}

	/* Target text section. */
	.text 0xF0000 :
	{
		__text_start = .;
		KEEP(*(".header"))
		KEEP(*(".start"))
		*(.text ".text.*[^&]")
		*(".fartext.*[^&]")
		*(".farrodata.*[^&]")
		__text_end = .;
	}

	/* segelf segment end markers for target text section. */
	".text&" . (NOLOAD) :
	{
		"__text_start&" = .;
		KEEP(*(".header&"))
		KEEP(*(".start&"))
		*(".text&*" ".text.*&")
		*(".fartext&*" ".fartext.*&")
		*(".farrodata&*" ".farrodata.*&")
		"__text_end&" = .;
		. = ALIGN (16);
	}

	/* segelf segment start markers for target data section. */
	".data!" 0x00000 (NOLOAD) : AT(ADDR(".text") + SIZEOF(".text"))
	{
		"__data_start!" = .;
		*(".rodata!*" ".rodata.*!")
		*(".data!*" ".data.*!")
		*(".bss!*" ".bss.*!")
		"__data_end!" = .;
		"__bss_end!" = .;
		"__heap_start!" = .;
		"__heap_end!" = .;
	}

	. = 0x230;

	/* Target data section. */
	.data . : AT(ADDR(".text") + SIZEOF(".text"))
	{
		__data_start = .;
		KEEP(*(.bios_data ".bios_data.*[^&]"))
		*(.rodata ".rodata.*[^&]")
		*(.data ".data.*[^&]")
		. = ALIGN (2);
		__data_end = .;
	}
	"__data_length!" = 0;
	__data_length = SIZEOF(.data);
	"__data_length_words!" = 0;
	__data_length_words = (__data_length + 1) / 2;

	/* Target BSS section, with same segment bases as data section. */
	.bss . (NOLOAD) :
	{
		*(.bss ".bss.*[^&]")
		. = ALIGN (2);
		__bss_end = .;
		__heap_start = .;
	}
	"__bss_length!" = 0;
	__bss_length = SIZEOF(.bss);
	"__bss_length_words!" = 0;
	__bss_length_words = (__bss_length + 1) / 2;

	__heap_end = 0x00E00;
	"__heap_length!" = 0;
	__heap_length = __heap_end - __heap_start - 4;

	/* segelf segment end markers for target data section. */
	".data&" . (NOLOAD) :
	{
		"__data_start&" = .;
		*(".rodata&*" ".rodata.*&")
		*(".data&*" ".data.*&")
		*(".bss&*" ".bss.*&")
		"__data_end&" = .;
		"__bss_end& " = .;
	}

	/* ROM footer */
	.footer . : AT(0xFFFF0)
	{
		KEEP(*(.footer))
	}

	"__bank_write_fill_block_flash_ram_size!" = 0;
	"__bank_erase_flash_ram_size!" = 0;

    /* Temporary workaround for avoiding debug relocation problems */

    ".comment!" = 0;
    .comment 0 : { *(.comment) }
    ".debug!" = 0;
    .debug 0 : { *(.debug) }
    ".line!" = 0;
    .line 0 : { *(.line) }
    ".debug_srcinfo!" = 0;
    .debug_srcinfo 0 : { *(.debug_srcinfo) }
    ".debug_sfnames!" = 0;
    .debug_sfnames 0 : { *(.debug_sfnames) }
    ".debug_aranges!" = 0;
    .debug_aranges 0 : { *(.debug_aranges) }
    ".debug_pubnames!" = 0;
    .debug_pubnames 0 : { *(.debug_pubnames) }
    ".debug_info!" = 0;
    .debug_info 0 : { *(.debug_info .gnu.linkonce.wi.*) }
    ".debug_abbrev!" = 0;
    .debug_abbrev 0 : { *(.debug_abbrev) }
    ".debug_line!" = 0;
    .debug_line 0 : { *(.debug_line .debug_line.* .debug_line_end) }
    ".debug_frame!" = 0;
    .debug_frame 0 : { *(.debug_frame) }
    ".debug_str!" = 0;
    .debug_str 0 : { *(.debug_str) }
    ".debug_loc!" = 0;
    .debug_loc 0 : { *(.debug_loc) }
    ".debug_macinfo!" = 0;
    .debug_macinfo 0 : { *(.debug_macinfo) }
    ".debug_weaknames!" = 0;
    .debug_weaknames 0 : { *(.debug_weaknames) }
    ".debug_funcnames!" = 0;
    .debug_funcnames 0 : { *(.debug_funcnames) }
    ".debug_typenames!" = 0;
    .debug_typenames 0 : { *(.debug_typenames) }
    ".debug_varnames!" = 0;
    .debug_varnames 0 : { *(.debug_varnames) }
    ".debug_pubtypes!" = 0;
    .debug_pubtypes 0 : { *(.debug_pubtypes) }
    ".debug_ranges!" = 0;
    .debug_ranges 0 : { *(.debug_ranges) }
    ".debug_addr!" = 0;
    .debug_addr 0 : { *(.debug_addr) }
    ".debug_line_str!" = 0;
    .debug_line_str 0 : { *(.debug_line_str) }
    ".debug_loclists!" = 0;
    .debug_loclists 0 : { *(.debug_loclists) }
    ".debug_macro!" = 0;
    .debug_macro 0 : { *(.debug_macro) }
    ".debug_names!" = 0;
    .debug_names 0 : { *(.debug_names) }
    ".debug_rnglists!" = 0;
    .debug_rnglists 0 : { *(.debug_rnglists) }
    ".debug_str_offsets!" = 0;
    .debug_str_offsets 0 : { *(.debug_str_offsets) }
    ".debug_sup!" = 0;
    .debug_sup 0 : { *(.debug_sup) }
}
