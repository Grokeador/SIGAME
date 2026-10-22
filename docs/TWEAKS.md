# SIGAME - NOTES

Every tweak of `SI-GAME.ps1`, the exact registry keys and services it touches, and
what its **Undo** does.

---

## Fix round 1

The first run on the owner's PC (Windows 10 22H2, PowerShell 5.1, 4 GB RAM) never
showed a window. Four problems were reported and the whole file was then read again
for the same kind of fault.

| # | What was wrong | Why | Fix |
|---|---|---|---|
| 1 | `Unable to find type [System.Windows.ColumnDefinition]` | The WPF type is `System.Windows.Controls.ColumnDefinition`. `System.Windows.ColumnDefinition` is a WinUI/UWP type and does not exist in WPF for .NET Framework, so the row builder died and the window never opened. | Corrected namespace. |
| 2 | `[WARN] [UI] The logo could not be loaded: The property 'Uri' cannot be found on this object` | `BitmapImage.Uri` only exists on the **WinRT** `BitmapImage`. The WPF one has `UriSource` (type `Uri`). The path also had to be made absolute before it was turned into a `Uri`. | `UriSource` + `UriKind.Absolute` + `Resolve-Path`. |
| 3 | Log said `[OK] [RestorePoint] System Restore point created.` although the script was not elevated | The old code logged `[OK]` as soon as `Checkpoint-Computer` did not throw, and never checked the rights nor looked at the list of restore points. | The rights are checked first, the restore point is verified in `Get-ComputerRestorePoint` before `[OK]` is written, and a restore point that cannot be made is reported as an error. The 24-hour limit of Windows is now understood and reported as "already there". |
| 4 | More than 35 s before the window appeared | The window was only built *after* the restore point, the WMI user lookup and every single state had been read. | The window is built and shown first (about 1 s). The slow work runs after the first paint, with the window pumped between the rows, so it stays alive and fills in row by row. |

Other faults of the same kind found while reading the whole file:

* **The restore point was made before the window was opened**, so the window had
  to wait for it. It is now made after the window is up, and the Apply/Undo
  buttons stay off until it is done, so nothing can be changed before it.
* **`Get-WindowsOptionalFeature -Online` was called on every state refresh** (DISM,
  several seconds each time). It is now asked once per session and cached, and on
  Windows 10 it is not asked at all, because Recall only exists on Windows 11 24H2
  (build 26100) and newer.
* **`Get-AppxPackage -AllUsers` was called on every state refresh.** The cheap check
  for the logged-on user is done first, the slow one only if that finds nothing, and
  the answer is cached.
* **`powercfg /list` and `powercfg /getactivescheme` were two processes.** One
  `powercfg /list` shows the active plan as well (it is the one with the star).
* **The DeviceGuard WMI class was asked even when VBS is clearly off.** It is only
  asked now when the registry says there is something to ask about.
* **`Get-CimInstance Win32_UserAccount` asked for every account on the machine.**
  It now asks for the one account it needs.
* **Ultimate Performance made a second copy of the plan** when the plan was already
  installed. It now activates the existing one, and the undo only deletes a plan
  that SI GAME really created.
* **An error that killed the script was invisible.** `Invoke-SIMain` and the whole
  run are now wrapped, so a failure is written to the log *and* shown in a message
  box with the path of the log file.

Nothing in the file uses PowerShell 7 syntax: no `??`, no `?.`, no ternary, no
`-AsHashtable`, no `&&`/`||`, no `Join-Path` with more than two parts. The only
.NET type that was wrong is the one in row 1 above; every other `[System.Windows.*]`
type in the file exists in WPF for .NET Framework.

**Still open:** nothing in this round was executed, the changes were made by reading
the code. The first real run should still be on a throwaway VM, and the
`GameDVR_FSEBehaviorMode = 2` question of section 2.3 is still open.

---

## Fix round 2

The second owner test (Windows 10 22H2, PowerShell 5.1, 4 GB RAM, started from the
.bat) still took 8-12 s to open the window, made no System Restore point and wrote
no JSON backup. The log of that run ended with:

```
[ERROR] [Start] The start-up work failed: Multiple ambiguous overloads found for op_Subtraction and the argument count: 2.
```

| # | What was wrong | Why | Fix |
|---|---|---|---|
| 1 | `Multiple ambiguous overloads found for op_Subtraction` | The age of a restore point was computed with `(Get-Date) - $rp.CreationTime`. `CreationTime` of `SystemRestore` is a **string** (`20261020220411000.000000-000`), and a string converts both to `DateTime` and to `TimeSpan`, so PowerShell cannot pick the overload and throws. | The date is parsed first (`ConvertTo-SIDateTime`, `yyyyMMddHHmmss` and the usual formats) and the age is computed with `[datetime]::Now.Subtract($stamp)`, a method call, so no operator is involved any more. `Get-SIRestorePointAge` and `Get-SIRestorePointTimeText` show the age and the date of the last restore point. |
| 2 | The restore point was never made, and no error was shown | `Clear-SICache` returned the `bool` of `Hashtable.Remove()`, so the return value of `New-SIRestorePoint` was an **array**, and `if (-not $restorePoint)` was never true. | `Clear-SICache` throws the result away (`$null = $script:SICache.Remove($key)`), and `New-SIRestorePoint` now returns a table with `Status` and `Message` instead of `$true`/`$false`, so the failure has a reason that can be shown. |
| 3 | 13 s between "Windows build" and "Creating a System Restore point", window seen only after everything | The whole table of tweaks, the `DetectOption` registry reads, every state (`Get-AppxPackage -AllUsers`, WMI DeviceGuard), the restore point and the backup were all done before/around the window on the UI thread. | The window is now shown **first** (XAML only, about 1 s). The rows are built after the first paint, each one saying `loading ...`, and the slow work runs in a **background copy of the same script** (`-Worker`), started hidden, so the window never freezes. |
| 4 | No JSON backup at the start | The backup was only written when a tweak was applied. | The background copy writes the backup of the current values of **all** the tweaks (`SI-GAME-backup.json`) before it reads the states, and the header says `writing` / `written` / `failed + reason`. |
| 5 | Apply and GAMING were usable before the restore point | Nothing tied the buttons to the restore point. | **Apply**, **Apply checked** and **GAMING** stay disabled until the restore point and the backup are both done, or have failed with a visible reason. |

**How the window and the background copy talk to each other.** The window writes a
small JSON request file in `%TEMP%` and starts
`powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "SI-GAME.ps1" -Worker -WorkerMode prepare -WorkerRequest ... -WorkerResult ...`
hidden. The copy does the work and writes a JSON result file (written to a `.tmp`
file first and then moved, so the window never reads half a file). Every 250 ms a
`DispatcherTimer` reads that file: the log lines of the copy are copied into
`SI-GAME.log`, the restore point and the backup statuses go to the header, and the
real state of every tweak replaces the `loading ...` of its row. The same copy is
used by the *Refresh states* and *Restore point* buttons (`-WorkerMode refresh` and
`-WorkerMode restorepoint`). The copy inherits the elevated token, so
`Checkpoint-Computer` keeps working.

**The same class of fault was looked for in the whole file.** The script was read
again for: operators applied to a value of an uncertain type (the same
`op_Subtraction` family), PowerShell 7 only syntax (`??`, `?.`, ternary,
`-AsHashtable`, `&&`/`||`), .NET types that do not exist in WPF for .NET Framework
(the two of *Fix round 1* were the only ones) and stray output that ends up in a
`return` value (the `Hashtable.Remove()` of row 2 was one, there are no others).
`Get-SITweakState`, `Get-SITweakRegistryEntries` and `New-SIOriginalRecord` now
take an `-OptionOverride`, so the background copy reads the same options as the
window.

Three more things were found while reading the new code again:

* **The state was read with the wrong option.** `Get-SITweakState` asked for the
  registry entries without the option it had just worked out, so a tweak with
  more than one choice was measured with the first choice. The option is now
  passed on.
* **The backup of a tweak and the change itself could use different options.**
  Apply now takes the option of the row once and uses it for both, so the
  backup always describes exactly what was changed.
* **A restore point that is too old is not a restore point.** The 24-hour limit
  of Windows is only accepted as an excuse when the restore point of SI GAME is
  less than 24 hours old. An older one is reported as a failure, with its date,
  because it does not protect the changes of this run.

If the background copy cannot be started at all, the window says so in the
header, the reason goes into the log and the buttons are enabled, so the window
never stays locked.

**The JSON backup now has two parts.** `SI-GAME-backup.json` keeps its `Tweaks`
part: the undo list, which is only filled when a tweak is applied, exactly as
before, so *Undo all* never touches a tweak that SI GAME did not change. The new
`Snapshot` part holds the current values of **all** the tweaks, read at the
start, and `SnapshotAt` says when. The two parts never fight each other: the
snapshot is written fresh every run and the undo list is left alone. An undo
entry that already exists also keeps the values from before the **first**
change, so a tweak that is applied twice can still be put back exactly as it
was.

**Still open:** nothing in this round was executed either, the changes were made
by reading the code. The first real run should still be on a throwaway VM, and it
is worth watching the log for the new `Restore point:` and `Backup:` lines in the
header.

---

## Fix round 3

The third owner test (Windows 10 22H2, PowerShell 5.1, 4 GB RAM, started from the
`.bat`) showed the window only after **30.7 s**. The log of that run:

