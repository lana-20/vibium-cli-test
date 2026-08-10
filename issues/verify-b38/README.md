# verify-b38

Repro assets for [B38](../B38.md) — BiDi error detail discarded, error code printed twice.

## fake_bidi.py — isolating repro, no browser

```sh
pip install websockets
python3 fake_bidi.py 9700 &
{ sleep 2; } | vibium pipe --connect ws://127.0.0.1:9700
# BiDi error: invalid argument - invalid argument
```

The endpoint sends `"message": "invalid argument: capability 'foo' is not supported by this
endpoint"`. It never appears in vibium's output, with or without `-v`.

Swap the `session.new` reply to the nested shape to see the detail appear — proof the parser
targets a shape WebDriver BiDi never sends:

```python
{"id": mid, "type": "error", "error": {"error": "invalid argument", "message": DETAIL}}
```

## protocol_error_test.go — regression test

Drop into `clicker/internal/bidi/` of a vibium source tree:

```sh
go test ./internal/bidi/ -run TestGetError -v
```

On `main` @ 59e4b4b, `TestGetErrorKeepsSiblingMessage` **FAILS**
(`detail = "invalid argument", want "Invalid URL: not-a-real-url"`) and
`TestGetErrorNestedObjectStillParses` passes. With the fix in B38 applied, both pass and the
package stays green.

## Fastest repro without any of this

```sh
vibium --headless go "not-a-real-url"
# Error: failed to navigate: BiDi error: invalid argument - invalid argument
# Chrome actually sent: Invalid URL: not-a-real-url
```
