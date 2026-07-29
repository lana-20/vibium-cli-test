#!/usr/bin/env bash
# B35 platform verification — Linux / macOS
#
# Checks whether `vibium screenshot -o <path>` honours the directory it is given.
# Everything runs against example.com and writes only into a temp directory and
# vibium's own screenshot directory. Nothing is deleted outside those.
#
#   bash verify-b35.sh
#
# Paste the RESULT BLOCK at the end into the issue.

set -u
TMP="$(mktemp -d)"
trap 'chmod -R u+w "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
PASS="honoured"; FAIL="DISCARDED"

VIB="${VIBIUM_BIN:-vibium}"
command -v "$VIB" >/dev/null 2>&1 || { echo "vibium not found — set VIBIUM_BIN=/path/to/vibium"; exit 1; }

say() { printf '%s\n' "$*"; }
res() { printf '  %-42s %s\n' "$1" "$2"; }

say "── environment ──"
res "os"            "$(uname -s) $(uname -r)"
res "vibium"        "$("$VIB" --version 2>&1 | head -1)"
res "npm latest"    "$(npm view vibium version 2>/dev/null || echo '(npm unavailable)')"
res "HOME"          "$HOME"
res "XDG_PICTURES_DIR" "${XDG_PICTURES_DIR:-(unset)}"

"$VIB" go https://example.com >/dev/null 2>&1 || { say "could not reach example.com"; exit 1; }

# ── 1 · where does the default land? ────────────────────────────────────────
say ""; say "── 1 · default location ──"
DEFAULT_OUT="$("$VIB" screenshot -o b35-default.png 2>&1 | tail -1)"
res "reported" "$DEFAULT_OUT"
SHOTDIR="$(printf '%s' "$DEFAULT_OUT" | sed -n 's/.*saved to \(.*\)\/[^/]*$/\1/p')"
res "inferred screenshot dir" "${SHOTDIR:-(could not parse)}"

# ── 2 · is an absolute path honoured? ───────────────────────────────────────
say ""; say "── 2 · absolute path (the core claim) ──"
TARGET="$TMP/abs/b35-abs.png"
mkdir -p "$TMP/abs"
OUT="$("$VIB" screenshot -o "$TARGET" 2>&1 | tail -1)"
res "reported" "$OUT"
if [ -f "$TARGET" ]; then R2="$PASS"; else R2="$FAIL"; fi
res "file at requested path?" "$R2"

# ── 3 · path forms ──────────────────────────────────────────────────────────
say ""; say "── 3 · path forms ──"
cd "$TMP"
for form in "b35-rel.png" "./b35-dot.png" "$HOME/b35-home.png" "sub/b35-nested.png" "../../../../tmp/b35-trav.png"; do
  O="$("$VIB" screenshot -o "$form" 2>&1 | tail -1)"
  res "$form" "$(printf '%s' "$O" | sed "s|$HOME|~|")"
done
res "escaped to /tmp/b35-trav.png?" "$([ -f /tmp/b35-trav.png ] && echo 'YES — guard failed' || echo 'no — guard held')"
rm -f "$HOME/b35-home.png" /tmp/b35-trav.png 2>/dev/null

# ── 4 · sibling commands ────────────────────────────────────────────────────
say ""; say "── 4 · sibling commands (expected: all honour their paths) ──"
"$VIB" pdf -o "$TMP/b35.pdf"       >/dev/null 2>&1; res "pdf -o"        "$([ -f "$TMP/b35.pdf" ]  && echo "$PASS" || echo "$FAIL")"
"$VIB" storage -o "$TMP/b35.json"  >/dev/null 2>&1; res "storage -o"    "$([ -f "$TMP/b35.json" ] && echo "$PASS" || echo "$FAIL")"
"$VIB" record start --name b35 >/dev/null 2>&1; sleep 1
"$VIB" record stop -o "$TMP/b35.zip" >/dev/null 2>&1; res "record stop -o" "$([ -f "$TMP/b35.zip" ] && echo "$PASS" || echo "$FAIL")"

# ── 5 · Windows-style path on a POSIX box ───────────────────────────────────
say ""; say "── 5 · backslash path (should NOT split on POSIX) ──"
BACKSLASH="$("$VIB" screenshot -o 'C:\temp\win.png' 2>&1 | tail -1 | sed 's|.*/||')"
res 'C:\temp\win.png -> basename' "$BACKSLASH"

# ── 6 · configurability ─────────────────────────────────────────────────────
say ""; say "── 6 · configurability ──"
DAEMONFLAG="$("$VIB" daemon start --screenshot-dir "$TMP" 2>&1 | tail -1 | head -c 60)"
res "daemon start --screenshot-dir" "$DAEMONFLAG"
ENVOUT="$(VIBIUM_SCREENSHOT_DIR="$TMP" "$VIB" screenshot -o b35-env.png 2>&1 | tail -1 | sed "s|$HOME|~|")"
res "VIBIUM_SCREENSHOT_DIR honoured?" "$ENVOUT"

# ── 7 · symlink at the destination filename ─────────────────────────────────
say ""; say "── 7 · symlink escape ──"
if [ -n "${SHOTDIR:-}" ] && [ -d "$SHOTDIR" ]; then
  mkdir -p "$TMP/escape"
  ln -sf "$TMP/escape/out.png" "$SHOTDIR/b35-sneaky.png" 2>/dev/null
  "$VIB" screenshot -o b35-sneaky.png >/dev/null 2>&1
  if [ -f "$TMP/escape/out.png" ]; then res "wrote through symlink?" "YES — escaped the sandbox"; else res "wrote through symlink?" "no — contained"; fi
  rm -f "$SHOTDIR/b35-sneaky.png"
else
  res "wrote through symlink?" "skipped (screenshot dir not resolved)"
fi

# ── result block ────────────────────────────────────────────────────────────
cat <<BLOCK

════════════ RESULT BLOCK — paste this into the issue ════════════
os:                  $(uname -s) $(uname -r) ($(uname -m))
vibium:              $("$VIB" --version 2>&1 | head -1)
screenshot dir:      ${SHOTDIR:-unknown}
XDG_PICTURES_DIR:    ${XDG_PICTURES_DIR:-(unset)}

absolute -o honoured:      $R2
pdf / storage / record -o: $([ -f "$TMP/b35.pdf" ] && echo ok || echo FAIL) / $([ -f "$TMP/b35.json" ] && echo ok || echo FAIL) / $([ -f "$TMP/b35.zip" ] && echo ok || echo FAIL)
traversal guard held:      $([ -f /tmp/b35-trav.png ] && echo NO || echo yes)
backslash 'C:\temp\win.png' -> $BACKSLASH
daemon --screenshot-dir:   $DAEMONFLAG
VIBIUM_SCREENSHOT_DIR:     $ENVOUT
symlink escape:            $([ -f "$TMP/escape/out.png" ] && echo YES || echo no)
══════════════════════════════════════════════════════════════════

Cleanup: this script removed its own temp files. Screenshots named b35-*.png
may remain in your vibium screenshot directory — safe to delete.
BLOCK