```
[22:34:11.351] [Start] SI GAME started, PowerShell 5.1.19041.7802.
[22:34:11.633] [Start] Working folder: D:\SI NEWS\si-game-race\B_free
[22:34:11.724] [Start] Administrator rights: True
[22:34:11.798] [Start] Signed in as: DESKTOP-QKS76FG\Caixa
[22:34:12.030] [Start] Windows build: 19045
[22:34:27.424] [Start] The background copy of SI GAME was started (prepare).   <-- 15 s later
[22:34:36.270] [RestorePoint] Creating a System Restore point ...
[22:35:03.305] [OK] [RestorePoint] System Restore point created (sequence 197, ...)
```

**Target of the owner: the window on the screen within 7 s.** The measured floor on
that PC is 5.1 s for an *empty* PowerShell 5.1 + WPF window, so only about 2 s
are left for everything SI GAME does itself.

| # | What was wrong | Why | Fix |
|---|---|---|---|
| 1 | **15 s between "Windows build" and the start of the background copy.** The window was built, the JSON backup was read, the 14 rows were created and the background copy was started - all of it before the window was painted. | Everything happened on the UI thread, and the UI thread is the thread that paints the window. While it was busy, the window stayed unpainted, so the owner saw nothing at all. | The window is painted **first**, with an empty list of tweaks, and the slow work starts **after** the first paint. `ContentRendered` is the trigger now, and the safety timer went from 250 ms to 2.5 s: a short timer won the race against the first paint and built the rows while the window was still empty. |
| 2 | The rows were built in one block, so the window froze for seconds and the first paint had to measure and arrange 14 rows with wrapped text. | `TextWrapping = 'Wrap'` is the most expensive thing in a WPF list: every text is measured again and again. | The description and the source of a row are **not wrapped any more** (the full text stays in the tool tip), and the window is **pumped after every row**, so the rows appear one after the other and the window never freezes. |
| 3 | Four log lines were written before the window was opened. | Every log line is a file write, and every file write is on the way to the window (about 0.15 s each on that PC). | Only **one** line is written before the window. The version information is written after the window is on the screen, so the log says the same as before. |
| 4 | The JSON backup (37 KB) was read before the window was opened. | It is not needed to show a window. | It is read after the window is on the screen, together with the last lines of the log. |
| 5 | The three WPF assemblies were loaded with three `Add-Type` calls. | The first call pulls the other two in anyway, and every call costs time. | One `Add-Type` call loads all three. |
| 6 | Every row made four new brushes. | A new `BrushConverter` and a new brush for every row of every screen. | The frozen brushes are made once and then shared. |
| 7 | The background copy was started **after** the rows were built. | The System Restore point takes half a minute, so it should not wait for the rows. | The background copy is started **first** (the restore point begins right away) and the rows are built while it works. A state that arrives before its row exists is kept and put into the row as soon as the row is there. |
| 8 | `Initialize-SIUserHive` (the WMI query for the person at the machine) was **never called**, so the `HKCU:` remap that NOTES.md describes did not happen. | Dead code from an earlier round. | It is called in the **background copy** now (it is a slow WMI query) and the answer is handed to the window with the result file. The window does no WMI query of its own any more. |
| 9 | The laptop test (`Win32_Battery` + `Win32_ComputerSystem`) was done on the UI thread when the GAMING preset was pressed. | Two WMI queries, one to two seconds of frozen window. | The background copy does the test and the window uses the answer. |
| 10 | If the background copy died without writing anything, the buttons stayed grey **forever**. | The poll only looked at the result file. | The poll also looks at the background process. If it is gone and it never said "done", the reason goes into the log and into the header, and the buttons are switched on anyway. |
| 11 | `$script:SIBackup` was `$null` when the start-up work failed, so the first Apply ended in a null error. | The backup was read in one place only. | Apply, Undo and Undo all read the backup when it is not in memory, so a change is never made without a backup to undo it. |

**The log now measures the wait.** Two new lines, both measured from the start of
the PowerShell process (the `.bat` adds a fraction of a second on top):

```
[Start] SI GAME started, PowerShell 5.1.19041.7802, the script was loaded after 2.31 s.
[Start] The window is on screen after 5.86 s.
```

* **"the script was loaded after"** is the cost of PowerShell itself: starting
  the process, Defender reading the file, and the parser reading the 3 500 lines.
  Nothing can be done about it inside the file, except making the file smaller.
* **"the window is on screen after"** is the cost of SI GAME: the WPF window and
  the work that was on the way to it. This is the number that has to be small,
  and it is now only the WPF window itself.

**The same class of fault was looked for in the whole file.** The file was read
again for: slow work on the UI thread (WMI, DISM, AppX, `Get-ComputerRestorePoint`,
the service list), slow work before the window is painted, file writes on the way
to the window, PowerShell 7 only syntax (there is none: no `??`, no `?.`, no
ternary, no `-AsHashtable`, no `&&`/`||`), .NET types that do not exist in WPF
for .NET Framework, and operators on a value of an uncertain type (the
`op_Subtraction` family - every time is now computed with `Subtract()`).

The slow calls that are left are all inside the background copy or inside an
explicit Apply/Undo that the owner asked for: `Get-AppxPackage` (the Widgets and
Windows AI rows), `Get-AppxProvisionedPackage` (the undo of the Widgets),
`Disable-WindowsOptionalFeature` (Windows 11 only), `powercfg` (the Ultimate
Performance plan) and `Get-Service`. The window is pumped between the packages,
so it stays alive during them.

**Still open:** nothing in this round was executed either, the changes were made
by reading the code. If the new log says that the *loading of the script* is the
big part of the wait, the next lever is to split the file (a small launcher with
the window and a second file with the engine), which would break the "one file"
rule of the brief. The number to look at is the first line of the log.

* One file: `SI-GAME.ps1`. PowerShell 5.1, no installs, no internet, no modules.
* It self-elevates through UAC (`Start-Process -Verb RunAs`) and refuses to run
  without administrator rights.
* It creates a **System Restore point before the first change**
  (`Checkpoint-Computer`, description `SI GAME - before the first change`). If
  System Restore is off on the machine the script says so in a message box and
  carries on, because every change is also reversible through the JSON backup.
* Every row of the window shows the **real current state**, read from the
  registry and from the service list. Nothing is assumed.
* Every tweak has its own **Apply** and its own **Undo** button, plus
  *Apply checked* and *Undo all* in the toolbar. The **GAMING preset** button
  applies the gaming tweaks in one go.
* Before a tweak is applied, the original values are written to
  `SI-GAME-backup.json` next to the script. The undo is driven **only** by that
  file: original value, original type, whether the value existed at all, the
  original service startup type and whether the service was running.
* Right after the window opens, the same file also gets a `Snapshot` part: the
  current values of **all** the tweaks, read at that moment. It is a safety net
  for the whole machine, not only for the tweaks SI GAME changes. The `Tweaks`
  part (the undo list) is left alone by it.
* Every single change is appended to `SI-GAME.log` next to the script, in the
  same format as the on-screen log:
  `[2026-10-20 14:03:21.117] [OK] [Tweak] Applied: Game Mode`

Files that SI GAME creates next to itself:

| File | What it is |
|---|---|
| `SI-GAME.log` | the text log of every change |
| `SI-GAME-backup.json` | the original values, used by every Undo, plus the `Snapshot` of all the tweaks taken at the start |
| `SI-GAME-measures.json` | the PROVE IT measurements (before / after) with a timestamp, written by the Measure button |
| `logo.png` | the SI NEWS logo shown in the window (already in this folder) |

Registry paths are written the way the tweak table uses them. `HKCU:` is
**remapped** to `HKU:\<sid>` when SI GAME is elevated with the credentials of a
different account than the person sitting at the machine, so a per-user tweak
always lands on the profile of the logged-on user.

---

## Fix round 5

Owner, 21/10: *"make SI GAME as complete as possible"* - read `spec_round5.md` and
implement all of it, keep what works, no Myths box, the window fast and
responsive.

**What was added (only what the spec lists).**

| Area | What is there now |
|---|---|
| Network & downloads | TCP receive window auto-tuning read with `Get-NetTCPSetting` and offered back to "normal"; DNS benchmark (5 domains x 3 rounds, `-NoHostsFile -DnsOnly`) against the current DNS, Cloudflare 1.1.1.1, Google 8.8.8.8 and Quad9 9.9.9.9, one button sets the fastest on the active adapter and Undo puts the old DNS back; `NetworkThrottlingIndex = 0xFFFFFFFF`; optional 25 MB Cloudflare speed test, **never automatic**, result stored with a timestamp |
| FPS | `SystemResponsiveness = 10`; per-game GPU preference (`GpuPreference=2;` under `DirectX\UserGpuPreferences`); per-game fullscreen optimizations off (`~ DISABLEDXMAXIMIZEDWINDOWEDMODE` under `AppCompatFlags\Layers`); transparency effects off (`EnableTransparency = 0`) |
| Windows speed | startup apps manager reading the Run keys and the Startup folders with the state from `Explorer\StartupApproved` (the place Task Manager uses) - a checkbox per app, **never a deletion**; hibernation off (`powercfg /hibernate off`) with the GB of `hiberfil.sys` that would be freed, "not recommended on laptops" on a battery; clean temporary files, which shows the size first and says plainly that it cannot be undone |
| PROVE IT | one **Measure** button that records free RAM, startup apps on, DNS ms, last speed test Mbps, power plan and the HAGS / Game Mode / VBS state into `SI-GAME-measures.json` with a timestamp, shown as BEFORE -> AFTER |
| Screen | one big yellow **OPTIMIZE** button (applies every safe tweak for this PC in one go and answers "12 done, 2 not available"), the PROVE IT numbers before -> after, one big **UNDO ALL** always visible, and everything else inside an **Advanced** section that is closed by default. No Myths box, no long text on the screen - the source of each tweak is in its tooltip. |

