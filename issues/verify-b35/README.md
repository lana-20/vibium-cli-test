# B35 platform verification

Two scripts that answer, on a machine we don't have, whether
`vibium screenshot -o <path>` honours the directory it is given.

Everything was measured on **macOS darwin 25.5.0 with vibium v26.5.31**. The source
(`clicker/internal/paths/paths.go`) applies the same `Pictures/Vibium` convention on
Linux and Windows, so the behaviour is *expected* to reproduce — but expected is not
measured, and the report says so. These close that gap.

## Running them

**Linux (or macOS, as a control):**

```sh
bash verify-b35.sh
```

**Windows, PowerShell 5.1 or 7+:**

```powershell
powershell -ExecutionPolicy Bypass -File verify-b35.ps1
```

Prerequisite is a working `vibium` on PATH (`npm install -g vibium`). If it is installed
somewhere unusual, set `VIBIUM_BIN` to its full path first.

Each script prints a **RESULT BLOCK** at the end — that block alone is enough to paste
into the issue; the sections above it are only there if someone wants to see the working.

## What they touch

They navigate to `example.com`, take a handful of screenshots, and write into a fresh
temp directory that is removed on exit. Files named `b35-*.png` may be left in vibium's
own screenshot directory — safe to delete, and named so they are easy to spot.

Nothing outside the temp directory and the screenshot directory is deleted.

## What each section establishes

| § | Question | macOS answer (control) |
|---|---|---|
| 1 | Where does the default land? | `~/Pictures/Vibium` |
| 2 | **Is an absolute `-o` honoured?** | **DISCARDED** |
| 3 | Do all path forms collapse? | yes; traversal guard held |
| 4 | Do `pdf` / `storage` / `record stop` honour theirs? | all honoured |
| 5 | **Backslash handling** | literal filename `C:\temp\win.png` |
| 6 | Any configurability? | `daemon --screenshot-dir` unknown; no env var |
| 7 | Symlink at the destination | **escaped the sandbox** |

§2 is the core claim. §5 is the one where Linux and Windows should genuinely differ.

## §5 — why it matters

`filepath.Base` splits only on `/` on POSIX and on both `/` and `\` on Windows. So
`-o 'C:\temp\win.png'` should produce:

- **POSIX** — a file literally named `C:\temp\win.png`
- **Windows** — `win.png`

If that holds, identical input produces different filenames per platform, which is worth
stating in the issue independently of the main defect. The PowerShell script reports it
explicitly as `split on backslash? YES/no`.

## §7 on Windows

Creating a symlink needs Developer Mode or an elevated shell. The script detects failure
and reports `skipped` rather than erroring — a skip there is fine, it is the least
important section.

## Reporting back

Paste the RESULT BLOCK into the issue with no editing. If §2 says `honoured` on your
platform, that is the most interesting possible outcome — it would mean the defect is
macOS-specific and the report needs narrowing.
