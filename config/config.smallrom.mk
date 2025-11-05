# ROMable build configuration file
# Note that this won't work with FreyaOS unless SRAM is pre-initialized,
# as it performs a flash write self-test on boot.

include config/config.rom.mk

OS_ENABLE_128K_SRAM := true
FLAVOR := smallrom
