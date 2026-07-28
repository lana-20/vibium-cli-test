# vibium-cli-test

A Claude Code skill that runs a full regression suite against [vibium](https://www.npmjs.com/package/vibium) — a browser automation CLI built on WebDriver BiDi.

The suite covers **35 bugs**. B1–B33 were originally found in vibium v26.3.18 and verified across 23 sites; B34–B35 were found in v26.5.31.

> **The original umbrella issue is closed.** [VibiumDev/vibium#112](https://github.com/VibiumDev/vibium/issues/112) was closed on 2026-07-06 after the maintainers split all 33 bugs into individual issues, one per bug, so each can be tracked and closed by its own PR. **The B-numbers are now labels for this suite, not a mapping to #112.** Per-bug issue numbers are in the table below.

Each test produces a `PASS / FAIL / PARTIAL / SKIP` result and includes exact repro steps and error strings so a developer can reproduce failures without running the suite.

## Status as of 2026-07-28 · published npm `latest` = v26.5.31

Three distinct states, and the middle one matters when reading suite output:

| State | Bugs | What the suite reports |
|---|---|---|
| **Fixed and published** in v26.5.31 | B1, B2, B4, B5, B7 | PASS |
| **Fixed in source, not yet published** | B6, B9, B14, B18, B20, B22, B30, B31 | **FAIL / PARTIAL — expected.** The fixes are merged but `npm latest` is still v26.5.31, so they are absent from any installed build. Not a regression. |
| **Open** | B3, B8, B10–B13, B16, B17, B19, B21, B23, B25–B29, B33 | FAIL |

Also: B15 passes (confirmed correct behaviour, regression check only); B32 is deferred.

**B24 has a working repro again.** It was deferred upstream because `blackboxpuzzles.workroomprds.com/puzzle29.html` now 404s. Re-tested from scratch: the bug is real but the original description was wrong — `map` does expose non-semantic elements when clickability is declared statically (`role`, `tabindex`, inline `onclick`); it misses handlers attached with `addEventListener`, and ignores `cursor:pointer`. New repro is [coffee-cart.app](https://coffee-cart.app/), where all 9 product cups are invisible to `map` (4 refs returned, none of them products), plus a self-contained `vibium content` signal matrix that cannot rot. See [`issues/B24.md`](issues/B24.md).

**B30 resolved — it is a symptom of B6.** The 2026-07-06 triage said "not reproduced"; our 2026-06-01 run said PARTIAL. Both are correct, measured on different builds. On published v26.5.31 `hover` has no `--timeout` and an effective default of **zero**, so it never auto-waits — and an `<img>` is simply the most common element that is briefly zero-size before it loads. `hover`, `dblclick` and `check` all fail identically with `timeout after 0s: visible check failed — zero size`, and none accept `--timeout`. [#182](https://github.com/VibiumDev/vibium/pull/182) names `hover` among the ~10 commands it fixes and sets a nonzero default, so B30 closes with it. Comment draft in [`issues/B30.md`](issues/B30.md) — it should be closed as *fixed by #182*, not *not reproduced*.

**Reporting queue:** [`issues/REPORTING-QUEUE.md`](issues/REPORTING-QUEUE.md) tracks everything worth reporting upstream across all five vibium suites — what is ready to file, ready to comment, awaiting the maintainers, explicitly rejected, and what to recheck after the next npm publish.

Two items are tracked here but not filed as bugs:

- [`issues/B34.md`](issues/B34.md) — **already reported upstream as [#221](https://github.com/VibiumDev/vibium/issues/221)**. The file is now a comment draft adding scope evidence, not a new report. Do not file.
- [`issues/FR1.md`](issues/FR1.md) — enhancement: expose the existing `BrowserContext.addInitScript` on the CLI and MCP surfaces. A parity gap, not a defect; no test in the suite.

## Usage

Install the skill via Claude Code, then run:

```
/vibium-cli-test
```

Claude will execute all 35 tests against the running vibium daemon and print a summary table.

## What it tests

| # | Severity | Priority | Command | Bug | Upstream |
|---|----------|----------|---------|-----|----------|
| B1 | Critical | P1 | `vibium count` | ~~Go type mismatch — crashes on every selector~~ **Fixed v26.5.31** | v26.5.31 · also #206 |
| B2 | Critical | P1 | `vibium storage` | ~~Go type mismatch — crashes on all sites~~ **Fixed v26.5.31** | v26.5.31 |
| B3 | Critical | P1 | `vibium click` (dialog/nav) | Navigation events deadlock daemon socket; three confirmed trigger patterns | [#151](https://github.com/VibiumDev/vibium/issues/151) OPEN |
| B4 | High | P1 | `vibium cookies <name> <value>` | ~~BiDi requires domain field; set always fails~~ **Fixed v26.5.31** — domain derived from current page | v26.5.31 |
| B5 | High | P1 | `vibium select` | ~~Silent false success on invalid or text-matched options~~ **Fixed v26.5.31** — now errors on no match; matches by visible label | v26.5.31 |
| B6 | High | P1 | `vibium click --timeout` | Flag accepted but silently ignored | [#182](https://github.com/VibiumDev/vibium/pull/182) merged |
| B7 | High | P1 | `vibium fill` | ~~Crashes on `<textarea>` — `element type is not supported`~~ **Fixed v26.5.31** | v26.5.31 |
| B8 | High | P2 | `vibium attr` | Boolean attributes indistinguishable from absent | [#198](https://github.com/VibiumDev/vibium/issues/198) OPEN |
| B9 | High | P2 | `vibium eval` | Objects and arrays print Go internal repr | [#180](https://github.com/VibiumDev/vibium/pull/180) merged |
| B10 | Medium | P2 | `vibium is actionable` | Requires 2 args; all sibling commands require 1 | [#199](https://github.com/VibiumDev/vibium/issues/199) OPEN |
| B11 | Medium | P2 | `vibium back` | Off-by-one at history boundary navigates to `about:blank` | [#200](https://github.com/VibiumDev/vibium/issues/200) OPEN |
| B12 | Medium | P2 | `vibium completion zsh` | Generated script errors on source | [#201](https://github.com/VibiumDev/vibium/issues/201) OPEN |
| B13 | Medium | P2 | `vibium daemon status/stop` | Always exit 0 regardless of daemon state | [#202](https://github.com/VibiumDev/vibium/issues/202) OPEN |
| B14 | Medium | P2 | `vibium geolocation` | Negative coordinates parsed as flags | [#179](https://github.com/VibiumDev/vibium/pull/179) merged |
| B15 | Medium | P2 | `vibium find text` | Searches DOM text, not CSS-transformed display text — **confirmed correct/consistent behavior** (regression check only) | not reproduced |
| B16 | Medium | P2 | `vibium map` | Web Components shadow DOM elements not exposed — eval shadowRoot workaround also returns `null` (full failure, no recovery path) | [#203](https://github.com/VibiumDev/vibium/issues/203) OPEN |
| B17 | Medium | P2 | `vibium find role` | `input[type=submit]` not found as `role button`; 30s timeout | [#204](https://github.com/VibiumDev/vibium/issues/204) OPEN |
| B18 | Medium | P2 | `vibium fill` / `vibium type` | Negative values parsed as flags — `unknown shorthand flag: '2' in -2` | [#179](https://github.com/VibiumDev/vibium/pull/179) merged |
| B19 | Medium | P2 | `vibium frame` | Frame context doesn't persist across CLI invocations | [#205](https://github.com/VibiumDev/vibium/issues/205) OPEN |
| B20 | Medium | P2 | `vibium fill` | Rejects empty string at CLI level — `Error: value is required` | [#187](https://github.com/VibiumDev/vibium/issues/187) closed |
| B21 | High | P3 | `vibium bidi-test` / `vibium launch-test` | BiDi WebSocket URL blank in ChromeDriver 147.0 | [#210](https://github.com/VibiumDev/vibium/issues/210) OPEN |
| B22 | Medium | P3 | `vibium sleep` | Negative values parsed as flags | [#179](https://github.com/VibiumDev/vibium/pull/179) merged |
| B23 | Medium | P3 | `vibium sleep` | Oversize values silently clamp to 30000ms | [#211](https://github.com/VibiumDev/vibium/issues/211) OPEN |
| B24 | Medium | P3 | `vibium map` | Framework-attached (`addEventListener`) click handlers not exposed as refs; static `role`/`tabindex`/`onclick` are | ready to file — new repro |
| B25 | Medium | P3 | `vibium text` | Buffer overflow crash on large page text (`bufio.Scanner: token too long`) | [#209](https://github.com/VibiumDev/vibium/issues/209) OPEN |
| B26 | Low | P3 | `vibium check` | No element type guard | [#195](https://github.com/VibiumDev/vibium/issues/195) OPEN |
| B27 | Low | P3 | `vibium ws-test` | `http://`/`https://` scheme not caught at input | [#196](https://github.com/VibiumDev/vibium/issues/196) OPEN |
| B28 | Low | P3 | `vibium upload` | No element type guard | [#197](https://github.com/VibiumDev/vibium/issues/197) OPEN |
| B29 | Low | P3 | `vibium find` | CSS selector and some find modes return @ref for disabled elements (exit 0); `vibium map` correctly excludes them | [#212](https://github.com/VibiumDev/vibium/issues/212) OPEN |
| B30 | Low | P3 | `vibium hover` | **PARTIAL v26.5.31** — `<div>` hover fixed; `<img>` with external src still fails (`visible check failed — zero size`). Root cause is B6 (zero default timeout), not `<img>` handling | [#182](https://github.com/VibiumDev/vibium/pull/182) merged |
| B31 | Low | P3 | `vibium fill` | Crashes on `input[type=range]` — `editable check failed` | [#188](https://github.com/VibiumDev/vibium/issues/188) closed |
| B32 | Low | P4 | `vibium serve` | **PARTIAL v26.5.31** — teardown clean on SIGTERM (fixed); no `--port` hint on port conflict (still failing) | deferred — minor UX |
| B33 | Low | P4 | `vibium content ""` | Inconsistent error message vs no-arg invocation | [#213](https://github.com/VibiumDev/vibium/issues/213) OPEN |
| B34 | High | P2 | `vibium eval` / `browser_evaluate` | All exception detail dropped — every error reduced to `script exception:`; reproduces identically on the MCP surface | [#221](https://github.com/VibiumDev/vibium/issues/221) OPEN — do not re-file |
| B35 | Medium | P2 | `vibium screenshot -o` | Output path silently discarded — CLI routes through the MCP handler and inherits its path-traversal guard; `pdf`/`storage`/`record stop` honour theirs | not yet filed |

B34 and B35 are **appended rather than renumbered** into strict priority order. B34 is
High · P2 and would otherwise sort next to B9. Renumbering is no longer about #112 — that
issue is closed — but the B-numbers are cited across the individual upstream issues, the
`issues/` write-ups, and prior comment history, so they are kept stable. Priority
ordering within B1–B33 is unchanged.

## Cross-site coverage

Bugs are verified across 23 sites:

| Site | Tests |
|------|-------|
| [testtrack.org](https://testtrack.org) | B1–B33 (baseline) |
| [var.parts](https://var.parts/) | B1, B4 |
| [sauce-demo.myshopify.com](https://sauce-demo.myshopify.com/) | B1, B4 |
| [saucedemo.com](https://www.saucedemo.com) | B1, B4 |
| [demo.prestashop.com](https://demo.prestashop.com/) | B1, B2, B3 (nav deadlock) |
| [coffee-cart.app](https://coffee-cart.app/) | B1, B2, B4, **B24 (primary repro — 9 Vue `.cup` divs invisible to `map`)** |
| [ecommerce-playground.lambdatest.io](https://ecommerce-playground.lambdatest.io/) | B1, B2, B4, B5 |
| [automationteststore.com](https://automationteststore.com/) | B1, B2, B4, B5 |
| [academybugs.com](https://academybugs.com/) | B1, B2, B4, B9, B15 |
| [www.shino.de/parkcalc](https://www.shino.de/parkcalc/) | B1, B5 |
| [testpages.eviltester.com](https://testpages.eviltester.com/styled/index.html) | B3 (pre-stub), B7 |
| [phptravels.com/demo](http://phptravels.com/demo/) | B3 (form submit deadlock) |
| [shop.polymer-project.org](https://shop.polymer-project.org/) | B16 (shadow DOM map) |
| [practicesoftwaretesting.com](https://practicesoftwaretesting.com/) | B17 (`find role button` on `input[type=submit]`) |
| [qa-practice.razvanvancea.ro](https://qa-practice.razvanvancea.ro/) | B15 (CSS uppercase ADD TO CART) |
| ~~blackboxpuzzles.workroomprds.com~~ | ~~B24~~ — **404, retired 2026-07-28**, replaced by coffee-cart.app |
| [ui5.sap.com](https://ui5.sap.com/#/demoapps) | B24 secondary (91 non-semantic `cursor:pointer` elements unexposed) |
| [bugeater.web.app](https://bugeater.web.app/) | B18 (fill/type reject negative values) |
| [compendiumdev.co.uk/apps/iframe-search](http://compendiumdev.co.uk/apps/iframe-search/iframe-search.html) | B5 (select silent false success) |
| [the-internet.herokuapp.com](http://the-internet.herokuapp.com/) | B19 (frame context), B20 (fill empty string), B28 (upload type guard), B30 (hover non-interactive), B31 (fill range) |
| [randomuser.me](https://randomuser.me/) | B25 (text buffer overflow) |
| [example.com](https://example.com) | B34 (exception detail dropped) |
| [testtrack.org/canvas-demo](https://testtrack.org/canvas-demo) | B34, B35 |

B35 is a local filesystem path-handling bug and is not site-dependent — it reproduces on
any page. B34 was confirmed page-independent across three stacks (example.com,
testtrack.org, saucedemo.com) and on both the CLI and MCP surfaces.

## B3 daemon deadlock — known triggers

B3 has three confirmed trigger patterns. All deadlock the daemon socket:

1. **JS alert/confirm/prompt dialogs** — original repro: `vibium click` on any button that calls `window.alert()`. Workaround: pre-stub via `vibium eval 'window.alert = () => {}'` before clicking.
2. **Form POST navigation** — clicking a submit button that triggers a server-side POST request and full page reload (PHP Travels demo form). Pre-stubbing dialogs does not help. Workaround: `vibium eval 'form.submit()'` or avoid clicking submit buttons that cause server navigation.
3. **PrestaShop subdomain page navigation** — any full-page navigation within a PrestaShop inner subdomain deadlocks the socket. This includes both `vibium click` on nav links AND `vibium go` to subdomain pages — the trigger is the navigation event itself, not the mechanism. Confirmed triggers: nav link clicks, `vibium go "$INNER/product-page.html"`. Workaround: `vibium eval 'location.href = "..."'` + `vibium wait load` (the only approach that does not deadlock).

## B16 vs B24 — shadow DOM vs non-interactive elements

Both B24 and B16 result in `vibium map` returning nothing, but the cause differs:

| | B24 | B16 |
|-|-----|-----|
| Site | coffee-cart.app (Vue) — was Black Box Puzzles, now 404 | Polymer Shop |
| Element type | `<div class="cup">` with a Vue `addEventListener` handler | Custom elements with shadow roots |
| Root cause | `map` infers clickability from static DOM attributes only (`role`, `tabindex`, inline `onclick`); cannot see `addEventListener`, ignores `cursor:pointer` | `vibium map` cannot cross shadow DOM boundaries |
| Discovery via `eval` | Yes — `querySelectorAll(".cup")` works | Yes — `querySelector("shop-app").shadowRoot` works |
| Recovery path | Yes — `vibium find ".cup"` returns a usable @ref | **No** — `eval` shadowRoot workaround also returns `null` |
| Fix scope | Detect listener-based handlers, or at minimum treat `cursor:pointer` as an affordance | Map should traverse shadow roots |

## Requirements

- vibium installed globally (`npm install -g vibium`) or locally
- Chrome + ChromeDriver installed (vibium manages this automatically)
- Claude Code with the skill installed

**macOS note:** the Python vibium client can shadow the npm binary in PATH. If `vibium` only shows `install` and `version` commands, use `/usr/local/bin/vibium` directly or confirm with `npm list -g vibium`.

## Output

The suite prints a `PASS / FAIL / PARTIAL / SKIP` line per test and a final summary table:

```
╔══════════════════════════════════════════════════════════════════╗
║                vibium CLI REGRESSION TEST RESULTS                ║
╠══════╦══════════╦══════════╦══════════════════════════════════╣
║ Bug  ║ Severity ║ Priority ║ Result                           ║
╠══════╬══════════╬══════════╬══════════════════════════════════╣
║  B1  ║ Critical ║ P1       ║ FAIL                             ║
...
║ B17  ║ Medium   ║ P2       ║ FAIL                             ║
║ B18  ║ Medium   ║ P2       ║ FAIL                             ║
╚══════════════════════════════════════════════════════════════════╝
```

Each `FAIL` includes the exact error string observed and notes whether the symptom matches the original bug report.

## Verified against

vibium v26.3.18 · ChromeDriver 147.0.7727.56 · macOS darwin 25.3.0 · zsh 5.9 (original)
vibium v26.5.31 · ChromeDriver 147.0.7727.56 · macOS darwin 25.5.0 · zsh 5.9 (2026-06-01)
vibium v26.5.31 · macOS darwin 25.5.0 · zsh 5.9 (2026-07-28 — B34, B35, FR1)

**Platform note for B35:** verified on macOS, but **not macOS-specific** — `paths.GetScreenshotDir()`
applies the same `Pictures/Vibium` convention on Linux and Windows, so it should reproduce there.
(An earlier draft wrongly flagged this as a macOS-only caveat.)

## B29 — `vibium find` over-includes disabled elements

`vibium map` consistently excludes disabled elements (no @ref assigned). `vibium find` returns an @ref for disabled elements in several modes (exit 0). Click on any leaked @ref always fails with "enabled check failed — disabled attribute" — the action layer is correct. The bug is that `find` leaks an @ref for an element the user cannot act on, while `map` does not.

### Find mode behavior matrix

Tested across three element types (`<button disabled>`, `<input type="submit" disabled>`, `<input type="text" disabled>`) injected on testtrack.org, plus a real disabled `<input type="button">` on Basic Calculator.

| Find mode | `<button>` | `<input type="submit">` | `<input type="text">` |
|-----------|------------|-------------------------|------------------------|
| `find "<selector>"` (CSS) | LEAKS @ref (exit 0) | LEAKS @ref (exit 0) | LEAKS @ref (exit 0) |
| `find text "<text>"` | LEAKS @ref (exit 0) | blocked (exit 1) | — |
| `find placeholder "<text>"` | — | — | LEAKS @ref (exit 0) |
| `find role <role>` | LEAKS @ref (exit 0) | blocked (exit 1) | blocked (exit 1) |
| `vibium map` | excluded (exit 0) | excluded (exit 0) | excluded (exit 0) |
| `click @leaked-ref` | FAIL exit 1 | FAIL exit 1 | FAIL exit 1 |

**Pattern**: CSS selector mode (`find "<selector>"`) leaks for all element types. `find text` and `find role` leak for `<button>` but not for `<input>` types. `find placeholder` leaks for text inputs. `vibium map` is always consistent.

### Repro

```sh
# Inject a disabled button
vibium eval 'document.body.insertAdjacentHTML("beforeend","<button id=b28 disabled>Disabled</button>")'

# find by selector — exits 0, returns @ref (bug)
vibium find "#b29"   # → @e1 [button] "Disabled", exit 0

# map — exits 0, no ref returned (correct)
vibium map --selector "#b29"  # → No interactive elements found

# click the leaked ref — exits 1, error (enabled check works correctly)
vibium click @e1  # → Error: enabled check failed — disabled attribute
```

## Changelog

| Date | Change |
|------|--------|
| 2026-04-22 | Added B7, B15, B23 (fill/textarea, find text/CSS transform, map/non-semantic) from batch 1–2 practice-testing |
| 2026-04-22 | Added B16–B17 (map/shadow DOM, find role/input[type=submit]) from batch 3; expanded B3 cross-site checks; expanded B1/B2/B4/B5/B9 cross-site coverage |
| 2026-04-22 | Added B18 (fill/type reject negative values) from batch 4 BugEater testing; added 5 new cross-site entries (bugeater.web.app, randomuser.me, codebase.show, thelab.boozang.com, compendiumdev.co.uk) |
| 2026-04-25 | Corrected B3 PrestaShop trigger: `vibium go` to subdomain pages also deadlocks (not just nav link clicks); corrected workaround from `vibium go direct-url` to `eval location.href`; added B28 candidate (`vibium click @ref` bypasses disabled check) |
| 2026-04-25 | Hardened B28 candidate across 3 sites (Basic Calculator `input[type=button]`, testtrack.org injected `button`, vibium find ref): enabled check enforced consistently in all cases — original PrestaShop observation was timing artifact; B28 narrowed to `vibium find` over-inclusion of disabled elements (returns @ref, click still fails) |
| 2026-04-25 | Promoted B28 to confirmed bug: completed full find-mode × element-type matrix (3 injected types × 5 find modes); CSS selector mode leaks for all types; `find text`/`find role` leak for `<button>` only; `vibium map` always correct; click always fails |
| 2026-04-27 | Added B19 (frame context persistence), B24 (text buffer overflow), B29 (hover non-interactive), B30 (fill range) from batch 5 practice-testing; renumbered B19–B32 into strict priority order |
| 2026-04-28 | Fixed bug numbering order (B19–B32 now strictly ascending by priority/severity); updated cross-site count to 23; synced VibiumDev/vibium#112 issue title and site counts |
| 2026-05-10 | Added B20 (`vibium fill` rejects empty string — `Error: value is required` — from Automation in Testing testing); renumbered B20–B32 → B21–B33 |
| 2026-06-01 | Ran full suite against v26.5.31; B1, B2, B4, B5, B7 now PASS (fixed at engine level); B15 reclassified as PASS/consistent (regression check only); B30 PARTIAL (div hover fixed, img still fails); B32 PARTIAL (teardown clean, port hint still missing); B3 deferred; B6/B8–B29/B31/B33 unchanged; fixed B29 repro selector typo (#b28 → #b29); added macOS PATH note for Python/npm vibium conflict |
| 2026-07-28 | Added B34 (`eval` drops all exception detail — confirmed on CLI and MCP, 6 exception classes, 3 sites, unrecoverable via `--json`/`--verbose`/`--stdin`) and B35 (`screenshot -o` discards the directory component; `pdf`/`storage`/`record stop` do not) from canvas-demo testing; appended rather than renumbered; added `issues/` with full write-ups. **Investigated and rejected:** an apparent "`eval` leaks `const`/`let` across invocations" bug — the scope is document-lifetime and clears on reload and navigation, which is correct JS semantics, not a defect. The empty error message from B34 is what made it look like one |
| 2026-07-28 | **B30 root cause found — it is B6, not an `<img>` defect.** On v26.5.31 `hover` has no `--timeout` and an effective default of zero, so it never auto-waits; an `<img>` is simply the most common briefly-zero-size element. `hover`/`dblclick`/`check` all fail with `timeout after 0s: visible check failed — zero size`; `focus`/`scroll` pass (no visibility check). Fixed by #182 alongside B6 — B30 moved to the fixed-in-source bucket and should be closed upstream as *fixed by #182*, not *not reproduced*. Comment draft in `issues/B30.md` |
| 2026-07-28 | **B24 re-established with a new repro after the original page 404'd.** Original description was wrong: `map` does expose non-semantic elements when clickability is static (`role`/`tabindex`/inline `onclick`) — it misses `addEventListener` handlers and ignores `cursor:pointer`. Built an isolated 8-case signal matrix via `vibium content` (cannot rot) and adopted coffee-cart.app as the live repro: 9 Vue `.cup` divs, all clickable, all invisible to `map` (4 refs returned, none of them products). ui5.sap.com added as secondary — improved from 0 refs to 127 since the 2026-05-19 comment, but 91 non-semantic `cursor:pointer` elements still unexposed. Recovery path exists (`vibium find ".cup"`), which keeps it P3. Write-up in `issues/B24.md` |
| 2026-07-28 | **Reconciled with upstream after #112 was closed and split.** #112 closed 2026-07-06; all 33 bugs split into individual issues. Added an Upstream column mapping every bug to its issue/PR and live state. Added a "fixed in source, not yet published" state — B6, B9, B14, B18, B20, B22, B31 are merged (#179, #180, #182, #187, #188) but `npm latest` is still v26.5.31, so the suite reports them FAIL and that is expected, not a regression. Flagged the **B30 discrepancy**: upstream triage says "not reproduced", our 2026-06-01 run found PARTIAL (`<img>` with external `src` still fails) — needs a reply before it is closed out. **B34 withdrawn as a new report** — already filed upstream as [#221](https://github.com/VibiumDev/vibium/issues/221) with the root cause located in `clicker/internal/bidi/script.go`; our file is now a comment draft. Also corrected a wrong fix suggestion in it (had cited CDP's `exceptionDetails.exception.description`; vibium is WebDriver BiDi, where it is `exceptionDetails.text`). **FR1 re-scoped** — `BrowserContext.addInitScript` already exists and passes in the Python and Java clients, so the request is CLI/MCP surface parity, not a new capability |
