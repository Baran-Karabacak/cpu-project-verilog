use std::{env, process};
use rom_builder::build_rom;

fn main() {
    // Collect command line arguments
    let args: Vec<String> = env::args().collect();

    // Check the arguments
    if args.len() != 3 {
        eprintln!("Usage: cargo run <input_file.hex> <output_file.v>");
        process::exit(1); 
    }

    let input_file = &args[1];
    let output_file = &args[2];

    println!("Starting generation...");
    println!("Reading from: {}", input_file);
    println!("Writing to: {}", output_file);

    // Call your library function and handle the Result
    match build_rom(input_file, output_file) {
        Ok(_) => {
            println!("Success! Verilog ROM file has been generated.");
        }
        Err(error_msg) => {
            eprintln!("\nGeneration Failed!");
            eprintln!("{}", error_msg);
            process::exit(1); 
        }
    }
}