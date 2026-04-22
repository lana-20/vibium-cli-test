# vibium-cli-test

A Claude Code skill that runs a full regression suite against [vibium](https://www.npmjs.com/package/vibium) — a browser automation CLI built on WebDriver BiDi.

The suite covers **21 confirmed bugs** in vibium v26.3.18, verified across 8 demo sites. Each test maps to a documented bug, produces a `PASS / FAIL / SKIP` result, and includes exact repro steps and error strings so a developer can reproduce failures without running the suite.

## Usage

Install the skill via Claude Code, then run:

```
/vibium-cli-test
```

Claude will execute all 21 tests against the running vibium daemon and print a summary table.

## What it tests

| # | Command | Bug |
|---|---------|-----|
| B1 | `vibium count` | Go type mismatch — crashes on every selector |
| B2 | `vibium storage` | Go type mismatch — crashes on all sites |
| B3 | `vibium dialog` | Alert deadlocks daemon; requires force-kill to recover |
| B4 | `vibium cookies <name> <value>` | BiDi requires domain field; set always fails |
| B5 | `vibium select` | Silent false success on invalid or text-matched options |
| B6 | `vibium click --timeout` | Flag accepted but silently ignored |
| B7 | `vibium attr` | Boolean attributes indistinguishable from absent |
| B8 | `vibium eval` | Objects and arrays print Go internal repr |
| B9 | `vibium is actionable` | Requires 2 args; all sibling commands require 1 |
| B10 | `vibium back` | Off-by-one at history boundary navigates to `about:blank` |
| B11 | `vibium completion zsh` | Generated script errors on source |
| B12 | `vibium daemon status/stop` | Always exit 0 regardless of daemon state |
| B13 | `vibium geolocation` | Negative coordinates parsed as flags |
| B14 | `vibium bidi-test` / `vibium launch-test` | BiDi WebSocket URL blank in ChromeDriver 147.0 |
| B15 | `vibium sleep` | Negative values parsed as flags |
| B16 | `vibium sleep` | Oversize values silently clamp to 30000ms |
| B17 | `vibium check` | No element type guard |
| B18 | `vibium ws-test` | `http://`/`https://` scheme not caught at input |
| B19 | `vibium upload` | No element type guard |
| B20 | `vibium serve` | No `--port` hint on port conflict |
| B21 | `vibium content ""` | Inconsistent error message vs no-arg invocation |

## Cross-site coverage

Critical and high-severity bugs are verified across 8 sites:

- [testtrack.org](https://testtrack.org) — primary repro site
- [var.parts](https://var.parts)
- [sauce-demo.myshopify.com](https://sauce-demo.myshopify.com/collections/all)
- [saucedemo.com](https://www.saucedemo.com)
- [demo.prestashop.com](https://demo.prestashop.com) (inner iframe store)
- [coffee-cart.app](https://coffee-cart.app)
- [ecommerce-playground.lambdatest.io](https://ecommerce-playground.lambdatest.io)
- [automationteststore.com](https://automationteststore.com)

WebSocket commands (B14, B18) also use `wss://echo.websocket.org` and `wss://ws.ifelse.io` as positive-baseline echo servers.

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
╚══════════════════════════════════════════════════════════════════╝
```

Each `FAIL` includes the exact error string observed and notes whether the symptom matches the original bug report.

## Verified against

vibium v26.3.18 · ChromeDriver 147.0.7727.56 · macOS darwin 25.3.0 · zsh 5.9
