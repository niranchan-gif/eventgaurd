import asyncio
import websockets
import json
import os

TOKEN = os.environ.get("EVENTGUARD_DEMO_TOKEN", "EVENTGUARD_DEMO_2026")
URI = "ws://127.0.0.1:8765/field"
CLIENT_COUNT = 30

async def simulate_client(client_id):
    device_id = f"EG-STAFF-{client_id:03d}"
    staff_id = f"STAFF-{client_id:03d}"
    team_id = f"SECURITY-{(client_id % 5) + 1}"
    
    try:
        async with websockets.connect(URI) as ws:
            # 1. Register
            register_msg = {
                "type": "REGISTER",
                "deviceId": device_id,
                "unitId": team_id,
                "staffId": staff_id,
                "teamId": team_id,
                "token": TOKEN,
                "appVersion": "1.0.0",
                "battery": 100
            }
            await ws.send(json.dumps(register_msg))
            
            # Wait for REGISTER_ACK
            response = await ws.recv()
            data = json.loads(response)
            if data.get("type") != "REGISTER_ACK":
                return {"client_id": client_id, "success": False, "error": "No REGISTER_ACK"}

            # 2. Heartbeat
            heartbeat_msg = {
                "type": "HEARTBEAT",
                "deviceId": device_id,
                "staffId": staff_id
            }
            await ws.send(json.dumps(heartbeat_msg))
            
            # Keep listening for a bit to catch alerts/tasks
            # In a real test we might trigger an alert from another connection
            # Here we just hold connection open briefly
            try:
                msg = await asyncio.wait_for(ws.recv(), timeout=2.0)
                data = json.loads(msg)
                if data.get("type") == "ALERT":
                    # Send ACK
                    ack_msg = {
                        "type": "ACK",
                        "eventId": data.get("eventId"),
                        "deviceId": device_id,
                        "staffId": staff_id
                    }
                    await ws.send(json.dumps(ack_msg))
            except asyncio.TimeoutError:
                pass
            
            return {"client_id": client_id, "success": True, "error": None}
    except Exception as e:
        return {"client_id": client_id, "success": False, "error": str(e)}

async def run_load_test():
    print(f"Starting load test with {CLIENT_COUNT} clients...")
    tasks = [simulate_client(i) for i in range(1, CLIENT_COUNT + 1)]
    results = await asyncio.gather(*tasks)
    
    success_count = sum(1 for r in results if r["success"])
    fail_count = CLIENT_COUNT - success_count
    
    print("========================================")
    print("EventGuard WebSocket Load Test")
    print("========================================")
    print(f"Clients attempted: {CLIENT_COUNT}")
    print(f"Connected: {success_count}")
    print(f"Registered: {success_count}")
    print(f"Heartbeat success: {success_count}")
    print(f"Failures: {fail_count}")
    print("========================================")
    
    if fail_count > 0:
        for r in results:
            if not r["success"]:
                print(f"Client {r['client_id']} failed: {r['error']}")
                
if __name__ == "__main__":
    asyncio.run(run_load_test())
