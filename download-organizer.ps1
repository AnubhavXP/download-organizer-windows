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

function Get-Folder($Extension) {
    foreach ($Folder in $Folders.Keys) {
        if ($Folders[$Folder] -contains $Extension) {
            return $Folder
        }
    }

    return "Other"
}

function Organize-File($File) {
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        return
    }

    $Name = Split-Path $File -Leaf

    if ($Name -like ".org.chromium.*") { return }
    if ($Name -like "*.crdownload") { return }
    if ($Name -like "*.part") { return }
    if ($Name -like "*.tmp") { return }
    if ($Name -like "Unconfirmed *") { return }

    try {
        $Size1 = (Get-Item -LiteralPath $File).Length
        Start-Sleep -Seconds 2

        if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
            return
        }

        $Size2 = (Get-Item -LiteralPath $File).Length
    }
    catch {
        return
    }

    if ($Size1 -ne $Size2) {
        return
    }

    $Extension = [System.IO.Path]::GetExtension($Name).TrimStart('.').ToLower()
    $Folder = Get-Folder $Extension

    $DestinationFolder = Join-Path $Downloads $Folder

    if (-not (Test-Path -LiteralPath $DestinationFolder)) {
        New-Item -ItemType Directory -Path $DestinationFolder | Out-Null
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
        Move-Item -LiteralPath $File -Destination $Destination
    }
    catch {
    }
}

Get-ChildItem -LiteralPath $Downloads -File | ForEach-Object {
    Organize-File $_.FullName
}

$Watcher = New-Object System.IO.FileSystemWatcher
$Watcher.Path = $Downloads
$Watcher.Filter = "*"
$Watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName
$Watcher.IncludeSubdirectories = $false
$Watcher.EnableRaisingEvents = $true

Register-ObjectEvent -InputObject $Watcher -EventName Created -Action {
    Organize-File $Event.SourceEventArgs.FullPath
} | Out-Null

while ($true) {
    Wait-Event -Timeout 5 | Out-Null
}
