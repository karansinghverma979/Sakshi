use egui::{Color32, FontData, FontDefinitions, FontFamily};
use std::fs;
use std::path::PathBuf;

pub const COLOR_BG: Color32 = Color32::from_rgb(10, 12, 16); // #0A0C10
pub const COLOR_BORDER: Color32 = Color32::from_rgb(40, 47, 63); // Subtle dark slate border
pub const COLOR_BORDER_ACTIVE: Color32 = Color32::from_rgb(245, 158, 11); // #F59E0B Amber
pub const COLOR_SPARK: Color32 = Color32::from_rgb(245, 158, 11); // #F59E0B Amber
pub const COLOR_TEXT: Color32 = Color32::from_rgb(248, 250, 252); // #F8FAFC Crisp White
pub const COLOR_MUTED: Color32 = Color32::from_rgb(100, 116, 139); // #64748B Slate
pub const COLOR_FOOTER: Color32 = Color32::from_rgb(80, 94, 114); // #505E72 Dimmed

pub fn setup_fonts(ctx: &egui::Context) {
    let mut fonts = FontDefinitions::default();

    if let Some(font_path) = find_preferred_font() {
        if let Ok(font_bytes) = fs::read(&font_path) {
            fonts.font_data.insert(
                "nerd_custom".to_owned(),
                FontData::from_owned(font_bytes),
            );

            // Set as highest priority for both Monospace and Proportional
            fonts
                .families
                .entry(FontFamily::Monospace)
                .or_default()
                .insert(0, "nerd_custom".to_owned());

            fonts
                .families
                .entry(FontFamily::Proportional)
                .or_default()
                .insert(0, "nerd_custom".to_owned());
        }
    }

    ctx.set_fonts(fonts);
}

fn find_preferred_font() -> Option<PathBuf> {
    let home = dirs::home_dir()?;
    let user_fonts = home.join("AppData\\Local\\Microsoft\\Windows\\Fonts");

    let candidates = [
        user_fonts.join("JetBrainsMonoNLNerdFont-SemiBold.ttf"),
        user_fonts.join("JetBrainsMonoNLNerdFont-Bold.ttf"),
        user_fonts.join("JetBrainsMonoNLNerdFont-Regular.ttf"),
        user_fonts.join("MesloLGSNerdFont-Regular.ttf"),
        user_fonts.join("SauceCodeProNerdFont-Regular.ttf"),
        PathBuf::from("C:\\Windows\\Fonts\\CascadiaCode.ttf"),
        PathBuf::from("C:\\Windows\\Fonts\\consola.ttf"),
    ];

    for candidate in &candidates {
        if candidate.exists() {
            return Some(candidate.clone());
        }
    }

    None
}
