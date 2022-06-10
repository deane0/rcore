# Building
TARGET := riscv64gc-unknown-none-elf
MODE := release
BUILD_DIR = target/$(TARGET)/$(MODE)

ifeq ($(MODE), release)
	MODE_ARG := --release
endif

KERNEL_ELF := $(BUILD_DIR)/rcore
DISASM_TMP := $(BUILD_DIR)/asm
KERNEL_BIN := $(KERNEL_ELF).bin

# BOARD
BOARD ?= qemu
SBI ?= rustsbi
BOOTLOADER := ./bootloader/$(SBI)-$(BOARD).bin

# KERNEL ENTRY
ifeq ($(BOARD), qemu)
	KERNEL_ENTRY_PA := 0x80200000
endif

# Binutils
OBJDUMP := rust-objdump --arch-name=riscv64
OBJCOPY := rust-objcopy --binary-architecture=riscv64

build: switch-check $(KERNEL_BIN)

switch-check:
ifeq ($(BOARD), qemu)
	make clean
endif

$(KERNEL_BIN): kernel
	@$(OBJCOPY) $(KERNEL_ELF) --strip-all -O binary $@

kernel:
	@echo Platform: $(BOARD)
	@cargo build $(MODE_ARG)

clean:
	@cargo clean

run: run-inner

run-inner: build
ifeq ($(BOARD),qemu)
	@qemu-system-riscv64 \
		-machine virt \
		-nographic \
		-bios $(BOOTLOADER) \
		-device loader,file=$(KERNEL_BIN),addr=$(KERNEL_ENTRY_PA)
endif
