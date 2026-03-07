# ReNamery User Manual

> [!WARNING]
> **Important Notes on Beta and Web Versions**
> - This application is currently in beta. Validation for forbidden characters, empty names, and duplicate file names is missing. Incorrect operations may result in file corruption or unexpected errors.
> - The **Web Demo version** operates in a simulated environment; actual files are not modified. Features such as history saving and "Undo" are also unavailable.
> - Always back up important files before use.

ReNamery is a file renaming tool that respects the classic "Namery" software, rebuilt and revived using modern technology (Flutter).
It runs on Windows, Android, Chromebook, and Web Demo version.

## UI Structure

The application consists of three main areas:
- **Left Panel**: Folder tree (Quick Access) and the **Preview screen** to check file content.
- **Center Panel**: File list. Displays current file names and a preview of the changes.
- **Right Panel (Side Panel)**: Contains various setting panels to configure renaming rules.

## Renaming Rules (Right Panel)

Use the functional panels in the right panel to configure renaming rules.

### 1. String and Numbering
- **String**: Appends specific characters to file names.
- **Numbering**: Adds sequential numbers like `001`.
  - **String + Number**: Adds numbering after a specified string.
  - **Original + Number**: Adds numbering after the original name.
  - **Number + String / Number + Original**: Prepends numbering to the name.

### 2. Replace, Insert, and Delete
- **Replace**: Replaces specific characters with others.
- **Regex Replace**: Advanced replacement using regular expressions.
  - *Note: Backreferences (e.g., `\1`) are currently not supported.*
- **Uppercase/Lowercase Conversion**: Use options within the Replace panel for bulk case changes.
- **Insert**: Inserts characters at a specific position.
- **Delete**: Removes characters based on rules like "N characters from start" or "up to a specific character."

### 3. Extension
- **Change Extension**: Change `txt` to `md`, etc.
- **Add / Remove**: Append or completely strip extensions.
- **Case Unification**: Unifies the case of the extension part only.

### 4. Dates and Character Conversion (Extra)
- **Append Date**: Adds file creation or modification dates to the name.
- **Half/Full-width Conversion**: Converts alphanumeric characters and Katakana.
  - *Note: Rendering issues where half-width Katakana appear as "tofu" (□) exist in some environments.*
- **Hiragana/Katakana Conversion**: Converts between Japanese Hiragana and Katakana.

### 5. Attributes and Timestamp (Etc)
**※ Changes made here CANNOT be undone.**
- **Change Attributes**: Toggles attributes like Read-only and Hidden (Windows only).
- **Change Timestamp**: Updates the file modification date and time.

---

## Limitations and Known Issues (Important)

### Safety and Validation
- **Lack of Checks**: Validation for forbidden characters (e.g., `\ / : * ? " < > |`) or duplicate file names is currently missing. Please verify the preview carefully before execution.

### Unimplemented or Unstable Features
- **Pin Icon**: The feature to preserve numbering sequence across rename operations is currently unavailable.
- **List Rename**: Renaming based on pasting a text list (TSV, etc.) is not yet implemented.
- **Folder Renaming**: Currently, only files are supported. You cannot rename folders themselves.
- **Folder Operations**: Double-clicking folders in the center list to navigate and folder-priority sorting (currently mixed with files) are unimplemented.

### Operations
- **Undo**: Revert renaming operations using `Ctrl+Z`.
- **Note**: Attribute/date changes and all operations in the Web version cannot be undone.

---

## License
This software is released under the **MIT License**.

**Copyright (c) 2026 Toyo Craft Lab**

See the `LICENSE` file for details.
