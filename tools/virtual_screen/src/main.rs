mod constants;
mod device;
mod render;

use minifb::{Key, Scale, Window, WindowOptions};
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::time::Duration;

use constants::{HEIGHT, WIDTH, COLOR_BLACK};
use device::VirtualDevice;
use render::render_dashboard;

fn main() {
    let mut window = Window::new(
        "8-Bit CPU Hardware Dashboard",
        WIDTH,
        HEIGHT,
        WindowOptions {
            scale: Scale::X2,
            ..WindowOptions::default()
        },
    ).expect("Could not open the screen!");

    let mut device = VirtualDevice::new();
    let mut front_buffer: Vec<u32> = vec![COLOR_BLACK; WIDTH * HEIGHT];

    let log_path = "../../build/dashboard_trace.csv";
    let file = File::open(log_path).expect("Could not found dashboard_trace.csv! First run the Verilog simulation.");
    let reader = BufReader::new(file);

    println!("Virtual Dashboard Started");

    for line in reader.lines() {
        if !window.is_open() || window.is_key_down(Key::Escape) { break; }

        let line = match line { Ok(l) => l, Err(_) => continue };
        let parts: Vec<&str> = line.split(',').collect();
        if parts.len() != 2 { continue; }

        let addr: u8 = match parts[0].trim().parse() { Ok(val) => val, Err(_) => continue };
        let data: u8 = match parts[1].trim().parse() { Ok(val) => val, Err(_) => continue };

        device.process_io(addr, data);

        if device.needs_render {
            render_dashboard(
                &mut front_buffer,
                &device.pixel_back_buffer,
                &device.char_buffer,
                if device.show_number { Some(device.number_display) } else { None },
            );

            window.update_with_buffer(&front_buffer, WIDTH, HEIGHT).unwrap();
            std::thread::sleep(Duration::from_millis(16)); // 60 FPS
            device.needs_render = false;
        }
    }

    println!("Simulation Finished. Press ESC to exit.");
    while window.is_open() && !window.is_key_down(Key::Escape) {
        window.update_with_buffer(&front_buffer, WIDTH, HEIGHT).unwrap();
        std::thread::sleep(Duration::from_millis(16));
    }
}