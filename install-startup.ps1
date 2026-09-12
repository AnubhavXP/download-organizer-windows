$StartupFolder = [Environment]::GetFolderPath("Startup")
$Launcher = Join-Path $PSScriptRoot "start-download-organizer.ps1"
$ShortcutPath = Join-Path $StartupFolder "Download Organizer.lnk"

$Shell = New-Object -ComObject WScript.Shell
$Shortcut = $Shell.CreateShortcut($ShortcutPath)

$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Launcher`""
$Shortcut.WorkingDirectory = $PSScriptRoot
$Shortcut.Description = "Start Download Organizer"

$Shortcut.Save()

Write-Host "Download Organizer added to Windows Startup."
