# ReNamery User Manual

> [!WARNING]
> **Beta Version Warning**
> This application is currently in beta. As it has a limited usage history, it may contain unexpected bugs.
> Please use with caution and back up important files before use.

ReNamery is a file renaming tool that respects the classic "Namery" software, rebuilt and revived using modern technology (Flutter).
It runs on Windows, Google Android, and Chromebook.
*Releases for macOS, Linux, and iOS (iPhone/iPad) will be considered upon valid request.*

## Main Features

ReNamery allows you to perform various renaming operations by switching tabs at the top of the screen.

### 1. Main Tab
Performs basic file renaming.

**Useful Features:**
- **Pin Icon (Save Sequence)**: Turning on the pin icon to the left of the numbering input will prevent the sequence count from resetting after a rename operation, allowing you to continue numbering from where you left off. Useful for numbering separate groups of files consecutively.

- **String + Number**: Adds a sequential number after the specified string.
- **Original + Number**: Adds a sequential number after the current file name.
- **Number + String**: Adds a specified string after the sequential number.
- **Number + Original**: Adds a sequential number before the current file name.
- **Replace**: Replaces specific characters in the file name with other characters.
- **Insert**: Inserts characters at a specified position.
- **Delete**: Deletes characters at a specified position.

### 2. Sub Tab
Performs extension changes and more advanced renaming.

#### Extension
- **Change Ext**: Changes the file extension to the specified one (e.g., `txt` -> `md`).
- **Add Extension**: Appends an extension to the end of the file name (e.g., `file` -> `file.bak`).
- **Remove Ext**: Removes the file extension.
- **Ext to Upper/Lower**: Unifies the case of the extension (e.g., `.JPG` -> `.jpg`).

#### Format
- **Capitalize Words**: Capitalizes the first letter of words separated by spaces, hyphens, or underscores (Proper Case).
  - Example: `my_document_file.txt` -> `My_Document_File.txt`

#### List Rename
Renames multiple files at once based on a text list.
You can change file names arbitrarily by pasting text data in **TSV (Tab-Separated Values)** format.
Suitable for using data created in Excel, etc.

**How to use:**
1.  Select **Text Input** mode.
2.  Enter the renaming rules in the text area below in the following format:
    ```text
    Old File Name [TAB] New File Name
    ```
    Alternatively, you can just list new file names line by line (in this case, they will be applied in order from the top of the list).

**Matching Rules:**
Files to be renamed are identified in the following order:
1.  **Exact Match**: When the "Old File Name" in the list exactly matches the actual file name (including extension).
2.  **Match without Extension**: When an exact match is not found, but it matches the actual file name (excluding the extension).

**Handling Extensions:**
- If the **New File Name** contains an extension, the name changes to include that extension. (e.g., `old.txt` -> `new.doc`)
- If the **New File Name** does not contain an extension, the original file's extension is preserved. (e.g., changing `old.txt` to `new` results in `new.txt`)

**Input Example (Tab-separated):**
```text
old_name.txt	new_name.txt
image01.png	photo01.png
report.doc	final_report.doc
```
*Input `[TAB]` using the Tab key on your keyboard. Coping and pasting two columns from spreadsheet software like Excel will automatically result in this format.*

**Useful Sample Features:**
You can call up frequently used patterns from the drop-down menu.
- **Sample: Sequential**: Example of sequential renaming for chaptered video files, etc.
- **Sample: Ext Replace**: Example of changing extensions in bulk.
- **Sample: Char Replace**: Example of replacing specific strings in bulk.

### 3. Extra Tab
Adds dates or converts character types.
- **Append Date**: Adds the creation or modification date to the file name. You can freely specify the format and position (front/back).
- **Half/Full Width Conversion**: Converts alphanumeric characters and Kana between half-width and full-width (mainly for Japanese text).

### 4. Attributes Tab
Changes file attributes and timestamps.
**Caution**: Changes made in this Attributes tab **cannot be undone (Undo)**. Please operate with caution.
- **Change Attributes**: Changes attributes such as Read-only and Hidden (Windows only).
- **Change Timestamp**: Changes the file modification date and time to an arbitrary value.

---

## Other Useful Features

### Filter Settings (Left Panel)
You can filter the folder tree display and the files to be processed.
- **Folder Icon (Show/Hide Folders)**: Clicking the folder icon in the title bar toggles the visibility of folders (directories) in the file list. Hide folders if you only want to see files.
- **Hide System Files**: Does not display OS system files in the list.
- **Recursive Search**: Lists files within subfolders of the selected folder. Useful for processing a large number of files at once.
- **Show Preview**: Displays a preview in the lower right when an image file, etc., is selected.

### Drag & Drop
Dragging and dropping a file or folder from Explorer (Finder) to the ReNamery file list will immediately open that location.

### Undo
After executing a rename, you can cancel the previous rename operation and restore the original names by pressing the "Undo" button on the toolbar (or `Ctrl+Z`).
*Attribute and timestamp changes are excluded.*

### About Macros
The Macro function present in Namery is not currently implemented. We will consider implementing it if there is strong demand.

---

## Developer Information
**Planning & Development**: Toyo Craft Lab
**URL**: https://toyo-craft.net/
This app was created with the utmost respect for the classic free software "Namery".
