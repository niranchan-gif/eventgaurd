import os
import re

backend_path = r'd:\vscode\enventguardai\backend_server.py'
with open(backend_path, 'r', encoding='utf-8') as f:
    content = f.read()

ws_code = """
import asyncio
import websockets

connected_field_devices = {}

async def field_ws_handler(websocket):
    client_id = id(websocket)
    connected_field_devices[client_id] = {'socket': websocket, 'status': 'ONLINE', 'device_id': 'UNKNOWN'}
    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                msg_type = data.get('type')
                
                # Basic Token Auth
                if msg_type == 'REGISTER':
                    token = data.get('token', '')
                    if token != 'EVENTGUARD_DEMO_2026':
                        await websocket.send(json.dumps({'type': 'ERROR', 'message': 'Invalid token'}))
                        continue
                    dev_id = data.get('deviceId', 'UNKNOWN')
                    connected_field_devices[client_id]['device_id'] = dev_id
                    connected_field_devices[client_id]['unit_id'] = data.get('unitId', '')
                    connected_field_devices[client_id]['last_heartbeat'] = time.time()
                    await websocket.send(json.dumps({'type': 'REGISTER_ACK', 'status': 'SUCCESS'}))
                    print(f"[WS] Device Registered: {dev_id}")
                
                elif msg_type == 'HEARTBEAT':
                    connected_field_devices[client_id]['last_heartbeat'] = time.time()
                
                elif msg_type == 'ACK':
                    print(f"[WS] ACK received from {connected_field_devices[client_id]['device_id']} for {data.get('eventId')}")
            except Exception as e:
                print(f"[WS ERR] {e}")
    except Exception:
        pass
    finally:
        del connected_field_devices[client_id]

def run_ws_server():
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    start_server = websockets.serve(field_ws_handler, "0.0.0.0", 8765)
    print("[INIT] Field WebSocket Server started on 0.0.0.0:8765")
    loop.run_until_complete(start_server)
    loop.run_forever()

ws_thread = threading.Thread(target=run_ws_server, daemon=True)
ws_thread.start()
"""

# Insert WS code before the REST API Endpoints
if "import websockets" not in content:
    content = content.replace("# ==============================================================================\n# REST API Endpoints", ws_code + "\n# ==============================================================================\n# REST API Endpoints")

with open(backend_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Injected WebSocket server into backend_server.py")
