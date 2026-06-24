#!/bin/bash

# 1. Check if the user forgot to provide a module name
if [ -z "$1" ]; then
    echo "Error: Missing module name!"
    echo "Usage: ./run_sim.sh <module_name> [wave]"
    echo "Example: ./run_sim.sh counter10 wave"
    exit 1
fi

# 2. Get the directory of THIS script (the 'sim' folder)
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# 3. Go up one level to get the project ROOT directory
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# 4. Dynamically set file names based on the first parameter ($1)
MODULE_NAME="$1"
VVP_OUT="$ROOT_DIR/sim/${MODULE_NAME}.vvp"
VCD_FILE="$ROOT_DIR/sim/${MODULE_NAME}.vcd"
TB_FILE="$ROOT_DIR/tb/${MODULE_NAME}_tb.sv"
RTL_FILE="$ROOT_DIR/rtl/${MODULE_NAME}.sv"

# 5. Check if the target source files actually exist before compiling
if [ ! -f "$TB_FILE" ] || [ ! -f "$RTL_FILE" ]; then
    echo "Error: Source files for '${MODULE_NAME}' not found."
    echo "Expected to find:"
    echo "  - Testbench: $TB_FILE"
    echo "  - RTL code:  $RTL_FILE"
    exit 1
fi

# 6. Compile and run the simulation
echo "Compiling ${MODULE_NAME} RTL and Testbench..."
iverilog -g2012 -o "$VVP_OUT" "$TB_FILE" "$RTL_FILE"

if [ $? -eq 0 ]; then
    echo "Running simulation..."
    vvp "$VVP_OUT"
else
    echo "Compilation failed!"
    exit 1
fi

# 7. Check the second parameter ($2) to see if we should open GTKWave
if [ "$2" == "wave" ]; then
    echo "Opening GTKWave for ${MODULE_NAME}..."
    
    if [ -f "$VCD_FILE" ]; then
        gtkwave "$VCD_FILE" &
    else
        echo "Error: $VCD_FILE not found. Check if your testbench has proper \$dumpfile syntax."
    fi
fi