#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod editor;
mod icon;
mod storage;
mod theme;
mod win32;

use chrono::Local;
use eframe::egui;
use std::time::Instant;

fn main() -> eframe::Result<()> {
    // 1. Enforce Single-Instance & Virtual Desktop Teleportation
    let _guard = match win32::SingleInstanceGuard::acquire_or_teleport("⚡ Spark") {
        Some(g) => g,
        None => return Ok(()), // Another instance was summoned and focused; exit immediately
    };

    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_inner_size([960.0, 580.0])
            .with_min_inner_size([550.0, 320.0])
            .with_decorations(false)
            .with_transparent(true)
            .with_always_on_top()
            .with_resizable(true)
            .with_icon(icon::generate_spark_icon())
            .with_title("⚡ Spark"),
        ..Default::default()
    };

    eframe::run_native(
        "⚡ Spark",
        options,
        Box::new(|cc| {
            theme::setup_fonts(&cc.egui_ctx);
            Ok(Box::new(SparkApp::new()))
        }),
    )
}

struct SparkApp {
    text: String,
    focused_once: bool,
    last_keystroke: Instant,
}

impl SparkApp {
    fn new() -> Self {
        Self {
            text: "* ".to_string(),
            focused_once: false,
            last_keystroke: Instant::now(),
        }
    }

    fn save_and_exit(&mut self, ctx: &egui::Context) {
        if let Err(err) = storage::append_spark(&self.text) {
            eprintln!("Failed to save spark: {}", err);
        }
        ctx.send_viewport_cmd(egui::ViewportCommand::Close);
    }
}

impl eframe::App for SparkApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        // Track keyboard and mouse interaction for inactivity watchdog
        ctx.input(|i| {
            if !i.events.is_empty() {
                self.last_keystroke = Instant::now();
            }
        });

        let idle_secs = self.last_keystroke.elapsed().as_secs();

        // 60-Second Inactivity Auto-Destruct (Closes without saving)
        if idle_secs >= 60 {
            ctx.send_viewport_cmd(egui::ViewportCommand::Close);
            return;
        }

        // Request repaint to update countdown timer if idle >= 10s
        if idle_secs >= 10 {
            ctx.request_repaint_after(std::time::Duration::from_millis(250));
        }

        // Global Keybindings
        if ctx.input(|i| i.key_pressed(egui::Key::Escape)) {
            // Strictly close WITHOUT saving
            ctx.send_viewport_cmd(egui::ViewportCommand::Close);
            return;
        }

        if ctx.input(|i| i.modifiers.command && i.key_pressed(egui::Key::Enter)) {
            // Strictly the ONLY path that commits thought to disk
            self.save_and_exit(ctx);
            return;
        }

        let enter_pressed = ctx.input(|i| {
            i.key_pressed(egui::Key::Enter)
                && !i.modifiers.command
                && !i.modifiers.shift
                && !i.modifiers.alt
        });

        // Dynamic amber border glow when user has typed actual content
        let has_content = {
            let trimmed = self.text.trim();
            !trimmed.is_empty() && trimmed != "*" && trimmed != "-"
        };

        let border_color = if has_content {
            theme::COLOR_BORDER_ACTIVE
        } else {
            theme::COLOR_BORDER
        };

        // Frameless Outer Container
        let frame = egui::Frame::none()
            .fill(theme::COLOR_BG)
            .stroke(egui::Stroke::new(1.0_f32, border_color))
            .rounding(egui::Rounding::same(8.0))
            .inner_margin(egui::Margin::symmetric(22.0, 18.0));

        egui::CentralPanel::default().frame(frame).show(ctx, |ui| {
            // Header: ⚡ Spark and current time
            ui.horizontal(|ui| {
                ui.label(
                    egui::RichText::new("⚡ Spark")
                        .color(theme::COLOR_SPARK)
                        .size(16.0)
                        .strong(),
                );

                ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                    let now = Local::now().format("%I:%M %p").to_string();
                    ui.label(
                        egui::RichText::new(now)
                            .color(theme::COLOR_MUTED)
                            .size(12.0),
                    );
                });
            });

            ui.add_space(10.0);

            // Multiline Text Editor Area
            let editor_id = egui::Id::new("spark_multiline_editor");
            let available_height = ui.available_height() - 32.0;

            let text_edit = egui::TextEdit::multiline(&mut self.text)
                .id(editor_id)
                .desired_width(f32::INFINITY)
                .desired_rows(16)
                .frame(false)
                .font(egui::FontId::new(18.0, egui::FontFamily::Monospace))
                .text_color(theme::COLOR_TEXT)
                .hint_text(
                    egui::RichText::new("Capture raw thought, strike, or idea...")
                        .color(theme::COLOR_MUTED)
                        .italics(),
                );

            let scroll_output = egui::ScrollArea::vertical()
                .max_height(available_height)
                .auto_shrink([false, false])
                .show(ui, |ui| text_edit.show(ui));

            let edit_output = scroll_output.inner;

            // Auto-focus on first frame and position cursor after initial "* "
            if !self.focused_once {
                ui.memory_mut(|m| m.request_focus(editor_id));
                let mut state = edit_output.state.clone();
                let initial_cursor = egui::text::CCursor::new(self.text.chars().count());
                state.cursor.set_char_range(Some(egui::text::CCursorRange::one(initial_cursor)));
                state.store(ui.ctx(), editor_id);
                self.focused_once = true;
            }

            // Smart list continuation on Enter
            if enter_pressed {
                if let Some(cursor_range) = edit_output.cursor_range {
                    let char_idx = cursor_range.primary.ccursor.index;
                    if let Some(new_idx) = editor::SmartList::handle_enter(&mut self.text, char_idx) {
                        let mut state = edit_output.state.clone();
                        let new_ccursor = egui::text::CCursor::new(new_idx);
                        state.cursor.set_char_range(Some(egui::text::CCursorRange::one(new_ccursor)));
                        state.store(ui.ctx(), editor_id);
                    }
                }
            }

            ui.add_space(8.0);

            // Footer: Left = CTRL+ENTER TO SAVE | Right = [Timer] • ESC TO CLOSE
            ui.horizontal(|ui| {
                // Left Side
                ui.label(
                    egui::RichText::new("CTRL+ENTER TO SAVE")
                        .color(theme::COLOR_FOOTER)
                        .size(11.0)
                        .strong(),
                );

                // Right Side
                ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                    ui.label(
                        egui::RichText::new("ESC TO CLOSE")
                            .color(theme::COLOR_FOOTER)
                            .size(11.0)
                            .strong(),
                    );

                    // Show auto-timer only if idle >= 10 seconds
                    if idle_secs >= 10 {
                        let remaining = 60 - idle_secs;
                        ui.label(
                            egui::RichText::new(format!("auto-close in {}s  •", remaining))
                                .color(theme::COLOR_BORDER_ACTIVE)
                                .size(11.0),
                        );
                    }
                });
            });
        });
    }
}
