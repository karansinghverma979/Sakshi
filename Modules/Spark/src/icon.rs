use eframe::egui::IconData;

pub fn generate_spark_icon() -> IconData {
    const SIZE: usize = 64;
    let mut rgba = Vec::with_capacity(SIZE * SIZE * 4);

    // Amber gold palette
    let bg_r = 10u8;
    let bg_g = 12u8;
    let bg_b = 16u8;

    let spark_r = 245u8;
    let spark_g = 158u8;
    let spark_b = 11u8;

    let spark_inner_r = 254u8;
    let spark_inner_g = 240u8;
    let spark_inner_b = 138u8;

    for y in 0..SIZE {
        for x in 0..SIZE {
            let dx = x as f32 - 31.5;
            let dy = y as f32 - 31.5;
            let dist = (dx * dx + dy * dy).sqrt();

            if dist > 30.5 {
                // Outside rounded badge
                rgba.extend_from_slice(&[0, 0, 0, 0]);
            } else if dist > 28.5 {
                // Subtle amber outer border glow
                let alpha = ((30.5 - dist) / 2.0 * 200.0) as u8;
                rgba.extend_from_slice(&[spark_r, spark_g, spark_b, alpha]);
            } else {
                // Check if inside stylized lightning bolt polygon
                // Normalized coordinate: u in [-1, 1], v in [-1, 1]
                let u = (x as f32 - 32.0) / 24.0;
                let v = (y as f32 - 32.0) / 24.0;

                let in_bolt = is_inside_lightning_bolt(u, v);

                if in_bolt {
                    // Central hot core vs outer amber
                    let core_dist = (u.abs() + (v + 0.1).abs()) * 0.5;
                    if core_dist < 0.25 {
                        rgba.extend_from_slice(&[spark_inner_r, spark_inner_g, spark_inner_b, 255]);
                    } else {
                        rgba.extend_from_slice(&[spark_r, spark_g, spark_b, 255]);
                    }
                } else {
                    rgba.extend_from_slice(&[bg_r, bg_g, bg_b, 255]);
                }
            }
        }
    }

    IconData {
        rgba,
        width: SIZE as u32,
        height: SIZE as u32,
    }
}

fn is_inside_lightning_bolt(x: f32, y: f32) -> bool {
    // Upper triangle of lightning bolt: (0.1, -0.9) to (-0.5, 0.05) to (0.1, 0.05)
    // Lower triangle of lightning bolt: (-0.1, -0.05) to (0.5, -0.05) to (-0.1, 0.9)
    if y >= -0.85 && y <= 0.08 {
        let t = (y + 0.85) / 0.93;
        let left = 0.1 - 0.6 * t;
        let right = 0.15 + 0.05 * t;
        if x >= left && x <= right {
            return true;
        }
    }

    if y >= -0.05 && y <= 0.85 {
        let t = (y + 0.05) / 0.90;
        let left = -0.15 - 0.05 * (1.0 - t);
        let right = 0.5 - 0.6 * t;
        if x >= left && x <= right {
            return true;
        }
    }

    false
}
