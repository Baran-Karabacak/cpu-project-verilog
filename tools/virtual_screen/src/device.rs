use crate::constants::*;

pub struct VirtualDevice {
    pub pixel_x: usize,
    pub pixel_y: usize,
    pub pixel_back_buffer: Vec<u32>,
    pub char_buffer: String,
    pub number_display: i32,
    pub show_number: bool,
    pub needs_render: bool,
}

impl VirtualDevice {
    pub fn new() -> Self {
        Self {
            pixel_x: 0,
            pixel_y: 0,
            pixel_back_buffer: vec![COLOR_COPPER; 32 * 32],
            char_buffer: String::new(),
            number_display: 0,
            show_number: false,
            needs_render: false,
        }
    }

    // I/O Decoder
    pub fn process_io(&mut self, addr: u8, data: u8) {
        match addr {
            240 => self.pixel_x = (data & 0x1F) as usize,
            241 => self.pixel_y = (data & 0x1F) as usize,
            242 => {
                if self.pixel_x < 32 && self.pixel_y < 32 {
                    self.pixel_back_buffer[self.pixel_y * 32 + self.pixel_x] = COLOR_WHITE;
                }
            }
            243 => {
                if self.pixel_x < 32 && self.pixel_y < 32 {
                    self.pixel_back_buffer[self.pixel_y * 32 + self.pixel_x] = COLOR_COPPER;
                }
            }
            245 => self.needs_render = true,
            246 => self.pixel_back_buffer.fill(COLOR_COPPER),
            247 => self.char_buffer.push(data as char),
            248 => {} // Reading from buffer for future
            249 => self.char_buffer.clear(),
            250 => {
                self.number_display = data as i32;
                self.show_number = true;
            }
            251 => self.show_number = false,
            _ => {}
        }
    }
}