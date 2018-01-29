PROGRAM = template
BUILDDIR = build

#runs as many concurrent jobs as possible
#comment out if you encounter dependency errors
MAKEFLAGS += -j

#location of libs relative to makefile
DEVICE = lib/device
CORE = lib/core
HAL = lib/hal
BOARD = lib/board
ASM = lib/asm

INCLUDES = -I$(DEVICE)/inc \
		   -I$(CORE)/inc \
		   -I$(HAL)/inc \
		   -I$(BOARD)/inc \
		   -Iinc

SOURCES = $(wildcard $(BOARD)/src/*.c) \
		  $(wildcard $(HAL)/src/*.c) \
		  $(wildcard $(ASM)/*.s) \
		  $(wildcard src/*.c)

OBJECTS = $(addprefix $(BUILDDIR)/, $(addsuffix .o, $(basename $(SOURCES))))

BIN = $(BUILDDIR)/$(PROGRAM).bin
ELF = $(BUILDDIR)/$(PROGRAM).elf
MAP = $(BUILDDIR)/$(PROGRAM).map

CC = arm-none-eabi-gcc
LD = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy

# COMPILER FLAGS
# -mcpu=cortex-m4              specifies processor core
# -mthumb                      use thumb ISA
# -mfloat-abi=hard             use on chip FPU
# -mfpu=fpv4-sp-d16            specifies FPU hardware
# -DUSE_HAL_DRIVER             preprocessor macro telling lib to use HAL drivers
# -DSTM32F311xE                preprocessor macro telling which device to target
# -DUSE_STM32F3XX_NUCLEO       preprocessor macro telling which board to target
# $(INCLUDES)                  include all the files
# -Os                          optimize for size
# -g3                          highest level of debugging info
# -Wall                        turn on lots of warnings
# -fmessage-length=0           1 error message per line
# -ffunction-sections          optimize via locality of reference, must be used with linker option --gc-sections
# -c                           outputs .o files
# -Wno-unused-variable         disable warning for unused variable
# -Wno-pointer-sign            disable warning for pointer argument passing or assignment with different signedness
# -Wno-main                    disable warning if the type of main is suspicious
# -Wno-format                  disable warning for printf and scanf type checking
# -Wno-address                 disable warning for address checking
# -Wno-unused-but-set-variable disable warning for unused but set variable
# -Wno-strict-aliasing         disable warning about type aliasing, option is included in -Os

CFLAGS = -mcpu=cortex-m4 \
		 -mthumb \
         -mfloat-abi=hard \
		 -mfpu=fpv4-sp-d16 \
		 -DUSE_HAL_DRIVER \
		 -DSTM32F311xE \
		 -DUSE_STM32F3XX_NUCLEO \
		 $(INCLUDES) \
		 -Os \
		 -g3 \
	     -Wall \
		 -fmessage-length=0 \
		 -ffunction-sections \
		 -c \
		 -Wno-unused-variable \
		 -Wno-pointer-sign \
		 -Wno-main \
		 -Wno-format \
		 -Wno-address \
		 -Wno-unused-but-set-variable \
		 -Wno-strict-aliasing

# LINKER FLAGS
# -mcpu=cortex-m4            specifies processor core
# -mthumb                    use thumb ISA
# -mfloat-abi=hard           use on chip FPU
# -mfpu=fpv4-sp-d16          specifies FPU hardware
# -specs=nosys.specs         use MCU lib for system calls like malloc
# -specs=nano.specs          use stripped down MCU lib
# -T"lib/asm/stm32_flash.ld" load script
# -Wl,-Map=output.map        creates a map file
# -Wl,--gc-sections          strips unused code from object files to reduce size
# -lm                        include math lib


LDFLAGS = -mcpu=cortex-m4 \
          -mthumb \
		  -mfloat-abi=hard \
		  -mfpu=fpv4-sp-d16 \
		  -specs=nosys.specs \
		  -specs=nano.specs \
		  -T$(ASM)/stm32_flash.ld \
		  -Wl,-Map=$(MAP) \
		  -Wl,--gc-sections \
		  -lm

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

$(ELF): $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $(OBJECTS)

$(BUILDDIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) $< -o $@

$(BUILDDIR)/%.o: %.s
	@mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) $< -o $@

flash: $(BIN)
	st-flash write $(BIN) 0x8000000

erase:
	st-flash erase

clean:
	rm -rf build
