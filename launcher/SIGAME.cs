// SIGAME.exe - a small launcher: it only starts SI-GAME-AUTO.ps1 from its own folder
// (the same command as SI-GAME-AUTO.bat). Built with the .NET Framework compiler of
// Windows, see launcher/build.ps1. Needed by winget, which installs .exe files only.
// Arguments are passed to the script (-ListPresets, -Preset "...", -UndoPreset "...",
// -Silent, -Minimized); with arguments the PowerShell window stays visible.
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

[assembly: AssemblyTitle("SIGAME")]
[assembly: AssemblyProduct("SIGAME")]
[assembly: AssemblyDescription("Starts SI-GAME-AUTO.ps1 (github.com/Grokeador/SIGAME)")]
[assembly: AssemblyCompany("SI NEWS")]
[assembly: AssemblyCopyright("MIT License, Copyright (c) 2026 SI NEWS")]
[assembly: AssemblyVersion("2026.11.18.11")]
[assembly: AssemblyFileVersion("2026.11.18.11")]

static class SIGameLauncher
{
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern IntPtr CreateFileW(string name, uint access, uint share, IntPtr sec, uint mode, uint flags, IntPtr template);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern uint GetFinalPathNameByHandleW(IntPtr h, StringBuilder buf, uint size, uint flags);
    [DllImport("kernel32.dll")]
    static extern bool CloseHandle(IntPtr h);

    // winget starts a portable app through a link in WinGet\Links: the script is next to the real file
    static string RealPath(string path)
    {
        IntPtr h = CreateFileW(path, 0, 7, IntPtr.Zero, 3, 0x02000000, IntPtr.Zero);
        if (h == new IntPtr(-1)) return path;
        try
        {
            StringBuilder sb = new StringBuilder(1024);
            uint n = GetFinalPathNameByHandleW(h, sb, (uint)sb.Capacity, 0);
            if (n == 0 || n >= sb.Capacity) return path;
            string p = sb.ToString();
            if (p.StartsWith(@"\\?\UNC\", StringComparison.Ordinal)) p = @"\\" + p.Substring(8);
            else if (p.StartsWith(@"\\?\", StringComparison.Ordinal)) p = p.Substring(4);
            return p;
        }
        finally { CloseHandle(h); }
    }

    static string Quote(string a)
    {
        if (a.Length > 0 && a.IndexOfAny(new char[] { ' ', '\t', '"' }) < 0) return a;
        return "\"" + a.Replace("\"", "\\\"") + "\"";
    }

    [STAThread]
    static int Main(string[] args)
    {
        string self = Assembly.GetExecutingAssembly().Location;
        string dir = Path.GetDirectoryName(RealPath(self));
        string script = Path.Combine(dir, "SI-GAME-AUTO.ps1");
        if (!File.Exists(script))
        {
            dir = Path.GetDirectoryName(self);
            script = Path.Combine(dir, "SI-GAME-AUTO.ps1");
        }
        if (!File.Exists(script))
        {
            MessageBox.Show("SI-GAME-AUTO.ps1 is missing next to SIGAME.exe:\n" + dir +
                "\n\nDownload SIGAME again: https://github.com/Grokeador/SIGAME", "SIGAME",
                MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return 2;
        }
        StringBuilder extra = new StringBuilder();
        foreach (string a in args) extra.Append(' ').Append(Quote(a));
        bool cli = args.Length > 0;
        string ps = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), @"WindowsPowerShell\v1.0\powershell.exe");
        ProcessStartInfo psi = new ProcessStartInfo(File.Exists(ps) ? ps : "powershell.exe");
        psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -STA " + (cli ? "" : "-WindowStyle Hidden ") +
            "-File " + Quote(script) + extra.ToString();
        psi.WorkingDirectory = dir;
        psi.UseShellExecute = false;
        psi.CreateNoWindow = !cli;
        try
        {
            using (Process p = Process.Start(psi))
            {
                if (!cli) return 0;
                p.WaitForExit();
                return p.ExitCode;
            }
        }
        catch (Exception e)
        {
            MessageBox.Show("SIGAME could not start PowerShell:\n" + e.Message, "SIGAME", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }
}
