use std::fs::File;
use std::io::{BufRead, BufReader};
use std::path::Path;

// Reads the input Hex file, cleans, and validates it.
// Returns a vector of 4 digit Hex Strings upon success.
pub fn parse_hex_file<P: AsRef<Path>>(filepath: P) -> Result<Vec<String>, String> {
    let file = File::open(&filepath).map_err(|e| {
        format!("Error: Could not open or find the input file! Details: {}", e)
    })?;

    let reader = BufReader::new(file);
    let mut valid_hex_codes = Vec::new();

    for (line_number, line_result) in reader.lines().enumerate() {
        let line = line_result.map_err(|e| {
            format!("Read Error (Line: {}): I/O interruption. Details: {}", line_number + 1, e)
        })?;

        let trimmed_line = line.trim();

        // Skips empty lines and comment lines
        if trimmed_line.is_empty() || trimmed_line.starts_with("//") {
            continue;
        }

        // If the line contains a comment alongside the code, extracts only opcode
        let code_part = trimmed_line.split("//").next().unwrap_or("").trim();

        // Invalid Character Control
        if !code_part.chars().all(|c| c.is_ascii_hexdigit()) {
            return Err(format!(
                "Syntax Error (Line: {}): Invalid machine code '{}'. Only hexadecimal characters are allowed.",
                line_number + 1,
                code_part
            ));
        }

        if code_part.len() > 4 {
            return Err(format!(
                "Error (Line: {}): 16-bit limit exceeded! '{}' cannot be longer than 4 digits.",
                line_number + 1,
                code_part
            ));
        }

        // Pad missing digits (e.g., "A" becomes "000A") with leading zeros to enforce standard 16-bit width
        let formatted_hex = format!("{:0>4}", code_part.to_uppercase());
        valid_hex_codes.push(formatted_hex);
    }

    Ok(valid_hex_codes)
}