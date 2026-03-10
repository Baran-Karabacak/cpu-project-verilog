CC = iverilog
SIM = vvp
VIEWER = gtkwave

SRC_DIR = src
TB_DIR = tb
BUILD_DIR = build
PROG_DIR = programs

TARGET ?= cpu_core_tb

TB_FILE = $(TB_DIR)/$(TARGET).v
VVP_FILE = $(BUILD_DIR)/$(TARGET).vvp
VCD_FILE = $(BUILD_DIR)/$(TARGET).vcd
HEX_FILE = $(PROG_DIR)/input.hex

CFLAGS = -I $(SRC_DIR) -Wall

.PHONY: all build_dir check_hex compile run wave clean

all: clean build_dir check_hex compile run

# Creates the build directory
build_dir:
		@mkdir -p $(BUILD_DIR)

# Checks the existence of input hex file
check_hex:
		@if [ ! -f $(HEX_FILE) ]; then \
				echo "ERROR: Could not found $(HEX_FILE)!"; \
				mkdir -p $(PROG_DIR); \
				touch $(HEX_FILE); \
				echo "INFO: An empty hex file created in programs folder."; \
				exit 1; \
		fi

# Compiles verilog
compile: check_hex
		@echo "Compiling: $(TB_FILE)"
		$(CC) $(CFLAGS) -o $(VVP_FILE) $(TB_FILE)

# Runs the simulation
run: compile
		@echo "Starting the simulation"
		$(SIM) $(VVP_FILE)

# Visualizes the waveform
wave: run
		@echo "Starting gtkwave"
		$(VIEWER) $(VCD_FILE) &

clean:
		@echo "Cleaning"
		@rm -rf $(BUILD_DIR)