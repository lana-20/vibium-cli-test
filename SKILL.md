---
name: vibium-cli-test
description: Regression test suite for 21 known vibium CLI bugs. Run after fixes to verify each bug is resolved. Tests are ordered B1–B21 matching the bug report, labeled PASS/FAIL/SKIP with exact repro steps.
---

# vibium CLI Regression Test Suite

Run all 21 tests and produce a final summary table. Each test maps to a bug in `/Users/lanabegunova/vibium-bug-report.md`.

## Setup

Resolve vibium binary: try `vibium` globally, then `./node_modules/.bin/vibium`.

Ensure daemon is running and healthy before starting:
```sh
vibium daemon status || (vibium daemon start && sleep 2)
vibium go https://testtrack.org && vibium title
```

If `vibium title` times out, the daemon is unhealthy — stop and restart it before proceeding.

---

## Tests

Print a result line for each test:
- `PASS B<n>` — bug is fixed
- `FAIL B<n>` — bug still present (include the exact error or symptom observed)
- `SKIP B<n>` — test could not run (explain why)

---

### B1 — `vibium count` — Go type mismatch (Critical · P1)

```sh
vibium go https://testtrack.org
vibium count "a"
echo "exit: $?"
```

PASS if: output is an integer (e.g. `42`), exit 0
FAIL if: `Error: failed to count: failed to parse script result: json: cannot unmarshal number into Go struct field .result.result.value of type string`

**Cross-site check** — the `/cart-patrol` skill documents `vibium count` as broken and uses `vibium eval 'document.querySelectorAll(...).length'` as a workaround on all 7 demo sites. When B1 is fixed, `vibium count` must return an integer on each:

```sh
vibium go https://var.parts/ && vibium count "button"; echo "exit: $? (var.parts)"

vibium go https://sauce-demo.myshopify.com/collections/all && vibium count "button"; echo "exit: $? (shopify)"

vibium go https://www.saucedemo.com
vibium fill "#user-name" "standard_user" && vibium fill "#password" "secret_sauce"
vibium click "#login-button" && vibium wait load
vibium count "button"; echo "exit: $? (saucedemo)"

vibium go https://demo.prestashop.com/
sleep 5  # wait for outer page to fully render the iframe
INNER=$(vibium eval 'document.querySelector("#framelive")?.src')
# Note: PrestaShop assigns a random subdomain per session (e.g. festive-number.demo.prestashop.com)
# If INNER is empty, run the eval manually and copy the URL
vibium go "$INNER" && vibium wait load
vibium count "button"; echo "exit: $? (prestashop)"

vibium go https://coffee-cart.app/ && vibium count "button"; echo "exit: $? (coffee-cart)"

vibium go https://ecommerce-playground.lambdatest.io/ && vibium count "button"; echo "exit: $? (lambdatest)"

vibium go https://automationteststore.com/ && vibium count "button"; echo "exit: $? (automationteststore)"
```

PASS (cross-site) if: integer returned on all 7 sites, exit 0 each time
FAIL (cross-site) if: `json: cannot unmarshal number...` on any site

---

### B2 — `vibium storage` — Go type mismatch crash (Critical · P1)

```sh
vibium go https://testtrack.org
vibium storage -o /tmp/vibium-reg-state.json
echo "exit: $?"
cat /tmp/vibium-reg-state.json | head -5
```

PASS if: JSON file written, exit 0
FAIL if: `Error: failed to get cookies: failed to parse storage.getCookies result: json: cannot unmarshal object into Go struct field Cookie.cookies.value of type string`

**Cross-site check** — verify storage dump works on cookie-rich cart-patrol sites (these carry session cookies and are more likely to trigger complex cookie struct shapes):

