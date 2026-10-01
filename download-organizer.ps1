$Downloads = Join-Path $env:USERPROFILE "Downloads"

$Folders = @{
    Images        = @("jpg","jpeg","png","gif","webp","bmp","svg","tif","tiff","heic","heif","avif","raw","cr2","cr3","nef","arw","dng")
    Videos        = @("mp4","mkv","avi","mov","webm","flv","wmv","m4v","mpeg","mpg","ts","mts","m2ts","3gp")
    Audio         = @("mp3","wav","flac","ogg","opus","aac","m4a","wma","aiff","ape")
    Documents     = @("pdf","doc","docx","txt","odt","rtf","epub","mobi","azw","azw3")
    Spreadsheets  = @("xls","xlsx","csv","ods","tsv")
    Presentations = @("ppt","pptx","odp")
    Archives      = @("zip","rar","7z","tar","gz","bz2","xz","zst","tgz")
    Installers    = @("exe","msi","msix","msixbundle")
    "Disk-Images" = @("iso","img","vhd","vhdx")
    Code          = @("py","ps1","sh","bash","js","ts","html","css","c","cpp","h","hpp","java","rs","go","json","xml","yaml","yml","toml","sql")
    Subtitles     = @("srt","ass","ssa","vtt","sub")
    Fonts         = @("ttf","otf","woff","woff2")
}

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

function Get-Folder($Extension) {
    foreach ($Folder in $Folders.Keys) {
        if ($Folders[$Folder] -contains $Extension) {
            return $Folder
        }
    }

    return "Other"
}

function Test-ExplorerRenameMode {

    try {
        $ExplorerProcesses = Get-Process explorer -ErrorAction SilentlyContinue

        foreach ($Explorer in $ExplorerProcesses) {

            try {
                if ($Explorer.MainWindowHandle -eq 0) {
                    continue
                }

                $Window = [System.Windows.Automation.AutomationElement]::FromHandle(
                    $Explorer.MainWindowHandle
                )

                if ($null -eq $Window) {
                    continue
                }

                $EditCondition =
                    New-Object System.Windows.Automation.PropertyCondition(
                        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
                        [System.Windows.Automation.ControlType]::Edit
                    )

                $Edits = $Window.FindAll(
                    [System.Windows.Automation.TreeScope]::Descendants,
                    $EditCondition
                )

                foreach ($Edit in $Edits) {

                    try {
                        if (-not $Edit.Current.IsOffscreen) {
                            return $true
                        }
                    }
                    catch {
                    }
                }
            }
            catch {
            }
        }

        return $false
    }
    catch {
        return $false
    }
}

function Organize-File($File) {

    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        return
    }

    try {
        $Item = Get-Item -LiteralPath $File -ErrorAction Stop
    }
    catch {
        return
    }

    $Name = $Item.Name

    # Browser temporary files.
    if ($Name -like ".org.chromium.*") { return }
    if ($Name -like "*.crdownload") { return }
    if ($Name -like "*.part") { return }
    if ($Name -like "*.tmp") { return }
    if ($Name -like "Unconfirmed *") { return }

    # Do not organize anything while Explorer has an active
    # filename editor.
    if (Test-ExplorerRenameMode) {
        return
    }

    $Extension = [System.IO.Path]::GetExtension($Name).TrimStart('.').ToLower()
    $Folder = Get-Folder $Extension

    $DestinationFolder = Join-Path $Downloads $Folder

    if (-not (Test-Path -LiteralPath $DestinationFolder)) {
        New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
    }

    $Destination = Join-Path $DestinationFolder $Name

    if (Test-Path -LiteralPath $Destination) {

        $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($Name)
        $ExtensionWithDot = [System.IO.Path]::GetExtension($Name)

        $Counter = 1

        do {
            $NewName = "${BaseName}_${Counter}${ExtensionWithDot}"
            $Destination = Join-Path $DestinationFolder $NewName
            $Counter++
        }
        while (Test-Path -LiteralPath $Destination)
    }

    try {
        Move-Item `
            -LiteralPath $File `
            -Destination $Destination `
            -ErrorAction Stop
    }
    catch {
        # Try again on the next scan.
    }
}

while ($true) {

    Get-ChildItem `
        -LiteralPath $Downloads `
        -File `
        -ErrorAction SilentlyContinue |
        ForEach-Object {
            Organize-File $_.FullName
        }

    Start-Sleep -Milliseconds 200
}