Every new change writes the original value to the JSON backup first, so the
existing Undo works on them too. A tweak that cannot work on the running Windows
says **"not available"** instead of failing.

**The PowerShell 5.1 problems that were found and fixed.**

| # | What was wrong | Fix |
|---|---|---|
| 1 | `New-SIWindow` looked up `BtnUndoAll`, which does not exist in the code-built window, and called `.Add_Click()` on the result. `$null.Add_Click()` throws "You cannot call a method on a null-valued expression" **before the window is shown**, so on 5.1 the script could die on the way to the window. | Every button lookup is guarded (`if ($button) { ... }`). |
| 2 | `Save-SIToolUndo` was called **after** the registry write, so the "original" value it saved was the new one. Undo then wrote back what it had just changed. | The tool records the value **before** the write and keeps the first record; the three call sites (GPU preference, fullscreen optimizations, startup app) were moved. |
| 3 | The XAML fallback built an empty tweak list, because the rows were only created by the Advanced expander. | `Start-SISlowStart` builds the rows when there is no expander. |
| 4 | The DNS / speed / temp runs of the background copy used the **same request and result files** as the start-up run, and would have destroyed the start-up results. | Only one background copy at a time; the other runs wait in a queue and start one after the other. |
| 5 | `SystemResponsiveness` said "applied" at the Windows default of 20. | The state test is now `-eq 10`. |
| 6 | The startup app state was read from the wrong `StartupApproved` key (`Run32` for the 64-bit `Run` key), and the binary written was 8 bytes instead of the 12 bytes Windows 10 writes. | Correct key per Run key, and 12 bytes (`2` = on, `3` = off). |
| 7 | The Widgets tweak (the `TaskbarDa` "operação não autorizada" in the log) fails on Windows 10 22H2. | It is blocked by an availability test on builds below 22000 and reports "not available". |
| 8 | An ApplyScript that failed on a tweak without registry entries and without services was written into the log as a warning and the tweak stayed "applied". | It is now a real failure: error in the log, "was not applied" on the screen, and the backup entry is removed again. |

**The start-up time.** The measured times on the owner's PC were 11-19 s for the
window (4.8-6.3 s of it is PowerShell reading the file). Everything of round 5
was therefore kept **off the way to the window**: the rows and the tools are
built when the Advanced section is opened for the first time, the DNS, speed
and temp runs go to the background copy, and the measures are read after the
window is on the screen. The launcher (`AVVIA SI GAME.bat`) now loads the WPF
assemblies in a **background thread while PowerShell parses the script**, which
is the only way to overlap the two; if that fails the normal start is used. The
layout was changed so that the log grows and the Advanced section is not
expanded, so the window is not measured with everything on it.

**Still open:** nothing in this round was executed either - the owner said that
commands cannot be run - so the changes were made by reading the code. The
open-time numbers still have to be measured on the owner's PC: the log now says
"the script was loaded after X s" and "the window is on screen after Y s", and
those two lines are the ones to read. The 5.1 s floor on that machine is the
cost of an empty PowerShell 5.1 + WPF window, so what is left for SI GAME is
small.

---

## Fix round 6

Owner, 21/10: *"come miglioreresti SI GAME? hai tutti i permessi"* - read
`spec_round6.md` and implement all of it on top of round 5: GAME BOOST / GAME
OVER, the games of Steam and of Epic found by themselves, the honest limit of
the machine, the share card, the language of Windows, the line of trust and the
progress bar. Keep everything that works, keep the window fast and responsive.

**What was added (only what the spec lists).**

| Area | What is there now |
|---|---|
| GAME BOOST / GAME OVER | Two buttons next to OPTIMIZE. **GAME BOOST** closes **only** the programs the user has ticked once in the boost list (default: nothing is ticked), switches the power plan to Ultimate / High performance (desktops only, a laptop is left alone) and shows how much memory was freed ("+N MB RAM free", measured before and after). **GAME OVER** puts the power plan back and opens the programs that were closed. The ticks are remembered in `SI-GAME-boost.json`. The Discord overlay is never closed. |
| Your games | The games of Steam (`libraryfolders.vdf` + `appmanifest_*.acf`) and of Epic (`...\EpicGamesLauncher\Data\Manifests\*.item`) are found by themselves and shown with their icon. Per game two boxes: the fast video card (`GpuPreference=2;`) and the fullscreen optimizations off (`~ DISABLEDXMAXIMIZEDWINDOWEDMODE`) - the same values the Windows pages write. The file picker of round 5 stays as a backup. |
| The honest limit | ONE line, read from the real machine: CPU, video card (`Win32_VideoController`), RAM (`Win32_ComputerSystem`), the type of the system disk (`Get-PhysicalDisk` MediaType) and the free space. The rules, in this order: RAM under 8 GB, a hard disk as system disk, less than 15% free, only an integrated video card. No score, nothing made up. |
| Share card | **Save my result** writes a 1200x630 PNG (WPF `RenderTargetBitmap`) with the numbers BEFORE -> AFTER, the SI GAME / SI NEWS logo and "made with SI GAME - YouTube @SINEWS-q5x", next to the script as `SI-GAME-result.png`, and opens the folder. |
| Language | The texts of the window are in the language of Windows when it is one of en, pt-BR, es, it, de, fr (English otherwise). All the texts are in one table at the top of the script (`$script:SIText`), so another language is only one more block. |
| The line of trust | The footer says "Open source. Every change can be undone. Restore point created: <time>", with the real time of the restore point - or that it is still on its way. |
| The progress bar | A bar under the buttons that fills during OPTIMIZE and during GAME BOOST with the name of the step that is running, and ends in a yellow "DONE". No sound. |

**The PowerShell 5.1 problems that were found and fixed.**

| # | What was wrong | Fix |
|---|---|---|
| 1 | `Invoke-SIElevate` built its command line with the `-f` operator on a string that contains the **braces of a script block**. The `-f` operator reads them as a format item and throws `FormatException: "Input string was not in a correct format."` - **before** the window is opened and outside every try/catch, so the script died on the way to the window and the .bat started it a second time in vain. This was the reason why SI GAME did not open. | The command line is built with `+` and the whole block of the elevation is inside a try/catch: if the request for administrator rights fails, the window still opens (without rights) and the reason goes to the log. |
| 2 | The same class of bug elsewhere: `BtnRefresh`, `BtnRestorePoint` and `BtnOpenLog` were looked up and `.Add_Click()` was called on the result without a check. A missing button throws "You cannot call a method on a null-valued expression" before the window is shown. | Every lookup is guarded, and the new buttons of round 6 are looked up the same way. |
| 3 | `HeaderSystem`, `BackupInfo` and `FooterText` were read without a check, so the XAML fallback (which has no such element) could stop the start. | Guarded. |
| 4 | The French texts had an accent (`Préréglage`). The script has no BOM, so PowerShell 5.1 reads it as ANSI and the accent would come out as two strange letters. | All the texts are pure ASCII (`Prereglage`). The whole script is ASCII now. |
| 5 | The XAML fallback had no OPTIMIZE, no PROVE IT, no progress bar and no boost list. | The XAML has the same screen as the window that is built in code, and `Set-SIWindowTexts` puts the texts in the right language after the window is built. |
| 6 | The buttons of the Advanced section were created inside the window that is built in code, so the XAML fallback had none of them. | They are created in `New-SIWindow`, for both windows, and are put in the toolbar when the section is built. |
| 7 | The list of the processes was read once for every program of the boost list (13 times on a machine with 150 processes), on the thread that draws the window. | The list is read **once** and the names are looked up in it. |

**The start-up time.** Nothing of round 6 is on the way to the window: the games
and the honest limit of the machine are read by the **background copy** of SI
GAME (the same one that makes the restore point), the list of the boost
programs and the icons of the games are only read when the Advanced section is
opened, and the share card is only made when the button is pressed.

**Still open:** nothing in this round was executed either - the owner said that
commands cannot be run - so the changes were made by reading the code. The
open-time numbers still have to be measured on the owner's PC: the log says
"the script was loaded after X s" and "the window is on screen after Y s".

---

## Fix round 7

Owner, 21/10 (OWNER TEST 4): the five points of the owner about the script as it
ran on his PC (Windows 10 22H2, PowerShell 5.1, 4 GB RAM, started by the .bat).
The whole file was read again for the same kind of fault, not only the lines of
the report.

