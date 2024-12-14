# SPDX-License-Identifier: CC0-1.0
#
# SPDX-FileContributor: Adrian "asie" Siekierka, 2023

WONDERFUL_TOOLCHAIN ?= /opt/wonderful
TARGET = wswan/small
include $(WONDERFUL_TOOLCHAIN)/target/$(TARGET)/makedefs.mk

# Configuration
# -------------

include config.defaults.mk
include config.mk
CONFIG_FILES := config.defaults.mk config.mk

NAME_BIOS	:= $(NAME)BIOS-$(VERSION)
NAME_OS		:= $(NAME)OS-$(VERSION)
SRC_BIOS	:= bios bios/bank bios/comm bios/disp bios/key bios/sound bios/system bios/text bios/timer bios/util
SRC_OS		:= os

# Defines
# -------

SRC_BIOS    += bios/comm/$(BIOS_COMM_DRIVER)
SRC_BIOS    += bios/timer/$(BIOS_TIMER_RTC)
DEFINES     += -DBIOS_BANK_MAPPER_$(BIOS_BANK_MAPPER)
DEFINES		+= -DBIOS_BANK_ROM_FORCE_COUNT=$(BIOS_BANK_ROM_FORCE_COUNT)

BIOS_BANK_MEMORY_IMPL := $(BIOS_BANK_MEMORY)

ifneq ($(filter $(BIOS_BANK_MEMORY),rom ram),)
DEFINES		+= -DBIOS_BANK_MAPPER_NO_PORT_CE_SUPPORT
endif
ifneq ($(filter $(BIOS_BANK_MEMORY),rom rom_ce),)
BIOS_BANK_MEMORY_IMPL := simple
DEFINES		+= -DBIOS_BANK_MAPPER_SIMPLE_ROM
endif
ifneq ($(filter $(BIOS_BANK_MEMORY),ram ram_ce),)
BIOS_BANK_MEMORY_IMPL := simple
DEFINES		+= -DBIOS_BANK_MAPPER_SIMPLE_RAM
endif

SRC_BIOS    += bios/bank/$(BIOS_BANK_MEMORY_IMPL)

# Tool paths
# ----------

PYTHON		:= python3
BIN2S		:= $(WONDERFUL_TOOLCHAIN)/bin/wf-bin2s

# File paths
# ----------

BUILDDIR	:= build
DISTDIR		:= dist
BUILDDIR_BIOS	:= $(BUILDDIR)/$(SRC_BIOS)
BUILDDIR_OS	:= $(BUILDDIR)/$(SRC_OS)
ELF_BIOS	:= $(BUILDDIR)/$(NAME_BIOS).elf
ELF_OS		:= $(BUILDDIR)/$(NAME_OS).elf
MAP_BIOS	:= $(BUILDDIR)/$(NAME_BIOS).map
MAP_OS		:= $(BUILDDIR)/$(NAME_OS).map
RAW_BIOS	:= $(DISTDIR)/$(NAME_BIOS).raw
BIN_BIOS	:= $(DISTDIR)/$(NAME_BIOS).bin
RAW_OS		:= $(DISTDIR)/$(NAME_OS).raw
BIN_OS		:= $(DISTDIR)/$(NAME_OS).bin

# Libraries
# ---------

LIBS		:= -lws
LIBDIRS		:= $(WF_ARCH_LIBDIRS)

# Verbose flag
# ------------

ifeq ($(V),1)
_V		:=
else
_V		:= @
endif

# Source files
# ------------

SOURCES_BIOS_S	:= $(shell find -L $(SRC_BIOS) -maxdepth 1 -name "*.s")
SOURCES_BIOS_C	:= $(shell find -L $(SRC_BIOS) -maxdepth 1 -name "*.c")
SOURCES_OS_S	:= $(shell find -L $(SRC_OS)   -maxdepth 1 -name "*.s")
SOURCES_OS_C	:= $(shell find -L $(SRC_OS)   -maxdepth 1 -name "*.c")

# Compiler and linker flags
# -------------------------

WARNFLAGS	:= -Wall

INCLUDEFLAGS	:= $(foreach path,$(LIBDIRS),-isystem $(path)/include)

LIBDIRSFLAGS	:= $(foreach path,$(LIBDIRS),-L$(path)/lib)

ASFLAGS		+= -x assembler-with-cpp $(DEFINES) $(WF_ARCH_CFLAGS) \
		   $(INCLUDEFLAGS) -ffunction-sections -fdata-sections -fno-common

CFLAGS		+= -std=gnu11 $(WARNFLAGS) $(DEFINES) $(WF_ARCH_CFLAGS) \
		   $(INCLUDEFLAGS) -ffunction-sections -fdata-sections -fno-common -Os

LDFLAGS		:= $(LIBDIRSFLAGS) $(WF_ARCH_LDFLAGS) $(LIBS)

CFLAGS_BIOS	:= -Ibios
CFLAGS_OS	:= -Ios

# Intermediate build files
# ------------------------

OBJS_BIOS	:= $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_BIOS_S))) \
		   $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_BIOS_C)))
