# === AthenaOS build configuration file ===

# == BIOS ==

# == BIOS / Hardware ==

# Select the mapper protocol used by the cartridge.
# Generally, there's no reason to change this.
#
# Available options:
# - 2001 - default protocol, fully supported (including by 2003 mappers)
# - 2003 - allows using a >16MB address space, limited support

# BIOS_BANK_MAPPER := 2001

# Select the memory type used by the cartridge.
# Defaults to read-only memory.
#
# Available options:
# - rom - read-only memory, does not depend on 0xCE port support
# - rom_ce - read-only memory, depends on 0xCE port support (slightly faster)
# - ram_ce - read-write memory, depends on 0xCE port support
# - mbm29dl400tc - MBM29DL400TC flash chip

BIOS_BANK_MEMORY := mbm29dl400tc

# Force ROM banking to emulate a specified number of banks.
# For WonderWitch compatibility on >512KB cartridges, set this value to 8.

# BIOS_BANK_ROM_FORCE_COUNT := 0

# Select the RTC provided by the cartridge.
#
# Available options:
# - none - no RTC provided, emulation stub used instead

# BIOS_TIMER_RTC := none

# == BIOS / Fonts ==

# Select the default ASCII font used by the cartridge.
# This should be an image containing 8x8 tiles in sequence, from left to right,
# then from top to bottom. Only the first 128 tiles will be used.

# BIOS_FONT_ANK  := fonts/font_ank.png

# Select the default Shift-JIS font used by the cartridge.
#
# The AthenaOS repository provides some alternate options:
# - fonts/misaki/misaki_gothic_2nd.png
#   Misaki Gothic 2nd (larger 7x7 kana characters)
# - fonts/misaki/misaki_mincho.png
#   Misaki Mincho

# BIOS_FONT_SJIS := fonts/misaki/misaki_gothic.png

# == OS ==

# == OS / Branding ==

# Define the project name.
# The BIOS is branded as $(NAME)BIOS, while the OS is branded as $(NAME)OS.

# NAME := Athenaaa

# Define the project version.

# VERSION := custom