| # | What the owner said | What was wrong | Fix |
|---|---|---|---|
| 1 | The program is called **SIGAME** (one word, no space, no dash) in every visible text: window title, header, buttons, messages, share card, log messages. The file keeps the name SI-GAME.ps1 (the launcher uses it). | The name was "SI GAME" in the title, in the header, in the tooltips, in the share card, in the footer and in the messages of the log. | Every visible text says SIGAME. The name of the file, of the log, of the JSON files and of the restore point does not change: the launcher (`AVVIA SI GAME.bat`), the old logs and the old restore points have to keep working. The restore points of the old name are still found - the pattern is `SI?GAME*`, so "SI GAME - before the first change" and "SIGAME - before the first change" are both seen. |
| 2 | The **Advanced** section shows nothing to click when it is opened. It must show all its controls: the single tweaks with Apply/Undo, the detected Steam/Epic games with their boxes (+ the "Add a game" picker), the startup programs with on/off, the DNS test, the speed test and the cleaning of the temporary files. | `Build-SIAdvancedContent` did `$host = Get-SIElement -Name 'AdvancedHost'`. **$Host is an automatic variable of PowerShell and cannot be written**, so the assignment threw "Cannot overwrite variable Host"; because the call is inside the event of the Expander, PowerShell swallowed the error and the section stayed empty. The failed attempt also left the "already built" flag set, so the section never came back. | The variable is called `$advancedHost`. The build is inside a try/catch that writes the error in the log, shows it inside the section and lets the section be built again the next time it is opened. A timer of 500 ms watches the Expander, so the section is built even if the event does not come. The handler of the Expander is added only once, in `New-SIWindow`, for the window that is built in code and for the XAML fallback. The button of the picker now says "Add a game" in the six languages. |
| 3 | As soon as the window is visible, SIGAME must **measure by itself** (FREE RAM, startup programs on, DNS ms, power plan, HAGS/Game Mode/VBS) and show the numbers **big** in the BEFORE column. The window must stay responsive while it measures. | There was no measurement at the start: the panel was filled only by the button or by the measures of the last run. | `Start-SISlowStart` measures right after the window is on the screen: free RAM, the startup programs that are on, the answer time of the DNS (one short question), the power plan, HAGS, Game Mode and VBS. The AFTER column stays empty until something is changed. The window is pumped before and after the measurement, so it stays alive while it measures. The numbers of the BEFORE column are bigger (21 instead of 16, in bold). |
| 4 | **GAME BOOST** with an empty boost list printed "+-2 MB de RAM livre". With an empty list the running programs have to be shown **before** anything is closed, and a negative number must never be printed. | The difference between the free memory before and after is signed and it was written as it was: "+-2 MB". With nothing ticked the boost went on anyway and printed the number. | When nothing is ticked, GAME BOOST closes nothing, does not change the power plan, does not write a number, opens the Advanced section, builds the boost list with the programs that are running now (browsers, the web helpers of the launchers, OneDrive, Teams) and asks the user to tick them and to press GAME BOOST again. The number of the memory is never negative: 0 is written when the computer used more memory while the boost was working. |
| 5 | **OPTIMIZE** also set TaskbarMn and ShowTaskViewButton (the icons of the taskbar). They are not in the spec: remove them. | Both were in the table of the tweaks, so OPTIMIZE wrote them and the undo put them back. | The two entries are gone from the table. The third entry of the search (`SearchboxTaskbarMode`) stays, because that one is in the spec of the round 5. |

**The other faults of the same kind that were found in the whole file.**

| # | What was wrong | Fix |
|---|---|---|
| 1 | The result of the speed test used `$error` as the name of a local text. `$Error` is an automatic variable of PowerShell. | It is called `$why` now. |
| 2 | The handler of the Expander of the Advanced section was added **twice** (once in the window that is built in code and once in `New-SIWindow`), and the first one set the "already built" flag before the section was really built. | The handler is added only once, in `New-SIWindow`. |
| 3 | The `-f` operator on a string with the braces of a script block (the round 6 bug) could have come back in another place. | Every use of `-f` in the file was read: none of them has a literal `{` or `}` in its string. |
| 4 | PowerShell 7 only things (`??`, `?.`, `&&`, `||`, `ConvertFrom-Json -AsHashtable`, `Get-Content -AsByteStream`, `Join-String`, `Split-Path -LeafBase`, `Join-Path -AdditionalChildPath`). | None of them is used: the script is 5.1 only. |
| 5 | Other automatic variables written by mistake (`$host`, `$pid`, `$input`, `$args`, ...). | None of them is written any more. |
| 6 | The accents of the texts (the file has no BOM, so PowerShell 5.1 reads it as ANSI). | The whole file is still pure ASCII, the new texts included. |
| 7 | The handlers of WPF swallow the errors of the script blocks, so a fault inside one of them leaves the screen empty with nothing in the log. | Every function that a handler calls has its own try/catch and writes the error in the log and on the status line; the build of the Advanced section does the same and shows the error inside the section. |

**Still open:** nothing in this round was executed either - the owner said that
commands cannot be run - so the changes were made by reading the code. The
open-time numbers still have to be measured on the owner's PC: the log says
"the script was loaded after X s" and "the window is on screen after Y s", and
those two lines are the ones to read. The new measurement of the start has to be
watched too: the log says "The first measurement of this run was made." when the
numbers of the BEFORE column are on the screen.

---

## Fix round 8

Owner, 21/10 (OWNER TEST 5): the BEFORE numbers at the start, the Advanced
section and the choice of the game of GAME BOOST work and must keep working
exactly as they are. Three things are added: AUTO-BOOST, a faster start and
the shortcut of the desktop. The whole program was read again for the same kind
of fault, not only the new lines.

### The three things the owner asked for

