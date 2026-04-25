---
name: vibium-cli-test
description: Regression test suite for 27 known vibium CLI bugs (B1–B27), ordered by priority and severity (P1 Critical first, P4 Low last). Run after fixes to verify each bug is resolved. Labels PASS/FAIL/SKIP with exact repro steps and cross-site verification.
---

# vibium CLI Regression Test Suite

Run all 27 tests and produce a final summary table. Each test maps to a bug in [VibiumDev/vibium#112](https://github.com/VibiumDev/vibium/issues/112). Tests are ordered by priority and severity — B1–B6 are P1 Critical/High, B7–B18 are P1–P2 High/Medium, B19–B25 are P3, B26–B27 are P4.

## Setup

Resolve vibium binary: try `vibium` globally, then `./node_modules/.bin/vibium`.

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

Also verify text-vs-value distinction:
```sh
vibium select "#oldSelectMenu" "Yellow"
echo "exit: $?"
vibium eval 'document.querySelector("#oldSelectMenu").value'
```

PASS if: exit 1 (text unsupported and clearly errored), OR exit 0 and `.value` is `"Yellow"`
FAIL if: exit 0 but `.value` is `""` (silent wrong state)

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

**Source:** Discovered during Polymer Shop testing (batch 3, 2026-04-22). All product listing, detail, cart, and checkout UI lives inside nested `<shop-app>` custom element shadow roots. `vibium map` returns "No interactive elements found" on every page. This is distinct from B22 (CSS-styled non-button `<li>` elements) — here the issue is shadow DOM encapsulation, not element type.

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

# This times out (B17 symptom)
vibium find role button --name "Login" --timeout 5000
echo "exit: $? (should timeout with B17 present)"

# This works (eval workaround)
vibium fill "#email" "customer@practicesoftwaretesting.com"
vibium fill "#password" "welcome01"
vibium eval 'document.querySelector("input[type=submit][value=Login]").click()' && vibium sleep 2000
vibium url
echo "url after login (workaround)"
```

PASS (B17 fixed) if: `find role button --name "Login"` returns a ref, exit 0
FAIL (B17 present) if: `find role button --name "Login"` times out; eval workaround required

---

### B18 — `vibium fill` / `vibium type` — negative values parsed as flags (Medium · P2)

**Source:** Discovered during BugEater QA Training Simulator testing (batch 4, 2026-04-22). Same root cause as B14 (geolocation negative coords) and B20 (sleep negative values) — the vibium CLI argument parser treats any argument starting with `-` as a flag rather than a value. Affects `vibium fill` and `vibium type`, meaning any form field that needs a negative number (e.g. `-2`, `-99.5`) cannot be filled directly.

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

### B19 — `vibium bidi-test` / `vibium launch-test` — WebSocket URL blank (High · P3)

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

### B20 — `vibium sleep` — negative values parsed as flags (Medium · P3)

```sh
vibium sleep -1
echo "exit: $?"
```

PASS if: error clearly states negative duration is invalid, exit 1
FAIL if: `Error: unknown shorthand flag: '1' in -1`

---

### B21 — `vibium sleep` — oversize values silently clamp (Medium · P3)

```sh
time vibium sleep 30001
echo "exit: $?"
```

PASS if: exit 1 with error that value exceeds the 30000ms maximum
FAIL if: exits 0 after sleeping exactly 30s with `Slept for 30000 ms` (silently clamped)

---

### B22 — `vibium map` — custom-rendered and canvas elements not exposed (Medium · P3)

**Source:** Discovered during Black Box Puzzles testing. Interactive clickable circles rendered as CSS-styled `<li>` elements (not `<button>` or `<a>`) did not appear in `vibium map` output. Required `getBoundingClientRect()` + `vibium mouse click x y`.

```sh
vibium go https://blackboxpuzzles.workroomprds.com/puzzle29.html
vibium wait load
vibium map
echo "exit: $?"
```

PASS if: output includes `@e1`, `@e2`... refs for the interactive puzzle elements (circles), exit 0
FAIL if: output is empty or contains only non-puzzle elements (nav, links), and the circles are not exposed as interactive refs — this forces coordinate-based interaction

Workaround verification — confirm coordinate-based clicking still works when map misses elements:
```sh
vibium eval 'JSON.stringify([...document.querySelectorAll("li")].slice(0,3).map(li => { const r = li.getBoundingClientRect(); return {x: Math.round(r.x + r.width/2), y: Math.round(r.y + r.height/2)} }))'
# Get x,y from output — e.g. x=100, y=200
vibium mouse click 100 200
echo "exit: $? (coordinate click workaround)"
```

PASS if: exit 0 (coordinate click works regardless of map exposure)
FAIL if: coordinate click fails (would indicate a separate `vibium mouse click` bug)

Also verify `vibium a11y-tree` as an alternative discovery mechanism:
```sh
vibium a11y-tree
echo "exit: $?"
```

PASS if: a11y-tree reveals the puzzle `<li>` elements even when `vibium map` does not
FAIL if: a11y-tree also misses them (full discovery failure — no alternative to coordinate heuristics)

---

### B23 — `vibium check` — no element type guard (Low · P3)

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

### B24 — `vibium ws-test` — http/https scheme not caught (Low · P3)

```sh
vibium ws-test https://testtrack.org; echo "exit: $?"
vibium ws-test http://testtrack.org; echo "exit: $?"
```

PASS if: error clearly tells the user to use `wss://` or `ws://` instead
FAIL if: generic `failed to connect... malformed ws or wss URL` with no scheme guidance

---

### B25 — `vibium upload` — no element type guard (Low · P3)

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

### B26 — `vibium serve` — noisy teardown (Low · P4)

```sh
vibium serve --port 8090 &
SERVE_PID=$!
sleep 1
kill $SERVE_PID
wait $SERVE_PID 2>/tmp/vibium-serve-stderr.txt
cat /tmp/vibium-serve-stderr.txt
```

PASS if: no stack traces or unexpected error lines on shutdown
FAIL if: multiple error lines / Go stack output printed to stderr on SIGTERM

Port conflict hint sub-test:
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

### B27 — `vibium content ""` — inconsistent error message (Low · P4)

```sh
vibium content ""
vibium content
```

PASS if: both produce the same error message, including the `--stdin` hint
FAIL if: the empty-string case omits the `--stdin` hint present in the no-arg message

---

## Cleanup

```sh
rm -f /tmp/vibium-reg-state.json /tmp/vibium-reg-lambdatest.json /tmp/vibium-reg-abantecart.json /tmp/vibium-reg-coffeecart.json /tmp/vibium-reg-academybugs.json /tmp/vibium-serve-stderr.txt /tmp/vibium-b12-stderr.txt
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
║ B7  ║ High     ║ P1       ║ PASS / FAIL / SKIP               ║
║  B8  ║ High     ║ P2       ║ PASS / FAIL / SKIP               ║
║  B9  ║ High     ║ P2       ║ PASS / FAIL / SKIP               ║
║ B10  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B11  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B12  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B13  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B14  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B15  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B16  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B17  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║ B18  ║ Medium   ║ P2       ║ PASS / FAIL / SKIP               ║
║  B19  ║ High     ║ P3       ║ PASS / FAIL / SKIP               ║
║ B20  ║ Medium   ║ P3       ║ PASS / FAIL / SKIP               ║
║ B21  ║ Medium   ║ P3       ║ PASS / FAIL / SKIP               ║
║ B22  ║ Medium   ║ P3       ║ PASS / FAIL / SKIP               ║
║ B23  ║ Low      ║ P3       ║ PASS / FAIL / SKIP               ║
║ B24  ║ Low      ║ P3       ║ PASS / FAIL / SKIP               ║
║ B25  ║ Low      ║ P3       ║ PASS / FAIL / SKIP               ║
║ B26  ║ Low      ║ P4       ║ PASS / FAIL / SKIP               ║
║ B27  ║ Low      ║ P4       ║ PASS / FAIL / SKIP               ║
╠══════╩══════════╩══════════╩══════════════════════════════════╣
║  X PASS   Y FAIL   Z SKIP   (27 total)                          ║
╚══════════════════════════════════════════════════════════════════╝
```

For each FAIL, include: the exact error output observed, and whether the symptom matches or differs from the original bug report.
