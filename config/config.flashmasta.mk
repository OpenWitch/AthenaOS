# Flash Masta build configuration file

BIOS_BANK_MEMORY := js28f00am29ew
BIOS_BANK_ROM_FORCE_COUNT := 8
BIOS_BANK_ROM_FORCE_DYNAMIC := true
BIOS_TIMER_RTC := none
FLAVOR := flashmasta

# This is technically only true for Flavor's 2003 mapper reimplementation (rev5+).
BIOS_BANK_QUIRK_CE_DISABLES_ROM := true