| # | What the owner said | What was done |
|---|---|---|
| 1 | **AUTO-BOOST**: a switch "Auto-BOOST", on by default once the user has set the Boost list. While SIGAME is open or in the tray, it checks every 5 s with `Get-Process` (light, no WMI event subscription) whether one of the Steam/Epic games found on the computer, or a game added with the picker, is running. When a game starts, GAME BOOST runs by itself and a small note says "GAME BOOST: &lt;game&gt;"; when the game ends, GAME OVER runs by itself. Both are written in the log. The boost is never done twice. | `modules/09-autoboost.ps1` is the new module. The switch is in the BOOST LIST of the Advanced section (and in the menu of the tray). It is on by default the first time the user ticks a program of the boost list: the sign of that is kept in `SI-GAME-boost.json` (`Configured`). The check is one `Get-Process` every 5 s, on a `DispatcherTimer`, and the names of the games are compared with the names of the processes (the .exe of the game without the .exe). The boost is never done twice: the game that the AUTO-BOOST took care of is remembered, a boost that the user did by hand is never done again, and a boost that did not work (nothing ticked) does not leave a GAME OVER to do. The games added with the picker are kept in the JSON file, so they are watched in the next run too. Everything is written in the log with the component `AutoBoost`. |
| 2 | **FASTER START**: the window appeared after about 22 s. The program is split into a small loader `SI-GAME.ps1` that shows the window with the logo and "Loading ..." at once, and module files in a "modules" folder that are loaded after the window is visible, one by one, with the window kept alive. The goal is the first window under 8 s on that PC. The time of every step is written in the log. | `SI-GAME.ps1` is now the loader (about 600 lines) and the program is in `modules\`: `00-core`, `01-registry`, `02-tweaks`, `03-features`, `04-state`, `05-engine`, `06-window`, `07-startup`, `08-boost`, `09-autoboost`. The loader opens the loading window (the logo of SI NEWS, "SIGAME", "Loading ..." and the name of the module that is loading) and pumps the dispatcher between the modules, so the window stays alive and moves on. The log says, for every module, "the module X was loaded in Y s, Z s after the start", plus "The first window (the logo and Loading) was on the screen after Z s" and "The window is on screen after Y s". The old file is kept as `SI-GAME.r7-ok.ps1.bak`. The request for administrator rights is now made **before** the modules are loaded, so the copy with the rights does the work and the modules are not read twice. |
| 3 | **DESKTOP ICON**: on the first start, a shortcut "SIGAME" on the desktop that starts "AVVIA SI GAME.bat" of the SIGAME folder, with an .ico made out of logo.png (System.Drawing). A flag keeps it from being made again if the user deletes it. A button in Advanced makes it again. | `New-SIDesktopShortcut` writes `SI-GAME.ico` (32x32, made out of logo.png with System.Drawing) and the shortcut `SIGAME.lnk` on the desktop of the person who is sitting at the machine (the account that is logged on is asked for, and its profile is found with its SID, so the shortcut does not land on the desktop of another account). The flag `SI-GAME-desktop.flag` remembers that the shortcut was made: it is never made again by itself, and if the user deletes it, it stays deleted. The button "Create the shortcut of the desktop" in the Advanced section makes it again (`-Force`). |

### The tray icon

The window can be closed and SIGAME goes on in the tray, with the logo of SI
NEWS as the icon and a menu with **Open SIGAME**, **AUTO-BOOST** (a box that
is on and off) and **Exit**. The window is hidden (not closed) when it is
closed or minimized, and a small note says that SIGAME is still running. The
icon is made with `System.Windows.Forms.NotifyIcon`; if it cannot be made
(no System.Windows.Forms), SIGAME works exactly as before and the window
closes the program.

Because of the tray, the main window is no longer opened with `ShowDialog`: a
modal window cannot be hidden. It is shown the normal way and the dispatcher
is run by hand with a `DispatcherFrame`, and the frame ends when the window is
really closed (the Exit of the tray).

### The other faults of the same kind that were found in the whole program

| # | What was wrong | Fix |
|---|---|---|
| 1 | `Invoke-SIElevate` used `$PSCommandPath`. In the new split that is the file of the module, so the copy with administrator rights would have started a module instead of SIGAME. | The path is `$script:SICurrentScript`, the path of the loader, and it is set in the loader. |
| 2 | `$PSScriptRoot` inside a module is the folder of the modules, not the folder of SIGAME. Everything SIGAME writes (log, JSON, icon, flag) would have landed in `modules\`. | `$script:SIRoot` is set in the loader, and every module uses it. |
| 3 | `Get-SIEpicGames` did `Join-Path $location $launch` without checking the folder. `Join-Path` throws when the path is empty, and that would have taken the **whole list of the games** away (Steam and Epic). | The folder is checked first. |
| 4 | `Test-SIValueEqual` did `[byte[]]@($A)` on every list. A MultiString is a list of strings, and the cast throws. | The cast is inside a try/catch: a value that is not binary is compared as a string. |
| 5 | `Get-SIStartupApps` did `Join-Path $env:APPDATA ...`. `Join-Path` throws when the environment variable is empty, and that would have taken the whole list of the startup programs away. | The two startup folders are built inside a try/catch, one at a time. |
| 6 | `Get-Content -Raw` gives `$null` for an empty file, and `$null.TrimStart()` throws. The check for the empty file was **after** the byte order mark was taken away (4 places: the measures, the boost list, the request of the background copy, the result of the background copy). | The empty file is checked first, the mark is taken away after. |
| 7 | `Start-Process` without `Out-Null` left the process object in the output of the function. | `Out-Null` was added (the share card and the programs that GAME OVER opens again). |
| 8 | The window was opened with `ShowDialog`, and a modal window cannot be hidden. | The window is shown the normal way, with a `DispatcherFrame` that ends when the window is closed. |
| 9 | The AUTO-BOOST could have done a GAME OVER for a boost that the user had done by hand. | The AUTO-BOOST remembers only the boost that it did by itself. A boost of the user is never done again and never taken back by the AUTO-BOOST. |
| 10 | The `-f` operator on a string with the braces of a script block (the round 6 bug) could have come back. | Every use of `-f` in the new code was read: none of them has a literal `{` or `}` in its string. |
| 11 | PowerShell 7 only things (`??`, `?.`, `&&`, `||`, `ConvertFrom-Json -AsHashtable`, `Get-Content -AsByteStream`, `Join-String`, `Split-Path -LeafBase`, `Join-Path -AdditionalChildPath`). | None of them is used: the program is 5.1 only. |
| 12 | The accents of the texts (the files have no BOM, so PowerShell 5.1 reads them as ANSI). | Every file of the program is pure ASCII, the new texts included ("AUTO-BOOST" is the same in the six languages). |
| 13 | The handlers of WPF swallow the errors of the script blocks, so a fault inside one of them leaves the screen empty with nothing in the log. | Every new function has its own try/catch and writes the error in the log. |
| 14 | The **Apply** and the **Undo** of every row of the tweaks used `$tweakId` in a script block of WPF **without** `GetNewClosure`. A script block of WPF is not a closure: it runs later, when the function that made it is long gone, so the variable was empty. The engine looks for a tweak with an empty name, does not find it and returns **without a word**: the button of the row did nothing at all and said nothing. The box of the options was worse: it re-read the state of **every** tweak of the table instead of the one of the row. | The three handlers of the row (Apply, Undo and the option box) are closed over the value of `$tweakId` with `GetNewClosure`, like the handlers of round 6. |
| 15 | The message boxes of the GAMING preset and of the two UNDO ALL buttons were opened with an empty owner window, because `$window` was also lost in the script block. | The handlers are closed with `GetNewClosure`, so the box is the child of the window of SIGAME. |
| 16 | A game whose boost did **not** work (nothing was ticked in the boost list) was never boosted again, not even after the user ticked a program: the game was "already seen" for good. | A new state (`SIAutoBoostAttempted`) remembers the game whose boost was tried. It is cleared when the user changes the boost list, so the boost is tried again, and it is not tried again every 5 s (the log would be full of the same line). |
| 17 | A game that was running **during** a boost that the user did by hand was never taken over by the AUTO-BOOST when that boost ended. | The flag "already seen" no longer stops the attempt: it only stops the writing of the same line in the log. The AUTO-BOOST takes the game over as soon as the boost of the user is over. |
| 18 | The `.ico` was written with `Icon.FromHandle()` + `Icon.Save()`, the combination that throws when the icon belongs to a handle. The icon of the tray and the shortcut would have fallen back on the icon of Windows. | The icon is copied (`Icon.Clone()`) before it is written, and the copy is the one that goes into the file. |
| 19 | The desktop of the person who is playing was found with `Win32_UserAccount`, with the **domain guessed** as the name of the computer. With a domain account the account was not found and the shortcut landed on the desktop of the administrator. | The name of the account is compared without the domain (the same account is the normal case), and the profile of the other account is found in the `ProfileList` of the registry by the name of the profile folder: no WMI, and the real path of the profile. |
| 20 | The shortcut of the desktop was made **before** the window was shown, and the search of the desktop is slow (WMI): the window waited for it, on the first start. | A timer does the work 3 s after the window is on the screen. The window does not wait for the shortcut. |
| 21 | Three state variables were read before they had a value (`SINames`, `SIButtonTemplate`, `SILogFolderChecked`). They do not throw (there is no `Set-StrictMode`), but they are not declared either. | They are declared with their value. |

### What the owner has to look at

* The log says "The first window (the logo and Loading) was on the screen after
  X s": that is the number of the goal of under 8 s. The next line, "The
  window is on screen after Y s", is the moment when the real window with the
  rows is on the screen.
* The log says, for every module, how long it took: "the module 02-tweaks.ps1
  was loaded in X s".
* The log says "the game X is running.", "the game X is not running any more."
  and the lines of the boost: the component is `AutoBoost`.
* The log says "the shortcut SIGAME was made on the desktop: ..." (component
  `Desktop`) and "the icon of the tray is on the screen." (component `Tray`).
  On the next start the shortcut is not made again: the flag
  `SI-GAME-desktop.flag` is next to the script.

**Still open:** nothing in this round was executed either - the owner said that
commands cannot be run - so the changes were made by reading the code, and the
open-time numbers still have to be measured on the owner's PC. The three
things that were added (the AUTO-BOOST, the tray icon and the shortcut of the
desktop) have to be tried on the machine of the owner: the AUTO-BOOST with a
game that is really installed, the tray with the closing of the window, and
the shortcut on the desktop. The **Apply** and the **Undo** of a single row of
the tweaks have to be tried too: they were broken (fault 14) and nothing in
the program showed that they were broken.

**One known limit of the tray:** if Windows Explorer is restarted while SIGAME
is in the tray, the icon of the tray is lost and SIGAME keeps running without
a way back to the window. The way out is the Task Manager (end
`powershell.exe` of SIGAME) or the start of SIGAME again. The icon was not
rebuilt on the restart of Explorer on purpose: that needs a message window
that only a compiled piece of code can have, and SIGAME has no compiled
piece of code.

---

## Fix round 9

Owner, 21/10 (OWNER TEST 6): two real faults on the owner's PC (Windows 10 22H2,
PowerShell 5.1, 4 GB RAM, started by the .bat).

```
[ERROR] [Start] SIGAME stopped with an error: Cannot find an overload for "Subtract" and the argument count: "1".
Stack: <ScriptBlock> modules\07-startup.ps1 line 1255 < Invoke-SIMain 07-startup.ps1 line 1303 < SI-GAME.ps1 line 566.
```

and the first window (the logo and "Loading") only after **11.38 s**, the real
window after **20.58 s**. The goal of the owner: the first window under **8 s**.

### 1. The crash

| # | What was wrong | Why | Fix |
|---|---|---|---|
| 1 | `Cannot find an overload for "Subtract" and the argument count: "1"` at `07-startup.ps1` line 1255, in the safety timer of the window. | The arithmetic was inside a script block closed with `.GetNewClosure()`. A closed block gets **its own scope and its own session state**: it does **not** see the `$script:` variables of the file, so the start time it used was empty and `Subtract()` had nothing to subtract. The same class of fault was in two other closed blocks (the GAMING preset and the box of the boost list), which worked only by accident of their local variables. | The arithmetic is **out** of the closed blocks. The timer and the event of the first paint call `Set-SIWindowOnScreenTime` (a function of `00-core.ps1`), which reads the start time with the normal scope and computes the time with `Subtract()`. The two other closed blocks now call a function of a module as well (`Invoke-SIGamingPreset`, `Set-SIAutoBoostListState`), so they do not depend on the scope of the block any more. |
| 2 | The dates of the JSON files and of WMI are **strings**, not `DateTime`. | `SI-GAME-backup.json` holds `"2026-10-21T10:37:01"` and the restore point of WMI holds `"20261020220411000.000000-000"`. A string converts both to `DateTime` and to `TimeSpan`, so an operator on them throws (that was the `op_Subtraction` of round 2) and a method call with a raw string throws the `Subtract` of this round. | Every date now goes through `ConvertTo-SIDateTime` (in `00-core.ps1`: the 14-digit form of WMI, then the usual formats) and **every** subtraction is a method call with an explicit cast: `[datetime]::Now.Subtract([datetime]$stamp)`. The `Undo all` of `05-engine.ps1` sorted the changes on the **raw string** of the backup, so "10:37:01" and "9:05:00" were in the wrong order; it now sorts on the parsed date. |
| 3 | The dates of the modules were not read the same way everywhere. | `ConvertTo-SIDateTime` was in `07-startup.ps1` and `05-engine.ps1` needed it, but the modules are read one by one and the order is not guaranteed for a function of a module that is not read yet. | The function is in `00-core.ps1`, the first module, and is used from every module. `Get-SIElapsedSinceStart` (the time since the start of the process) and `Set-SIWindowOnScreenTime` (the moment the window is on the screen) are there too. |

### 2. The start (the goal of under 8 s)

| # | What was wrong | Fix |
|---|---|---|
| 1 | The loader (`SI-GAME.ps1`, 598 lines) did everything: the log, the rights, the WMI, the JSON files, the four `Add-Type` calls, the modules and the run. The first window could not be opened before all of it. | The loader is now **only** the loading window and the list of the modules. The log, the paths and the rights moved to `00-core.ps1`; the run moved to `Invoke-SIRun` in `07-startup.ps1`. |
| 2 | The window was opened after the assemblies, the logo and the other work. | The window is now the **first** thing: the loader opens it, pumps the dispatcher, and only then loads the modules. No WMI, no JSON, no other `Add-Type`: the only assembly the loader asks for is **PresentationFramework** (the .bat loads the four of WPF in **four parallel threads** while PowerShell reads the script). |
| 3 | The logo was decoded before the first paint. | The `Image` is created empty and the PNG is decoded **after** the first paint (`Set-SILoadingLogo`), so the window is on the screen with the logo a moment later. |
| 4 | There was no way to see where the time went. | One new log line after the modules: "the start: PowerShell X s, the WPF assemblies X s, the loading window X s, the first window on the screen X s after the start of the process." and, for every module, "the module X was loaded in Y s, Z s after the start". |
| 5 | The request for administrator rights was made before the modules, so the modules were read twice (once by the copy without rights, once by the copy with rights). | The rights are asked **after** the first module (`00-core.ps1`), when the copy with the rights takes over. The cost is one UAC prompt a fraction of a second later, and the modules are read once. |

### 3. What the owner has to look at

* The log says "the start: PowerShell X s, the WPF assemblies X s, the loading
  window X s, the first window on the screen X s after the start of the
  process." - that is the breakdown of the wait.
* The log says "The first window (the logo and Loading) was on the screen after
  X s": that is the number of the goal of under 8 s.
* The log says, for every module, "the module X was loaded in Y s, Z s after the
  start": the module that costs the most is the one to slim down next.
* The log has to show **no** error at the start: the crash of this round was
  after the first window, so the window was there and the program died behind
  it.

**Still open:** nothing in this round was executed either - the owner said that
commands cannot be run - so the changes were made by reading the code, and the
open-time numbers still have to be measured on the owner's PC: the log says
"the script was loaded after X s", "The first window (the logo and Loading) was
on the screen after Y s" and "the window is on screen after Z s", and those are
the lines to read. The 5.1 s floor of that machine is the cost of an empty
PowerShell 5.1 + WPF window, so what is left for SIGAME is small.

---

## Fix round 10

Owner, 21/10 (OWNER TEST 6): a double click on the icon of the desktop wrote
"The fast start did not work, SI GAME is started the normal way now." on the
screen of PowerShell, and SIGAME was started a second time (two full starts
24 s apart in the log, 13:13:23 and 13:13:47). The launcher was made simple
again and the whole program was read again for the faults of PowerShell 5.1.

**What the log of the owner really shows:** the run of 13:13:22 is the program
(the module `06-window.ps1` is in it), the run of 13:13:47 is the **background
copy** (the module `06-window.ps1` is NOT in it, and the log says "the
background copy of SIGAME was started (prepare)" at 13:13:39). So the program
was started once, but the launcher had already decided that the start had
failed, and it started a second copy on top of it.

### 1. The launcher ("AVVIA SI GAME.bat")

| # | What was wrong | Why | Fix |
|---|---|---|---|
| 1 | The launcher read the exit code of PowerShell and, when the code was not 0, wrote a message on the screen and started SIGAME a second time. | The code of a process that ends while WPF is still being freed is not always 0, and the code is read before the program is really finished. `if errorlevel 1` is true for EVERY code that is not 0, so one bad code was enough for a second SIGAME. | The launcher does **not** read the exit code any more. There is ONE line, there is no second start and there is no text on the screen. |
| 2 | The launcher loaded the four WPF assemblies in four threads before the script, and the copy with the administrator rights did the same with one thread. | The log says that the assemblies take 0,22 s to 0,32 s, so the preload brought nothing. The thread of the copy with the rights had **no try/catch** around the load, and an unhandled exception in a thread ends the whole process in .NET, so a single failure there killed that copy before its window was on the screen. | The preload is gone, in the launcher and in the copy with the rights. The copy with the rights is started the normal way, with `-File`. |
| 3 | The console of PowerShell was on the screen the whole time. | The launcher is a .bat, so cmd.exe opens a console, and the copy with the administrator rights opens a second one. | The launcher starts PowerShell with `start "" /min` and with `-WindowStyle Hidden`, and it ends at once. The copy with the administrator rights is hidden too. |
| 4 | The name of the program in the launcher was "SI GAME". | The name of the program in every text is SIGAME (one word). | "SIGAME" in every text of the launcher. The NAME of the file stays, because the shortcut of the desktop and the button of the Advanced section look for it. |

The launcher is now, in full:

```
@echo off
cd /d "%~dp0"
start "" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0SI-GAME.ps1"
exit /b 0
```

### 2. The exit code of the program

| # | What was wrong | Why | Fix |
|---|---|---|---|
| 1 | The program could end with a code that is not 0, and the launcher read that code. | The last line of the loader was `exit 0`, but the keyword is only reached when nothing goes wrong while the process is shutting down. A crash in that moment (the WPF objects that are freed at the end) leaves a code that is not 0. | The loader ends with `[System.Environment]::Exit(0)`: the process ends at once, with the code 0, and nothing can change it afterwards. |
| 2 | The copy without the administrator rights left its loading window on the screen while the copy with the rights opened its own. | The user saw two SIGAME windows at the same time, and the program looked like it started twice. | The loading window of the copy that hands over is closed before it leaves, and that copy ends with the code 0 like every other end (it does not run the program: the copy with the rights is the one that opens the window). |
| 3 | The reason of a start that fails was written on the console, and the console is hidden now. | The owner would have seen nothing at all. | The reason goes to the log AND to a message box (the loader and the window). |

### 3. The other faults of PowerShell 5.1 found while reading the whole program

| # | What was wrong | Why | Fix |
|---|---|---|---|
| 1 | The XAML fallback of the window could never work: `XamlReader.Load` needs the assembly System.Xaml, and nothing ever loaded it (the loader asks for PresentationFramework only, because the window that is built in code does not need it). | The fallback is the last chance of the program: when the window cannot be built in code, the XAML is used. It failed with "Could not load file or assembly 'System.Xaml'" and the program had no window at all. | `New-SIWindowXaml` loads System.Xaml before it parses the XAML. |
| 2 | When the window cannot be built at all, nothing was said to the user. | The console is hidden now, so a program that opens no window would be silent. | A message box says that SIGAME cannot open a window and where the log is. |
| 3 | The loader went on when a module could not be loaded, and only wrote a line in the log. | The window of the module 06 calls the functions of the modules 07, 08 and 09. If one of them is missing, every button of the window dies with an error that the user cannot see, and the program looks like it works while nothing works. | The loader stops when a module cannot be loaded, writes the reason in the log and shows it in a message box. |

### 4. The faults found in the modules while reading them again

| # | Where | What was wrong | Fix |
|---|---|---|---|
| 1 | `07-startup.ps1` | The tick of the timer that reads the result of the background copy was not protected. A terminating error in a tick leaves the hand-made dispatcher loop and ends the program with the box of the error, while the owner is using it. It is the same shape of the crash of round 9. | The tick is wrapped in a try/catch and the reason goes to the log. |
| 2 | `02-tweaks.ps1` | The test of the active power plan looked for the star of `powercfg /list` at the BEGINNING of the line. The star is at the END of the line, so the active plan was never found, the row of the Ultimate Performance was never "installed and active" and the Undo never put the previous plan back. | The test is `\*\s*$`. |
| 3 | `02-tweaks.ps1` | The row of the Widgets read the backup from the cache, and the cache never expires. The row could show a backup of a start from hours ago, with the Widgets panel still in it, and say "not available" when SIGAME had removed the panel. | The row reads the backup that is in memory, which the engine keeps up to date, and falls back to the file only when there is none. |
| 4 | `03-features.ps1` | The list of the programs of the start-up read the key `HKCU` of the account that was elevated, and the on/off state was read of the person at the machine. The list could show the programs of the administrator with the state of the other user. | The path goes through `Get-SIUserRegistryPath`, like the state below. |
| 5 | `SI-GAME.ps1` | The handler of the paint of the loading window did the work itself on the variables of the script scope. It works today, but it is one edit away from the crash of round 9: the moment somebody makes that handler with `GetNewClosure()`, the value of the script scope disappears and the log prints a time of -1,00 s for ever. | The handler calls a function of the loader, `Set-SIFirstWindowOnScreenTime`, and the time of the first window is written only when it is really known. |
| 6 | `06-window.ps1` | The tip of the button of the shortcut of the desktop was the only visible text that said "SI GAME", because it named the launcher of the disk. | The tip says "the launcher of SIGAME". The NAME of the file on the disk stays, because the shortcut looks for it. |
| 7 | `08-boost.ps1` | The line of the trust asks the window for the text of the footer with `Get-SIElement`, and that function is in the module `06-window.ps1`. The background copy of SIGAME does not read that module, so the call there had no protection. | The call is wrapped in a try/catch, so the line of the trust can never break a run of the background copy. |

**The order of the modules is left as it is.** The window (06) calls the
functions of the modules 07, 08 and 09, and the module 07 calls the functions
of the modules 08 and 09. That is safe because every one of those calls is made
at RUN time, and not while the modules are read: the loader reads the ten
modules and only then it runs the program. The only way the order could hurt is
a module that fails to be read, and that case is now stopped by the loader
itself (row 3 of the table above), with a reason on the screen.

**Still open:** nothing in this round was executed either - the owner said that
commands cannot be run - so the changes were made by reading the code. The
owner has to check on his PC that the icon of the desktop opens SIGAME **once**,
that no console is left on the screen, that the copy with the administrator
rights asks for the rights exactly once, and that the log has no "[ERROR]" at
the start of the run.

---

## 1. The tweaks

### 1.1 Game Mode

* **Source:** WinUtil `WPFToggleGameMode`
* **Group:** Gaming - part of the GAMING preset

| Hive | Key | Value | Type | Set to |
|---|---|---|---|---|
| HKCU | `Software\Microsoft\GameBar` | `AllowAutoGameMode` | DWORD | `1` |
| HKCU | `Software\Microsoft\GameBar` | `AutoGameModeEnabled` | DWORD | `1` |

**Undo:** both values are written back with the exact type they had before
(DWORD stays DWORD, a missing value is deleted again, a value that was a
different type is restored with that type). The entry is then removed from the
JSON backup.

---

### 1.2 Mouse acceleration

* **Source:** WinUtil `WPFToggleMouseAcceleration` (inverted: SI GAME switches
  acceleration **off**, WinUtil's toggle flips it)
* **Group:** Gaming - part of the GAMING preset

| Hive | Key | Value | Type | Set to |
|---|---|---|---|---|
| HKCU | `Control Panel\Mouse` | `MouseSpeed` | DWORD | `0` |
| HKCU | `Control Panel\Mouse` | `MouseThreshold1` | DWORD | `0` |
| HKCU | `Control Panel\Mouse` | `MouseThreshold2` | DWORD | `0` |

**Undo:** the three values are restored exactly as they were; a value that did
not exist before is deleted again. No service is touched.

---

### 1.3 Background apps

* **Source:** WinUtil `WPFTweaksDisableBGapps`
* **Group:** Gaming - part of the GAMING preset

| Hive | Key | Value | Type | Set to |
|---|---|---|---|---|
| HKCU | `Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications` | `GlobalUserDisabled` | DWORD | `1` |

**Undo:** the original value is restored (or the value is deleted again if it
was not there before).

---

### 1.4 Visual effects (best performance)

* **Source:** WinUtil `WPFTweaksDisplay`
* **Group:** Gaming - part of the GAMING preset

| Hive | Key | Value | Type | Set to |
|---|---|---|---|---|
| HKCU | `Control Panel\Desktop` | `DragFullWindows` | String | `0` |
| HKCU | `Control Panel\Desktop` | `MenuShowDelay` | String | `200` |
| HKCU | `Control Panel\Desktop\WindowMetrics` | `MinAnimate` | String | `0` |
| HKCU | `Control Panel\Keyboard` | `KeyboardDelay` | DWORD | `0` |
| HKCU | `Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `ListviewAlphaSelect` | DWORD | `0` |
| HKCU | `Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `ListviewShadow` | DWORD | `0` |
| HKCU | `Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `TaskbarAnimations` | DWORD | `0` |
| HKCU | `Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects` | `VisualFXSetting` | DWORD | `3` |
| HKCU | `Software\Microsoft\Windows\CurrentVersion\DWM` | `EnableAeroPeek` | DWORD | `0` |
| HKCU | `Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `TaskbarMn` | DWORD | `0` |
| HKCU | `Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `ShowTaskViewButton` | DWORD | `0` |
| HKCU | `Software\Microsoft\Windows\CurrentVersion\Search` | `SearchboxTaskbarMode` | DWORD | `0` |
| HKCU | `Control Panel\Desktop` | `UserPreferencesMask` | Binary | `144,18,3,128,16,0,0,0` |

