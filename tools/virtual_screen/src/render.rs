use crate::constants::*;

pub fn render_dashboard(
    front_buffer: &mut [u32],
    pixel_back_buffer: &[u32],
    char_buffer: &str,
    number_display: Option<i32>,
) {
    // Clear Screen
    front_buffer.fill(COLOR_BLACK);

    draw_text(front_buffer, char_buffer, CHAR_X_START, CHAR_Y_START);
    
    if let Some(num) = number_display {
        draw_number(front_buffer, num, NUMBER_X_START, NUMBER_Y_START);
    }

    draw_copper_matrix(front_buffer, pixel_back_buffer, 0, 64);
}

fn get_font_data(c: char) -> [u8; 15] {
    match c.to_ascii_uppercase() {
        '0' => [1,1,1,  1,0,1,  1,0,1,  1,0,1,  1,1,1],
        '1' => [0,1,0,  1,1,0,  0,1,0,  0,1,0,  1,1,1],
        '2' => [1,1,1,  0,0,1,  1,1,1,  1,0,0,  1,1,1],
        '3' => [1,1,1,  0,0,1,  1,1,1,  0,0,1,  1,1,1],
        '4' => [1,0,1,  1,0,1,  1,1,1,  0,0,1,  0,0,1],
        '5' => [1,1,1,  1,0,0,  1,1,1,  0,0,1,  1,1,1],
        '6' => [1,1,1,  1,0,0,  1,1,1,  1,0,1,  1,1,1],
        '7' => [1,1,1,  0,0,1,  0,0,1,  0,0,1,  0,0,1],
        '8' => [1,1,1,  1,0,1,  1,1,1,  1,0,1,  1,1,1],
        '9' => [1,1,1,  1,0,1,  1,1,1,  0,0,1,  1,1,1],
        
        'A' => [1,1,1,  1,0,1,  1,1,1,  1,0,1,  1,0,1],
        'B' => [1,1,0,  1,0,1,  1,1,0,  1,0,1,  1,1,0],
        'C' => [1,1,1,  1,0,0,  1,0,0,  1,0,0,  1,1,1],
        'D' => [1,1,0,  1,0,1,  1,0,1,  1,0,1,  1,1,0],
        'E' => [1,1,1,  1,0,0,  1,1,1,  1,0,0,  1,1,1],
        'F' => [1,1,1,  1,0,0,  1,1,1,  1,0,0,  1,0,0],
        'G' => [1,1,1,  1,0,0,  1,0,1,  1,0,1,  1,1,1],
        'H' => [1,0,1,  1,0,1,  1,1,1,  1,0,1,  1,0,1],
        'I' => [1,1,1,  0,1,0,  0,1,0,  0,1,0,  1,1,1],
        'J' => [0,0,1,  0,0,1,  0,0,1,  1,0,1,  1,1,1],
        'K' => [1,0,1,  1,0,1,  1,1,0,  1,0,1,  1,0,1],
        'L' => [1,0,0,  1,0,0,  1,0,0,  1,0,0,  1,1,1],
        'M' => [1,0,1,  1,1,1,  1,0,1,  1,0,1,  1,0,1],
        'N' => [1,1,1,  1,0,1,  1,0,1,  1,0,1,  1,0,1],
        'O' => [1,1,1,  1,0,1,  1,0,1,  1,0,1,  1,1,1],
        'P' => [1,1,1,  1,0,1,  1,1,1,  1,0,0,  1,0,0],
        'Q' => [1,1,1,  1,0,1,  1,0,1,  1,1,1,  0,0,1],
        'R' => [1,1,1,  1,0,1,  1,1,0,  1,0,1,  1,0,1],
        'S' => [1,1,1,  1,0,0,  1,1,1,  0,0,1,  1,1,1],
        'T' => [1,1,1,  0,1,0,  0,1,0,  0,1,0,  0,1,0],
        'U' => [1,0,1,  1,0,1,  1,0,1,  1,0,1,  1,1,1],
        'V' => [1,0,1,  1,0,1,  1,0,1,  1,0,1,  0,1,0],
        'W' => [1,0,1,  1,0,1,  1,0,1,  1,1,1,  1,0,1],
        'X' => [1,0,1,  1,0,1,  0,1,0,  1,0,1,  1,0,1],
        'Y' => [1,0,1,  1,0,1,  0,1,0,  0,1,0,  0,1,0],
        'Z' => [1,1,1,  0,0,1,  0,1,0,  1,0,0,  1,1,1],

        '!' => [0,1,0,  0,1,0,  0,1,0,  0,0,0,  0,1,0],
        '?' => [1,1,1,  0,0,1,  0,1,0,  0,0,0,  0,1,0],
        '-' => [0,0,0,  0,0,0,  1,1,1,  0,0,0,  0,0,0],
        '+' => [0,0,0,  0,1,0,  1,1,1,  0,1,0,  0,0,0],
        '=' => [0,0,0,  1,1,1,  0,0,0,  1,1,1,  0,0,0],
        '.' => [0,0,0,  0,0,0,  0,0,0,  0,0,0,  0,1,0],
        ':' => [0,0,0,  0,1,0,  0,0,0,  0,1,0,  0,0,0],

        _   => [0,0,0,  0,0,0,  0,0,0,  0,0,0,  0,0,0], 
    }
}

fn draw_char(buffer: &mut [u32], c: char, x_start: usize, y_start: usize, scale: usize) {
    let font_data = get_font_data(c);
    
    for y in 0..5 {
        for x in 0..3 {
            if font_data[y * 3 + x] == 1 {
                for dy in 0..scale {
                    for dx in 0..scale {
                        let px = x_start + (x * scale) + dx;
                        let py = y_start + (y * scale) + dy;
                        if px < WIDTH && py < HEIGHT {
                            buffer[py * WIDTH + px] = COLOR_WHITE;
                        }
                    }
                }
            }
        }
    }
}

fn draw_text(buffer: &mut [u32], text: &str, mut x_start: usize, y_start: usize) {
    let font_scale = 4;
    let char_width = 3 * font_scale;
    let spacing = 1 * font_scale;

    for c in text.chars() {
        draw_char(buffer, c, x_start, y_start, font_scale);
        x_start += char_width + spacing;
    }
}

fn draw_number(buffer: &mut [u32], num: i32, x_start: usize, y_start: usize) {
    let text = num.to_string();
    draw_text(buffer, &text, x_start, y_start);
}

fn draw_copper_matrix(buffer: &mut [u32], matrix: &[u32], x_offset: usize, y_offset: usize) {
    for y in 0..32 {
        for x in 0..32 {
            let pixel_color = matrix[y * 32 + x];
            for dy in 0..16 {
                for dx in 0..16 {
                    let target_y = y * 16 + dy + y_offset;
                    let target_x = x * 16 + dx + x_offset;
                    let index = target_y * WIDTH + target_x;
                    
                    if dy == 15 || dx == 15 {
                        if index < buffer.len() { buffer[index] = COLOR_BLACK; }
                    } else {
                        if index < buffer.len() { buffer[index] = pixel_color; }
                    }
                }
            }
        }
    }
}