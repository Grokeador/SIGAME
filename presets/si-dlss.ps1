# SI DLSS - NVIDIA RTX, every DLSS game (driver level) - by SI NEWS, MIT.
# The NVIDIA driver keeps hidden DLSS overrides in its profile database (DRS). This preset writes them in the GLOBAL
# profile, so every DLSS 2+ game whose own driver profile does not set them gets:
#   - DLSS Super Resolution, Ray Reconstruction and Frame Generation swapped for the LATEST version the driver has
#     installed (DLL override 0x10E41E01 / 0x10E41E02 / 0x10E41E03 = 1);
#   - the model preset picked for YOUR card (Forced Model Preset Profile 0x00634291 = Custom, Forced Preset Letter
#     0x10E41DF3). NVIDIA's DLSS Programming Guide (SDK 310.5.0+, section 3.12): preset M = "similar image quality
#     improvements as Preset L but closer in speed to Presets J, K", "peak performant on RTX 40 series GPUs and
#     above"; preset K = "less expensive performance wise". So RTX 40 and newer get M, RTX 20/30 get K.
# Setting ids and values: NVIDIA Profile Inspector's CustomSettingNames.xml (github.com/Orbmu2k/nvidiaProfileInspector,
# MIT). The NvAPI calls and struct layout follow its NvapiDrsWrapper.cs. Nothing is downloaded, no game file is touched.
# The previous values are saved first (si-dlss.sigame.bak.json); -Undo puts them back. Needs admin (SIGAME has it).
param(
    [switch]$Undo,
    [string]$BackupPath = (Join-Path $env:LOCALAPPDATA 'SIGAME\si-dlss.sigame.bak.json'),
    [string]$MockStore = '',     # test only: a text file that stands in for the driver ("id value own" per line)
    [string]$MockGpu = ''        # test only: GPU name to use instead of the real one
)

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

public static class SIDrs
{
    [StructLayout(LayoutKind.Sequential, Pack = 8, CharSet = CharSet.Unicode, Size = 4100)]
    public struct Union { [MarshalAs(UnmanagedType.ByValArray, SizeConst = 4100)] public byte[] raw; }

