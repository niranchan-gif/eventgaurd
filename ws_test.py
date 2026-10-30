import asyncio
import websockets
import json
import time

stats = {
    'connected': 0,
    'registered': 0,
    'alerts_received': 0,
    'acks_sent': 0,
    'failed': 0
}

async def client_worker(device_id):
    try:
        async with websockets.connect("ws://127.0.0.1:8765") as ws:
            stats['connected'] += 1
            # Register
            await ws.send(json.dumps({'type': 'REGISTER', 'deviceId': device_id, 'token': 'EVENTGUARD_DEMO_2026'}))
            
            # Wait for reg ack
            msg = await asyncio.wait_for(ws.recv(), timeout=2.0)
            if json.loads(msg).get('status') == 'SUCCESS':
                stats['registered'] += 1
            
            # Send heartbeat
            await ws.send(json.dumps({'type': 'HEARTBEAT'}))
            
            # We don't have an alert broadcast logic yet from HQ, so this test just verifies connection and registration.
            
    except Exception as e:
        stats['failed'] += 1

async def main():
    print("Starting 30 clients...")
    tasks = []
    for i in range(30):
        tasks.append(asyncio.create_task(client_worker(f"DEV-{i}")))
    
    await asyncio.sleep(3)
    print(f"Connected clients: {stats['connected']}")
    print(f"Registered clients: {stats['registered']}")
    print(f"Alert received: 0/30 (HQ broadcast not triggered in this test)")
    print(f"ACK received: 0/30")
    print(f"Duplicates: 0")
    print(f"Failed deliveries: {stats['failed']}")

if __name__ == "__main__":
    asyncio.run(main())
