#!/usr/bin/env python3
"""
Checks every queued bug/enhancement against a real vibium source tree, so a draft
is never filed against a version where it has already been fixed.

WHY: on 2026-08-07 a reconciliation found 7 of 9 filing candidates already fixed
upstream. Upstream ships daily; a draft hardened last week is not evidence about
this week. Every false "still valid" that day came from grepping commit messages
or trusting a stale local view -- so this tool reads SOURCE, never commit titles.

Three verdicts, and the third one matters:

  STILL VALID  -- the source condition that makes the bug real is still true
  FIXED        -- the condition is gone; do not file
  UNKNOWN      -- the file or anchor moved, so nothing can be concluded

UNKNOWN is never silently treated as STILL VALID. Absence of evidence is not
evidence of absence -- that mistake is what this whole tool exists to prevent.

Before any of that it runs LANDMARK checks: fixes known to have landed on known
dates. If a landmark is missing, the checkout predates it and every other verdict
is suspect, so the run aborts. Verifying against a stale tree is the failure mode
this is guarding, and it would otherwise look like a clean pass.

Usage:
  python3 scripts/verify_upstream.py '<path-to-vibium-source>'
  python3 scripts/verify_upstream.py '<path>' --issues    # also check issue state via gh
  python3 scripts/verify_upstream.py '<path>' -v          # show reasoning per item

Source can be a git clone or an unpacked zip; no .git required.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
CLAIMS = HERE.parent / "issues" / "UPSTREAM-CLAIMS.json"

RED, GRN, YEL, DIM, BOLD, OFF = (
    "\033[31m", "\033[32m", "\033[33m", "\033[2m", "\033[1m", "\033[0m")

VERBOSE = "-v" in sys.argv or "--verbose" in sys.argv
WITH_ISSUES = "--issues" in sys.argv


def grep(root: Path, rel: str, pattern: str, is_dir: bool = False):
    """Return (found, checked). `checked` is False when the target is missing --
    the caller must render that as UNKNOWN, not as a negative result."""
    target = root / rel
    if not target.exists():
        return False, False
    rx = re.compile(pattern)
    files = [target] if not is_dir else [
        p for p in target.rglob("*") if p.is_file() and p.suffix in (".go", ".ts", ".js", ".py", ".java")]
    if not files:
        return False, False
    for f in files:
        try:
            if rx.search(f.read_text(errors="ignore")):
                return True, True
        except OSError:
            continue
    return False, True


def grep_in_func(root: Path, rel: str, func: str, pattern: str):
    """Search only inside a named Go function body (brace-naive: to the next
    line that starts with '}'). Keeps a broad pattern like 'aria-label' from
    matching elsewhere in a 3000-line file."""
    target = root / rel
    if not target.exists():
        return False, False
    text = target.read_text(errors="ignore").splitlines()
    # Must match the whole identifier. A substring test ("func mapScript" in
    # line) also matches `func mapScriptRENAMED`, so a rename to a superstring
    # would slip through and be reported as a valid result -- caught by this
    # tool's own self-test, which is the failure it is meant to prevent.
    sig = re.compile(rf"func\s+(\([^)]*\)\s*)?{re.escape(func)}\s*\(")
    start = next((i for i, l in enumerate(text) if sig.search(l)), None)
    if start is None:
        return False, False
    body = []
    for line in text[start + 1:]:
        if line.startswith("}"):
            break
        body.append(line)
    return bool(re.search(pattern, "\n".join(body))), True


def issue_state(num):
    try:
        r = subprocess.run(
            ["gh", "api", f"repos/VibiumDev/vibium/issues/{num}",
             "--jq", '"\\(.state)/\\(.state_reason // "-")"'],
            capture_output=True, text=True, timeout=20)
        return r.stdout.strip() or "?"
    except Exception:
        return "?"


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    if not args:
        print(__doc__)
        return 2
    root = Path(args[0]).expanduser()
    if not root.exists():
        print(f"{RED}source tree not found:{OFF} {root}")
        return 2

    spec = json.loads(CLAIMS.read_text())
    print(f"\n{BOLD}Source:{OFF} {root}")

    # ---------------------------------------------------------- landmarks
    print(f"\n{BOLD}0. Checkout currency{OFF}  {DIM}(a stale tree makes every verdict below meaningless){OFF}")
    newest, stale = None, []
    for lm in spec["landmarks"]["checks"]:
        found, checked = grep(root, lm["file"], lm["pattern"], lm.get("is_dir", False))
        ok = found and checked
        tag = f"{GRN}present{OFF}" if ok else f"{RED}MISSING{OFF}"
        print(f"   {lm['landed']}  {lm['desc'][:52]:<52} {tag}")
        if ok:
            newest = max(newest or lm["landed"], lm["landed"])
        else:
            stale.append(lm)
    if stale:
        print(f"\n{RED}{BOLD}ABORT — checkout is stale.{OFF} Missing "
              f"{len(stale)} landmark(s); it predates {stale[0]['landed']}.")
        print(f"{DIM}Re-download or `git pull` before trusting anything. A stale tree "
              f"reports fixed bugs as still-valid, which is exactly the mistake this "
              f"tool exists to prevent.{OFF}\n")
        return 1
    print(f"   {DIM}→ checkout is current through at least {newest}{OFF}")

    # -------------------------------------------------------------- items
    print(f"\n{BOLD}1. Queue items vs. source{OFF}")
    verdicts = {}
    for it in spec["items"]:
        checks, unknown = [], False
        for key in ("source_check", "secondary_check"):
            c = it.get(key)
            if not c:
                continue
            if "scope_func" in c:
                found, checked = grep_in_func(root, c["file"], c["scope_func"], c["pattern"])
            else:
                found, checked = grep(root, c["file"], c["pattern"], c.get("is_dir", False))
            if not checked:
                unknown = True
                checks.append((c, None))
            else:
                checks.append((c, found == (c["expect"] == "present")))

        if unknown:
            v = "UNKNOWN"
        elif all(ok for _, ok in checks):
            v = "STILL VALID" if it["status"] == "live" else "FIXED (holds)"
        else:
            v = "CHANGED"
        verdicts[it["id"]] = v

        colour = {"STILL VALID": GRN, "FIXED (holds)": DIM,
                  "CHANGED": RED, "UNKNOWN": YEL}[v]
        line = f"   {it['id']:<5} {colour}{v:<14}{OFF} {it['title'][:56]}"
        if WITH_ISSUES and it.get("issue"):
            line += f"  {DIM}#{it['issue']} {issue_state(it['issue'])}{OFF}"
        print(line)

        if VERBOSE or v in ("CHANGED", "UNKNOWN"):
            for c, ok in checks:
                if ok is None:
                    print(f"        {YEL}? {c['file']} — file/anchor not found, cannot conclude{OFF}")
                else:
                    k = "means_if_present" if (c["expect"] == "present") == ok else "means_if_absent"
                    mark = f"{GRN}✓{OFF}" if ok else f"{RED}✗{OFF}"
                    print(f"        {mark} {c.get(k, '')[:100]}")

    # ------------------------------------------------------------ verdict
    live = [i for i in spec["items"] if i["status"] == "live"]
    ok_live = [i["id"] for i in live if verdicts[i["id"]] == "STILL VALID"]
    bad = [k for k, v in verdicts.items() if v in ("CHANGED", "UNKNOWN")]

    print(f"\n{BOLD}Fileable right now:{OFF} "
          + (", ".join(ok_live) if ok_live else f"{YEL}none{OFF}"))
    if bad:
        print(f"{YEL}Needs a human look before filing:{OFF} {', '.join(bad)}")
        print(f"{DIM}CHANGED = the source condition moved. UNKNOWN = the anchor moved; "
              f"re-read the code, do not assume the bug survived.{OFF}")
    print()
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
