use chrono::Local;
use std::fs::{create_dir_all, OpenOptions};
use std::io::{self, Write};
use std::path::PathBuf;

pub fn get_spark_path() -> Result<PathBuf, io::Error> {
    let home = dirs::home_dir().ok_or_else(|| {
        io::Error::new(io::ErrorKind::NotFound, "Could not determine home directory")
    })?;
    let gemini_dir = home.join(".gemini");
    create_dir_all(&gemini_dir)?;
    Ok(gemini_dir.join("Spark.md"))
}

pub fn append_spark(content: &str) -> Result<(), io::Error> {
    let trimmed = content.trim();
    if trimmed.is_empty()
        || trimmed == "*"
        || trimmed == "-"
        || trimmed == "* "
        || trimmed == "- "
    {
        return Ok(());
    }

    let now = Local::now().format("%Y-%m-%d %I:%M %p").to_string();
    let path = get_spark_path()?;
    let is_new = !path.exists();

    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(path)?;

    if is_new {
        writeln!(file, "# ⚡ Spark (Ephemeral Thoughts Stream)\n")?;
    }

    writeln!(file, "---\n### {}\n{}\n", now, trimmed)?;
    file.flush()?;
    Ok(())
}
