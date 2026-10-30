import sys
import os
site_packages = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'venv', 'Lib', 'site-packages')
if site_packages not in sys.path:
    sys.path.insert(0, site_packages)
import asyncio
import json
import uuid
import time
from datetime import datetime, timezone
import websockets

connected_staff = {}
connected_hq = set()
connected_ai = set()

# Deduplication cache for alerts: alert_id -> timestamp
recent_alerts = {}


async def broadcast_to_hq(message_data: dict):
    """Broadcasts a JSON message to all connected HQ consoles."""
    if not connected_hq:
        return
    payload = json.dumps(message_data)
    to_remove = set()
    for ws in list(connected_hq):
        try:
            await ws.send(payload)
        except Exception:
            to_remove.add(ws)
    for ws in to_remove:
        connected_hq.discard(ws)


async def handle_crowd_risk_alert(alert_data: dict, source_ws=None):
    """
    Handles a CROWD_RISK_ALERT:
    1. Validates and deduplicates.
    2. Forwards to all connected HQ consoles.
    3. If CRITICAL, synthesizes an emergency task and alert for connected field staff.
    """
    alert_id = alert_data.get("alert_id", f"GRA-{uuid.uuid4().hex[:8].upper()}")
    now = time.time()

    # Deduplicate recent alerts (within 3 seconds)
    if alert_id in recent_alerts and (now - recent_alerts[alert_id]) < 3.0:
        return
    recent_alerts[alert_id] = now

    severity = alert_data.get("severity", "HIGH_WARNING").upper()
    zone = alert_data.get("zone", "UNKNOWN")
    risk_score = alert_data.get("risk_score", 0.0)
    metrics = alert_data.get("metrics", {})
    msg_text = alert_data.get("message", f"{severity} crowd risk in grid {zone}")

    print(f"\n[GRA ALERT RECEIVED]\nZone: {zone}\nSeverity: {severity}\nRisk: {risk_score}\nMessage: {msg_text}")

    # Forward CROWD_RISK_ALERT to HQ consoles
    await broadcast_to_hq(alert_data)

    # If critical risk condition, create an emergency field task & alert for staff
    if severity == "CRITICAL":
        task_id = f"TASK-GRA-{uuid.uuid4().hex[:6].upper()}"
        task_msg = {
            "type": "TASK_ASSIGNED",
            "taskId": task_id,
            "title": f"CRITICAL CROWD RISK - Grid {zone}",
            "description": f"Urgent: Crowd surge detected in {zone}. Density: {metrics.get('density', 100)}%, Congestion: {metrics.get('congestion', 0)}%. Deploy immediately.",
            "priority": "CRITICAL",
            "locationName": f"Sector Grid {zone}",
            "severity": "CRITICAL",
            "grid": zone,
            "metrics": metrics,
            "assignedTeamId": "SECURITY-A"
        }

        staff_alert = {
            "type": "ALERT",
            "eventId": alert_id,
            "severity": "CRITICAL",
            "grid": zone,
            "message": f"CRITICAL: Crowd hazard in Grid {zone}! Immediate crowd dispersal requested.",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "metrics": metrics
        }

        # Send to connected staff
        sent_task = False
        for ws, info in list(connected_staff.items()):
            try:
                # Send emergency task
                await ws.send(json.dumps(task_msg))
                # Also send emergency alert banner
                await ws.send(json.dumps(staff_alert))
                print(f"CRITICAL TASK DISPATCHED -> Staff: {info.get('staffId')}, Team: {info.get('teamId')}")
                sent_task = True
            except Exception as e:
                print(f"Error sending to staff: {e}")

        if not sent_task:
            print("[INFO] No active field staff online to receive automated task.")

    # Acknowledge back to AI publisher if requested
    if source_ws:
        try:
            await source_ws.send(json.dumps({
                "type": "ALERT_ACK",
                "alert_id": alert_id,
                "status": "FORWARDED",
                "hq_clients": len(connected_hq),
                "staff_clients": len(connected_staff)
            }))
        except Exception:
            pass