**Undo:** all thirteen values are restored byte for byte. The binary
`UserPreferencesMask` is compared and restored byte by byte, not as a string.

---

### 1.5 Delivery Optimization

* **Source:** WinUtil `WPFTweaksDeliveryOptimization`
* **Group:** Gaming - part of the GAMING preset

| Hive | Key | Value | Type | Set to |
|---|---|---|---|---|
| HKLM | `SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization` | `DODownloadMode` | DWORD | `0` |

**Service**

| Service | Startup type after Apply |
|---|---|
| `DoSvc` (Delivery Optimization) | `Disabled` |

**Undo:** the registry value is restored, and the service gets back the startup
type it had before (`Automatic`, `Manual`, `Disabled` or
`AutomaticDelayedStart`) and is started again if it was running.

---

### 1.6 Telemetry

* **Source:** WinUtil `WPFTweaksTelemetry`
* **Group:** Gaming - part of the GAMING preset

| Hive | Key | Value | Type | Set to |
|---|---|---|---|---|
| HKCU | `Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo` | `Enabled` | DWORD | `0` |
| HKCU | `Software\Microsoft\Windows\CurrentVersion\Privacy` | `TailoredExperiencesWithDiagnosticDataEnabled` | DWORD | `0` |
| HKCU | `Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy` | `HasAccepted` | DWORD | `0` |
| HKCU | `Software\Microsoft\Input\TIPC` | `Enabled` | DWORD | `0` |
| HKCU | `Software\Microsoft\InputPersonalization` | `RestrictImplicitInkCollection` | DWORD | `1` |
| HKCU | `Software\Microsoft\InputPersonalization` | `RestrictImplicitTextCollection` | DWORD | `1` |
| HKCU | `Software\Microsoft\InputPersonalization\TrainedDataStore` | `HarvestContacts` | DWORD | `0` |
| HKCU | `Software\Microsoft\Windows\CurrentVersion\Personalization\Settings` | `AcceptedPrivacyPolicy` | DWORD | `0` |
| HKLM | `SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection` | `AllowTelemetry` | DWORD | `0` |
| HKCU | `Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `Start_TrackProgs` | DWORD | `0` |
| HKLM | `SOFTWARE\Policies\Microsoft\Windows\System` | `PublishUserActivities` | DWORD | `0` |
| HKCU | `Software\Microsoft\Windows\CurrentVersion\Siuf\Rules` | `NumberOfSIUFInPeriod` | DWORD | `0` |

**Services**

| Service | Startup type after Apply |
|---|---|
| `DiagTrack` (Connected User Experiences and Telemetry) | `Disabled` |
| `WerSvc` (Windows Error Reporting) | `Disabled` |

**Undo:** the twelve registry values are restored exactly and both services get
back their original startup type and running state.

> **Difference from WinUtil:** WinUtil names the error reporting service
> `wermgr`, which does not exist on Windows 10 / 11. SI GAME uses the real
> service name `WerSvc`.

---

### 1.7 Activity history

* **Source:** WinUtil `WPFTweaksActivity`
* **Group:** Gaming - part of the GAMING preset

| Hive | Key | Value | Type | Set to |
|---|---|---|---|---|
| HKLM | `SOFTWARE\Policies\Microsoft\Windows\System` | `EnableActivityFeed` | DWORD | `1` (1 = the feed is **off**) |
| HKLM | `SOFTWARE\Policies\Microsoft\Windows\System` | `PublishUserActivities` | DWORD | `0` |
| HKLM | `SOFTWARE\Policies\Microsoft\Windows\System` | `UploadUserActivities` | DWORD | `0` |

**Undo:** the three values are restored exactly. No service is touched.

---

### 1.8 Multiplane Overlay (MPO)

* **Source:** WinUtil `WPFMultiplaneOverlay` - **SI GAME adds the undo that
  WinUtil does not have**
* **Group:** Gaming - part of the GAMING preset
* **Choice in the row:** `Enabled` / `Disabled (Compatibility)` /
  `Fully Disabled`. The GAMING preset picks `Disabled (Compatibility)`.

| Choice | `HKLM\SOFTWARE\Microsoft\Windows\Dwm` → `OverlayTestMode` | `HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers` → `DisableOverlays` |
|---|---|---|
| Enabled | value deleted | value deleted |
| Disabled (Compatibility) | DWORD `5` | value deleted |
| Fully Disabled | DWORD `5` | DWORD `1` |

**Undo:** the two values are restored to the state they had before, with their
original type. A value that was not there before is deleted again, so "Enabled"
really returns the machine to the untouched Windows default. The state column
reads the two values back and shows which of the three modes is really active.

---

### 1.9 Widgets

* **Source:** WinUtil `WPFTweaksWidget` - **SI GAME adds the undo that WinUtil
  does not have**
* **Group:** Gaming - part of the GAMING preset

| Hive | Key | Value | Type | Set to |
|---|---|---|---|---|
| HKCU | `Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `TaskbarDa` | DWORD | `0` |

