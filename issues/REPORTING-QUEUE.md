# Vibium reporting queue

Cross-suite tracker for everything worth reporting upstream to VibiumDev/vibium —
CLI, MCP, JS, Java and Python findings in one place. Update the checkbox and the
**Filed as** line in the matching write-up whenever something moves.

Last reconciled with upstream: **2026-07-28** · published npm `latest`: **v26.5.31**
All five hardened to filing standard 2026-07-28, including a three-way
vibium/Playwright/Selenium parity pass measured on testtrack.org/canvas-demo.

---

## A · Ready to file — new issues

Nothing upstream covers these. Write-ups are complete and every repro has been run
verbatim.

- [ ] **B35 · `screenshot -o` output path silently discarded; CLI inherits the MCP sandbox**
  Severity Medium · P2 · CLI only · **fully hardened, ready to file**
  All path forms flatten to `~/Pictures/Vibium/<basename>`; `pdf`, `storage` and
  `record stop` honour theirs. Silent — `--json` reports `ok:true`, exit 0.
  → [`B35.md`](B35.md) · **only genuinely novel finding of this batch** · hardened 2026-07-28
  → **Lead with the root cause, not the symptom.** The flattening is deliberate — a
  path-traversal guard in `agent/handlers.go`. The CLI dispatches through
  `daemonCall("browser_screenshot", …)`, so it is treated as an untrusted agent surface.
  The guard is right for MCP and wrong for a user's own shell, and MCP is also the *only*
  surface with `--screenshot-dir`.
  → Propose a **surface-aware** fix. "Just honour the path" would reintroduce the
  traversal risk on MCP and will be rejected.
  → **Strongest argument:** every capability the fix needs already ships. Directory trees
  are created on demand for `--screenshot-dir`; path errors are reported accurately
  (`permission denied`, `file name too long`); a no-disk mode exists (`--screenshot-dir ""`);
  and `internal/api/recording.go`'s `WriteRecordToFile` is the in-tree precedent — which
  is why `record stop -o` works.
  → **Handle the security angle carefully.** The guard is bypassable: a symlink already at
  the destination basename is followed. Frame as defence-in-depth, *not* remotely
  exploitable — planting the link needs write access `browser_screenshot` does not grant.
  It weakens the rationale for flattening the CLI; it is not an attack to publicise.
  → Not macOS-specific: `GetScreenshotDir()` uses `Pictures/Vibium` on Linux and Windows.
  Long-standing, not a regression — predates the Mar-2026 `mcp → agent` rename.
  → Platform gap has a two-minute answer attached: [`verify-b35/`](verify-b35/) ships
  `verify-b35.sh` and `verify-b35.ps1`, each printing a paste-ready RESULT BLOCK. Ask a
  Linux/Windows holder to run one **before or just after filing**; §5 predicts backslash
  splitting differs by platform.