async def handler(websocket):
    # Depending on websockets version, path might be in websocket.path or websocket.request.path
    path = getattr(websocket, 'path', getattr(getattr(websocket, 'request', None), 'path', '/'))
    
    if path == "/hq":
        connected_hq.add(websocket)
        print(f"[HQ CONNECTED] Active HQ consoles: {len(connected_hq)}")
        try:
            async for message in websocket:
                try:
                    data = json.loads(message)
                    msg_type = data.get("type")

                    if msg_type in ("DEPLOY_TROOP", "DEPLOY_STAFF", "DEPLOY_STEWARD", "DEPLOY_TASK", "DEPLOY", "DISPATCH_EMERGENCY"):
                        team = data.get("teamId", "")
                        target_staff = data.get("staffId", "")
                        task_id = data.get("taskId") or f"TASK-{uuid.uuid4().hex[:6].upper()}"
                        print(f"[HQ] Deploying emergency task {task_id} to Team: '{team}', Staff: '{target_staff}'...")
                        
                        task_msg = {
                            "type": "TASK_ASSIGNED",
                            "taskId": task_id,
                            "title": data.get("title", "Critical Crowd Safety Deployment"),
                            "description": data.get("description", "Deploy immediately to assigned sector to manage crowd flow and ensure attendee safety."),
                            "priority": data.get("priority", "CRITICAL"),
                            "locationName": data.get("locationName", "Main Concourse"),
                            "severity": data.get("severity", "CRITICAL"),
                            "assignedTeamId": team,
                            "assignedStaffId": target_staff,
                            "timestamp": datetime.now(timezone.utc).isoformat(),
                            "alarm": True,
                            "vibrate": True
                        }
                        
                        sent_count = 0
                        for ws, info in list(connected_staff.items()):
                            # Match if team matches, or staffId matches, or team is ALL/empty (broadcast)
                            matches_team = (team == "ALL" or not team or info.get("teamId") == team)
                            matches_staff = (not target_staff or info.get("staffId") == target_staff)
                            
                            if matches_team and matches_staff:
                                try:
                                    await ws.send(json.dumps(task_msg))
                                    print(f"EMERGENCY DISPATCH SENT -> Staff: {info.get('staffId')}, Team: {info.get('teamId')}")
                                    sent_count += 1
                                except Exception as e:
                                    print(f"Dispatch send error: {e}")
                        
                        if sent_count == 0:
                            print("[WARN] No active field staff matched dispatch criteria.")
                        
                        await websocket.send(json.dumps({
                            "type": "DEPLOY_ACK",
                            "taskId": task_id,
                            "sentCount": sent_count,
                            "status": "sent" if sent_count > 0 else "offline"
                        }))

                    elif msg_type == "GET_STAFF_ROSTER":
                        roster = []
                        for ws, info in list(connected_staff.items()):
                            roster.append({
                                "staffId": info.get("staffId", "STAFF-001"),
                                "teamId": info.get("teamId", "SECURITY-A"),
                                "zone": info.get("zone", "Zone A"),
                                "status": "ONLINE",
                                "lastHeartbeat": info.get("last_heartbeat", time.time())
                            })
                        await websocket.send(json.dumps({
                            "type": "STAFF_ROSTER",
                            "roster": roster,
                            "staff": roster,
                            "count": len(roster)
                        }))

                    elif msg_type == "CROWD_RISK_ALERT":
                        await handle_crowd_risk_alert(data, websocket)

                except Exception as e:
                    print("HQ Error:", e)
        finally:
            connected_hq.discard(websocket)
            print(f"[HQ DISCONNECTED] Remaining HQ consoles: {len(connected_hq)}")

    elif path == "/ai":
        connected_ai.add(websocket)
        print(f"[AI AGENT CONNECTED] Active AI publishers: {len(connected_ai)}")
        try:
            async for message in websocket:
                try:
                    data = json.loads(message)
                    if data.get("type") == "CROWD_RISK_ALERT":
                        await handle_crowd_risk_alert(data, websocket)
                    elif data.get("type") == "PING":
                        await websocket.send(json.dumps({"type": "PONG", "timestamp": time.time()}))
                except Exception as e:
                    print(f"AI Publisher Error: {e}")
        finally:
            connected_ai.discard(websocket)
            print(f"[AI AGENT DISCONNECTED] Active AI publishers: {len(connected_ai)}")

    elif path == "/field" or path == "/":
        staff_info = {}
        try:
            async for message in websocket:
                data = json.loads(message)
                msg_type = data.get("type")
                
                if msg_type in ("REGISTER", "FIELD_REGISTER"):
                    staff_id = data.get("staffId") or data.get("stewardId") or "STAFF-001"
                    team_id = data.get("teamId", "SECURITY-A")
                    name = data.get("name", staff_id)
                    zone = data.get("zone", "Zone A")
                    staff_info = {"staffId": staff_id, "teamId": team_id, "name": name, "zone": zone, "socket": websocket, "last_heartbeat": time.time()}
                    connected_staff[websocket] = staff_info
                    print(f"STAFF CONNECTED:\n{staff_id} ({name})\nTEAM: {team_id} | ZONE: {zone}")
                    await websocket.send(json.dumps({"type": "REGISTER_ACK", "status": "CONNECTED", "staffId": staff_id}))
                    # Notify HQ about newly registered staff
                    await broadcast_to_hq({
                        "type": "STAFF_ONLINE",
                        "staffId": staff_id,
                        "teamId": team_id,
                        "name": name,
                        "zone": zone
                    })
                
                elif msg_type == "HEARTBEAT":
                    pass
                    
                elif msg_type == "TASK_STATUS":
                    print(f"TASK {data.get('status')}\n{data.get('staffId')}\n{data.get('taskId')}")
                    # Forward task status to connected HQ consoles
                    await broadcast_to_hq(data)
                    
                elif msg_type == "ACK":
                    print(f"ALERT ACKNOWLEDGED\n{data.get('staffId')}\n{data.get('eventId')}")
                    # Forward acknowledgement to connected HQ consoles
                    await broadcast_to_hq(data)

                elif msg_type == "CROWD_RISK_ALERT":
                    # In case AI agent connected via /field
                    await handle_crowd_risk_alert(data, websocket)
                    
        finally:
            if websocket in connected_staff:
                del connected_staff[websocket]
                print(f"STAFF DISCONNECTED: {staff_info.get('staffId', 'Unknown')}")
                await broadcast_to_hq({
                    "type": "STAFF_OFFLINE",
                    "staffId": staff_info.get("staffId", "Unknown"),
                    "teamId": staff_info.get("teamId", "Unknown")
                })


async def main():
    print("Starting EventGuard Enhanced Demo WebSocket Server on 0.0.0.0:8765")
    print("HQ should connect to /hq")
    print("Staff should connect to /field")
    print("AI GRA Engine can connect to /ai")
    async with websockets.serve(handler, "0.0.0.0", 8765):
        await asyncio.Future()


if __name__ == "__main__":
    asyncio.run(main())
