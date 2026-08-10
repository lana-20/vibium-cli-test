# Vibium reporting queue

Cross-suite tracker for everything worth reporting upstream to VibiumDev/vibium —
CLI, MCP, JS, Java and Python findings in one place. Update the checkbox and the
**Filed as** line in the matching write-up whenever something moves.

> **Nothing here goes to `VibiumDev/vibium` without explicit, peer-reviewed approval.**
> Every write-up is a *draft* until Lana has reviewed it and says to submit. No issue,
> comment or PR is opened upstream on the strength of this file alone.
>
> Pushing to Lana's own repos (`lana-20/*`) is fine and expected — that is where drafts
> live and get reviewed. The line is the upstream project, not visibility.

Last reconciled with upstream: **2026-08-10** (B38 filed as #343; `--connect` re-confirmed fixed) · published npm `latest`: **v26.5.31**

> ## ⚠ 2026-08-07 reconciliation — most of this queue is now dead
>
> Upstream shipped **198 commits since 2026-06-01**, with a burst 2026-08-02→07,
> in the ten days after the previous reconciliation. **Four of six pending items
> are fixed upstream and must not be filed**, and the entire §C state table is
> wrong — every issue it lists as OPEN is now closed.
>
> | Item | Was | Now |
> |---|---|---|
> | B34 → comment on #221 | "OPEN, 0 comments" | **#221 closed/completed 2026-08-02**, PR #253 |
> | B36 | "fixing #221 does not fix this" | **fixed by that same PR** — verified in source |
> | B35 | "Nothing upstream covers these" | **fixed under #119** (`c349fcd`, `ea5c2be`) |
> | B30 → comment on #112 | pending | #112 and #182 both closed/completed — largely moot |
> | B24 | ready to file | **still valid** — and upstream *named* its blocker (a stable repro page), which this write-up now answers |
> | FR1 | ready to file | **still valid**, no CLI init-script command exists |
> | B32 | untracked here | deferred upstream alongside B24, no issue exists — now recorded, recommendation is to leave it |
> | ~~B37~~ | *new 2026-08-07, dead the same day* | **`find` mints a @ref on a miss — FIXED on `main` 2026-08-03 by #206 (PR #280), one day after `hugs` named it. DO NOT FILE.** |
>
> **B36 is the important correction.** PR #253 ("Route every BiDi script result
> through one decoder", #221 + #124) rewrote `deserializeScriptResult`, whose new
> doc line reads *"A thrown exception is surfaced as an error rather than null."*
> `handlePageEval` calls it and `sendError`s on failure — which is exactly B36's
> defect. The maintainer independently shipped the broader shared-decoder fix
> that B34's comment was going to argue for. **#124 (§C) is fixed by the same PR.**
>
> **Nothing above is published.** Installed and npm `latest` are both v26.5.31
> (2026-06-01), so every fix is source-only and the local suites still FAIL these
> — expected, not a regression. **§E is now much larger than the 8 bugs it lists.**
>
> **Process lesson, worth more than any single item:** the protocol here was
> *followed* — "search before writing" and "re-verify on the installed version"
> were both done at hardening time — and it still produced four dead drafts. On an
> upstream this active, **re-verification belongs immediately before filing, not
> at hardening time.** Ten days of drift was enough.
>
> **⚠ Method rule, earned four times over: never conclude "unfixed" from a
> commit-message grep.** Every false negative this session came from grepping commit
> *titles*, and none of the four fixes contained the searched keyword: #221 was titled
> after a "shared script result decoder"; #119 "Write screenshots where the CLI was told
> to"; #240/#158; and B37's fix "Make `is` exit-honest and `find --timeout` real".
> **Read the relevant source on `main`, and check the issue's `state_reason`.** A
> commit grep can prove presence, never absence. (Also: a scan returning exactly 100 is
> the API page limit, not a result — paginate.)
>
> **One of our 33 was wrong, and it cost the maintainer real effort.** **B29/#212**
> is the only item closed `not_planned` rather than `completed` — and not on
> priority grounds. `hugs` verified against `main` and refuted the premise with
> source citations: *"the premise does not hold on either half, so this is not the
> bug it describes."* `map` never filters `disabled`, so `find` and `map` already
> agreed; and `--selector` is a documented scope, not a filter. **Calibration this
> demands: premises get checked against source here.** B24 in particular must be
> filed as an enhancement, not a defect — see its entry for why the same rebuttal
> would otherwise apply. The one upside is that the same comment handed us B37.

---

## A · Ready to file — new issues

**Header corrected 2026-08-07: "Nothing upstream covers these" was false.** B35 was
covered by #119, B36 by the #221 PR, and B37 — added and killed the same day — by #206.
**B38 was filed 2026-08-10 as [#343](https://github.com/VibiumDev/vibium/issues/343) — the
first item to leave this queue since the 2026-08-07 reconciliation. B24 and FR1 remain
fileable, both confirmed against `main` source rather than the installed build:**
- **B24** — `mapScript()` (`internal/agent/handlers.go:2848`) still queries a fixed
  interactive-selector list on `main`. A plain `<div class="cup-body">` matches no term
  in it, so the gap is real *and* the enhancement framing is the correct one.
- **FR1** — `addInitScript` exists in the engine (`internal/api/handlers_storage.go`,
  `router.go`) and in the Python/JS/Java clients, but `internal/agent/schema.go` has
  **zero** occurrences. The capability ships; only the CLI/MCP surfaces lack it, which
  is exactly the surface-parity ask.

- [x] **B38 · BiDi error detail discarded; error code printed twice** — ✅ **FILED 2026-08-10 as
  [#343](https://github.com/VibiumDev/vibium/issues/343), open.** Drafted 2026-08-09, live on
  `main` @ `59e4b4b`, verified by building it. `vibium go "not-a-real-url"` prints
  `BiDi error: invalid argument - invalid argument`; Chrome sent `Invalid URL: not-a-real-url`.
  Cause is a **parse** defect, not formatting: `Message` (`internal/bidi/protocol.go:43-52`)
  has no field for BiDi's *sibling* `message`, so it is dropped by `encoding/json`; `GetError`
  (`:70-86`) then targets a nested shape that never arrives, so its fallback fabricates the
  detail by copying the code. A build patched only at the formatter **still loses the detail**
  — that falsifier is what makes this a verified cause rather than a plausible story.
  Severity Medium · **Priority P2** (no workaround, everyday commands, ~19 call sites, and
  upstream has fixed five issues of this exact class). No upstream issue covers it.
  Write-up: `issues/B38.md` · repro assets: `issues/verify-b38/`.

- [x] **B35 · ~~`screenshot -o` output path silently discarded~~ — FIXED UPSTREAM, DO NOT FILE**
  **Fixed under [#119](https://github.com/VibiumDev/vibium/issues/119)** (closed 2026-08-03) by
  `c349fcd` "Write screenshots where the CLI was told to" and `ea5c2be` (same for pdf/record).
  **The shipped fix is the surface-aware design this write-up proposed**: the CLI resolves `-o`
  itself and sends an absolute path; a bare filename still goes to the screenshot dir, keeping the
  MCP default intact. **#119 was an existing open issue this queue's duplicate check missed** —
  the entry below claimed "Nothing upstream covers these." Original notes kept for the record:
  Severity Medium · P2 · CLI only
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

- [x] **B36 · ~~`page.eval` discards script exceptions~~ — FIXED UPSTREAM, DO NOT FILE**
  **Fixed by PR #253** (`8c70929`, "Route every BiDi script result through one decoder", #221+#124).
  Verified in source: `deserializeScriptResult`'s new doc reads *"A thrown exception is surfaced as
  an error rather than null"*, and `handlePageEval` calls it then `sendError`s — exactly this defect.
  **This entry's core claim — "fixing #221 does not fix this" — is now wrong.** It was right about
  the original report's scope; the actual fix went broader, which is what B34's comment intended to
  argue for. Original notes kept for the record:
  Severity High · P2 · client libraries only
  Split out of B34 on 2026-07-28. `Router.handlePageEval` has no `Type == "exception"`
  check, so a thrown script becomes a `sendSuccess` with nil and Python, JS and Java all
  return null without raising. Distinct from #221 in handler, symptom and affected
  surfaces — **fixing #221 does not fix this**.
  → [`B36.md`](B36.md)
  → File as its own issue, cross-referencing #221. Do not fold it into that thread; it
  would dilute both.
  → Strongest supporting detail: the clients' error handling is *correct* — the Python
  guard raises on any error response, and `p.go("not-a-url://x")` proves it. They are
  never given an error to raise.
  → Impact framing that lands: any test asserting a null result passes whether the value
  was absent or the script threw. Two such assertions existed in our own suites.

- [x] **B37 · ~~`find` mints a `@ref` on a miss~~ — FIXED ON `main`, DO NOT FILE**
  Fixed 2026-08-03 by [#206](https://github.com/VibiumDev/vibium/issues/206) (PR #280,
  *"Make `is` exit-honest and `find --timeout` real"*), one day after `hugs` named the
  defect closing #212. The fix was incidental — adding polling to the CSS path so
  `--timeout` works routed a miss through the error branch. Drafted then killed the same
  day by its own fact-check; kept as [`B37.md`](B37.md) for the record and for the
  methodology note it produced.

- [ ] **B24 · `map` misses framework-attached click handlers** — ✅ **STILL VALID, and now the
  best-positioned item in this queue.** Re-verified 2026-08-07.
  Reproduces on installed v26.5.31: coffee-cart.app has 10 `[data-test]` elements in the DOM;
  `map` returns 4 (3 nav links + checkout). No upstream commits touch `map` handler detection.

  → **The maintainer named the exact blocker, and this write-up answers it.**
  `vincebln2` on #112 (2026-07-06) split 33 bugs into individual issues and listed:
  *"**Deferred:** B24 (test site 404s, needs a stable repro page), B32 (minor UX,
  skipping for now)."* B24 is **absent from the "Individual issues filed" list**
  (B8/#198 … B33/#213) — confirmed, so **no upstream issue exists for it**. The
  deferral reason is a stable repro page, which is precisely what this write-up now
  supplies. Lead with that.

  → **NEW, strongest argument — vibium's own `a11y-tree` already sees what `map` misses.**
  Measured 2026-08-07 on coffee-cart.app: `a11y-tree` returns all 9 cups as named nodes
  (`{"role":"generic","name":"Espresso"}`, `"Cappuccino"`, `"Mocha"` …); `map` returns
  **0** of them. The cups carry `aria-label` (→ accessible name "Espresso"). This is the
  same "every capability the fix needs already ships" argument that carried B35 — and it
  is **BiDi-native, no CDP required**, which matters given the filing convention below.

  → **State the honest limit, or the argument overreaches.** The cups' a11y role is
  `generic`, not `button`/`link` — so `a11y-tree` shows they are *named and present*, not
  that they are *interactive*. A strict role-based "map interactive elements" contract
  would legitimately skip them. The defensible framing is therefore: the page's primary
  interaction target has **no static signal at all** (verified: no inline `onclick`, no
  `role`, no `tabindex`, `cursor: auto` — behaviour attached purely via
  `addEventListener`), so `map` returns nothing for it and an agent cannot drive the
  page's main function, while `a11y-tree` and `find` both still work. Do **not** claim
  a11y-tree proves interactivity.

  → **Distinct from #203, and say so pre-emptively.** #203 (`map` misses Web Component
  shadow DOM, = B16) is **closed/completed 2026-08-03**. Different mechanism, and
  irrelevant to this repro: coffee-cart.app has **0 shadow roots and 0 custom elements**
  (verified). Cross-reference it so this isn't closed as a duplicate.

  → **Caveat to disclose when filing:** verification is on installed v26.5.31
  (2026-06-01), which **predates** #203's pierce work and every other August fix. Whether
  any of those incidentally changed `map`'s element discovery is untested and untestable
  until the next npm publish. Offer to retest on `main`.

  → **⚠ Frame this as an ENHANCEMENT, not a defect — or it will be closed like B29 was.**
  Closing #212, `hugs` documented how `map` actually works: `mapScript`
  (`internal/agent/handlers.go:2722-2748`) queries a fixed **interactive selector set**
  (:2727) and then applies exactly **one** filter — visibility (:2737). It never reads
  `disabled`/`aria-disabled`, and `--selector` is a *scope*, not a filter. So a plain
  `<div class="cup-body">` with no `role`/`tabindex`/`onclick` **does not match the
  selector set at all** — `map` omitting it is that design working as written, not a
  filter bug. Claiming "`map` has a bug" invites the same source-cited rebuttal B29 got.
  The defensible ask is: *the interactive-selector strategy cannot see behaviour attached
  via `addEventListener`, and vibium already has a signal that can (`a11y-tree` reads the
  accessible name) — consider a fallback.*

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

- [ ] **B32 · serve port-conflict hint** — ⚠️ **untracked here until 2026-08-07; deferred upstream, no issue exists**
  Surfaced by re-reading #112's split comment: `vincebln2` deferred **both** B24 and B32
  — *"B32 (minor UX, skipping for now)"* — and B32, like B24, is **absent from the
  "Individual issues filed" list**, so nothing upstream tracks it. This queue listed B32
  only as a "known partial" in the suite description and never carried it as a reportable
  item, so the deferral went unnoticed.
  → **Recommendation: leave it deferred.** "Minor UX, skipping for now" is a soft defer,
  not a rejection, but it is P4 and the maintainer has already weighed it. Filing it
  against their stated judgement spends credibility that B24 and FR1 need more. Revisit
  only if it starts blocking something real.
  → Recorded here so the deferral is a *decision on file* rather than an omission.

- [ ] **FR1 · Expose `BrowserContext.addInitScript` on the CLI and MCP surfaces** — ✅ **STILL VALID, re-verified 2026-08-07**
  No init-script command exists on the CLI (`--help` confirms); no upstream commits add one.
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

### Recommended order

**Superseded 2026-08-07.** Items 1, 2, 3 and 5 below are dead (see the banner).
The live order is now just:

1. **B24** — new issue; upstream explicitly deferred it wanting a stable repro, which
   this write-up now supplies. Re-verified reproducing.
2. **FR1** — enhancement, queues behind defects as always. Re-verified absent.

Original order kept below for the record, struck through:

1. ~~B34 → comment on #221~~ — #221 is closed/completed.
2. ~~B36~~ — fixed by the same PR.
3. ~~B35~~ — fixed under #119.
4. **B24** — still live.
5. ~~B30 → comment on #112~~ — #112/#182 closed; largely moot.
6. **FR1** — still live.

## B · Ready to comment — existing issues

- [x] **B34 → ~~comment on #221~~ — CLOSED/COMPLETED 2026-08-02, DO NOT COMMENT**
  Fixed by PR #253 (`8c70929`), which also closes #124 and B36. The recommended-order entry below
  calls this "highest leverage per unit of effort" on the strength of it being open with zero
  comments — that is no longer true. Original notes:
  ~~(OPEN, 0 comments)~~
  `eval` drops all exception detail. **Do not file a duplicate** — #221 already has it,
  and locates the root cause in `clicker/internal/bidi/script.go`.
  Our comment adds what #221 lacks: the 6-class exception matrix, all flags
  (`--json`/`--verbose`/`--stdin`) unrecoverable, MCP cross-surface confirmation,
  a `try/catch` control proving the data is reachable, 3-site independence,
  **a three-way comparison showing Playwright and Selenium both return the message**
  (the strongest single argument — this is not a hard problem peers also failed),
  **the escalation that all three client libraries swallow the exception entirely**
  (Python, JS and Java all return None/null and never raise — worse than the CLI, which at
  least exits 1), and the
  [#156](https://github.com/VibiumDev/vibium/issues/156) sibling
  (`failed to annotate: script exception:` — same truncated suffix, likely same helper).
  → [`B34.md`](B34.md)
  → **All three client libraries confirmed swallowing** (Python, JS, Java) — they return
  `None`/`null` and never raise, which is worse than the CLI's empty message because a
  broken script is indistinguishable from one returning nothing. Verified per client with
  a `1 + 1` control.
  → Consequence already actioned in our own suites: two assertions could not distinguish a
  real null from a thrown exception. Fixed in vibium-js-test `27770fe` and
  vibium-java-test `04cc720`, both re-verified at baseline (JS 194/3/1, Java 140/0/22).
  Python was already safe (`is not None`).

- [ ] **B30 → comment on [#112](https://github.com/VibiumDev/vibium/issues/112)** — ⚠️ **largely moot, re-verified 2026-08-07**
  #112 and #182 are both closed/completed. The comment's purpose was to stop B30 being closed as
  "not reproduced"; with #182 landed that risk is mostly gone. File only if a reopen actually happens.
  ~~(CLOSED — comments still land)~~
  Ask that B30 be closed as **fixed by #182**, not "not reproduced". Its `<img>` case is
  B6: `hover` has no `--timeout` and a zero default on v26.5.31, so it never auto-waits;
  an `<img>` is just the most common briefly-zero-size element. `dblclick` and `check`
  fail identically. "Not reproduced" invites a reopen the first time someone hovers an
  uncached image on a published build.
  → [`B30.md`](B30.md)

## C · Filed — all closed except #343 (table below is stale, kept for history)

**Re-checked 2026-08-07: every issue in this table was closed at that point.** The "State"
column below says OPEN throughout and is wrong for those rows. **#343, added 2026-08-10, is
genuinely open** — it is the one live filing. Verified states:

| Item | Issue | Actual state 2026-08-07 |
|---|---|---|
| CLI B3 · click/dialog deadlock | #151 | **closed/completed** |
| CLI B8, B10–B13, B16–B29, B33 | #195–#213 | **closed/completed** (sampled #195, #196, #213) |
| JS Bug 2 · `evaluate` nested `string[][]` | #124 | **closed/completed** — same PR #253 as #221 |
| Java B3 · `waitForFunction` double-wrap | #174 | **closed/completed** |
| Java B7 · `page.expose()` | #135 | **closed/duplicate** |
| **CLI B38 · BiDi error detail discarded** | **#343** | **open — filed 2026-08-10** |
| Java B10 · `setHeaders` deadlock | #128 | **closed/completed** |

§C1's four (#129, #130, #136, #137) are also all **closed/completed** now — the
"decide whether to request a reopen" question is moot unless a residual failure
survives the next publish.

Original table follows, unedited.

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

Kept so they are not re-raised. All cost real time before being ruled out.

- [x] **`vibium pipe --connect` fails against a live BiDi endpoint** — **already
  reported and already fixed upstream; do not file.** Raised during the
  vibium-efficiency CLI batching work and flagged there as "a real, specific,
  reproducible bug that deserves its own report." Both halves of that were wrong:
  - **Already filed twice, both closed/completed**: **#240** ("Remote connect mode
    broken: session.new rejected on endpoints that already have a session", closed
    2026-08-01 — **opened by the maintainer himself**) and **#158** (`pipe --connect`
    disconnects immediately after browser launch, closed 2026-08-04, fixed by
    `102a320`). It still reproduces locally only because nothing is published.
    **Re-confirmed 2026-08-09 to the hilt:** 20/20 runs on v26.5.31 against freshly-created
    live endpoints (10 chromedriver `webSocketUrl` sessions + 10 `vibium serve` instances,
    headless *and* headed with UA-asserted provenance), every one failing
    `session not created`; a raw BiDi probe on the same socket returns
    `session already exists`, which is the router's unconditional `session.new`. **Fixed on
    `main`** by #242 — a build of `59e4b4b` attaches and answers (`rc=0`, real context id).
    Verified by running the binary, not by reading the commit message.
  - **The original diagnosis was mis-targeted.** It was framed as "`--connect`
    won't attach to the daemon's existing session" — that is a *feature request*,
    not a defect. `--connect` is documented as "connect to a remote BiDi endpoint,"
    and negotiating a session there is correct behaviour.
  - **The real manifestation, which is what #240 describes**: `vibium pipe
    --connect ws://localhost:9515` against `vibium serve` — pipe's own help-text
    example, on serve's default port — fails with `BiDi error: session not
    created`, because serve auto-creates a session on connect and pipe sends
    `session.new` anyway. Confirmed 2026-08-07: a raw WebSocket to that endpoint
    receives live `browsingContext.contextCreated` events, and sending
    `session.new` by hand reproduces the identical error. The *mechanism* was
    right; the *target* was not.
  - Corrected in `vibium-efficiency/references/upstream-report-node-wrapper.md`,
    which had carried the "deserves its own report" claim into a document headed
    upstream.

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
  (`assert ... is not None`, the safe direction). **Java audited too** — one instance,
  `test("evaluate null", () -> assertEquals(null, page.evaluate("null")))`, fixed the same
  way. All three clients confirmed to swallow exceptions.

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
- **Search again immediately before filing, not just before writing.** Added
  2026-08-07 after four hardened drafts died in the ten days between hardening and
  filing. Searching once at write time is what let B35 be hardened against #119 and
  `pipe --connect` against #240 — both already open at the time. Re-run the search,
  and check `state_reason` (`completed` vs `not_planned`) rather than open/closed
  alone.
- **Scan commits with pagination.** A single `gh api .../commits` page caps at 100
  and will silently support a false "no fix exists." An exactly-100 result set is a
  truncation smell, not a finding.
- vibium is **WebDriver BiDi, not CDP**. Do not cite CDP field names in suggested fixes;
  an earlier draft of B34 got this wrong.
- Always state the platform and version scope. Everything here is macOS darwin 25.5.0 on
  v26.5.31 unless noted; Linux and Windows are untested.
- Include a recovery path or workaround when one exists — it sets severity honestly and
  is the difference between B24 (P3, `find` still works) and B16 (no recovery at all).

---

## Submission protocol

Drafts live here and in `lana-20/vibium-cli-test`. Publishing a draft to Lana's own repo
is not submission — it is where review happens.

**Step 0, added 2026-08-08 — run the source verifier.** Upstream ships daily, so
"hardened last week" is not evidence about this week. Download or pull a current
source tree and run:

```sh
python3 scripts/verify_upstream.py '<path-to-vibium-source>' --issues
```

It reports **STILL VALID / FIXED / CHANGED / UNKNOWN** per item by reading *source*,
never commit messages, and **aborts if the checkout is stale** (it asserts landmark
fixes with known landing dates first — verifying against an old tree reports fixed
bugs as still-valid, which is precisely how four hardened drafts died on 2026-08-07).
`UNKNOWN` means the anchor moved and nothing can be concluded — it is never rounded
up to "still valid". Claims live in `issues/UPSTREAM-CLAIMS.json`.

Before anything reaches `VibiumDev/vibium`:

1. **Lana reviews the write-up in full.** Every claim in these files is measured, but
   measured is not the same as ready to send.
2. **Confirm no duplicate.** `gh search issues --repo VibiumDev/vibium "<keywords>"`.
   B34 was fully written and hardened before #221 was found already open.
3. **Re-verify on the installed version.** Several of these were hardened over days; a
   published release may have moved. `vibium --version && npm view vibium version`.
4. **Lana gives an explicit instruction to submit**, per item. Approval of one write-up
   is not approval of the batch.
5. Update **Filed as:** in the write-up and tick the checkbox here.

Claude does not open issues, post comments, or file PRs upstream on its own initiative —
including when a draft looks finished and a maintainer thread seems to invite it.