**Extra work on Apply (no registry value):**

1. The `*Widget*` processes are stopped.
2. The AppX packages `Microsoft.WidgetsPlatformRuntime` and
   `MicrosoftWindows.Client.WebExperience` are removed for all users.

**Undo:**

1. `TaskbarDa` is restored to its original value (or deleted again if it did
   not exist).
2. Every package that was removed is put back: the provisioned package
   (`Get-AppxProvisionedPackage -Online`) is registered with
   `Add-AppxPackage -DisableDevelopmentMode -Register <ApXManifest.xml>`, and if
   there is no provisioned package the manifest of the installed package is
   registered instead.
3. The list of removed packages is kept in the JSON backup
   (`RemovedPackages`), so only the packages that SI GAME really removed are
   touched by the undo.

The state column reads whether the packages are still installed, so it does not
claim "removed" when only the taskbar button was hidden.

---

### 1.10 Windows AI / Recall

* **Source:** WinUtil `WPFTweaksWindowsAI` - **SI GAME adds the undo that WinUtil
  does not have**
* **Group:** Gaming - part of the GAMING preset

| Hive | Key | Value | Type | Set to |
|---|---|---|---|---|
| HKLM | `SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer` | `SettingsPageVisibility` | String | `hide:aicomponents` |
| HKLM | `SOFTWARE\Policies\WindowsNotepad` | `DisableAIFeatures` | DWORD | `1` |

