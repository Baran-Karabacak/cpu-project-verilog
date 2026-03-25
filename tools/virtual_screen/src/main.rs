use minifb::{Key, Scale, Window, WindowOptions};
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::time::Duration;

const WIDTH: usize = 32;
const HEIGHT: usize = 32;

const COLOR_BLACK: u32 = 0xFF_1E1E2E; // Background
const COLOR_WHITE: u32 = 0xFF_A6E3A1; // Pixels

fn main() {
    let mut window = Window::new(
        "8-bit CPU Display",
        WIDTH,
        HEIGHT,
        WindowOptions {
          scale: Scale::X16, // 32x32 to 512x512
          ..WindowOptions::default()
        },
    ).expect("Could not open the screen");
    
    let mut pixel_x: usize = 0;
    let mut pixel_y: usize = 0;
    
    let mut back_buffer: Vec<u32> = vec![COLOR_BLACK; WIDTH * HEIGHT];
    let mut front_buffer: Vec<u32> = vec![COLOR_BLACK; WIDTH * HEIGHT];
    
    println!("Virtual Display Engine started.");
    
    let log_path = "../../build/io_trace.csv";
    let file = File::open(log_path).expect("Could not found io_trace.csv. First run Verilog simulation.");
    let reader = BufReader::new(file);
    
    window.update_with_buffer(&front_buffer, WIDTH, HEIGHT).unwrap();
    
    for line in reader.lines() {
        if !window.is_open() || window.is_key_down(Key::Escape) { break; }

        let line = match line {
            Ok(l) => l,
            Err(_) => continue,
        };

        let parts: Vec<&str> = line.split(',').collect();
        if parts.len() != 2 { continue; }
        
        let addr: u8 = match parts[0].trim().parse() {
            Ok(val) => val,
            Err(_) => continue,
        };
        
        let data: u8 = match parts[1].trim().parse() {
            Ok(val) => val,
            Err(_) => continue,
        };
        
        match addr {
            240 => pixel_x = (data & 0x1F) as usize,
            241 => pixel_y = (data & 0x1F) as usize,
            242 => {
                if pixel_x < WIDTH && pixel_y < HEIGHT {
                    back_buffer[pixel_y * WIDTH + pixel_x] = COLOR_WHITE;
                }
            },
            243 => {
                if pixel_x < WIDTH && pixel_y < HEIGHT {
                    back_buffer[pixel_y * WIDTH + pixel_x] = COLOR_BLACK;
                }
            },
            245 => {
                front_buffer.copy_from_slice(&back_buffer);
                window.update_with_buffer(&front_buffer, WIDTH, HEIGHT).unwrap();
                std::thread::sleep(Duration::from_millis(50));
            },
            246 => { // Clear Screen Buffer
                back_buffer.fill(COLOR_BLACK);
            },
            250 => println!("[NUMBER DISPLAY]: {}", data),
            _ => {},
        }
    }
    
    println!("Simülasyon Finished. Press ESC to exit.");
    while window.is_open() && !window.is_key_down(Key::Escape) {
        window.update_with_buffer(&front_buffer, WIDTH, HEIGHT).unwrap();
        std::thread::sleep(Duration::from_millis(16));
    }
}