```sh
vibium go https://ecommerce-playground.lambdatest.io/
vibium storage -o /tmp/vibium-reg-lambdatest.json; echo "exit: $? (lambdatest)"

vibium go https://automationteststore.com/
vibium storage -o /tmp/vibium-reg-abantecart.json; echo "exit: $? (automationteststore)"

vibium go https://coffee-cart.app/
vibium storage -o /tmp/vibium-reg-coffeecart.json; echo "exit: $? (coffee-cart)"
```

PASS (cross-site) if: JSON files written, exit 0 on all three
FAIL (cross-site) if: unmarshal error on any site

---

### B3 — `vibium dialog` — alert deadlocks daemon (Critical · P1)

**Caution:** if this test FAILS, the daemon will be deadlocked. `vibium daemon stop` will also hang in this state — force-kill instead:
`pkill -f vibium && sleep 2 && vibium daemon start && sleep 2`

```sh
vibium go https://the-internet.herokuapp.com/javascript_alerts
vibium map
# Note the ref for "Click for JS Alert" — typically @e1
vibium click @e1
vibium dialog accept
echo "exit: $?"
vibium url
```

PASS if: `vibium dialog accept` returns immediately (exit 0); `vibium url` returns the alerts page URL
FAIL if: `vibium click` hangs until i/o timeout, or `vibium dialog accept` times out

After this test (pass or fail) confirm the daemon is responsive:
```sh
vibium url
```

If that hangs, restart daemon before B4.

---

### B4 — `vibium cookies <name> <value>` — domain field required (High · P1)

```sh
vibium go https://testtrack.org
vibium cookies vibium_reg_test abc123
echo "exit: $?"
```

PASS if: cookie set successfully, exit 0
FAIL if: error on set (observed: `Error: failed to set cookie: BiDi error: invalid argument - invalid argument`; original bug report said `domain is required` — error message differs but root cause is the same)

**Cross-site check** — domain inference must work when the browser is already on each cart-patrol domain:

```sh
vibium go https://var.parts/ && vibium cookies vibium_reg_test abc123; echo "exit: $? (var.parts)"
vibium go https://coffee-cart.app/ && vibium cookies vibium_reg_test abc123; echo "exit: $? (coffee-cart)"
vibium go https://ecommerce-playground.lambdatest.io/ && vibium cookies vibium_reg_test abc123; echo "exit: $? (lambdatest)"
vibium go https://automationteststore.com/ && vibium cookies vibium_reg_test abc123; echo "exit: $? (automationteststore)"
vibium go https://sauce-demo.myshopify.com/ && vibium cookies vibium_reg_test abc123; echo "exit: $? (shopify)"
vibium go https://www.saucedemo.com && vibium cookies vibium_reg_test abc123; echo "exit: $? (saucedemo)"
```

PASS (cross-site) if: cookie set successfully on all 6 sites, exit 0 each
FAIL (cross-site) if: any domain fails with an argument or domain error

---

### B5 — `vibium select` — silent false success (High · P1)

```sh
vibium go https://demoqa.com/select-menu
vibium wait load
vibium select "#oldSelectMenu" "nonexistent_xyz"
echo "exit: $?"
vibium eval 'document.querySelector("#oldSelectMenu").value'
```

PASS if: exit 1 with option-not-found error
FAIL if: exit 0 with success message, but `.value` is `""` (no selection actually occurred)

Also verify text-vs-value distinction:
```sh
vibium select "#oldSelectMenu" "Yellow"
echo "exit: $?"
vibium eval 'document.querySelector("#oldSelectMenu").value'
```

PASS if: exit 1 (text-matching unsupported and clearly errored), OR exit 0 and `.value` is `"Yellow"`
FAIL if: exit 0 with success message but `.value` is `""` (silent wrong state)

**Cross-site check** — real-world selects from cart-patrol sites:

```sh
# automationteststore.com — color dropdown on product page (product_id=53)
vibium go "https://automationteststore.com/index.php?rt=product/product&product_id=53"
vibium wait load
vibium map  # identify the color select — look for a <select> element
# Use the selector from the map output; example assumes a select with option values like "Red", "Blue"
vibium select "select[name^='option']" "nonexistent_color"
echo "exit: $?"
```