**Service**

| Service | Startup type after Apply |
|---|---|
| `WSAIFabricSvc` | `Disabled` |

**Extra work on Apply (no registry value):**

1. The `Recall` Windows optional feature is disabled
   (`Disable-WindowsOptionalFeature -Online -NoRestart`) when it is present and
   enabled.
2. The AppX packages `MicrosoftWindows.Client.CoreAI` and `*Copilot*` are
   removed for all users.

**Undo:**

1. Both registry values are restored exactly and `WSAIFabricSvc` gets back its
   original startup type and running state.
2. Recall is enabled again **only if it was enabled before SI GAME ran** (the
   snapshot `RecallEnabled` is stored in the JSON backup).
3. Every AppX package that was removed is registered again from its
   `ApXManifest.xml`. The removed full package names are stored in the JSON
   backup (`RemovedPackages`), so the undo only touches what SI GAME removed.

---

### 1.11 Ultimate Performance

* **Source:** WinUtil `WPFAddUltPerf` - **SI GAME adds the undo that WinUtil
  does not have**
* **Group:** Gaming - part of the GAMING preset
* **Desktops only.** On a laptop the plan is skipped, both by the GAMING
  preset and by Apply, and the log says why. The laptop test is
  `Win32_Battery` present, or `Win32_ComputerSystem.PCSystemType = 2`.

**Extra work on Apply (no registry value):**

1. `powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61` (the
   Ultimate Performance GUID).
2. `powercfg /setactive <new guid>`.

**Undo:**

1. `powercfg /delete <new guid>` removes the plan SI GAME created.
2. `powercfg /setactive <previous guid>` puts the plan that was active before
   back in place.

Both GUIDs are stored in the JSON backup (`NewScheme` and `PreviousScheme`).

---

## 2. The tweaks that are new for 2026

These four are **not** in WinUtil. They were researched separately.

### 2.1 Game Bar background capture

* **Source:** new for 2026 - Microsoft, "Record with Game Bar"
  `https://support.microsoft.com/windows/record-with-game-bar`
* **Group:** Gaming - part of the GAMING preset
* **Choice in the row:** `Background capture OFF` / `Background capture ON`.
  The GAMING preset picks `Background capture OFF`.

| Choice | Hive | Key | Value | Type | Set to |
|---|---|---|---|---|---|
| OFF | HKCU | `Software\Microsoft\Windows\CurrentVersion\GameDVR` | `AppCaptureEnabled` | DWORD | `0` |
| OFF | HKCU | `System\GameConfigStore` | `GameDVR_Enabled` | DWORD | `0` |
| ON | HKCU | `Software\Microsoft\Windows\CurrentVersion\GameDVR` | `AppCaptureEnabled` | DWORD | `1` |
| ON | HKCU | `System\GameConfigStore` | `GameDVR_Enabled` | DWORD | `1` |

**Undo:** both values are restored to the original value and type, or deleted
again when they did not exist before.

### 2.2 Hardware accelerated GPU scheduling (HAGS)

* **Source:** new for 2026 - Microsoft, `HwSchMode` under `GraphicsDrivers`
* **Group:** Gaming - part of the GAMING preset
* **Choice in the row:** `HAGS ON` / `HAGS OFF`. The GAMING preset picks
  `HAGS ON`.
* **A restart is needed** for HAGS to take effect.

| Choice | Hive | Key | Value | Type | Set to |
|---|---|---|---|---|---|
| ON | HKLM | `SYSTEM\CurrentControlSet\Control\GraphicsDrivers` | `HwSchMode` | DWORD | `1` |
| OFF | HKLM | `SYSTEM\CurrentControlSet\Control\GraphicsDrivers` | `HwSchMode` | DWORD | the value is **deleted** (the driver then decides) |

**Undo:** the original value is restored with its original type; when the value
was not there before it is deleted again, which is the untouched Windows state.

The state column reads `HwSchMode` back and says which of the three real
states the machine is in (on / off / not configured).

### 2.3 Optimizations for windowed games

* **Source:** new for 2026 - `GameDVR_FSEBehaviorMode`
* **Group:** Gaming - part of the GAMING preset
* **Choice in the row:** `Optimizations ON` / `Optimizations OFF`. The GAMING
  preset picks `Optimizations ON`.

| Choice | Hive | Key | Value | Type | Set to |
|---|---|---|---|---|---|
| ON | HKCU | `System\GameConfigStore` | `GameDVR_FSEBehaviorMode` | DWORD | `2` |
| OFF | HKCU | `System\GameConfigStore` | `GameDVR_FSEBehaviorMode` | DWORD | `0` |

**Undo:** the original value is restored with its original type, or the value is
deleted again when it did not exist before.

> **Open point, check before the release:** the value `2` for
> `GameDVR_FSEBehaviorMode` is the widely used "Optimizations for windowed
> games" setting, but SI GAME could not be validated against the official
> Microsoft documentation during the writing of this file. Before shipping,
> confirm the meaning of the values in
> `HKCU\System\GameConfigStore\GameDVR_FSEBehaviorMode` in the Microsoft
> documentation for Game Bar / Xbox Game Bar. The undo works whatever the
> value means, because it restores the original value, not a hard-coded one.

### 2.4 Memory integrity (core isolation / HVCI) - **SHOW ONLY**

* **Source:** new for 2026 - Microsoft, Device Guard /
  `HypervisorEnforcedCodeIntegrity`
* **Group:** Security - **NOT** part of the GAMING preset
* **SI GAME never switches this.** The Apply and Undo buttons are disabled and
  the row only shows what the machine is doing.

**What is read (read only, never written):**

| Source | Key | Value | Type |
|---|---|---|---|
| HKLM | `SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity` | `Enabled` | DWORD |
| HKLM | `SYSTEM\CurrentControlSet\Control\DeviceGuard` | `EnableVirtualizationBasedSecurity` | DWORD |
| CIM | `root\Microsoft\Windows\DeviceGuard` → `Win32_DeviceGuard` | `VirtualizationBasedSecurityStatus` | - |

**The trade-off shown in the row:**

* Memory integrity **ON** - the state column is green and says to keep it:
  it blocks kernel level malware and costs a few percent of performance.
* Memory integrity **OFF** but VBS enabled - the state column is orange: the
  hypervisor is running, the protection is not, and switching it on costs a
  little performance.
* Memory integrity **OFF** and VBS not enabled - the state column is grey.

**Undo:** none, on purpose. SI GAME writes nothing for this row, so there is
nothing to undo and the System Restore point stays the safety net.

---

## 3. The engine: how Apply and Undo fit together

Apply, for one tweak:

1. Read the current value of every registry entry the tweak wants to write,
   including the **exact type** (`DWord`, `QWord`, `String`, `ExpandString`,
   `Binary`, `MultiString`) and whether the value exists at all.
2. Read the startup type and the running state of every service.
3. Run the snapshot script, if the tweak has one (Windows AI / Recall and
   Ultimate Performance use it).
4. **Write the JSON backup to disk BEFORE the first change is made.** If the
   machine is pulled away or the change half fails, the originals are already
   safe on disk.
5. Write the registry values and set the service startup types.
6. Run the extra work (AppX removal, power plan, optional feature).
7. Write the JSON backup again, now with the extra undo data.

Undo, for one tweak:

1. Every registry entry is put back with its original type. A value that did
   not exist before is deleted again - this is what makes the undo exact.
2. Every service gets its original startup type back and is started again when
   it was running before.
3. The extra work is undone (AppX re-registered, Recall enabled again, power
   plan deleted and the previous plan re-activated).
4. The entry is removed from the JSON backup, so a second Undo does nothing.

*Undo all* walks the backup from the newest entry to the oldest, so the changes
come back in the reverse order of the changes.

The registry is written through the .NET API
(`Microsoft.Win32.Registry`), not through the PowerShell registry provider,
because the provider keeps the **old** type of a value when you write a new
one. SI GAME always writes the type it read.

---

## 4. Differences from WinUtil, on purpose

| Point | WinUtil | SI GAME |
|---|---|---|
| Undo values | hard-coded `OriginalValue` / `OriginalType` in `tweaks.json` | a real snapshot of the machine, written to `SI-GAME-backup.json` before the change |
| Multiplane Overlay | apply only | apply **and** undo |
| Widgets | apply only (the packages are removed for good) | apply **and** undo (the packages are registered again) |
| Windows AI / Recall | apply only | apply **and** undo (Recall and the AppX packages come back) |
| Ultimate Performance | apply only (the plan stays behind) | apply **and** undo (the plan is deleted, the previous one comes back) |
| Error reporting service | `wermgr` (does not exist) | `WerSvc` (the real name) |
| User profile | always `HKCU` of the elevated account | `HKCU` is remapped to `HKU:\<sid>` of the logged-on user when they are not the same person |
| State column | separate status functions | one table, so Apply and Undo can never disagree about what a tweak touches |

---

## 5. Credits and licence

The tweak set, the registry keys and the apply/undo mechanics come from
**Chris Titus WinUtil** - <https://github.com/ChrisTitusTech/winutil>, which
is licensed under the **MIT License**.

> MIT License
> Copyright (c) 2023 Chris Titus
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.

The same credit and the same MIT text are in the header of `SI-GAME.ps1`.

The four tweaks of section 2 (Game Bar background capture, HAGS, windowed game
optimizations and the read-only memory integrity row) are **not** from WinUtil.
They follow the Microsoft documentation for those settings; the windowed game
optimizations value is the one point that still has to be confirmed against the
official Microsoft documentation before the release, as written in section 2.3.
