"""
EventGuardAI - GRA (Grid-based Risk Analysis) Execution CLI
Connects camera/video stream -> YOLOv11/ByteTrack -> GRA Engine -> Real-time OpenCV HUD -> WebSocket Publisher.

Usage Examples:
    # 1. Live Webcam Feed
    python run_gra.py --source 0

    # 2. Prerecorded Video Feed
    python run_gra.py --source path/to/crowd_video.mp4

    # 3. Automated Simulation (No webcam / headless verification)
    python run_gra.py --source simulate --headless --max-frames 100

    # 4. Connect to HQ & Staff WebSocket Server
    python run_gra.py --source 0 --ws ws://127.0.0.1:8765/ai
"""

import sys
import os
site_packages = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'venv', 'Lib', 'site-packages')
if site_packages not in sys.path:
    sys.path.insert(0, site_packages)
import argparse
import asyncio
import json
import threading
import time
from typing import Optional

from gra.config import GRAConfig
from gra.cv_pipeline import GRAPipeline


class AsyncWebSocketAlertPublisher:
    """Publishes confirmed CROWD_RISK_ALERT messages to the EventGuard WebSocket server asynchronously."""

    def __init__(self, uri: str = "ws://127.0.0.1:8765/ai"):
        self.uri = uri
        self.loop: Optional[asyncio.AbstractEventLoop] = None
        self.queue: Optional[asyncio.Queue] = None
        self.thread: Optional[threading.Thread] = None
        self.is_running = False

    def start(self):
        self.is_running = True
        self.thread = threading.Thread(target=self._run_loop, daemon=True)
        self.thread.start()

    def _run_loop(self):
        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)
        self.queue = asyncio.Queue()
        self.loop.run_until_complete(self._worker())

    async def _worker(self):
        import websockets
        while self.is_running:
            try:
                print(f"[GRA WS PUBLISHER] Connecting to {self.uri} ...")
                async with websockets.connect(self.uri) as ws:
                    print(f"[GRA WS PUBLISHER] Connected to EventGuard WebSocket server at {self.uri}")
                    while self.is_running:
                        try:
                            # Wait for alert from synchronous pipeline
                            alert = await asyncio.wait_for(self.queue.get(), timeout=1.0)
                            payload = json.dumps(alert)
                            await ws.send(payload)
                            print(f"[GRA WS PUBLISHER] Sent alert for Zone {alert.get('zone')} (Risk: {alert.get('risk_score')})")
                            self.queue.task_done()
                        except asyncio.TimeoutError:
                            continue
            except Exception as e:
                if self.is_running:
                    print(f"[GRA WS PUBLISHER WARN] Connection error: {e}. Retrying in 2.0s...")
                    await asyncio.sleep(2.0)

    def publish_alert(self, alert_data: dict):
        """Thread-safe dispatch from CV pipeline."""
        if self.loop and self.queue:
            self.loop.call_soon_threadsafe(self.queue.put_nowait, alert_data)

    def stop(self):
        self.is_running = False


def main():
    parser = argparse.ArgumentParser(description="EventGuardAI - GRA Crowd Risk Assessment Engine")
    parser.add_argument("--source", default="0", help="Camera index (e.g. 0), video file path, or 'simulate'")
    parser.add_argument("--model", default="yolo11n.pt", help="Path to YOLO weights")
    parser.add_argument("--conf", type=float, default=0.35, help="Detection confidence threshold")
    parser.add_argument("--imgsz", type=int, default=640, help="Inference image resolution")
    parser.add_argument("--capacity", type=float, default=12.0, help="Grid capacity parameter K")
    parser.add_argument("--cooldown", type=float, default=15.0, help="Alert cooldown in seconds per grid")
    parser.add_argument("--ws", default="ws://127.0.0.1:8765/ai", help="WebSocket server URL or 'none' to disable")
    parser.add_argument("--headless", action="store_true", help="Run in headless mode without cv2 display window")
    parser.add_argument("--max-frames", type=int, default=None, help="Stop after processing N frames")

    args = parser.parse_args()

    # Configure GRA settings
    config = GRAConfig(
        yolo_model_path=args.model,
        confidence_threshold=args.conf,
        input_image_size=args.imgsz,
        capacity_k=args.capacity,
        alert_cooldown_seconds=args.cooldown,
    )

    # Initialize WebSocket publisher if enabled
    publisher = None
    alert_callback = None
    if args.ws.lower() != "none":
        publisher = AsyncWebSocketAlertPublisher(uri=args.ws)
        publisher.start()
        alert_callback = publisher.publish_alert

    # Initialize CV Pipeline
    pipeline = GRAPipeline(
        source=args.source,
        config=config,
        on_alert_callback=alert_callback,
        headless=args.headless,
    )

    print("=" * 70)
    print("EVENTGUARD-AI : GRID-BASED RISK ANALYSIS (GRA) PROTOTYPE")
    print(f"Video Source      : {args.source}")
    print(f"YOLO Model        : {args.model} (CPU Inference)")
    print(f"Grid Partitioning : 3x3 (A1..A3, B1..B3, C1..C3)")
    print(f"Grid Capacity (K) : {args.capacity}")
    print(f"Alert Cooldown    : {args.cooldown}s")
    print(f"WebSocket Target  : {args.ws}")
    print(f"Headless Mode     : {args.headless}")
    print("=" * 70)

    try:
        pipeline.run(max_frames=args.max_frames)
    finally:
        if publisher:
            publisher.stop()
        print("[GRA] Shutdown complete.")


if __name__ == "__main__":
    main()
