# ROMable build configuration file
# Note that this won't work with FreyaOS unless SRAM is pre-initialized,
# as it performs a flash write self-test on boot.

BIOS_BANK_MEMORY := rom
BIOS_BANK_ROM_FORCE_DYNAMIC := true
BIOS_TIMER_RTC := none
FLAVOR := rom
