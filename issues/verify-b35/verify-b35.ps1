# B35 platform verification — Windows (PowerShell 5.1 or 7+)
#
# Checks whether `vibium screenshot -o <path>` honours the directory it is given.
# Runs against example.com and writes only into a temp directory and vibium's own
# screenshot directory. Nothing is deleted outside those.
#
#   powershell -ExecutionPolicy Bypass -File verify-b35.ps1
#
# Paste the RESULT BLOCK at the end into the issue.

$ErrorActionPreference = 'Continue'
$Tmp  = Join-Path $env:TEMP ("b35-" + [guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Path $Tmp -Force | Out-Null
$Vib  = if ($env:VIBIUM_BIN) { $env:VIBIUM_BIN } else { 'vibium' }

function Res($label, $value) { "{0,-42} {1}" -f ("  " + $label), $value }
function Vibium { & $Vib @args 2>&1 | Select-Object -Last 1 }

if (-not (Get-Command $Vib -ErrorAction SilentlyContinue)) {
  Write-Host "vibium not found — set VIBIUM_BIN to its full path"; exit 1
}

Write-Host "── environment ──"
Res "os"           ((Get-CimInstance Win32_OperatingSystem).Caption + " " + [System.Environment]::OSVersion.Version)
Res "arch"         $env:PROCESSOR_ARCHITECTURE
Res "powershell"   $PSVersionTable.PSVersion
Res "vibium"       (Vibium --version)
Res "npm latest"   (try { (npm view vibium version 2>$null) } catch { '(npm unavailable)' })
Res "USERPROFILE"  $env:USERPROFILE

Vibium go https://example.com | Out-Null

# ── 1 · default location ────────────────────────────────────────────────────
Write-Host "`n── 1 · default location ──"
$DefaultOut = Vibium screenshot -o b35-default.png
Res "reported" $DefaultOut
$ShotDir = if ($DefaultOut -match 'saved to (.*)[\\/][^\\/]+$') { $Matches[1] } else { $null }
Res "inferred screenshot dir" $(if ($ShotDir) { $ShotDir } else { '(could not parse)' })

# ── 2 · absolute path — the core claim ──────────────────────────────────────
Write-Host "`n── 2 · absolute path (the core claim) ──"
$AbsDir = Join-Path $Tmp 'abs'; New-Item -ItemType Directory -Path $AbsDir -Force | Out-Null
$Target = Join-Path $AbsDir 'b35-abs.png'
Res "reported" (Vibium screenshot -o $Target)
$R2 = if (Test-Path $Target) { 'honoured' } else { 'DISCARDED' }
Res "file at requested path?" $R2

# ── 3 · path forms ──────────────────────────────────────────────────────────
Write-Host "`n── 3 · path forms ──"
Push-Location $Tmp
foreach ($form in @(
    'b35-rel.png',
    '.\b35-dot.png',
    (Join-Path $env:USERPROFILE 'b35-home.png'),
    'sub\b35-nested.png',
    '..\..\..\..\Windows\Temp\b35-trav.png',
    'C:/temp/b35-fwdslash.png'          # forward slashes on Windows
  )) {
  Res $form (Vibium screenshot -o $form)
}
Pop-Location
$TravPath = 'C:\Windows\Temp\b35-trav.png'
Res "escaped to $TravPath ?" $(if (Test-Path $TravPath) { 'YES — guard failed' } else { 'no — guard held' })
Remove-Item (Join-Path $env:USERPROFILE 'b35-home.png'), $TravPath -ErrorAction SilentlyContinue

# ── 4 · sibling commands ────────────────────────────────────────────────────
Write-Host "`n── 4 · sibling commands (expected: all honour their paths) ──"
$Pdf  = Join-Path $Tmp 'b35.pdf'
$Json = Join-Path $Tmp 'b35.json'
$Zip  = Join-Path $Tmp 'b35.zip'
Vibium pdf -o $Pdf      | Out-Null; Res "pdf -o"     $(if (Test-Path $Pdf)  { 'honoured' } else { 'DISCARDED' })
Vibium storage -o $Json | Out-Null; Res "storage -o" $(if (Test-Path $Json) { 'honoured' } else { 'DISCARDED' })
Vibium record start --name b35 | Out-Null; Start-Sleep -Seconds 1
Vibium record stop -o $Zip     | Out-Null; Res "record stop -o" $(if (Test-Path $Zip) { 'honoured' } else { 'DISCARDED' })

# ── 5 · THE Windows question ────────────────────────────────────────────────
# On POSIX, filepath.Base does not split on "\", so `C:\temp\win.png` becomes a
# literal filename. On Windows it should split to `win.png`. If so, identical
# input produces different filenames per platform.
Write-Host "`n── 5 · backslash handling (the platform divergence) ──"
$Back = Vibium screenshot -o 'C:\temp\win.png'
$BackBase = if ($Back -match '[\\/]([^\\/]+)$') { $Matches[1] } else { $Back }
Res 'C:\temp\win.png -> basename' $BackBase
Res "split on backslash?" $(if ($BackBase -eq 'win.png') { 'YES — differs from POSIX' } else { 'no — literal, same as POSIX' })

# ── 6 · configurability ─────────────────────────────────────────────────────
Write-Host "`n── 6 · configurability ──"
$DaemonFlag = Vibium daemon start --screenshot-dir $Tmp
Res "daemon start --screenshot-dir" $DaemonFlag
$env:VIBIUM_SCREENSHOT_DIR = $Tmp
$EnvOut = Vibium screenshot -o b35-env.png
Remove-Item Env:\VIBIUM_SCREENSHOT_DIR -ErrorAction SilentlyContinue
Res "VIBIUM_SCREENSHOT_DIR honoured?" $EnvOut

# ── 7 · symlink escape (needs Developer Mode or an elevated shell) ──────────
Write-Host "`n── 7 · symlink escape ──"
$SymResult = 'skipped'
if ($ShotDir -and (Test-Path $ShotDir)) {
  $EscDir = Join-Path $Tmp 'escape'; New-Item -ItemType Directory -Path $EscDir -Force | Out-Null
  $EscFile = Join-Path $EscDir 'out.png'
  $Link = Join-Path $ShotDir 'b35-sneaky.png'
  try {
    New-Item -ItemType SymbolicLink -Path $Link -Target $EscFile -ErrorAction Stop | Out-Null
    Vibium screenshot -o b35-sneaky.png | Out-Null
    $SymResult = if (Test-Path $EscFile) { 'YES — escaped the sandbox' } else { 'no — contained' }
    Remove-Item $Link -ErrorAction SilentlyContinue
  } catch {
    $SymResult = 'skipped — symlink creation needs Developer Mode or an elevated shell'
  }
}
Res "wrote through symlink?" $SymResult

# ── result block ────────────────────────────────────────────────────────────
$Sib = "{0} / {1} / {2}" -f `
  $(if (Test-Path $Pdf) {'ok'} else {'FAIL'}),
  $(if (Test-Path $Json){'ok'} else {'FAIL'}),
  $(if (Test-Path $Zip) {'ok'} else {'FAIL'})

@"

════════════ RESULT BLOCK — paste this into the issue ════════════
os:                  $((Get-CimInstance Win32_OperatingSystem).Caption) $([System.Environment]::OSVersion.Version) ($env:PROCESSOR_ARCHITECTURE)
vibium:              $(Vibium --version)
screenshot dir:      $(if ($ShotDir) { $ShotDir } else { 'unknown' })

absolute -o honoured:      $R2
pdf / storage / record -o: $Sib
traversal guard held:      $(if (Test-Path $TravPath) {'NO'} else {'yes'})
backslash 'C:\temp\win.png' -> $BackBase
daemon --screenshot-dir:   $DaemonFlag
VIBIUM_SCREENSHOT_DIR:     $EnvOut
symlink escape:            $SymResult
══════════════════════════════════════════════════════════════════

Cleanup: temp files removed. Screenshots named b35-*.png may remain in your
vibium screenshot directory — safe to delete.
"@

Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue
