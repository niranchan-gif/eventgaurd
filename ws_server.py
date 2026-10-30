import asyncio
import json
import websockets
import time

connected_clients = {}

async def handler(websocket):
    client_id = id(websocket)
    connected_clients[client_id] = {'socket': websocket, 'status': 'ONLINE'}
    try:
        async for message in websocket:
            data = json.loads(message)
            msg_type = data.get('type')
            if msg_type == 'REGISTER':
                connected_clients[client_id]['device'] = data.get('deviceId')
            elif msg_type == 'HEARTBEAT':
                connected_clients[client_id]['last_heartbeat'] = time.time()
            elif msg_type == 'ACK':
                # handle ack
                pass
            
            # echo back for demo
            await websocket.send(json.dumps({'status': 'RECEIVED'}))
    except Exception:
        pass
    finally:
        del connected_clients[client_id]

async def broadcast_alert():
    while True:
        await asyncio.sleep(10)
        if connected_clients:
            msg = json.dumps({'type': 'ALERT', 'eventId': 'EVT-001', 'message': 'Test Alert'})
            for client in list(connected_clients.values()):
                try:
                    await client['socket'].send(msg)
                except: pass

async def main():
    server = await websockets.serve(handler, "127.0.0.1", 8765)
    print("WebSocket Server Started on 8765")
    asyncio.create_task(broadcast_alert())
    await server.wait_closed()

if __name__ == "__main__":
    asyncio.run(main())
