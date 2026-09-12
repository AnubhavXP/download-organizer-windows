$ScriptPath = Join-Path $PSScriptRoot "download-organizer.ps1"

Start-Process powershell.exe `
    -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$ScriptPath`"" `
    -WindowStyle Hidden
