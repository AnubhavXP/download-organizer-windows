# Download Organizer for Windows

A lightweight PowerShell-based download organizer for Windows 10 and Windows 11.

Automatically sorts files downloaded directly into the user's Downloads folder into folders based on their file type.

## Features

- Automatically organizes downloaded files
- Runs continuously in the background
- Starts with Windows
- Ignores browser temporary files
- Prevents files from being overwritten
- Automatically numbers duplicate filenames
- Supports multiple file categories
- Unknown file types are placed in Other
- Uses native Windows PowerShell functionality

## Categories

- Images
- Videos
- Audio
- Documents
- Spreadsheets
- Presentations
- Archives
- Installers
- Disk Images
- Code
- Subtitles
- Fonts
- Other

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or newer

## Installation

Download the project files to your Windows computer.

Open PowerShell in the project directory.

To allow local PowerShell scripts for your user account:

    Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

Run the organizer:

    .\download-organizer.ps1

To start the organizer automatically when Windows starts:

    .\install-startup.ps1

The startup installer creates a shortcut in the user's Windows Startup folder.

The organizer then runs in the background whenever the user logs into Windows.

## How It Works

The organizer monitors the Downloads directory using the Windows FileSystemWatcher API.

When a file appears in the Downloads directory, the script checks whether the file has finished changing before organizing it.

Browser temporary files such as `.crdownload`, `.part`, `.tmp`, `.org.chromium.*`, and `Unconfirmed` files are ignored.

If a file with the same name already exists, the organizer creates a numbered copy instead of overwriting the existing file.

## Supported File Types

### Images

JPG, JPEG, PNG, GIF, WEBP, BMP, SVG, TIF, TIFF, HEIC, HEIF, AVIF, RAW, CR2, CR3, NEF, ARW, DNG

### Videos

MP4, MKV, AVI, MOV, WEBM, FLV, WMV, M4V, MPEG, MPG, TS, MTS, M2TS, 3GP

### Audio

MP3, WAV, FLAC, OGG, OPUS, AAC, M4A, WMA, AIFF, APE

### Documents

PDF, DOC, DOCX, TXT, ODT, RTF, EPUB, MOBI, AZW, AZW3

### Spreadsheets

XLS, XLSX, CSV, ODS, TSV

### Presentations

PPT, PPTX, ODP

### Archives

ZIP, RAR, 7Z, TAR, GZ, BZ2, XZ, ZST, TGZ

### Installers

EXE, MSI, MSIX, MSIXBUNDLE

### Disk Images

ISO, IMG, VHD, VHDX

### Code

PY, PS1, SH, BASH, JS, TS, HTML, CSS, C, CPP, H, HPP, JAVA, RS, GO, JSON, XML, YAML, YML, TOML, SQL

### Subtitles

SRT, ASS, SSA, VTT, SUB

### Fonts

TTF, OTF, WOFF, WOFF2

Unsupported file types are placed in Other.

## Limitations

The organizer processes files directly inside the Downloads folder.

Files inside existing subdirectories are not processed.

## License

MIT License
