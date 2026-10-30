import asyncio
import websockets
import json
import time

connected_field_devices = {}

async def field_ws_handler(websocket):
    client_id = id(websocket)
    connected_field_devices[client_id] = {'socket': websocket, 'status': 'ONLINE', 'device_id': 'UNKNOWN'}
    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                msg_type = data.get('type')
                if msg_type == 'REGISTER':
                    token = data.get('token', '')
                    if token != 'EVENTGUARD_DEMO_2026':
                        await websocket.send(json.dumps({'type': 'ERROR', 'message': 'Invalid token'}))
                        continue
                    dev_id = data.get('deviceId', 'UNKNOWN')
                    connected_field_devices[client_id]['device_id'] = dev_id
                    await websocket.send(json.dumps({'type': 'REGISTER_ACK', 'status': 'SUCCESS'}))
                elif msg_type == 'HEARTBEAT':
                    connected_field_devices[client_id]['last_heartbeat'] = time.time()
                elif msg_type == 'ACK':
                    pass
            except Exception:
                pass
    except Exception:
        pass
    finally:
        del connected_field_devices[client_id]

async def main():
    server = await websockets.serve(field_ws_handler, "127.0.0.1", 8765)
    await asyncio.sleep(5) # run for 5 seconds for test
    server.close()

if __name__ == "__main__":
    asyncio.run(main())