- [ ] **B24 · `map` misses framework-attached click handlers**
  Severity Medium · P3 · CLI
  Previously deferred upstream for lack of a stable repro (original page 404s). Now has
  a self-contained `vibium content` signal matrix that cannot rot, plus coffee-cart.app
  where all 9 product divs are invisible to `map`.
  → [`B24.md`](B24.md)
  → Correct the record when filing: the original description ("map only scans semantic
  elements") was **wrong**. It misses `addEventListener` handlers and ignores
  `cursor:pointer`; static `role`/`tabindex`/`onclick` work fine.
  → Fold in the ui5.sap.com update: CLI `map` improved from 0 refs (2026-05-19 report)
  to 137, and **now matches MCP exactly** (137 vs 137; coffee-cart 4 vs 4).
  → **Do not repeat the "MCP may be more complete" lead** — that was in an earlier draft
  and is now disproven. Both surfaces share the gap, so one fix covers both.

- [ ] **FR1 · Expose `BrowserContext.addInitScript` on the CLI and MCP surfaces**
  Enhancement — surface parity, not a new capability
  Already implemented and passing in the Python (`context.add_init_script`) and Java
  (`context.addInitScript`) clients; absent from CLI and MCP. Justified by measured
  determinism data: 190× noise-to-signal unseeded vs 0.00% with a pre-load seed.
  → **Selenium needs no first-class API** — raw CDP `Page.addScriptToEvaluateOnNewDocument`
  reaches the same 0.00%. So vibium's agent-facing surfaces are the only ones in the
  comparison without any pre-load mechanism at all.
  → [`FR1.md`](FR1.md)
  → File as `enhancement`, not a bug. Reference #130/#167 — `context.addInitScript` is
  already the documented workaround for `page.addScript()` not surviving navigation.

## B · Ready to comment — existing issues

- [ ] **B34 → comment on [#221](https://github.com/VibiumDev/vibium/issues/221)** (OPEN, 0 comments)
  `eval` drops all exception detail. **Do not file a duplicate** — #221 already has it,
  and locates the root cause in `clicker/internal/bidi/script.go`.
  Our comment adds what #221 lacks: the 6-class exception matrix, all flags
  (`--json`/`--verbose`/`--stdin`) unrecoverable, MCP cross-surface confirmation,
  a `try/catch` control proving the data is reachable, 3-site independence,
  **a three-way comparison showing Playwright and Selenium both return the message**
  (the strongest single argument — this is not a hard problem peers also failed),
  **the escalation that the Python and JS clients swallow the exception entirely**
  (return None/null, never raise — worse than the CLI, which at least exits 1), and the
  [#156](https://github.com/VibiumDev/vibium/issues/156) sibling
  (`failed to annotate: script exception:` — same truncated suffix, likely same helper).
  → [`B34.md`](B34.md)

- [ ] **B30 → comment on [#112](https://github.com/VibiumDev/vibium/issues/112)** (CLOSED — comments still land)
  Ask that B30 be closed as **fixed by #182**, not "not reproduced". Its `<img>` case is
  B6: `hover` has no `--timeout` and a zero default on v26.5.31, so it never auto-waits;
  an `<img>` is just the most common briefly-zero-size element. `dblclick` and `check`
  fail identically. "Not reproduced" invites a reopen the first time someone hovers an
  uncached image on a published build.
  → [`B30.md`](B30.md)

## C · Filed, awaiting maintainer

No action needed unless they go stale. Recheck when a build newer than v26.5.31 ships.

| Item | Issue | State | Note |
|---|---|---|---|
| CLI B3 · click/dialog deadlock | [#151](https://github.com/VibiumDev/vibium/issues/151) | OPEN | deferred; also covers MCP MB3 |
| CLI B8, B10–B13, B16, B17, B19, B21, B23, B25–B29, B33 | #195–#213 | OPEN | split out of #112 on 2026-07-06 |
| JS Bug 2 · `evaluate` nested `string[][]` | [#124](https://github.com/VibiumDev/vibium/issues/124) | OPEN | Go deserializer; still `test.skip` |
| Java B3 · `waitForFunction` double-wrap | [#174](https://github.com/VibiumDev/vibium/issues/174) | OPEN | |
| Java B7 · `page.expose()` | [#135](https://github.com/VibiumDev/vibium/issues/135) | OPEN | maintainer deferred; needs API redesign |
| Java B10 · `setHeaders` deadlock | [#128](https://github.com/VibiumDev/vibium/issues/128) | OPEN | same root cause as route/dialog deadlock |

### C1 · Partial fixes reported on issues that stayed closed

Comments posted 2026-06-06; all four remain CLOSED. **Decide whether to request a
reopen** — the residual failures are real and currently untracked by any open issue.

- [ ] **Java B1** → [#129](https://github.com/VibiumDev/vibium/issues/129) — `waitForURL` glob/regex: `**/*.html` (path-separator glob) and regex `.*x.*` still fail
- [ ] **Java B2** → [#130](https://github.com/VibiumDev/vibium/issues/130) — `addScript → go() → evaluate` still returns null (cross-navigation persistence, the primary use case)
- [ ] **Java B8** → [#136](https://github.com/VibiumDev/vibium/issues/136) — `window.ErrorEvent` dispatch and unhandled Promise rejections still not forwarded
- [ ] **Java B9** → [#137](https://github.com/VibiumDev/vibium/issues/137) — clock: residual failures beyond the ISO-8601/epoch-ms fix

## D · Do not file — investigated and rejected

Kept so they are not re-raised. Both cost real time before being ruled out.

- [x] **`eval` "leaks" `const`/`let` across invocations** — **not a bug.** The scope is
  document-lifetime and clears on reload and navigation, which is correct JS semantics.
  It only *looked* like a bug because B34 strips the error message. Verified 2026-07-28.
- [x] **Daemon degrades over a long session** — **failed re-testing.** Four hypotheses,
  all negative. MCP ~490ms/call vs CLI ~140ms remains confounded by harness overhead.
  See `feedback_vibium_timing_gotchas`.

## E · Recheck after the next npm publish

Eight bugs are **fixed in source but unpublished** — they still FAIL on any installed
build and that is expected, not a regression. When `npm view vibium version` exceeds
26.5.31:

- [ ] Re-run `/vibium-cli-test`; confirm **B6, B9, B14, B18, B20, B22, B30, B31** flip to PASS
- [ ] Re-run `/vibium-java-test`, `/vibium-js-test`, `/vibium-python-test`, `/vibium-mcp-test`
- [ ] Recheck B34/#221 and B24 — either may be fixed in the same window
- [ ] Update the status table in the cli-test README and every suite's baseline line

## F · Internal doc sync — not upstream

- [x] **Audited our own suites for null-expecting `evaluate` assertions** (2026-07-28).
  While the clients swallow JS exceptions (#221), any assertion expecting null/None passes
  both when the value is genuinely absent *and* when the script threw. Found exactly one —
  `context.clearStorage removes localStorage entries` in vibium-js-test — fixed in
  `27770fe` with a `JSON.stringify` sentinel. The Python suite was already clean
  (`assert ... is not None`, the safe direction). Java suite not audited.

- [ ] `project_vibium_wiki` memory still says *"CLI bugs: B1–B33 (umbrella issue #112
  covers all 33; no per-bug issues)"* — **stale.** #112 is closed and split; per-bug
  issues exist. Update the wiki's bug-numbering convention and any graph nodes that
  encode the #112 mapping.
- [ ] Consider a `CLI #NNN` prefix alongside the existing `MCP #NNN` / `JS #NNN` /
  `Jv #NNN` / `Py #NNN` conventions, now that CLI bugs have individual issue numbers.

---

## Filing conventions

- One issue per bug — the maintainers explicitly moved to this on 2026-06-30 and
  completed the split on 2026-07-06. Do not open another umbrella issue.
- **Search before writing.** B34 was fully written and hardened before #221 was found
  already open. Check `gh search issues --repo VibiumDev/vibium "<keywords>"` first.
- vibium is **WebDriver BiDi, not CDP**. Do not cite CDP field names in suggested fixes;
  an earlier draft of B34 got this wrong.
- Always state the platform and version scope. Everything here is macOS darwin 25.5.0 on
  v26.5.31 unless noted; Linux and Windows are untested.
- Include a recovery path or workaround when one exists — it sets severity honestly and
  is the difference between B24 (P3, `find` still works) and B16 (no recovery at all).