    [StructLayout(LayoutKind.Sequential, Pack = 8, CharSet = CharSet.Unicode)]
    public struct Setting
    {
        public uint version;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 2048)] public string name;
        public uint id;
        public int type;              // 0 = DWORD
        public int location;          // 0 = set in this profile
        public uint isCurrentPredefined;
        public uint isPredefinedValid;
        public Union predefined;
        public Union current;
    }

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate IntPtr QI(uint id);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int F0();
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int FSess(ref IntPtr h);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int F1(IntPtr h);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int FProf(IntPtr h, ref IntPtr p);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int FSet(IntPtr h, IntPtr p, ref Setting s, uint x, uint y);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int FGet(IntPtr h, IntPtr p, uint id, ref Setting s, ref uint x);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int FId(IntPtr h, IntPtr p, uint id);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int FVer(ref uint v, StringBuilder branch);

    [DllImport("kernel32.dll", CharSet = CharSet.Ansi)] static extern IntPtr LoadLibrary(string n);
    [DllImport("kernel32.dll", CharSet = CharSet.Ansi)] static extern IntPtr GetProcAddress(IntPtr m, string n);

    public const int NOT_FOUND = -160;
    static QI qi; static FSess createSession; static F1 destroy, load, save;
    static FProf globalProfile; static FSet set; static FGet get; static FId restore, del; static FVer ver;
    static IntPtr session, profile;
    static Dictionary<uint, uint[]> mock;     // id -> { value, own }
    static string mockPath;

    public static uint SettingVersion { get { return (uint)Marshal.SizeOf(typeof(Setting)) | (1u << 16); } }

    static T D<T>(uint id, uint fallback) where T : class
    {
        IntPtr p = qi(id);
        if (p == IntPtr.Zero && fallback != 0) p = qi(fallback);
        if (p == IntPtr.Zero) return null;
        return Marshal.GetDelegateForFunctionPointer(p, typeof(T)) as T;
    }

    // 0 = ok; otherwise the NvAPI status (-2 = no NVIDIA driver library, -3 = a DRS function is missing).
    public static int Open(string mockFile)
    {
        if (!string.IsNullOrEmpty(mockFile))
        {
            mockPath = mockFile; mock = new Dictionary<uint, uint[]>();
            if (File.Exists(mockFile))
                foreach (string l in File.ReadAllLines(mockFile))
                {
                    string[] a = l.Split(' ');
                    if (a.Length == 3) mock[Convert.ToUInt32(a[0], 16)] = new uint[] { Convert.ToUInt32(a[1], 16), uint.Parse(a[2]) };
                }
            return 0;
        }
        IntPtr lib = LoadLibrary(IntPtr.Size == 8 ? "nvapi64.dll" : "nvapi.dll");
        if (lib == IntPtr.Zero) return -2;
        IntPtr q = GetProcAddress(lib, "nvapi_QueryInterface");
        if (q == IntPtr.Zero) return -2;
        qi = (QI)Marshal.GetDelegateForFunctionPointer(q, typeof(QI));
        F0 init = D<F0>(0x0150E828, 0);
        createSession = D<FSess>(0x0694D52E, 0); destroy = D<F1>(0xDAD9CFF8, 0);
        load = D<F1>(0x375DBD6B, 0); save = D<F1>(0xFCBC7E14, 0);
        globalProfile = D<FProf>(0x617BFF9F, 0);
        set = D<FSet>(0x8A2CF5F5, 0x577DD202); get = D<FGet>(0xEA99498D, 0x73BF8338);
        del = D<FId>(0xD20D29DF, 0xE4A26362); restore = D<FId>(0x7DD5B261, 0x53F0381E);
        ver = D<FVer>(0x2926AAAD, 0);
        if (init == null || createSession == null || load == null || save == null || globalProfile == null ||
            set == null || get == null || del == null || restore == null) return -3;
        int r = init(); if (r != 0) return r;
        r = createSession(ref session); if (r != 0) return r;
        r = load(session); if (r != 0) return r;
        return globalProfile(session, ref profile);
    }

    public static string Driver()
    {
        if (mock != null || ver == null) return "";
        uint v = 0; StringBuilder b = new StringBuilder(64);
        if (ver(ref v, b) != 0) return "";
        return (v / 100) + "." + (v % 100).ToString("00");
    }

    static Setting Blank(uint id)
    {
        Setting s = new Setting();
        s.version = SettingVersion; s.name = ""; s.id = id;
        s.predefined.raw = new byte[4100]; s.current.raw = new byte[4100];
        return s;
    }

    // Returns 0 and value/own (own = 1 when the value is set by hand in the global profile), or NOT_FOUND.
    public static int Get(uint id, out uint value, out uint own)
    {
        value = 0; own = 0;
        if (mock != null)
        {
            if (!mock.ContainsKey(id)) return NOT_FOUND;
            value = mock[id][0]; own = mock[id][1]; return 0;
        }
        Setting s = Blank(id); uint x = 0;
        int r = get(session, profile, id, ref s, ref x);
        if (r != 0) return r;
        value = BitConverter.ToUInt32(s.current.raw, 0);
        own = (s.location == 0 && s.isCurrentPredefined == 0) ? 1u : 0u;
        return 0;
    }

    public static int Set(uint id, uint value)
    {
        if (mock != null) { mock[id] = new uint[] { value, 1 }; return 0; }
        Setting s = Blank(id);
        s.type = 0; s.location = 0;
        Buffer.BlockCopy(BitConverter.GetBytes(value), 0, s.current.raw, 0, 4);
        return set(session, profile, ref s, 0, 0);
    }

    // Back to the driver's own value: restore the predefined default, else drop our setting.
    public static int Reset(uint id)
    {
        if (mock != null) { mock.Remove(id); return 0; }
        int r = restore(session, profile, id);
        if (r != 0) r = del(session, profile, id);
        return (r == NOT_FOUND) ? 0 : r;
    }

    public static int Commit()
    {
        if (mock != null)
        {
            List<string> lines = new List<string>();
            foreach (KeyValuePair<uint, uint[]> kv in mock)
                lines.Add(string.Format("0x{0:X8} 0x{1:X} {2}", kv.Key, kv.Value[0], kv.Value[1]));
            File.WriteAllLines(mockPath, lines.ToArray());
            return 0;
        }
        return save(session);
    }

    public static void Close() { if (mock == null && session != IntPtr.Zero) destroy(session); }
}
'@

function Write-Line([string]$s) { Write-Output $s }
function Get-Hex([uint32]$v) { '0x{0:X8}' -f $v }

# PowerShell note: an [ordered] dictionary indexed with an [int] reads by POSITION, so these are plain hashtables.
$names = @{
    0x10E41E01 = 'DLSS Super Resolution: latest DLL the driver has'
    0x10E41E02 = 'DLSS Ray Reconstruction: latest DLL the driver has'
    0x10E41E03 = 'DLSS Frame Generation: latest DLL the driver has'
    0x00634291 = 'DLSS model preset profile: custom'
    0x10E41DF3 = 'DLSS model preset'
}
$order = @(0x10E41E01, 0x10E41E02, 0x10E41E03, 0x00634291, 0x10E41DF3)

