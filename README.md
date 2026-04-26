# vibium-cli-test

A Claude Code skill that runs a full regression suite against [vibium](https://www.npmjs.com/package/vibium) — a browser automation CLI built on WebDriver BiDi.

The suite covers **28 confirmed bugs** in vibium v26.3.18, verified across 17 sites. Each test maps to a documented bug, produces a `PASS / FAIL / SKIP` result, and includes exact repro steps and error strings so a developer can reproduce failures without running the suite.

## Usage

Install the skill via Claude Code, then run:

```
/vibium-cli-test
```

Claude will execute all 28 tests against the running vibium daemon and print a summary table.

## What it tests

| # | Severity | Priority | Command | Bug |
|---|----------|----------|---------|-----|
| B1 | Critical | P1 | `vibium count` | Go type mismatch — crashes on every selector |
| B2 | Critical | P1 | `vibium storage` | Go type mismatch — crashes on all sites |
| B3 | Critical | P1 | `vibium click` (dialog/nav) | Navigation events deadlock daemon socket; three confirmed trigger patterns |
| B4 | High | P1 | `vibium cookies <name> <value>` | BiDi requires domain field; set always fails |
| B5 | High | P1 | `vibium select` | Silent false success on invalid or text-matched options |
| B6 | High | P1 | `vibium click --timeout` | Flag accepted but silently ignored |
| B7 | High | P1 | `vibium fill` | Crashes on `<textarea>` — `element type is not supported` |
| B8 | High | P2 | `vibium attr` | Boolean attributes indistinguishable from absent |
| B9 | High | P2 | `vibium eval` | Objects and arrays print Go internal repr |
| B10 | Medium | P2 | `vibium is actionable` | Requires 2 args; all sibling commands require 1 |
| B11 | Medium | P2 | `vibium back` | Off-by-one at history boundary navigates to `about:blank` |
| B12 | Medium | P2 | `vibium completion zsh` | Generated script errors on source |
| B13 | Medium | P2 | `vibium daemon status/stop` | Always exit 0 regardless of daemon state |
| B14 | Medium | P2 | `vibium geolocation` | Negative coordinates parsed as flags |
| B15 | Medium | P2 | `vibium find text` | Searches DOM text, not CSS-transformed display text |
| B16 | Medium | P2 | `vibium map` | Web Components shadow DOM elements not exposed |
| B17 | Medium | P2 | `vibium find role` | `input[type=submit]` not found as `role button`; 30s timeout |
| B18 | Medium | P2 | `vibium fill` / `vibium type` | Negative values parsed as flags — `unknown shorthand flag: '2' in -2` |
| B19 | High | P3 | `vibium bidi-test` / `vibium launch-test` | BiDi WebSocket URL blank in ChromeDriver 147.0 |
| B20 | Medium | P3 | `vibium sleep` | Negative values parsed as flags |
| B21 | Medium | P3 | `vibium sleep` | Oversize values silently clamp to 30000ms |
| B22 | Medium | P3 | `vibium map` | Non-semantic clickable elements (`<li>`) not exposed as refs |
| B23 | Low | P3 | `vibium check` | No element type guard |
| B24 | Low | P3 | `vibium ws-test` | `http://`/`https://` scheme not caught at input |
| B25 | Low | P3 | `vibium upload` | No element type guard |
| B26 | Low | P4 | `vibium serve` | No `--port` hint on port conflict |
| B27 | Low | P4 | `vibium content ""` | Inconsistent error message vs no-arg invocation |
| B28 | Low | P3 | `vibium find` | CSS selector and some find modes return @ref for disabled elements (exit 0); `vibium map` correctly excludes them |

## Cross-site coverage

Bugs are verified across 18 sites:

| Site | Tests |
|------|-------|
| [testtrack.org](https://testtrack.org) | B1–B27 (baseline) |
| [var.parts](https://var.parts/) | B1, B4 |
| [sauce-demo.myshopify.com](https://sauce-demo.myshopify.com/) | B1, B4 |
| [saucedemo.com](https://www.saucedemo.com) | B1, B4 |
| [demo.prestashop.com](https://demo.prestashop.com/) | B1, B2, B3 (nav deadlock) |
| [coffee-cart.app](https://coffee-cart.app/) | B1, B2, B4 |
| [ecommerce-playground.lambdatest.io](https://ecommerce-playground.lambdatest.io/) | B1, B2, B4, B5 |
| [automationteststore.com](https://automationteststore.com/) | B1, B2, B4, B5 |
| [academybugs.com](https://academybugs.com/) | B1, B2, B4, B9, B15 |
| [www.shino.de/parkcalc](https://www.shino.de/parkcalc/) | B1, B5 |
| [testpages.eviltester.com](https://testpages.eviltester.com/styled/index.html) | B3 (pre-stub), B7 |
| [phptravels.com/demo](http://phptravels.com/demo/) | B3 (form submit deadlock) |
| [shop.polymer-project.org](https://shop.polymer-project.org/) | B16 (shadow DOM map) |
| [practicesoftwaretesting.com](https://practicesoftwaretesting.com/) | B17 (`find role button` on `input[type=submit]`) |
| [qa-practice.razvanvancea.ro](https://qa-practice.razvanvancea.ro/) | B15 (CSS uppercase ADD TO CART) |
| [blackboxpuzzles.workroomprds.com](https://blackboxpuzzles.workroomprds.com/) | B22 (map misses `<li>` elements) |
| [bugeater.web.app](https://bugeater.web.app/) | B18 (fill/type reject negative values) |
| [compendiumdev.co.uk/apps/iframe-search](http://compendiumdev.co.uk/apps/iframe-search/iframe-search.html) | B5 (select silent false success) |

## B3 daemon deadlock — known triggers

B3 has three confirmed trigger patterns. All deadlock the daemon socket:

1. **JS alert/confirm/prompt dialogs** — original repro: `vibium click` on any button that calls `window.alert()`. Workaround: pre-stub via `vibium eval 'window.alert = () => {}'` before clicking.
2. **Form POST navigation** — clicking a submit button that triggers a server-side POST request and full page reload (PHP Travels demo form). Pre-stubbing dialogs does not help. Workaround: `vibium eval 'form.submit()'` or avoid clicking submit buttons that cause server navigation.
3. **PrestaShop subdomain page navigation** — any full-page navigation within a PrestaShop inner subdomain deadlocks the socket. This includes both `vibium click` on nav links AND `vibium go` to subdomain pages — the trigger is the navigation event itself, not the mechanism. Confirmed triggers: nav link clicks, `vibium go "$INNER/product-page.html"`. Workaround: `vibium eval 'location.href = "..."'` + `vibium wait load` (the only approach that does not deadlock).

## B16 vs B22 — shadow DOM vs non-interactive elements

Both B22 and B16 result in `vibium map` returning nothing, but the cause differs:

| | B22 | B16 |
|-|-----|-----|
| Site | Black Box Puzzles | Polymer Shop |
| Element type | CSS-styled `<li>` (not button/a) | Custom elements with shadow roots |
| Root cause | `vibium map` only scans semantic interactive elements | `vibium map` cannot cross shadow DOM boundaries |
| Discovery via `eval` | Yes — `querySelectorAll("li")` works | Yes — `querySelector("shop-app").shadowRoot` works |
| Fix scope | Map should include non-semantic clickable elements | Map should traverse shadow roots |

## Requirements

- vibium installed globally (`npm install -g vibium`) or locally
- Chrome + ChromeDriver installed (vibium manages this automatically)
- Claude Code with the skill installed

## Output

The suite prints a `PASS / FAIL / SKIP` line per test and a final summary table:

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

vibium v26.3.18 · ChromeDriver 147.0.7727.56 · macOS darwin 25.3.0 · zsh 5.9

## B28 — `vibium find` over-includes disabled elements

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
vibium find "#b28"   # → @e1 [button] "Disabled", exit 0

# map — exits 0, no ref returned (correct)
vibium map --selector "#b28"  # → No interactive elements found

# click the leaked ref — exits 1, error (enabled check works correctly)
vibium click @e1  # → Error: enabled check failed — disabled attribute
```

## Changelog

| Date | Change |
|------|--------|
| 2026-04-22 | Added B7, B15, B22 (fill/textarea, find text/CSS transform, map/non-semantic) from batch 1–2 practice-testing |
| 2026-04-22 | Added B16–B17 (map/shadow DOM, find role/input[type=submit]) from batch 3; expanded B3 cross-site checks; expanded B1/B2/B4/B5/B9 cross-site coverage |
| 2026-04-22 | Added B18 (fill/type reject negative values) from batch 4 BugEater testing; added 5 new cross-site entries (bugeater.web.app, randomuser.me, codebase.show, thelab.boozang.com, compendiumdev.co.uk) |
| 2026-04-25 | Corrected B3 PrestaShop trigger: `vibium go` to subdomain pages also deadlocks (not just nav link clicks); corrected workaround from `vibium go direct-url` to `eval location.href`; added B28 candidate (`vibium click @ref` bypasses disabled check) |
| 2026-04-25 | Hardened B28 candidate across 3 sites (Basic Calculator `input[type=button]`, testtrack.org injected `button`, vibium find ref): enabled check enforced consistently in all cases — original PrestaShop observation was timing artifact; B28 narrowed to `vibium find` over-inclusion of disabled elements (returns @ref, click still fails) |
| 2026-04-25 | Promoted B28 to confirmed bug: completed full find-mode × element-type matrix (3 injected types × 5 find modes); CSS selector mode leaks for all types; `find text`/`find role` leak for `<button>` only; `vibium map` always correct; click always fails |
