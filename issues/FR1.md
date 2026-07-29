# Feature request — expose `BrowserContext.addInitScript` on the CLI and MCP surfaces

**vibium v26.5.31 · macOS darwin 25.5.0**
**Filed as:** _not yet filed_
**Type:** surface parity gap — the capability already exists, it is just not reachable
from the CLI or MCP

## Request

`BrowserContext.addInitScript` is implemented and working in the client libraries. It
has no equivalent on the CLI or MCP surfaces. This asks for it to be exposed there, not
for it to be built.

Existing, tested, passing on v26.5.31:

| Client | Method |
|---|---|
| Python | `context.add_init_script(script)` |
| Java | `context.addInitScript(script)` |

Verified behaviour — the script runs in a document created *after* registration and
survives navigation:

```python
ctx = bro.new_context()
ctx.add_init_script("window.__vibium_init__ = true;")
p = ctx.new_page()
p.go("https://example.com")
assert p.evaluate("window.__vibium_init__") is True     # passes on v26.5.31
```

Proposed surface, following the existing `--stdin` convention:

```sh
vibium init-script --stdin < seed.js     # register for subsequent documents
vibium init-script --clear
vibium init-script --list
```

MCP: `browser_add_init_script { script }`.

## Why the CLI cannot reach it today

The CLI has no command that executes before page scripts. `eval` runs against a document
that has already loaded and run its own code; `content` replaces HTML later still.
Nothing in the current command set reaches the page earlier:

```
a11y-tree add-skill attr back bidi-test check click completion content cookies count
daemon dblclick dialog diff download drag eval fill find focus forward frame frames
geolocation go help highlight hover html install is is-installed keys launch-test map
mcp media mouse page pages paths pdf pipe press record reload screenshot scroll select
serve sleep start stop storage text title type uncheck upload url value version
viewport wait window ws-test
```

So a capability that Python and Java users have is unavailable to CLI and MCP users,
including agent-driven workflows, which is where scripted determinism matters most.

## What it unblocks — measured

Canvas applications are frequently non-deterministic by construction, which makes
snapshot and pixel comparison impossible unless the randomness can be stubbed before it
runs.

Measured on `testtrack.org/canvas-demo`, whose `Deploy Vehicle Fleet` places fifty units
at `Math.random()` positions with random radii. Five identical runs, all ten pairs
diffed, under vibium, Playwright and Selenium:

| Configuration | Run-to-run noise | One-marker defect | Verdict |
|---|---|---|---|
| unseeded | 1.64% of canvas | 0.0088% | noise is **190×** the signal — no threshold works |
| `Math.random` stubbed pre-load | **0.00%** | 0.0088% | byte-identical; snapshot comparison viable |

The stub is four lines:

```js
let s = 42;
Math.random = () => { s = (s * 1664525 + 1013904223) % 4294967296; return s / 4294967296; };
```

Playwright delivers it with `context.addInitScript()`. **Selenium does not even need a
first-class API** — raw CDP works and reaches the same 0.00%:

```python
drv.execute_cdp_cmd("Page.addScriptToEvaluateOnNewDocument", {"source": SEED})
```

Measured on this AUT, 2026-07-28:

| Tool | Mechanism | Determinism reached |
|---|---|---|
| Playwright 1.62 | `context.addInitScript()` | 0.00% |
| Selenium 4.44 | CDP `Page.addScriptToEvaluateOnNewDocument` | 0.00% |
| vibium 26.5.31 CLI/MCP | **no mechanism** | 0.00% only by accident (see below) |

A Python or Java vibium user can already do the equivalent through
`context.add_init_script`. A CLI or MCP user cannot — making vibium's agent-facing
surfaces the only ones in this comparison without a pre-load hook.

## Why the post-load workaround is not a substitute

Seeding via `eval` after load did reach 0.00% on this target — but only by coincidence.
`Deploy Vehicle Fleet` replaces the unit array outright, discarding the mount-time
randomisation, so everything captured was generated after the seed. That is a property
of this application, not a technique.

It fails whenever:

- the canvas randomises once at mount and is never regenerated,
- content accumulates rather than being replaced,
- the value is read during module evaluation and cached,
- the target is `Date.now()`, `crypto.getRandomValues()`, `performance.now()` or
  `requestAnimationFrame` timing rather than `Math.random()`,
- auth or feature flags must be stubbed before the app boots.

## Other uses

A pre-load hook is also the standard place to stub `navigator.geolocation`,
`Notification` or `matchMedia` before feature detection runs; install a console or
network spy that catches startup activity; seed `localStorage` before boot; freeze
`Date`; or inject test hooks exposing internal state — the technique the ASE 2022
canvas-testing literature is built on ([arXiv:2208.02335](https://arxiv.org/abs/2208.02335)).

## Related

- [#130](https://github.com/VibiumDev/vibium/issues/130) — `page.addScript()` in the Java
  client, partially fixed by [#167](https://github.com/VibiumDev/vibium/pull/167).
  Different mechanism: it injects into the current page and still does not persist across
  `go()`. `context.addInitScript()` is the documented workaround for that gap, which is
  further reason to expose it more widely.
- [#135](https://github.com/VibiumDev/vibium/issues/135) — `page.expose()` in the Java client.

## Acceptance criteria

1. A script registered before `vibium go` runs in the new document ahead of application code.
2. It re-applies on `reload`, `back`, `forward` and subsequent `go`.
3. Multiple registrations run in order.
4. `--clear` removes them; nothing leaks between daemon sessions.
5. Behaviour matches `context.add_init_script` in the Python client.
6. Available on both CLI and MCP.

## Verification

```sh
~/.claude/skills/canvas-demo/scripts/determinism.sh 5                 # vibium, post-load seed
node ~/.claude/skills/canvas-demo/scripts/compare-playwright.js       # Playwright, addInitScript
python3 ~/.claude/skills/canvas-demo/scripts/compare-selenium.py      # Selenium, raw CDP
```

Once implemented, `determinism.sh` should reach 0.00% using a registered init script
rather than the post-load `eval`, and stay at 0.00% on a target that randomises only at
mount.