OBJS_OS		:= $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_OS_S))) \
		   $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_OS_C)))

OBJS_BIOS	+= $(BUILDDIR)/fonts/font_ank_dat.o $(BUILDDIR)/fonts/font_sjis_dat.o

OBJS		:= $(OBJS_BIOS) $(OBJS_OS)

DEPS		:= $(OBJS:.o=.d)

# Targets
# -------

.PHONY: all clean

all: $(RAW_BIOS) $(RAW_OS) $(BIN_BIOS) $(BIN_OS)

$(BIN_BIOS): $(RAW_BIOS)
	@echo "  UPDATE  $@"
	@$(MKDIR) -p $(@D)
	$(_V)$(PYTHON) tools/convert_update.py $< $@

$(BIN_OS): $(RAW_OS)
	@echo "  UPDATE  $@"
	@$(MKDIR) -p $(@D)
	$(_V)$(PYTHON) tools/convert_update.py $< $@

$(RAW_BIOS): $(ELF_BIOS)
	@echo "  OBJCOPY $@"
	@$(MKDIR) -p $(@D)
	$(_V)$(OBJCOPY) -O binary $< $@

$(RAW_OS): $(ELF_OS)
	@echo "  OBJCOPY $@"
	@$(MKDIR) -p $(@D)
	$(_V)$(OBJCOPY) -O binary $< $@

$(ELF_BIOS): $(OBJS_BIOS) bios/link.ld
	@echo "  LD      $@"
	@$(MKDIR) -p $(@D)
	$(_V)$(CC) -o $(ELF_BIOS) -Tbios/link.ld -Wl,-Map,$(MAP_BIOS) -Wl,--gc-sections $(OBJS_BIOS) $(LDFLAGS)

$(ELF_OS): $(OBJS_OS) os/link.ld
	@echo "  LD      $@"
	@$(MKDIR) -p $(@D)
	$(_V)$(CC) -o $(ELF_OS) -Tos/link.ld -Wl,-Map,$(MAP_OS) -Wl,--gc-sections $(OBJS_OS) $(LDFLAGS)

clean:
	@echo "  CLEAN"
	$(_V)$(RM) $(DISTDIR) $(BUILDDIR)

# Rules
# -----

$(BUILDDIR)/fonts/font_ank_dat.o : $(BIOS_FONT_ANK) tools/ank_font_pack.py $(CONFIG_FILES)
	@echo "  FONT    $<"
	@mkdir -p $(@D)
	$(PYTHON) tools/ank_font_pack.py $(BIOS_FONT_ANK) $(patsubst %_dat.o,%.dat,$@)
	@echo "  BIN2S   $(patsubst %_dat.o,%.dat,$@)"
	$(_V)$(BIN2S) --section ".text" $(@D) $(patsubst %_dat.o,%.dat,$@)
	$(_V)$(CC) $(ASFLAGS) -c -o $@ $(patsubst %.o,%.s,$@)

$(BUILDDIR)/fonts/font_sjis_dat.o : $(BIOS_FONT_SJIS) tools/sjis_font_pack.py $(CONFIG_FILES)
	@echo "  FONT    $<"
	@mkdir -p $(@D)
	$(PYTHON) tools/sjis_font_pack.py $(BIOS_FONT_SJIS) $(patsubst %_dat.o,%.dat,$@)
	@echo "  BIN2S   $(patsubst %_dat.o,%.dat,$@)"
	$(_V)$(BIN2S) --section ".text" $(@D) $(patsubst %_dat.o,%.dat,$@)
	$(_V)$(CC) $(ASFLAGS) -c -o $@ $(patsubst %.o,%.s,$@)

$(BUILDDIR)/bios/%.s.o : bios/%.s $(CONFIG_FILES)
	@echo "  AS      $<"
	@$(MKDIR) -p $(@D)
	$(_V)$(CC) $(ASFLAGS) $(CFLAGS_BIOS) -MMD -MP -MJ $(patsubst %.o,%.cc.json,$@) -c -o $@ $<

$(BUILDDIR)/bios/%.c.o : bios/%.c $(CONFIG_FILES)
	@echo "  CC      $<"
	@$(MKDIR) -p $(@D)
	$(_V)$(CC) $(CFLAGS) $(CFLAGS_BIOS) -MMD -MP -MJ $(patsubst %.o,%.cc.json,$@) -c -o $@ $<

$(BUILDDIR)/os/%.s.o : os/%.s $(CONFIG_FILES)
	@echo "  AS      $<"
	@$(MKDIR) -p $(@D)
	$(_V)$(CC) $(ASFLAGS) $(CFLAGS_OS) -MMD -MP -MJ $(patsubst %.o,%.cc.json,$@) -c -o $@ $<

$(BUILDDIR)/os/%.c.o : os/%.c $(CONFIG_FILES)
	@echo "  CC      $<"
	@$(MKDIR) -p $(@D)
	$(_V)$(CC) $(CFLAGS) $(CFLAGS_OS) -MMD -MP -MJ $(patsubst %.o,%.cc.json,$@) -c -o $@ $<

# Include dependency files if they exist
# --------------------------------------

-include $(DEPS)
