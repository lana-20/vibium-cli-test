---
name: vibium-cli-test
description: "Regression test suite for 35 known vibium CLI bugs (B1–B35), ordered by priority and severity (P1 Critical first, P4 Low last; B34–B35 appended out of order). Umbrella issue #112 was closed 2026-07-06 and split into one issue per bug — B-numbers are suite labels now, see README for the per-bug issue map. B6, B9, B14, B18, B20, B22, B30, B31 are fixed in source but unpublished, so they FAIL expectedly on v26.5.31. B30's <img> case is a symptom of B6 (hover has no --timeout and a zero default on v26.5.31), fixed by #182. B24 re-established 2026-07-28 with a new repro (coffee-cart.app + self-contained matrix) after its original page 404'd. Known partials: B15, B32. B34 is tracked upstream as #221 and reproduces on MCP too — a CLI-only fix is PARTIAL. Labels PASS/FAIL/PARTIAL/SKIP with exact repro steps and cross-site verification."
---

# vibium CLI Regression Test Suite

Run all 35 tests and produce a final summary table. B1–B33 are ordered by priority and severity — B1–B7 are P1, B8–B20 are P2, B21–B31 are P3, B32–B33 are P4. **B34 (High · P2) and B35 (Medium · P2) are appended rather than renumbered**, because the B-numbers are cited across upstream issues and prior comments.

