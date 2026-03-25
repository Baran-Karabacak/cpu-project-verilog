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
    let file = File::open(log_path).expect("Could not find dashboard_trace.csv!");
    let mut reader = BufReader::new(file);

    println!("Virtual Dashboard Started");

    let mut line = String::new();

    device.needs_render = true;

    loop {
        if !window.is_open() || window.is_key_down(Key::Escape) { break; }

        line.clear();
        match reader.read_line(&mut line) {
            Ok(0) => {
                if device.needs_render {
                    draw_all(&mut front_buffer, &device);
                    window.update_with_buffer(&front_buffer, WIDTH, HEIGHT).unwrap();
                    device.needs_render = false;
                }
                std::thread::sleep(Duration::from_millis(10));
                window.update_with_buffer(&front_buffer, WIDTH, HEIGHT).unwrap();
                continue;
            }
            Ok(_) => {
                let parts: Vec<&str> = line.split(',').collect();
                if parts.len() == 2 && let (Ok(addr), Ok(data)) = (parts[0].trim().parse::<u8>(), parts[1].trim().parse::<u8>()) {
                    device.process_io(addr, data);
                }

                if device.needs_render {
                    draw_all(&mut front_buffer, &device);
                    window.update_with_buffer(&front_buffer, WIDTH, HEIGHT).unwrap();
                    device.needs_render = false;
                }
            }
            Err(e) => {
                println!("Error reading line: {}", e);
                break;
            }
        }
    }
}

fn draw_all(buffer: &mut [u32], device: &VirtualDevice) {
    render_dashboard(
        buffer,
        &device.pixel_back_buffer,
        &device.char_buffer,
        if device.show_number { Some(device.number_display) } else { None },
    );
}