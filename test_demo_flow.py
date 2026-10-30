import asyncio
import websockets
import json

async def simulate_staff():
    try:
        async with websockets.connect("ws://127.0.0.1:8765/field") as ws:
            # register
            await ws.send(json.dumps({"type": "REGISTER", "staffId": "STAFF-001", "teamId": "SECURITY-A"}))
            res = await ws.recv()
            print("STAFF RECV:", res)
            
            # wait for task
            task = await ws.recv()
            print("STAFF RECV:", task)
            
            # send accept
            await ws.send(json.dumps({"type": "TASK_STATUS", "taskId": "TASK-DEMO-001", "staffId": "STAFF-001", "status": "ACCEPTED"}))
            print("STAFF SENT ACCEPTED")
            
            await asyncio.sleep(1)
            # send en route
            await ws.send(json.dumps({"type": "TASK_STATUS", "taskId": "TASK-DEMO-001", "staffId": "STAFF-001", "status": "EN_ROUTE"}))
            print("STAFF SENT EN_ROUTE")
    except Exception as e:
        print("STAFF ERR:", e)

async def simulate_hq():
    try:
        await asyncio.sleep(1) # wait for staff to connect
        async with websockets.connect("ws://127.0.0.1:8765/hq") as ws:
            # deploy troop
            await ws.send(json.dumps({
                "type": "DEPLOY_TROOP",
                "teamId": "SECURITY-A",
                "title": "North Entrance",
                "description": "Go there"
            }))
            res = await ws.recv()
            print("HQ RECV:", res)
    except Exception as e:
        print("HQ ERR:", e)

async def main():
    await asyncio.gather(simulate_staff(), simulate_hq())

asyncio.run(main())
