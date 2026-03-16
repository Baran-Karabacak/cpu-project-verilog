pub mod parser;
pub mod generator;

use std::fs;
use std::path::Path;

// Builds the ROM file
// Returns Ok(()) on success, or a detailed String error on failure
pub fn build_rom<P: AsRef<Path>>(input_path: P, output_path: P) -> Result<(), String> {
    let hex_codes = parser::parse_hex_file(input_path)?;
    let verilog_code = generator::generate_verilog_content(&hex_codes)?;

    // 3. Write to the output file
    fs::write(output_path, verilog_code).map_err(|e| {
        format!("File Write Error: Could not write to the output file. Details: {}", e)
    })?;
    Ok(())
}