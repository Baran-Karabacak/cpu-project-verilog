pub mod parser;
pub mod generator;

use std::fs::File;
use std::io::Write;
use std::path::Path;

// Builds the ROM file
// Returns Ok(()) on success, or a detailed String error on failure
pub fn build_rom<P: AsRef<Path>>(input_path: P, output_path: P) -> Result<(), String> {
    
}