PASS if: exit 1 with option-not-found error
FAIL if: exit 0 claiming success when no valid option was selected

```sh
# ecommerce-playground.lambdatest.io — sort-by dropdown on catalog page (no cart needed)
# Note: sort select ID is dynamically suffixed (e.g. #input-sort-212403) — use attribute prefix selector
vibium go "https://ecommerce-playground.lambdatest.io/index.php?route=product/category&path=20"
vibium wait load
vibium select "select[id^='input-sort']" "nonexistent_sort"
echo "exit: $?"
```

PASS if: exit 1 with option-not-found error
FAIL if: exit 0 with success message when option does not exist

---

### B6 — `vibium click --timeout` — flag silently ignored (High · P1)

Inject a button that appears after a 1s delay, then click it with a 3s timeout:
```sh
vibium go https://testtrack.org
vibium content --stdin <<'EOF'
<button id="delayed-btn" style="display:none">Delayed</button>
<script>setTimeout(()=>document.getElementById('delayed-btn').style.display='block',1000)</script>
EOF
vibium click "#delayed-btn" --timeout 3s
echo "exit: $?"
```

PASS if: click succeeds within 3s (element appears at 1s, timeout honoured), exit 0
FAIL if: fails in ~160ms with `timeout after 0s` (timeout flag ignored)

---

### B7 — `vibium attr` — boolean attributes indistinguishable from absent (High · P2)

```sh
vibium content '<input id="req" type="text" required><input id="norq" type="text">'
vibium attr "#req" "required"
vibium attr "#norq" "required"
```

PASS if: outputs differ in any way (e.g. `"true"` vs `""`, or `""` vs `null`, or non-empty vs empty)
FAIL if: both return identical output (both empty string or both `{"ok":true,"result":""}`)

---

### B8 — `vibium eval` — objects/arrays print Go internal repr (High · P2)

```sh
vibium go https://testtrack.org
vibium eval '({url: location.href, title: document.title})'
vibium eval '[1, 2, 3]'
```

PASS if: first output is valid JSON (`{"url":"...","title":"..."}`); second is `[1,2,3]` or equivalent
FAIL if: output contains `map[type:string value:...]` or `map[type:number value:1]` (Go struct repr)

---

### B9 — `vibium bidi-test` / `vibium launch-test` — WebSocket URL blank (High · P3)

```sh
vibium bidi-test
```

PASS if: all 5 steps pass (including `[3/5] Connecting to BiDi WebSocket...` succeeds)
FAIL if: `WebSocket URL: ` is blank at step 2 and `Error connecting: ... malformed ws or wss URL`

Also test `vibium launch-test` — same bug, different command:
```sh
vibium launch-test
```

PASS if: BiDi WebSocket URL is non-empty and connection succeeds
FAIL if: `BiDi WebSocket: ` is blank and command hangs or errors

**Positive baseline** — when B9 is fixed, `vibium ws-test` against known-good echo servers should connect cleanly:
```sh
vibium ws-test wss://echo.websocket.org; echo "exit: $?"
vibium ws-test wss://ws.ifelse.io; echo "exit: $?"
```

PASS if: both connect and exchange a message, exit 0
FAIL if: connection fails (would indicate a different issue, not B9)

---

### B10 — `vibium is actionable` — requires 2 args (Medium · P2)

```sh
vibium go https://testtrack.org
vibium is actionable "button"
echo "exit: $?"
```

PASS if: returns `true` or `false`, exit 0
FAIL if: `Error: accepts 2 arg(s), received 1`

---

### B11 — `vibium back` — off-by-one at history boundary (Medium · P2)

```sh
vibium page new https://example.com
vibium back
echo "exit: $?"
vibium url
vibium page close
```

PASS if: exit 1 (no previous history); `vibium url` still returns `https://example.com/`
FAIL if: exit 0 (`Navigated back`) and `vibium url` returns `about:blank`