# --- Undo: put every value back from the backup ---
if ($Undo) {
    if (-not (Test-Path -LiteralPath $BackupPath)) { Write-Line '[FAIL] No backup si-dlss.sigame.bak.json to restore.'; exit 3 }
    $bak = Get-Content -LiteralPath $BackupPath -Raw | ConvertFrom-Json
    $r = [SIDrs]::Open($MockStore)
    if ($r -ne 0) { Write-Line "[FAIL] NVIDIA driver settings not reachable (NvAPI $r)."; exit 5 }
    $bad = 0
    foreach ($b in @($bak.Settings)) {
        $id = [uint32]$b.Id
        $r = if ($b.Own) { [SIDrs]::Set($id, [uint32]$b.Value) } else { [SIDrs]::Reset($id) }
        if ($r -eq 0) { Write-Line "[SET]  $(($names[[int]$id] -split ':')[0]): back to $(if ($b.Own) { Get-Hex $b.Value } else { 'driver default' })" }
        else { Write-Line "[FAIL] $(Get-Hex $id): NvAPI $r"; $bad++ }
    }
    $r = [SIDrs]::Commit(); [SIDrs]::Close()
    if ($r -ne 0) { Write-Line "[FAIL] The driver did not save (NvAPI $r). Run SIGAME as administrator."; exit 6 }
    if ($bad) { exit 5 }
    Move-Item -LiteralPath $BackupPath -Destination "$BackupPath.undone" -Force
    Write-Line '[OK]   DLSS driver settings restored. Restart your games.'
    exit 0
}

# --- Your GPU: RTX only, preset by generation ---
$gpuName = $MockGpu
if (-not $gpuName) {
    $gpuName = (@(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'NVIDIA' }) | Select-Object -First 1).Name
}
if ($gpuName -notmatch 'RTX\s*(\d{2})\d{2}') {
    Write-Line "[FAIL] DLSS needs an NVIDIA GeForce RTX card$(if ($gpuName) { " (found: $gpuName)" })."
    exit 2
}
$gen = [int]$Matches[1]
if ($gen -ge 40) { $preset = 0x0D; $letter = 'M' } else { $preset = 0x0B; $letter = 'K' }
Write-Line "[PC]   $gpuName -> preset $letter"

$want = @{ 0x10E41E01 = 1; 0x10E41E02 = 1; 0x10E41E03 = 1; 0x00634291 = 2; 0x10E41DF3 = $preset }

$r = [SIDrs]::Open($MockStore)
if ($r -eq -2) { Write-Line '[FAIL] NVIDIA driver not found: install the GeForce driver, then apply again.'; exit 2 }
if ($r -ne 0) { Write-Line "[FAIL] NVIDIA driver settings not reachable (NvAPI $r). Update the GeForce driver."; exit 5 }
$drv = [SIDrs]::Driver()
if ($drv) { Write-Line "[PC]   GeForce driver $drv" }

# --- Backup first (the first one is kept: applying twice never loses your original values) ---
if (-not (Test-Path -LiteralPath $BackupPath)) {
    $saved = foreach ($id in $order) {
        $v = [uint32]0; $own = [uint32]0
        $g = [SIDrs]::Get([uint32]$id, [ref]$v, [ref]$own)
        [pscustomobject]@{ Id = [uint32]$id; Value = $v; Own = ($g -eq 0 -and $own -eq 1) }
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $BackupPath) | Out-Null
    [pscustomobject]@{ Preset = 'si-dlss'; Saved = [datetime]::Now.ToString('s'); Settings = @($saved) } |
        ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $BackupPath -Encoding UTF8
}

$ok = 0
foreach ($id in $order) {
    $r = [SIDrs]::Set([uint32]$id, [uint32]$want[$id])
    $label = $names[[int]$id]; if ($id -eq 0x10E41DF3) { $label += " $letter" }
    if ($r -eq 0) { Write-Line "[SET]  $label"; $ok++ } else { Write-Line "[SKIP] $label (this driver says NvAPI $r)" }
}
$r = [SIDrs]::Commit(); [SIDrs]::Close()
if ($r -eq -137) { Write-Line '[FAIL] The driver needs administrator rights: run SIGAME as administrator.'; exit 6 }
if ($r -ne 0) { Write-Line "[FAIL] The driver did not save (NvAPI $r)."; exit 5 }
if ($ok -eq 0) { Write-Line '[FAIL] This driver accepted none of the DLSS overrides: update the GeForce driver.'; exit 5 }
Write-Line "[OK]   $ok DLSS overrides saved in the driver. Restart your games: every DLSS game picks them up at launch."
exit 0
