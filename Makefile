CC = iverilog
SIM = vvp
VIEWER = gtkwave

SRC_DIR = src
TB_DIR = tb
BUILD_DIR = build
PROG_DIR = programs
TOOLS_DIR = tools/

TARGET ?= cpu_core_tb

TB_FILE = $(TB_DIR)/$(TARGET).v
VVP_FILE = $(BUILD_DIR)/$(TARGET).vvp
VCD_FILE = $(BUILD_DIR)/$(TARGET).vcd
PROG ?= input
HEX_FILE = $(PROG_DIR)/$(PROG).hex
ROM_FILE = $(SRC_DIR)/instruction_memory.v
RAM_FILE = $(SRC_DIR)/data_memory.v
SRC_FILES = $(shell find $(SRC_DIR) -type f -name '*.v')

CFLAGS = -I $(SRC_DIR) -Wall

.PHONY: all build_dir check_hex generate_rom compile run wave clean

all: clean build_dir check_hex generate_rom generate_ram compile run

# Creates the build directory
build_dir:
	@mkdir -p $(BUILD_DIR)

# Checks the existence of input hex file
check_hex:
	@if [ ! -f $(HEX_FILE) ]; then \
		echo "ERROR: Could not find $(HEX_FILE)!"; \
		mkdir -p $(PROG_DIR); \
		touch $(HEX_FILE); \
		echo "INFO: An empty hex file created in programs folder."; \
		exit 1; \
	fi

# Compiles and runs the Rust ROM Generator
generate_rom: check_hex
	@echo "Generating pure hardware ROM via Rust..."
	@cd $(TOOLS_DIR)/rom_builder && cargo run --release --quiet -- ../../$(HEX_FILE) ../../$(ROM_FILE)
	
$(RAM_FILE):
	@echo "RAM file not found. Forging gate-level RAM via Rust..."
	@cd $(TOOLS_DIR)/ram_builder && cargo run --release --quiet

# Compiles verilog (Now depends on generate_rom)
compile: generate_rom $(RAM_FILE) build_dir
	@echo "Compiling Testbench and all Hardware Modules..."
	$(CC) $(CFLAGS) -o $(VVP_FILE) $(TB_FILE) $(SRC_FILES)

# Runs the simulation
run: compile
	@echo "Starting the simulation"
	$(SIM) $(VVP_FILE)

# Visualizes the waveform
wave: run
	@echo "Starting gtkwave"
	$(VIEWER) $(VCD_FILE) &

clean:
	@echo "Cleaning Build Directory"
	@rm -rf $(BUILD_DIR)
	@echo "Cleaning Auto-Generated ROM and RAM Files..."
	@rm -f $(ROM_FILE)
	@echo "Cleaning Rust Target Directory"
	@cd $(TOOLS_DIR)/rom_builder && cargo clean
	@cd $(TOOLS_DIR)/ram_builder && cargo clean
	