---

### B12 — `vibium completion zsh` — generated script errors on source (Medium · P2)

```sh
zsh -c 'source <(vibium completion zsh) 2>/tmp/vibium-b12-stderr.txt; echo "exit: $?"; cat /tmp/vibium-b12-stderr.txt'
```

PASS if: exit 0, no output on stderr
FAIL if: `compdef` error appears on stderr — exact message varies by zsh version:
- zsh 5.9+ (macOS): `/dev/fd/11:2: command not found: compdef` — exit code is 0 but stderr has error
- older zsh: `compdef:...: _comps: assignment to invalid subscript range`
Note: on zsh 5.9 the exit code is 0 even when broken — check stderr, not just exit code

---

### B13 — `vibium daemon status/stop` — always exit 0 (Medium · P2)

```sh
vibium daemon stop
vibium daemon stop
echo "stop-when-stopped exit: $?"
vibium daemon status
echo "status-when-stopped exit: $?"
```

PASS if: second `daemon stop` exits 1; `daemon status` when stopped exits 1
FAIL if: either exits 0 regardless of daemon state

Restart daemon after this test:
```sh
vibium daemon start && sleep 2
```

---

### B14 — `vibium geolocation` — negative coords parsed as flags (Medium · P2)

```sh
vibium go https://testtrack.org
vibium geolocation 37.7749 -122.4194
echo "exit: $?"
```

PASS if: exit 0, geolocation overridden with no error
FAIL if: `Error: unknown shorthand flag: '1' in -122.4194`

---

### B15 — `vibium sleep` — negative values parsed as flags (Medium · P3)

```sh
vibium sleep -1
echo "exit: $?"
```

PASS if: error clearly states negative duration is invalid (not a flag error), exit 1
FAIL if: `Error: unknown shorthand flag: '1' in -1`

---

### B16 — `vibium sleep` — oversize values silently clamp (Medium · P3)

```sh
time vibium sleep 30001
echo "exit: $?"
```

PASS if: exit 1 with error that value exceeds the 30000ms maximum
FAIL if: exits 0 after sleeping exactly 30s with output `Slept for 30000 ms` (silently clamped, no warning or error)

---

### B17 — `vibium check` — no element type guard (Low · P3)

```sh
vibium go https://testtrack.org
vibium map
# Identify a non-checkbox element from the map (e.g. a link or button) — use its @ref
vibium check @e1
echo "exit: $?"
```

PASS if: error or warning that element is not a checkbox or radio, exit 1
FAIL if: silent exit 0 with no feedback when targeting a non-checkbox

---

### B18 — `vibium ws-test` — http/https scheme not caught (Low · P3)

```sh
vibium ws-test https://testtrack.org; echo "exit: $?"
vibium ws-test http://testtrack.org; echo "exit: $?"
```

PASS if: error clearly tells the user to use `wss://` or `ws://` instead
FAIL if: generic `Error: failed to connect to https://...: malformed ws or wss URL` with no scheme guidance

**Positive check** — verify valid `wss://` endpoints still work (regression guard):
```sh
vibium ws-test wss://echo.websocket.org; echo "exit: $? (echo.websocket.org)"
vibium ws-test wss://ws.ifelse.io; echo "exit: $? (ws.ifelse.io)"
```

PASS if: both connect successfully, exit 0
FAIL if: connection fails on a valid `wss://` endpoint (separate issue from B18)

---

### B19 — `vibium upload` — no element type guard (Low · P3)

```sh
vibium go https://the-internet.herokuapp.com/upload
vibium map
# Find the submit button ref (not the file input) from the map — e.g. @e2
vibium upload @e2 /tmp/vibium-reg-state.json
echo "exit: $?"
```

PASS if: clear user-facing error that element is not a file input, exit 1
FAIL if: exit 0 with no validation error, OR exit 1 with only a cryptic BiDi error (observed: `BiDi error: unable to set file input - unable to set file input`) — the latter is exit 1 but not a proper type guard

