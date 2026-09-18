pub struct SmartList;

impl SmartList {
    /// Inspects the line before `cursor_char_idx` (which just had a newline inserted)
    /// and determines what modification, if any, should be applied to `text`.
    /// Returns the new cursor position if modified.
    pub fn handle_enter(text: &mut String, cursor_char_idx: usize) -> Option<usize> {
        if cursor_char_idx == 0 || text.is_empty() {
            return None;
        }

        // Convert char index to byte offset
        let char_indices: Vec<(usize, char)> = text.char_indices().collect();
        if cursor_char_idx > char_indices.len() {
            return None;
        }

        let byte_pos = if cursor_char_idx == char_indices.len() {
            text.len()
        } else {
            char_indices[cursor_char_idx].0
        };

        // Text before the newly inserted newline
        let text_before = &text[..byte_pos];
        if !text_before.ends_with('\n') {
            return None;
        }

        let without_newline = &text_before[..text_before.len() - 1];
        let last_line = match without_newline.rfind('\n') {
            Some(pos) => &without_newline[pos + 1..],
            None => without_newline,
        };

        let trimmed_line = last_line.trim_start();
        let indent = &last_line[..last_line.len() - trimmed_line.len()];

        // 1. Check for empty bullet: "-" or "*" or "- " or "* "
        if trimmed_line == "-" || trimmed_line == "*" || trimmed_line == "- " || trimmed_line == "* " {
            let remove_start_byte = byte_pos - 1 - last_line.len();
            text.replace_range(remove_start_byte..byte_pos, "");
            let new_char_idx = text[..remove_start_byte].chars().count();
            return Some(new_char_idx);
        }

        // 2. Check for active bullet: "- text" or "* text"
        if trimmed_line.starts_with("- ") || trimmed_line.starts_with("* ") {
            let bullet = if trimmed_line.starts_with("- ") { "- " } else { "* " };
            let prefix = format!("{}{}", indent, bullet);
            text.insert_str(byte_pos, &prefix);
            let new_char_idx = cursor_char_idx + prefix.chars().count();
            return Some(new_char_idx);
        }

        // 3. Check for numbered list: "1. text"
        if let Some(dot_pos) = trimmed_line.find(". ") {
            let num_str = &trimmed_line[..dot_pos];
            if let Ok(num) = num_str.parse::<usize>() {
                let rest = &trimmed_line[dot_pos + 2..];
                if rest.trim().is_empty() {
                    // Empty numbered line -> exit list mode
                    let remove_start_byte = byte_pos - 1 - last_line.len();
                    text.replace_range(remove_start_byte..byte_pos, "");
                    let new_char_idx = text[..remove_start_byte].chars().count();
                    return Some(new_char_idx);
                } else {
                    // Continue with next number
                    let next_num = num + 1;
                    let prefix = format!("{}{}. ", indent, next_num);
                    text.insert_str(byte_pos, &prefix);
                    let new_char_idx = cursor_char_idx + prefix.chars().count();
                    return Some(new_char_idx);
                }
            }
        }

        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_bullet_continuation() {
        let mut text = "- first item\n".to_string();
        let cursor = text.chars().count();
        let new_cursor = SmartList::handle_enter(&mut text, cursor);
        assert_eq!(text, "- first item\n- ");
        assert_eq!(new_cursor, Some(cursor + 2));
    }

    #[test]
    fn test_empty_bullet_clearing() {
        let mut text = "- first item\n- \n".to_string();
        let cursor = text.chars().count();
        let new_cursor = SmartList::handle_enter(&mut text, cursor);
        assert_eq!(text, "- first item\n");
        assert_eq!(new_cursor, Some(13));
    }

    #[test]
    fn test_numbered_continuation() {
        let mut text = "1. step one\n".to_string();
        let cursor = text.chars().count();
        let new_cursor = SmartList::handle_enter(&mut text, cursor);
        assert_eq!(text, "1. step one\n2. ");
        assert_eq!(new_cursor, Some(cursor + 3));
    }

    #[test]
    fn test_empty_numbered_clearing() {
        let mut text = "1. step one\n2. \n".to_string();
        let cursor = text.chars().count();
        let new_cursor = SmartList::handle_enter(&mut text, cursor);
        assert_eq!(text, "1. step one\n");
        assert_eq!(new_cursor, Some(12));
    }
}