**Upstream tracking changed.** The umbrella issue [#112](https://github.com/VibiumDev/vibium/issues/112) was closed 2026-07-06 and split into one issue per bug. B-numbers are labels for this suite now, not a mapping to #112 — see the README for the per-bug issue map.

## Expected FAILs — do not report as regressions

As of 2026-07-28 the published npm `latest` is **v26.5.31**. These seven are **fixed in source but not published**, so they still FAIL on any installed build. Label them `FAIL (expected — fixed in #NNN, unpublished)` rather than a plain FAIL:

| Bug | Fixed by |
|---|---|
| B6 `click --timeout` | [#182](https://github.com/VibiumDev/vibium/pull/182) merged |
| B9 `eval` Go repr | [#180](https://github.com/VibiumDev/vibium/pull/180) merged |
| B14, B18, B22 negative-as-flag | [#179](https://github.com/VibiumDev/vibium/pull/179) merged |
| B20 `fill ""` | [#187](https://github.com/VibiumDev/vibium/issues/187) closed |
| B30 `hover` on zero-size elements | [#182](https://github.com/VibiumDev/vibium/pull/182) merged — same root cause as B6 |
| B31 `fill` on `input[type=range]` | [#188](https://github.com/VibiumDev/vibium/issues/188) closed |

Before running, confirm the installed version — if it is newer than 26.5.31 these should flip to genuine PASS:

```sh
vibium --version && npm view vibium version
```

**B24 has a working repro again** — the original page 404s, so it now uses a self-contained `vibium content` signal matrix plus coffee-cart.app. No longer expected to SKIP; it should FAIL on v26.5.31 (9 product divs invisible to `map`).

**B30 is resolved, not disputed.** Its `<img>` case is a symptom of B6: on v26.5.31 `hover` has no `--timeout` and an effective default of zero, so it never auto-waits, and an `<img>` is briefly zero-size before it loads. `hover`, `dblclick` and `check` all fail identically with `timeout after 0s: visible check failed — zero size`. Fixed by #182 alongside B6. Report the `<div>` and `<img>` cases separately; see [`issues/B30.md`](issues/B30.md).

## Setup

Resolve vibium binary: try `vibium` globally, then `./node_modules/.bin/vibium`, then `/usr/local/bin/vibium`.

**macOS PATH note:** on macOS the Python vibium client can shadow the npm binary. If `vibium` shows only `install` and `version` commands, the Python client is winning. Use the full path `/usr/local/bin/vibium` (npm global) instead, or confirm with `npm list -g vibium`.

Ensure daemon is running and healthy before starting:
```sh
vibium daemon status || (vibium daemon start && sleep 2)
vibium go https://testtrack.org && vibium title
```

If `vibium title` times out, the daemon is unhealthy — force-kill and restart:
```sh
pkill -f vibium && sleep 2 && vibium daemon start && sleep 2
```

---

## Tests

Print a result line for each test:
- `PASS B<n>` — bug is fixed
- `FAIL B<n>` — bug still present (include exact error or symptom)
- `SKIP B<n>` — test could not run (explain why)

---

### B1 — `vibium count` — Go type mismatch (Critical · P1)

```sh
vibium go https://testtrack.org
vibium count "a"
echo "exit: $?"
```

PASS if: output is an integer (e.g. `42`), exit 0
FAIL if: `json: cannot unmarshal number into Go struct field .result.result.value of type string`

**Cross-site check** — the `/cart-patrol` skill uses `vibium eval 'document.querySelectorAll(...).length'` as a workaround on all demo sites. When B1 is fixed, `vibium count` must return an integer on each:

```sh
vibium go https://var.parts/ && vibium count "button"; echo "exit: $? (var.parts)"

vibium go https://sauce-demo.myshopify.com/collections/all && vibium count "button"; echo "exit: $? (shopify)"

vibium go https://www.saucedemo.com
vibium fill "#user-name" "standard_user" && vibium fill "#password" "secret_sauce"
vibium click "#login-button" && vibium wait load
vibium count "button"; echo "exit: $? (saucedemo)"

vibium go https://demo.prestashop.com/
sleep 5
INNER=$(vibium eval 'document.querySelector("#framelive")?.src')
vibium go "$INNER" && vibium wait load
vibium count "button"; echo "exit: $? (prestashop)"

vibium go https://coffee-cart.app/ && vibium count "button"; echo "exit: $? (coffee-cart)"

vibium go https://ecommerce-playground.lambdatest.io/ && vibium count "button"; echo "exit: $? (lambdatest)"

vibium go https://automationteststore.com/ && vibium count "button"; echo "exit: $? (automationteststore)"

vibium go https://academybugs.com/ && vibium count "button"; echo "exit: $? (academybugs)"

vibium go https://www.shino.de/parkcalc/ && vibium count "button"; echo "exit: $? (parkcalc)"
```

PASS (cross-site) if: integer returned on all 9 sites, exit 0 each time
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
FAIL if: `json: cannot unmarshal object into Go struct field Cookie.cookies.value of type string`

**Cross-site check** — verify storage dump works on cookie-rich cart-patrol sites:

```sh
vibium go https://ecommerce-playground.lambdatest.io/
vibium storage -o /tmp/vibium-reg-lambdatest.json; echo "exit: $? (lambdatest)"

vibium go https://automationteststore.com/
vibium storage -o /tmp/vibium-reg-abantecart.json; echo "exit: $? (automationteststore)"

vibium go https://coffee-cart.app/
vibium storage -o /tmp/vibium-reg-coffeecart.json; echo "exit: $? (coffee-cart)"

vibium go https://academybugs.com/
vibium storage -o /tmp/vibium-reg-academybugs.json; echo "exit: $? (academybugs)"
```

PASS (cross-site) if: JSON files written, exit 0 on all four
FAIL (cross-site) if: unmarshal error on any site

---

### B3 — `vibium dialog` — alert deadlocks daemon (Critical · P1)

**Caution:** if this test FAILS, the daemon will be deadlocked. `vibium daemon stop` will also hang — force-kill instead:
```sh
pkill -f vibium && sleep 2 && vibium daemon start && sleep 2
```

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

After this test (pass or fail) confirm daemon is responsive:
```sh
vibium url
```
If that hangs, restart daemon before B4.

**Cross-site check — Evil Tester alert page:**

This site has multiple JS alert triggers. Pre-stub dialogs BEFORE clicking to prevent B3 deadlock — this is the established workaround; the cross-site check verifies it works:

```sh
vibium go https://testpages.eviltester.com/styled/alerts/alert-test.html
vibium wait load

# Pre-stub all dialog types before clicking any trigger
vibium eval 'window.alert = () => {}; window.confirm = () => true; window.prompt = () => "vibium-test"'

# Click the JS Alert trigger
vibium find text "Show alert box" && vibium click @e1
echo "exit: $? (evil-tester alert — should not deadlock after pre-stub)"
vibium url
```

PASS if: click returns immediately without deadlock, exit 0
FAIL if: click hangs or daemon becomes unresponsive despite the pre-stub (pre-stub workaround broken)

**Cross-site check — PHP Travels form submit deadlocks daemon:**

Form submission that triggers a network request or page navigation can deadlock the daemon in the same way as dialogs — the socket cannot follow the POST navigation. Pre-stubbing dialogs does not prevent this variant.

```sh
vibium go http://phptravels.com/demo/
vibium wait load
# Pre-stub dialogs first
vibium eval 'window.alert = () => {}; window.confirm = () => true; window.onbeforeunload = null'
# Find and click the Submit / Demo Request button
vibium find role button --name "Submit" 2>/dev/null || vibium find text "Submit" && vibium click @e1
echo "exit: $? (php-travels submit)"
# If this hangs, daemon is deadlocked — force-kill required
```

PASS if: click returns and daemon stays responsive (verify with `vibium url`)
FAIL if: command hangs until i/o timeout — same B3 symptom, triggered by form POST navigation not dialog

Recovery if deadlocked:
```sh
pkill -f vibium && sleep 2 && vibium daemon start && sleep 2
```

**Cross-site check — Presta Shop subdomain page navigation deadlocks daemon:**

Any full-page navigation within a PrestaShop inner subdomain deadlocks the daemon socket — this includes both `vibium click` on nav links AND `vibium go` to subdomain pages. The trigger is the navigation event itself, not the mechanism used. Symptom is the same as B3 — command hangs until i/o timeout.

```sh
vibium go https://demo.prestashop.com/ && vibium wait load && vibium sleep 5000
INNER=$(vibium eval 'document.querySelector("#framelive")?.src')
vibium go "$INNER" && vibium wait load  # homepage only — safe

# Trigger 1: clicking a category nav link (original trigger)
vibium find text "Clothes" && vibium click @e1
echo "exit: $? (prestashop-nav-click-clothes)"
# If this hangs, restart daemon before testing trigger 2

# Trigger 2: vibium go to a subdomain product page (also deadlocks — confirmed 2026-04-25)
vibium go "$INNER/1-1-hummingbird-printed-t-shirt.html"
echo "exit: $? (prestashop-vibium-go-product)"
```

PASS if: both navigate correctly and return; daemon stays responsive
FAIL if: either command hangs — daemon deadlocked; real workaround is `eval 'location.href = "..."'` + `vibium wait load` (NOT `vibium go` to a subdomain page — that also deadlocks):
```sh
# Correct workaround — confirmed working 2026-04-25:
vibium eval "location.href = '${INNER}/1-1-hummingbird-printed-t-shirt.html'"
vibium wait load --timeout 10000
```

Also verify the pre-stub values are observed:
```sh
vibium go https://testpages.eviltester.com/styled/alerts/alert-test.html
vibium wait load
vibium eval 'window.confirm = () => false'
vibium find text "Show confirm box" && vibium click @e1
vibium sleep 300
vibium eval 'document.querySelector("#confirmreturn")?.textContent'
```

PASS if: result element contains "false" (pre-stub return value was used)
FAIL if: result element is empty or shows "true" (pre-stub ignored; dialog may have blocked)

---

### B4 — `vibium cookies <name> <value>` — domain field required (High · P1)

```sh
vibium go https://testtrack.org
vibium cookies vibium_reg_test abc123
echo "exit: $?"
```

PASS if: cookie set successfully, exit 0
FAIL if: `BiDi error: invalid argument - invalid argument` or `domain is required`

**Cross-site check:**

```sh
vibium go https://var.parts/ && vibium cookies vibium_reg_test abc123; echo "exit: $? (var.parts)"
vibium go https://coffee-cart.app/ && vibium cookies vibium_reg_test abc123; echo "exit: $? (coffee-cart)"
vibium go https://ecommerce-playground.lambdatest.io/ && vibium cookies vibium_reg_test abc123; echo "exit: $? (lambdatest)"
vibium go https://automationteststore.com/ && vibium cookies vibium_reg_test abc123; echo "exit: $? (automationteststore)"
vibium go https://sauce-demo.myshopify.com/ && vibium cookies vibium_reg_test abc123; echo "exit: $? (shopify)"
vibium go https://www.saucedemo.com && vibium cookies vibium_reg_test abc123; echo "exit: $? (saucedemo)"
vibium go https://academybugs.com/ && vibium cookies vibium_reg_test abc123; echo "exit: $? (academybugs)"
```

PASS (cross-site) if: cookie set successfully on all 7 sites, exit 0 each
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
FAIL if: exit 0 with success message but `.value` is `""` (no selection occurred)

Also verify label-based selection (fixed in v26.5.31 — now matches by visible label, not `value` attribute):
```sh
vibium select "#oldSelectMenu" "Yellow"
echo "exit: $?"
vibium eval 'document.querySelector("#oldSelectMenu").value'
```

PASS if: exit 0 and `.value` is non-empty (option selected by visible label "Yellow"; underlying value attribute may differ, e.g. `"3"`)
FAIL if: exit 0 but `.value` is `""` (silent wrong state), OR exit 1 with unsupported error

**Cross-site check — Parking Cost Calculator lot dropdown:**

This site was found during practice-testing. The lot dropdown uses short string values that don't match display text. Selecting by display text silently keeps the previous selection:

```sh
vibium go https://www.shino.de/parkcalc/
vibium wait load

# Inspect the option values — display text ≠ value
vibium eval 'JSON.stringify([...document.querySelectorAll("#ParkingLot option")].map(o => ({text: o.text, value: o.value})))'
# Expected: [{text:"Valet Parking",value:"Valet"},{text:"Short-Term Parking",value:"Short"},...]

# Attempt to select by display text (should fail or silently wrong)
vibium select "#ParkingLot" "Short-Term Parking"
echo "exit: $?"
vibium eval 'document.querySelector("#ParkingLot").value'
# FAIL if: exit 0 but value is still "Valet" (silently wrong)
# PASS if: exit 1 with option-not-found error

# Correct selection by value
vibium select "#ParkingLot" "Short"
echo "exit: $?"
vibium eval 'document.querySelector("#ParkingLot").value'
# PASS if: exit 0 and value is "Short"
```

**Cross-site check — automationteststore.com product option select:**

```sh
vibium go "https://automationteststore.com/index.php?rt=product/product&product_id=53"
vibium wait load
vibium select "select[name^='option']" "nonexistent_color"
echo "exit: $?"
```

PASS if: exit 1 with option-not-found error
FAIL if: exit 0 claiming success when no valid option was selected

**Cross-site check — ecommerce-playground sort dropdown:**

```sh
vibium go "https://ecommerce-playground.lambdatest.io/index.php?route=product/category&path=20"
vibium wait load
vibium select "select[id^='input-sort']" "nonexistent_sort"
echo "exit: $?"
```

PASS if: exit 1 with option-not-found error
FAIL if: exit 0 with success message when option does not exist

---

### B6 — `vibium click --timeout` — flag silently ignored (High · P1)

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

### B7 — `vibium fill` — crashes on `<textarea>` elements (High · P1)

**Source:** Discovered during Evil Tester testing (textarea in the forms test page).

```sh
vibium go https://testpages.eviltester.com/styled/basic-html-form-test.html
vibium wait load
vibium find "textarea" && vibium fill @e1 "hello world"
echo "exit: $?"
```

PASS if: textarea value is set to "hello world", exit 0
FAIL if: error such as `element type is not supported for fill` or similar (workaround is `vibium click "textarea" && vibium type "textarea" "text"`)

Also test with inline content to isolate from site-specific variables:
```sh
vibium content '<textarea id="ta"></textarea>'
vibium fill "#ta" "hello"
echo "exit: $?"
vibium eval 'document.querySelector("#ta").value'
```

PASS if: exit 0 and value is `"hello"`
FAIL if: error on fill; note that the workaround — `vibium click "#ta" && vibium type "#ta" "hello"` — appends rather than replaces, which is a secondary limitation

Cross-check workaround still works:
```sh
vibium content '<textarea id="ta"></textarea>'
vibium click "#ta" && vibium type "#ta" "workaround text"
echo "exit: $?"
vibium eval 'document.querySelector("#ta").value'
```

PASS if: exit 0 and value contains "workaround text"

---

### B8 — `vibium attr` — boolean attributes indistinguishable from absent (High · P2)

```sh
vibium content '<input id="req" type="text" required><input id="norq" type="text">'
vibium attr "#req" "required"
vibium attr "#norq" "required"
```

PASS if: outputs differ in any way (e.g. `"true"` vs `""`, or non-empty vs empty)
FAIL if: both return identical output (both empty string or both `{"ok":true,"result":""}`)

---

### B9 — `vibium eval` — objects/arrays print Go internal repr (High · P2)

```sh
vibium go https://testtrack.org
vibium eval '({url: location.href, title: document.title})'
vibium eval '[1, 2, 3]'
```

PASS if: first output is valid JSON (`{"url":"...","title":"..."}`); second is `[1,2,3]`
FAIL if: output contains `map[type:string value:...]` or `map[type:number value:1]`

**Cross-site check — confirm the eval workaround used across practice-testing sites still works:**

The `--stdin` heredoc pattern is used heavily across practice-testing and cart-patrol for complex DOM queries. Verify it works correctly:

```sh
vibium go https://academybugs.com/
vibium eval --stdin <<'EOF'
JSON.stringify([...document.querySelectorAll("a")].slice(0,3).map(a => ({text: a.textContent.trim(), href: a.href})))
EOF
echo "exit: $?"
```

PASS if: valid JSON array output, exit 0
FAIL if: Go struct repr, empty output, or parse error

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
FAIL if: `compdef` error appears on stderr

Note: on zsh 5.9 (macOS) the exit code is 0 even when broken — check stderr, not just exit code.

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

### B15 — `vibium find text` — searches DOM text, not CSS-transformed display text (Medium · P2)

**Status as of v26.5.31:** Confirmed PASS — behavior is consistent and correct. `find text` is case-sensitive against DOM text only; CSS `text-transform` is never applied. This test is retained as a regression check.

**Source:** Discovered during AcademyBugs testing. Nav items and buttons had CSS `text-transform: uppercase` visually but mixed-case DOM text. Searching by the uppercase rendered string returned no results.

```sh
vibium content '<button style="text-transform:uppercase" id="btn">add to cart</button>'
vibium find text "ADD TO CART"
echo "exit: $? (uppercase search)"
vibium find text "add to cart"
echo "exit: $? (DOM text search)"
```

PASS if: `"ADD TO CART"` search returns exit 1 (not found) AND `"add to cart"` search returns exit 0 with `@e1` — this is consistent, predictable behavior that matches DOM semantics
FAIL if: `"ADD TO CART"` search returns exit 0 (falsely claims to find it via rendered text matching), inconsistently

Expected behavior distinction — also test with mixed-case DOM text:
```sh
vibium content '<button style="text-transform:uppercase" id="btn">Add to Cart</button>'
vibium find text "ADD TO CART"
echo "exit: $? (uppercase search, mixed DOM)"
vibium find text "Add to Cart"
echo "exit: $? (DOM-cased search)"
```

PASS if: only the DOM-cased `"Add to Cart"` search succeeds (exit 0)
FAIL if: uppercase search succeeds when DOM text is mixed-case (would mean rendered-text matching, which would be an inconsistency vs the previous case)

**AcademyBugs live verification:**
```sh
vibium go https://academybugs.com/
vibium wait load
# Dismiss tutorial modal if present
vibium find text "×" && vibium click @e1 2>/dev/null || true

# Nav items render as "SHOP", "FIND BUGS", "ABOUT" visually (CSS uppercase)
# DOM text is mixed-case
vibium find text "SHOP"
echo "exit: $? (uppercase — should NOT find)"
vibium find text "Shop"
echo "exit: $? (DOM-cased — should find)"
```

PASS if: uppercase search returns not-found (exit 1), DOM-cased search returns @e1 (exit 0)
FAIL if: uppercase search returns @e1 (exit 0) — would mean rendered-text matching is inconsistently applied

**QA Practice ecommerce live verification:**

The ecommerce section of qa-practice.razvanvancea.ro has ADD TO CART buttons rendered uppercase via CSS. Discovered during batch 3 practice-testing (2026-04-22).

```sh
vibium go https://qa-practice.razvanvancea.ro/auth_ecommerce.html && vibium wait load
vibium map
# Find and use the email/password/submit refs to login
# @e25 = email, @e26 = password, @e27 = submit (after login: these shift)
vibium fill @e25 "admin@admin.com" && vibium fill @e26 "admin123" && vibium click @e27
vibium wait load

# Product ADD TO CART buttons are CSS uppercase — DOM text is "ADD TO CART" (all caps)
# This is unusual: DOM text IS already uppercase, so both searches should behave the same
vibium find text "ADD TO CART"
echo "exit: $? (all-caps DOM text)"
vibium find text "add to cart"
echo "exit: $? (lowercase DOM text)"
```

Note: unlike AcademyBugs (where DOM text is mixed-case and CSS transforms it), QA Practice ADD TO CART buttons have all-caps DOM text. This tests whether `vibium find text` matches case-insensitively or case-sensitively.

PASS (B15 consistent behavior) if: only the exact DOM-cased `"ADD TO CART"` succeeds (case-sensitive matching)
PASS (alternative consistent behavior) if: both succeed (case-insensitive matching — also consistent)
FAIL if: results differ between this site and AcademyBugs for the same input (inconsistent matching rules)

Regardless — for automation reliability use `vibium map` refs instead of `find text` for these buttons.

---

### B16 — `vibium map` — Web Components shadow DOM elements not exposed (Medium · P2)

**Source:** Discovered during Polymer Shop testing (batch 3, 2026-04-22). All product listing, detail, cart, and checkout UI lives inside nested `<shop-app>` custom element shadow roots. `vibium map` returns "No interactive elements found" on every page. This is distinct from B24 (CSS-styled non-button `<li>` elements) — here the issue is shadow DOM encapsulation, not element type.

```sh
vibium go https://shop.polymer-project.org/ && vibium wait load
vibium map
echo "exit: $?"
```

PASS if: interactive elements from the page (e.g. category links, product buttons) appear as `@eN` refs
FAIL if: output is "No interactive elements found" or only returns non-shadow-DOM elements like `<a>` hrefs in the light DOM

Deep component check — verify map also fails inside a specific sub-component:
```sh
vibium go https://shop.polymer-project.org/list/mens_outerwear && vibium wait load
vibium map
# Expected FAIL: returns nothing; all product cards are inside shop-app > shop-list shadow DOM
```

Workaround verification — confirm shadow DOM traversal via eval still works:
```sh
vibium eval 'JSON.stringify(document.querySelector("shop-app")?.shadowRoot?.querySelector("shop-list")?.shadowRoot?.querySelectorAll("a")?.length)'
# Expected: a number > 0 (links are findable via eval shadowRoot traversal)
```

PASS (workaround) if: eval returns a count > 0
FAIL (full failure) if: eval also returns null or 0 (shadow DOM completely opaque to eval — no recovery path)

**Note (confirmed v26.5.31):** eval shadowRoot traversal also returns `null` on shop.polymer-project.org — this is a full failure with no eval workaround available.

---

### B17 — `vibium find role button` — times out on `input[type=submit]` (Medium · P2)

**Source:** Discovered during Practice Software Testing (practicesoftwaretesting.com) batch 3 testing. The login form uses `<input type="submit" value="Login">` instead of `<button>`. Per ARIA spec, `input[type=submit]` has implicit role `button`, so `vibium find role button --name "Login"` should find it. Instead it times out after 30s.

```sh
vibium content '<form><input type="text" name="u"><input type="submit" value="Login"></form>'
vibium find role button --name "Login"
echo "exit: $?"
```

PASS if: `@e1 [input[type=submit]] "Login"` found, exit 0
FAIL if: times out after 30s — `vibium find role button` does not recognise `input[type=submit]` as having the `button` role

Also verify the workaround works:
```sh
vibium content '<form><input type="text" name="u"><input type="submit" value="Login"></form>'
vibium eval 'document.querySelector("input[type=submit]").click()'
echo "exit: $? (eval click workaround)"
```

PASS (workaround) if: exit 0

Live site verification — PST login:
```sh
vibium go https://practicesoftwaretesting.com/auth/login && vibium wait load

# This times out (B17 symptom) — note: find role has no --timeout flag; use shell timeout
timeout 8 vibium find role button --name "Login"
echo "exit: $? (124=timeout, confirms B17 present)"

# This works (eval workaround)
vibium fill "#email" "customer@practicesoftwaretesting.com"
vibium fill "#password" "welcome01"
vibium eval 'document.querySelector("input[type=submit][value=Login]").click()' && vibium sleep 2000
vibium url
echo "url after login (workaround)"
```

PASS (B17 fixed) if: `find role button --name "Login"` returns a ref, exit 0
FAIL (B17 present) if: `find role button --name "Login"` times out (shell timeout exit 124); eval workaround required

---

### B18 — `vibium fill` / `vibium type` — negative values parsed as flags (Medium · P2)

**Source:** Discovered during BugEater QA Training Simulator testing (batch 4, 2026-04-22). Same root cause as B14 (geolocation negative coords) and B21 (sleep negative values) — the vibium CLI argument parser treats any argument starting with `-` as a flag rather than a value. Affects `vibium fill` and `vibium type`, meaning any form field that needs a negative number (e.g. `-2`, `-99.5`) cannot be filled directly.

```sh
vibium go https://bugeater.web.app/app/challenge/learn/adder && vibium wait load
vibium fill "input#first" "-2"
echo "exit: $?"
```

PASS if: value `-2` is typed into the field, exit 0
FAIL if: `unknown shorthand flag: '2' in -2` — negative value treated as flag argument

Also verify `vibium type`:
```sh
vibium type "input#first" "-2"
echo "exit: $?"
```

PASS if: value appended to field, exit 0
FAIL if: `unknown shorthand flag: '2' in -2`

Workaround verification — confirm native value setter + input event still works:
```sh
vibium eval 'const s=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,"value").set; const el=document.querySelector("input#first"); s.call(el,"-2"); el.dispatchEvent(new Event("input",{bubbles:true})); el.value'
# Expected: "-2"
```

PASS (workaround) if: eval returns `"-2"`

---

### B19 — `vibium frame` — context doesn't persist across CLI invocations (Medium · P2)

**Source:** Discovered during The Internet `/nested_frames` testing (batch 5, 2026-04-27). `vibium frame "name"` outputs the frame info and exits 0, but subsequent CLI invocations execute in the main frame context — the daemon resets frame context between commands.

```sh
vibium go http://the-internet.herokuapp.com/nested_frames && vibium wait load
vibium frames
# Returns frames including frame-middle → https://the-internet.herokuapp.com/frame_middle

vibium frame "frame-middle"
echo "exit: $? (frame switch)"
# Expected: context now set to frame-middle
vibium eval 'document.body.textContent.trim()'
echo "eval result (should be MIDDLE if context persisted)"
```

PASS if: `vibium frame "frame-middle"` exits 0 AND subsequent `vibium eval` returns `"MIDDLE"` (the frame body text)
FAIL if: `vibium eval` returns frameset HTML from the main page (context not persisted; each CLI invocation resets to main frame)

Also verify chained commands behave the same as separate calls:
```sh
vibium frame "frame-middle" && vibium eval 'document.body.textContent.trim()'
# FAIL if: frame switch output shown but eval returns main page content
```

Workaround verification — confirm cross-frame access via eval still works:
```sh
vibium eval 'document.querySelector("[name=frame-middle]")?.contentDocument?.body?.textContent?.trim()'
# Expected: "MIDDLE" (direct contentDocument access bypasses frame context requirement)
```

PASS (workaround) if: returns `"MIDDLE"`

---

### B20 — `vibium fill` — rejects empty string at CLI level (Medium · P2)

**Source:** Discovered during Automation in Testing batch testing (2026-05-10). Empty string `""` is rejected as a missing positional argument before any browser interaction occurs. Prevents clearing a pre-filled field via `vibium fill`. Companion inconsistency: `vibium type <sel> ""` accepts empty string (exit 0) but silently no-ops — field value unchanged. Neither command can clear a field.

```sh
vibium go https://the-internet.herokuapp.com/login && vibium wait load
vibium fill "#username" "hello"
vibium fill "#username" ""
echo "exit: $?"
```

PASS if: exit 0, field cleared to empty string
FAIL if: `Error: value is required` — CLI rejects `""` before reaching the browser

Verify across element types:
```sh
# input[type=password]
vibium fill "#password" "secret"
vibium fill "#password" ""
echo "exit: $?"

# input[type=number]
vibium go https://the-internet.herokuapp.com/inputs && vibium wait load
vibium fill @e1 "42"
vibium fill @e1 ""
echo "exit: $?"

# textarea
vibium go "data:text/html,<textarea id=ta></textarea>" && vibium wait load
vibium fill "#ta" "text"
vibium fill "#ta" ""
echo "exit: $?"
```

PASS if: all exit 0 and field is cleared
FAIL if: all exit 1 with `Error: value is required`

Verify `vibium type` inconsistency:
```sh
vibium go https://the-internet.herokuapp.com/login && vibium wait load
vibium fill "#username" "prefilled"
vibium type "#username" ""
echo "exit: $?"
vibium eval 'document.querySelector("#username").value'
```

PASS if: exit 1 (consistent with fill), OR exit 0 and field is cleared
FAIL if: exit 0 but field value unchanged (`"prefilled"`) — silent no-op

Verify whitespace bypass:
```sh
vibium fill "#username" " "
echo "exit: $?"
vibium eval 'document.querySelector("#username").value'
```

Expected FAIL note: single space `" "` and tab `"\t"` are accepted by CLI (exit 0) but leave literal whitespace in the field — they do not clear it. This is the only available "workaround" without dropping to eval.

Workaround verification:
```sh
vibium fill "#username" "to_clear"
vibium eval 'document.querySelector("#username").value = ""'
vibium eval 'document.querySelector("#username").value'
# Expected: ""
```

PASS (workaround) if: eval clears the field and returns `""`

---

### B21 — `vibium bidi-test` / `vibium launch-test` — WebSocket URL blank (High · P3)

```sh
vibium bidi-test
```

PASS if: all 5 steps pass (including `[3/5] Connecting to BiDi WebSocket...` succeeds)
FAIL if: `WebSocket URL: ` is blank at step 2 and `Error connecting: ... malformed ws or wss URL`

```sh
vibium launch-test
```

PASS if: BiDi WebSocket URL is non-empty and connection succeeds
FAIL if: `BiDi WebSocket: ` is blank and command hangs or errors

---

### B22 — `vibium sleep` — negative values parsed as flags (Medium · P3)

```sh
vibium sleep -1
echo "exit: $?"
```

PASS if: error clearly states negative duration is invalid, exit 1
FAIL if: `Error: unknown shorthand flag: '1' in -1`

---

### B23 — `vibium sleep` — oversize values silently clamp (Medium · P3)

```sh
time vibium sleep 30001
echo "exit: $?"
```

PASS if: exit 1 with error that value exceeds the 30000ms maximum
FAIL if: exits 0 after sleeping exactly 30s with `Slept for 30000 ms` (silently clamped)

---

### B24 — `vibium map` — framework-attached click handlers not exposed (Medium · P3)

**Source:** originally Black Box Puzzles (`puzzle29.html`), which now **404s** — upstream deferred B24 for lack of a stable repro. Re-established 2026-07-28 with a self-contained matrix plus coffee-cart.app. See [`issues/B24.md`](issues/B24.md).

**The original description was wrong.** `map` does expose non-semantic elements when clickability is declared statically. It infers from DOM attributes only — semantic tag, `role`, `tabindex`, inline `onclick` — so it cannot see handlers registered with `addEventListener`, and ignores `cursor:pointer`. Every modern framework attaches handlers via `addEventListener`.

**Part 1 — self-contained signal matrix.** No external site, cannot rot:

```sh
vibium content --stdin <<'EOF'
<div id="s1" onclick="void 0">1 · inline onclick only</div>
<div id="s2" style="cursor:pointer">2 · cursor:pointer only</div>
<div id="s3" role="button">3 · role=button only</div>
<div id="s4" tabindex="0">4 · tabindex only</div>
<div id="s5">5 · addEventListener only</div>
<div id="s6" style="cursor:pointer">6 · addEventListener + cursor:pointer</div>
<div id="s7" role="button">7 · addEventListener + role=button</div>
<div id="s8" class="btn">8 · nothing at all</div>
<script>['s5','s6','s7'].forEach(id =>
  document.getElementById(id).addEventListener('click', () => {}));</script>
EOF
vibium map
```

v26.5.31 exposes 1, 3, 4, 7 and misses 2, 5, 6. Case 8 is correctly missed.

PASS if: cases 2, 5 and 6 are also exposed, and case 8 is still missed
FAIL if: 2, 5 or 6 remain missing

**Part 2 — live repro, coffee-cart.app.** All nine products are plain `<div class="cup">` with Vue listeners, `cursor: auto`, no `role`, no `tabindex`, no `onclick` attribute:

```sh
vibium go https://coffee-cart.app/
sleep 3
vibium map
vibium eval '(() => document.querySelectorAll(".cup").length)()'
```

PASS if: `map` exposes the 9 cups alongside the 3 nav links and checkout button
FAIL if: `map` returns only 4 refs (`Menu page`, `Cart page`, `GitHub page`, `Proceed to checkout`) and no products

Confirm the cups really are interactive, so a FAIL is a discovery gap and not a dead element:

```sh
vibium eval '(() => { document.querySelectorAll(".cup")[2].click(); return "clicked"; })()'
# the cart total should change from $0.00 to $19.00
```

**Recovery path — must keep working.** This is what holds B24 at P3 rather than higher:

```sh
vibium find ".cup"     # → @e1 [div] "espresso"
```

PASS if: a usable @ref is returned
FAIL if: `find` also misses it — that would be a full discovery failure with no recovery, as in B16

**Secondary — ui5.sap.com** (heavier, ~6s load). Improved since the 2026-05-19 report of "No interactive elements found": now returns 127 refs, but 91 visible non-semantic `cursor:pointer` elements (80 `<span>`, 9 `<div>`, 2 `<bdi>`) remain unexposed:

```sh
vibium go "https://ui5.sap.com/#/demoapps"
sleep 6
vibium map | grep -c '^@e'
```

---

### B25 — `vibium text` — buffer overflow on large page text (Medium · P3)

**Source:** Discovered during randomuser.me API testing (batch 4, 2026-04-27). `vibium text` crashes with `bufio.Scanner: token too long` when page body text exceeds the scanner buffer limit (~64KB). Affects large JSON API responses and any page returning very large text content.

```sh
vibium go "https://randomuser.me/api/?results=5000&format=pretty" && vibium wait load
vibium text
echo "exit: $?"
```

PASS if: exit 0, page text returned (possibly truncated with a clear warning)
FAIL if: `bufio.Scanner: token too long` — process crashes, exit non-zero

Also test with a synthetic large page:
```sh
python3 -c "print('<html><body>' + 'x'*100000 + '</body></html>')" | vibium content --stdin
vibium text
echo "exit: $?"
```

PASS if: text returned without crash (may truncate; truncation with warning is acceptable)
FAIL if: `bufio.Scanner: token too long` crash

Workaround verification — eval with slice avoids the buffer limit:
```sh
vibium go "https://randomuser.me/api/?results=5000&format=pretty" && vibium wait load
vibium eval 'JSON.parse(document.body.innerText).info.results'
# Expected: 5000 (or whatever the API returned)
```

PASS (workaround) if: eval returns integer without crashing
FAIL (full failure) if: eval also crashes or returns null for very large responses

---

### B26 — `vibium check` — no element type guard (Low · P3)

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

### B27 — `vibium ws-test` — http/https scheme not caught (Low · P3)

```sh
vibium ws-test https://testtrack.org; echo "exit: $?"
vibium ws-test http://testtrack.org; echo "exit: $?"
```

PASS if: error clearly tells the user to use `wss://` or `ws://` instead
FAIL if: generic `failed to connect... malformed ws or wss URL` with no scheme guidance

---

### B28 — `vibium upload` — no element type guard (Low · P3)

```sh
vibium go https://the-internet.herokuapp.com/upload
vibium map
# Find the submit button ref (not the file input) from the map — e.g. @e2
vibium upload @e2 /tmp/vibium-reg-state.json
echo "exit: $?"
```

PASS if: clear user-facing error that element is not a file input, exit 1
FAIL if: exit 0 with no validation error, OR exit 1 with only `BiDi error: unable to set file input`

---

### B29 — `vibium find` returns @ref for disabled elements (Low · P3)

```sh
# Navigate to any page and inject a disabled button
vibium go https://testtrack.org
vibium eval 'document.body.insertAdjacentHTML("beforeend","<button id=\"b29\" disabled>B29</button>")'

# CSS selector find — should exit 1 (element disabled), actually exits 0 (bug)
vibium find "#b29"; echo "exit:$?"

# map — correctly excludes it
vibium map --selector "#b29"

# Confirm click on the leaked ref fails correctly
vibium find "#b29" && vibium click @e1; echo "click exit:$?"
```

PASS if: `vibium find "#b29"` exits 1 (element not found / not actionable) — consistent with `vibium map`
FAIL if: `vibium find "#b29"` exits 0 and returns an @ref for a disabled element

Expected FAIL output: `@e1 [button type="button"] "B29"` (exit 0) — ref returned despite element being disabled; `vibium map --selector "#b29"` returns "No interactive elements found" (inconsistency confirmed); subsequent `vibium click @e1` exits 1 with "enabled check failed — disabled attribute"

Note: CSS selector mode (`find "<selector>"`) leaks for all element types. `find text` and `find role` also leak for `<button>` but not for `<input>` types. `vibium map` always excludes disabled elements consistently.

---

### B30 — `vibium hover` — fails on non-interactive elements (Low · P3)

**Source:** Discovered during The Internet `/hovers` testing (batch 5, 2026-04-27). `vibium hover` fails with "element not found" on CSS-styled div elements even when they are fully visible in the DOM. CSS `:hover` pseudo-class works on any visible element — `vibium hover` should not require the element to be interactive.

**Status as of v26.5.31:** PARTIAL — `hover` on inline `<div>` now works (exit 0). `hover` on `<img>` with an external `src` still fails with `timeout after 0s: visible check failed — zero size`.

**Root cause identified 2026-07-28 — this is B6, not an `<img>` defect.** On v26.5.31 `hover` has no `--timeout` flag and an effective default of **zero**, so it never auto-waits; an `<img>` is simply the most common element that is briefly zero-size before it loads. A cached image passes, an uncached one fails at ~200ms. `dblclick` and `check` fail identically; `focus` and `scroll` pass (no visibility check). [#182](https://github.com/VibiumDev/vibium/pull/182) adds `--timeout` to these commands with a nonzero default and tests the auto-wait path on `hover` specifically, so B30 closes with B6. Comment draft: [`issues/B30.md`](issues/B30.md).

**Deterministic repro** — makes the zero-size window independent of network timing:

```sh
vibium go https://the-internet.herokuapp.com/hovers
vibium eval --stdin <<'EOF'
(() => {
  const im = document.createElement('img'); im.id = 'b30';
  document.body.appendChild(im);                    // 0x0 — no src yet
  setTimeout(() => { im.src = '/img/avatar-blank.jpg?cb=' + Date.now(); }, 600);
  return 'created';
})()
EOF
vibium hover "#b30"
```

PASS if: waits for the image to gain dimensions, then succeeds
FAIL if: `timeout after 0s: visible check failed — zero size` in ~200ms

```sh
vibium content '<div id="hov" style="width:100px;height:100px;background:blue;"></div>'
vibium hover "#hov"
echo "exit: $?"
```

PASS if: exit 0 (element hovered, mouse moved to element center)
FAIL if: `failed to hover: timeout after 0s: element not found` — non-interactive elements rejected

Also verify on a styled image (another common hover target):
```sh
vibium content '<img id="img" src="https://placekitten.com/100/100" style="display:block">'
vibium hover "#img"
echo "exit: $?"
```

PASS if: exit 0
FAIL if: `visible check failed — zero size` — image with external src not yet rendered at hover time (still failing as of v26.5.31)

Live site verification — The Internet `/hovers`:
```sh
vibium go http://the-internet.herokuapp.com/hovers && vibium wait load
vibium hover ".figure:first-child"
echo "exit: $? (should hover over first figure div)"
```

PASS if: exit 0, mouse moves to figure (CSS :hover triggers caption reveal)
FAIL if: "element not found" — hover rejects non-interactive element

Workaround verification — confirm `vibium mouse move x y` triggers CSS `:hover`:
```sh
vibium eval 'JSON.stringify(document.querySelector(".figure img")?.getBoundingClientRect())'
# Get center coordinates from output
vibium mouse move <cx> <cy> && vibium sleep 300
vibium eval 'window.getComputedStyle(document.querySelector(".figure:first-child .figcaption")).display'
# Expected: "block" (CSS :hover activated via mouse move)
```

PASS (workaround) if: `display` is `"block"` after `mouse move`

---

### B31 — `vibium fill` — fails on `input[type=range]` (Low · P3)

**Source:** Discovered during The Internet `/horizontal_slider` testing (batch 5, 2026-04-27). Same class as B7 (`vibium fill` on textarea) — fill rejects range inputs as "not editable". Range inputs accept values programmatically and should be fillable.

```sh
vibium content '<input type="range" id="s" min="0" max="10" step="1" value="5">'
vibium fill "#s" "3"
echo "exit: $?"
vibium value "#s"
```

PASS if: exit 0, `vibium value "#s"` returns `"3"`
FAIL if: `failed to fill: ... editable check failed — input type range not editable`

Live site verification:
```sh
vibium go http://the-internet.herokuapp.com/horizontal_slider && vibium wait load
vibium map
# @e1 = input[type="range"]
vibium fill @e1 "3"
echo "exit: $?"
vibium value @e1
# Expected: "3"
```

PASS if: exit 0, value set to "3"
FAIL if: "not editable" error — range input rejected by fill

Workaround verification:
```sh
vibium eval 'const s=document.querySelector("input[type=range]"); s.value="3"; s.dispatchEvent(new Event("input",{bubbles:true})); s.dispatchEvent(new Event("change",{bubbles:true})); s.value'
# Expected: "3"
```

PASS (workaround) if: eval returns `"3"` and display updates

---

### B32 — `vibium serve` — noisy teardown / missing port conflict hint (Low · P4)

**Status as of v26.5.31:** PARTIAL — teardown is now clean (PASS). Port conflict error still lacks `--port` hint (FAIL).

Sub-test 1 — teardown:
```sh
vibium serve --port 8090 &
SERVE_PID=$!
sleep 1
kill $SERVE_PID
wait $SERVE_PID 2>/tmp/vibium-serve-stderr.txt
cat /tmp/vibium-serve-stderr.txt
```

PASS if: no output on stderr on SIGTERM (fixed in v26.5.31)
FAIL if: stack traces or multiple error lines printed to stderr on SIGTERM

Sub-test 2 — port conflict hint:
```sh
vibium serve --port 8090 &
BGPID=$!
sleep 1
vibium serve --port 8090 2>&1; echo "conflict exit: $?"
kill $BGPID 2>/dev/null; wait $BGPID 2>/dev/null
```

PASS if: error mentions `--port` as a workaround
FAIL if: only `bind: address already in use` with no `--port` hint

---

### B33 — `vibium content ""` — inconsistent error message (Low · P4)

```sh
vibium content ""
vibium content
```

PASS if: both produce the same error message, including the `--stdin` hint
FAIL if: the empty-string case omits the `--stdin` hint present in the no-arg message

---

### B34 — `vibium eval` — all exception detail dropped (High · P2)

Appended out of priority order — see README. Would otherwise sort beside B9.
**Tracked upstream as [#221](https://github.com/VibiumDev/vibium/issues/221) (OPEN) — do
not file a new issue.** Root cause is located there: `clicker/internal/bidi/script.go`
builds the message from `evalResult.Result`, which is empty for exception responses; the
text lives on BiDi's `exceptionDetails.text`.

```sh
vibium go https://example.com
vibium eval '(() => { throw new Error("CUSTOM_MESSAGE_HERE") })()'
```

PASS if: output contains `CUSTOM_MESSAGE_HERE`
FAIL if: output is `Error: failed to evaluate: script exception:` with nothing after the colon

**Exception-class check — every class must carry its detail:**

```sh
vibium eval 'const = = 5'                                    # SyntaxError
vibium eval 'totallyUndefinedThing.foo'                      # ReferenceError
vibium eval 'null.foo'                                       # TypeError
vibium eval '(() => { throw "PLAIN_STRING_THROWN" })()'      # thrown string
```

PASS if: each names its error type or message
FAIL if: all four return the identical empty `script exception:`

**Flag check — the detail must be reachable somewhere:**

```sh
vibium eval --json '(() => { throw new Error("CUSTOM_MESSAGE_HERE") })()'
vibium eval -v '(() => { throw new Error("CUSTOM_MESSAGE_HERE") })()'
```

PASS if: either surfaces the message
FAIL if: `--json` gives `{"ok":false,"error":"failed to evaluate: script exception: "}` — note the
trailing space where the text should be interpolated — and `-v` adds nothing

**Control — confirms the detail exists and is only lost on the error path:**

```sh
vibium eval "(() => { try { null.foo } catch (e) { return e.constructor.name + ': ' + e.message } })()"
```

Must return `TypeError: Cannot read properties of null (reading 'foo')` in both the failing and
fixed states. If this ever stops working, the problem is larger than B34.

**Cross-surface check (MCP)** — the defect is in the shared evaluate path, so a CLI-only fix is
PARTIAL:

```
browser_navigate { url: "https://example.com" }
browser_evaluate { expression: "(() => { throw new Error(\"CUSTOM_MESSAGE_HERE\") })()" }
```

PASS if: the MCP error also carries `CUSTOM_MESSAGE_HERE`
PARTIAL if: the CLI is fixed but MCP still returns bare `script exception:`

**Cross-site check** — confirmed page-independent; run on any two of example.com,
testtrack.org/canvas-demo, saucedemo.com. All must behave identically.

---

### B35 — `vibium screenshot -o` — output path directory discarded (Medium · P2)

```sh
cd /tmp
vibium go https://example.com
rm -f /tmp/vibium-b35-check.png ~/Pictures/Vibium/vibium-b35-check.png
vibium screenshot -o /tmp/vibium-b35-check.png
ls /tmp/vibium-b35-check.png
```

PASS if: the file exists at `/tmp/vibium-b35-check.png`
FAIL if: absent, and the command reports `Screenshot saved to ~/Pictures/Vibium/vibium-b35-check.png`

**Path-form matrix — every form must be honoured:**

```sh
vibium screenshot -o b35-rel.png          # relative to cwd
vibium screenshot -o ./b35-dot.png        # explicit ./
vibium screenshot -o ~/b35-home.png       # tilde expansion
vibium screenshot -o /tmp/b35-abs.png     # absolute
vibium screenshot -o sub/b35-nested.png   # subdirectory component
```

PASS if: each lands where specified (`sub/` created or a clear error)
FAIL if: all five land in `~/Pictures/Vibium/` as bare basenames, `sub/` silently dropped

**Sibling consistency check — these three already honour `-o` and must not regress:**

```sh
vibium pdf -o /tmp/b35.pdf        && ls /tmp/b35.pdf
vibium storage -o /tmp/b35.json   && ls /tmp/b35.json
vibium record start --name b35 && sleep 1 && vibium record stop -o /tmp/b35.zip && ls /tmp/b35.zip
```

PASS if: all three write to the given paths (current behaviour — regression guard)
FAIL if: any now flattens like `screenshot`

**Silent-failure check:**

```sh
vibium screenshot --json -o /tmp/b35-json.png
```

PASS if: reports the true path, or `ok:false` with an error
FAIL if: reports `{"ok":true,...}` naming the redirected `~/Pictures/Vibium/` location

Not site-dependent — a local path-handling bug, reproducible on any page.

---

## Cleanup

```sh
rm -f /tmp/vibium-reg-state.json /tmp/vibium-reg-lambdatest.json /tmp/vibium-reg-abantecart.json /tmp/vibium-reg-coffeecart.json /tmp/vibium-reg-academybugs.json /tmp/vibium-serve-stderr.txt /tmp/vibium-b12-stderr.txt
# B35 leaves captures in both the target dir and the forced fallback
rm -f /tmp/vibium-b35-check.png /tmp/b35-abs.png /tmp/b35.pdf /tmp/b35.json /tmp/b35.zip ~/b35-home.png
rm -f ~/Pictures/Vibium/{vibium-b35-check,b35-rel,b35-dot,b35-home,b35-abs,b35-nested,b35-json}.png
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
║  B7  ║ High     ║ P1       ║ PASS / FAIL / SKIP               ║
║  B8  ║ High     ║ P2       ║ PASS / FAIL / SKIP               ║
║  B9  ║ High     ║ P2       ║ PASS / FAIL / SKIP               ║
║ B10  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B11  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B12  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B13  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B14  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B15  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║      ║          ║          ║ (PASS = consistent DOM-cased     ║
║      ║          ║          ║ matching; regression check only) ║
║ B16  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B17  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B18  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B19  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B20  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B21  ║ High     ║ P3       ║ PASS / FAIL / SKIP               ║
║ B22  ║ Medium   ║ P3       ║ PASS / FAIL / SKIP               ║
║ B23  ║ Medium   ║ P3       ║ PASS / FAIL / SKIP               ║
║ B24  ║ Medium   ║ P3       ║ PASS / FAIL / SKIP               ║
║ B25  ║ Medium   ║ P3       ║ PASS / FAIL / SKIP               ║
║ B26  ║ Low      ║ P3       ║ PASS / FAIL / SKIP               ║
║ B27  ║ Low      ║ P3       ║ PASS / FAIL / SKIP               ║
║ B28  ║ Low      ║ P3       ║ PASS / FAIL / SKIP               ║
║ B29  ║ Low      ║ P3       ║ PASS / FAIL / SKIP               ║
║ B30  ║ Low      ║ P3       ║ PASS / FAIL / SKIP               ║
║ B31  ║ Low      ║ P3       ║ PASS / FAIL / SKIP               ║
║ B32  ║ Low      ║ P4       ║ PASS / FAIL / SKIP               ║
║ B33  ║ Low      ║ P4       ║ PASS / FAIL / SKIP               ║
║ B34  ║ High     ║ P2       ║ PASS / FAIL / PARTIAL / SKIP     ║
║      ║          ║          ║ (PARTIAL = CLI fixed, MCP still  ║
║      ║          ║          ║ returns bare script exception:)  ║
║ B35  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
╠══════╩══════════╩══════════╩══════════════════════════════════╣
║  X PASS   Y FAIL   Z PARTIAL   W SKIP   (35 total)               ║
╚══════════════════════════════════════════════════════════════════╝
```

For each FAIL, include: the exact error output observed, and whether the symptom matches or differs from the original bug report.
