using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

class Program
{
    static readonly string Downloads =
        Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
            "Downloads"
        );

    static readonly Dictionary<string, string[]> Folders = new()
    {
        ["Images"] = new[] { "jpg","jpeg","png","gif","webp","bmp","svg","tif","tiff","heic","heif","avif","raw","cr2","cr3","nef","arw","dng" },
        ["Videos"] = new[] { "mp4","mkv","avi","mov","webm","flv","wmv","m4v","mpeg","mpg","ts","mts","m2ts","3gp" },
        ["Audio"] = new[] { "mp3","wav","flac","ogg","opus","aac","m4a","wma","aiff","ape" },
        ["Documents"] = new[] { "pdf","doc","docx","txt","odt","rtf","epub","mobi","azw","azw3" },
        ["Spreadsheets"] = new[] { "xls","xlsx","csv","ods","tsv" },
        ["Presentations"] = new[] { "ppt","pptx","odp" },
        ["Archives"] = new[] { "zip","rar","7z","tar","gz","bz2","xz","zst","tgz" },
        ["Installers"] = new[] { "exe","msi","msix","msixbundle" },
        ["Disk-Images"] = new[] { "iso","img","vhd","vhdx" },
        ["Code"] = new[] { "py","ps1","sh","bash","js","ts","html","css","c","cpp","h","hpp","java","rs","go","json","xml","yaml","yml","toml","sql" },
        ["Subtitles"] = new[] { "srt","ass","ssa","vtt","sub" },
        ["Fonts"] = new[] { "ttf","otf","woff","woff2" }
    };

    [DllImport("user32.dll")]
    static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern int GetClassName(
        IntPtr hWnd,
        StringBuilder lpClassName,
        int nMaxCount
    );

    [DllImport("user32.dll")]
    static extern IntPtr GetParent(IntPtr hWnd);

    [DllImport("user32.dll")]
    static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    static extern void GetWindowThreadProcessId(
        IntPtr hWnd,
        out uint processId
    );

    [DllImport("user32.dll")]
    static extern bool EnumChildWindows(
        IntPtr hWndParent,
        EnumWindowsProc lpEnumFunc,
        IntPtr lParam
    );

    delegate bool EnumWindowsProc(
        IntPtr hWnd,
        IntPtr lParam
    );

    static NotifyIcon? trayIcon;
    static Icon? trayIconImage;
    static CancellationTokenSource? cancellation;

    static string? GetClass(IntPtr hwnd)
    {
        StringBuilder sb = new(256);

        if (GetClassName(hwnd, sb, sb.Capacity) == 0)
            return null;

        return sb.ToString();
    }

    static bool IsExplorerWindow(IntPtr hwnd)
    {
        GetWindowThreadProcessId(hwnd, out uint pid);

        if (pid == 0)
            return false;

        try
        {
            using Process process = Process.GetProcessById((int)pid);

            return process.ProcessName.Equals(
                "explorer",
                StringComparison.OrdinalIgnoreCase
            );
        }
        catch
        {
            return false;
        }
    }

    static bool TestExplorerRenameMode()
    {
        IntPtr foreground = GetForegroundWindow();

        if (foreground == IntPtr.Zero)
            return false;

        IntPtr root = foreground;

        while (true)
        {
            IntPtr parent = GetParent(root);

            if (parent == IntPtr.Zero)
                break;

            root = parent;
        }

        if (!IsExplorerWindow(root))
            return false;

        bool renameEditFound = false;

        EnumChildWindows(
            root,
            (hwnd, lParam) =>
            {
                if (!IsWindowVisible(hwnd))
                    return true;

                string? className = GetClass(hwnd);

                if (className == null)
                    return true;

                if (
                    className.Equals("Edit", StringComparison.OrdinalIgnoreCase) ||
                    className.Equals("RichEdit20W", StringComparison.OrdinalIgnoreCase) ||
                    className.Equals("RichEdit50W", StringComparison.OrdinalIgnoreCase)
                )
                {
                    renameEditFound = true;
                    return false;
                }

                return true;
            },
            IntPtr.Zero
        );

        return renameEditFound;
    }

    static string GetFolder(string extension)
    {
        foreach (var pair in Folders)
        {
            foreach (string ext in pair.Value)
            {
                if (ext.Equals(
                    extension,
                    StringComparison.OrdinalIgnoreCase
                ))
                {
                    return pair.Key;
                }
            }
        }

        return "Other";
    }

    static bool TestFileAvailable(string file)
    {
        try
        {
            using FileStream stream = new(
                file,
                FileMode.Open,
                FileAccess.ReadWrite,
                FileShare.None
            );

            return true;
        }
        catch
        {
            return false;
        }
    }

    static void OrganizeFile(string file)
    {
        if (!File.Exists(file))
            return;

        string name;

        try
        {
            name = Path.GetFileName(file);
        }
        catch
        {
            return;
        }

        if (name.StartsWith(".org.chromium.", StringComparison.OrdinalIgnoreCase))
            return;

        if (name.EndsWith(".crdownload", StringComparison.OrdinalIgnoreCase))
            return;

        if (name.EndsWith(".part", StringComparison.OrdinalIgnoreCase))
            return;

        if (name.EndsWith(".tmp", StringComparison.OrdinalIgnoreCase))
            return;

        if (name.StartsWith("Unconfirmed ", StringComparison.OrdinalIgnoreCase))
            return;

        if (TestExplorerRenameMode())
            return;

        if (!TestFileAvailable(file))
            return;

        string extension =
            Path.GetExtension(name)
                .TrimStart('.')
                .ToLowerInvariant();

        string folder = GetFolder(extension);

        string destinationFolder =
            Path.Combine(Downloads, folder);

        try
        {
            Directory.CreateDirectory(destinationFolder);
        }
        catch
        {
            return;
        }

        string destination =
            Path.Combine(destinationFolder, name);

        if (File.Exists(destination))
        {
            string baseName =
                Path.GetFileNameWithoutExtension(name);

            string extensionWithDot =
                Path.GetExtension(name);

            int counter = 1;

            do
            {
                destination =
                    Path.Combine(
                        destinationFolder,
                        $"{baseName}_{counter}{extensionWithDot}"
                    );

                counter++;
            }
            while (File.Exists(destination));
        }

        try
        {
            File.Move(file, destination);
        }
        catch
        {
        }
    }

    static void OrganizerLoop(CancellationToken token)
    {
        while (!token.IsCancellationRequested)
        {
            try
            {
                if (Directory.Exists(Downloads))
                {
                    foreach (string file in Directory.GetFiles(Downloads))
                    {
                        if (token.IsCancellationRequested)
                            return;

                        OrganizeFile(file);
                    }
                }
            }
            catch
            {
            }

            try
            {
                token.WaitHandle.WaitOne(200);
            }
            catch
            {
                return;
            }
        }
    }

    static void SetupTray()
    {
        string iconPath =
            Path.Combine(
                AppContext.BaseDirectory,
                "DownloadOrganizer.png"
            );

        trayIcon = new NotifyIcon
        {
            Text = "Download Organizer",
            Visible = true
        };

        if (File.Exists(iconPath))
        {
            using Bitmap bitmap = new(iconPath);

            trayIconImage = Icon.FromHandle(
                bitmap.GetHicon()
            );

            trayIcon.Icon = trayIconImage;
        }

        ContextMenuStrip menu = new();

        ToolStripMenuItem openDownloads =
            new("Open Downloads");

        openDownloads.Click += (_, _) =>
        {
            Process.Start(
                new ProcessStartInfo
                {
                    FileName = Downloads,
                    UseShellExecute = true
                }
            );
        };

        ToolStripMenuItem exit =
            new("Exit");

        exit.Click += (_, _) =>
        {
            cancellation?.Cancel();

            if (trayIcon != null)
            {
                trayIcon.Visible = false;
                trayIcon.Dispose();
                trayIcon = null;
            }

            trayIconImage?.Dispose();
            trayIconImage = null;

            Application.ExitThread();
        };

        menu.Items.Add(openDownloads);
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add(exit);

        trayIcon.ContextMenuStrip = menu;
    }

    static void Main()
    {
        ApplicationConfiguration.Initialize();

        cancellation = new CancellationTokenSource();

        SetupTray();

        Task.Run(
            () => OrganizerLoop(cancellation.Token),
            cancellation.Token
        );

        Application.Run();

        cancellation.Cancel();
        cancellation.Dispose();
    }
}