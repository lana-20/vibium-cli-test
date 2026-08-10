import asyncio, json, sys, websockets

PORT = int(sys.argv[1])
DETAIL = "invalid argument: capability 'foo' is not supported by this endpoint"

async def handler(ws):
    async for raw in ws:
        msg = json.loads(raw)
        mid, method = msg.get("id"), msg.get("method")
        if method == "session.status":
            await ws.send(json.dumps({"id": mid, "type": "success",
                                      "result": {"ready": True, "message": ""}}))
        elif method == "session.new":
            await ws.send(json.dumps({"id": mid, "type": "error",
                                      "error": "invalid argument", "message": DETAIL}))
        else:
            await ws.send(json.dumps({"id": mid, "type": "success", "result": {}}))

async def main():
    async with websockets.serve(handler, "127.0.0.1", PORT):
        print("listening", flush=True)
        await asyncio.Future()

asyncio.run(main())