---

### B20 — `vibium serve` — noisy teardown (Low · P4)

```sh
vibium serve --port 8090 &
SERVE_PID=$!
sleep 1
kill $SERVE_PID
wait $SERVE_PID 2>/tmp/vibium-serve-stderr.txt
cat /tmp/vibium-serve-stderr.txt
```

PASS if: no stack traces or unexpected error lines on shutdown (clean or single-line stop message)
FAIL if: multiple error lines / Go stack output printed to stderr on SIGTERM
NOTE: teardown has been clean in all three test runs against v26.3.18 — this sub-bug is considered fixed. Confirm by checking stderr line count is 0.

Also test port conflict hint — run a second instance against an already-occupied port:
```sh
vibium serve --port 8090 &
BGPID=$!
sleep 1
vibium serve --port 8090 2>&1; echo "conflict exit: $?"
kill $BGPID 2>/dev/null; wait $BGPID 2>/dev/null
```

PASS if: error mentions `--port` as a workaround (e.g. "try a different port with --port")
FAIL if: only `bind: address already in use` with no `--port` hint

---

### B21 — `vibium content ""` — inconsistent error message (Low · P4)

```sh
vibium content ""
vibium content
```

PASS if: both produce the same error message, including the `--stdin` hint
FAIL if: the empty-string case omits the `--stdin` hint present in the no-arg message

---

## Cleanup

```sh
rm -f /tmp/vibium-reg-state.json /tmp/vibium-reg-lambdatest.json /tmp/vibium-reg-abantecart.json /tmp/vibium-reg-coffeecart.json /tmp/vibium-serve-stderr.txt
vibium daemon status || (vibium daemon start && sleep 2)
```

---

## Final Report

Print a summary table with actual results filled in:

```
╔══════════════════════════════════════════════════════════════════╗
║                vibium CLI REGRESSION TEST RESULTS                ║
╠══════╦══════════╦══════════╦══════════════════════════════════╣
║ Bug  ║ Severity ║ Priority ║ Result                           ║
╠══════╬══════════╬══════════╬══════════════════════════════════╣
║  B1  ║ Critical ║ P1       ║ PASS / FAIL / SKIP               ║
║  B2  ║ Critical ║ P1       ║ PASS / FAIL / SKIP               ║
║  B3  ║ Critical ║ P1       ║ PASS / FAIL / SKIP               ║
║  B4  ║ High     ║ P1       ║ PASS / FAIL / SKIP               ║
║  B5  ║ High     ║ P1       ║ PASS / FAIL / SKIP               ║
║  B6  ║ High     ║ P1       ║ PASS / FAIL / SKIP               ║
║  B7  ║ High     ║ P2       ║ PASS / FAIL / SKIP               ║
║  B8  ║ High     ║ P2       ║ PASS / FAIL / SKIP               ║
║  B9  ║ High     ║ P3       ║ PASS / FAIL / SKIP               ║
║ B10  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B11  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B12  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B13  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B14  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B15  ║ Medium   ║ P3       ║ PASS / FAIL / SKIP               ║
║ B16  ║ Medium   ║ P3       ║ PASS / FAIL / SKIP               ║
║ B17  ║ Low      ║ P3       ║ PASS / FAIL / SKIP               ║
║ B18  ║ Low      ║ P3       ║ PASS / FAIL / SKIP               ║
║ B19  ║ Low      ║ P3       ║ PASS / FAIL / SKIP               ║
║ B20  ║ Low      ║ P4       ║ PASS / FAIL / SKIP               ║
║ B21  ║ Low      ║ P4       ║ PASS / FAIL / SKIP               ║
╠══════╩══════════╩══════════╩══════════════════════════════════╣
║  X PASS   Y FAIL   Z SKIP                                        ║
╚══════════════════════════════════════════════════════════════════╝
```

For each FAIL, include: the exact error output observed, and whether the symptom matches or differs from the original bug report.
