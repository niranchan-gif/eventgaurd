"""
EventGuardAI - GRA Computer Vision & ByteTrack Pipeline
Handles video ingestion (webcam, prerecorded video, simulated generator),
YOLO person detection, ByteTrack tracking, CPU optimization, and feeds into GRAEngine.
"""

import os
import sys
import time
from typing import Callable, Dict, List, Optional, Tuple, Any
import cv2
import numpy as np

from .config import GRAConfig, DEFAULT_GRA_CONFIG
from .engine import GRAEngine, GRAResult
from .visualizer import GRAVisualizer


class GRAPipeline:
    """
    Complete Computer Vision Pipeline connecting YOLOv11/v8 + ByteTrack + GRAEngine + Visualizer.
    """

    def __init__(
        self,
        source: Any = 0,
        config: Optional[GRAConfig] = None,
        on_alert_callback: Optional[Callable[[Dict[str, Any]], None]] = None,
        headless: bool = False
    ):
        self.config = config or DEFAULT_GRA_CONFIG
        self.source = source
        self.on_alert_callback = on_alert_callback
        self.headless = headless

        self.engine = GRAEngine(self.config)
        self.visualizer = GRAVisualizer(self.config)

        self.model = None
        self.cap = None
        self.is_running = False
        self.fps = 0.0
        self.frame_count = 0
        self.last_result: Optional[GRAResult] = None

        self._init_model()

    def _init_model(self):
        """Initializes Ultralytics YOLO model on CPU with fallback error handling."""
        model_path = self.config.yolo_model_path

        # If yolo11n.pt isn't found at relative path, try repo root
        if not os.path.exists(model_path):
            repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            alt_path = os.path.join(repo_root, model_path)
            if os.path.exists(alt_path):
                model_path = alt_path

        print(f"[GRA PIPELINE] Loading YOLO model from {model_path} for CPU inference...")
        try:
            from ultralytics import YOLO
            self.model = YOLO(model_path)
            print("[GRA PIPELINE] YOLO model loaded successfully.")
        except Exception as e:
            print(f"[GRA PIPELINE WARN] Could not load YOLO model: {e}")
            self.model = None

    def start_capture(self) -> bool:
        """Opens video capture device or file."""
        if str(self.source).lower() == "simulate":
            print("[GRA PIPELINE] Initialized synthetic video simulator.")
            return True

        # Check if source is integer camera index or string path
        src = int(self.source) if str(self.source).isdigit() else self.source
        print(f"[GRA PIPELINE] Opening video source: {src}...")

        if os.name == 'nt' and isinstance(src, int):
            self.cap = cv2.VideoCapture(src, cv2.CAP_DSHOW)
            if not self.cap.isOpened():
                self.cap = cv2.VideoCapture(src)
        else:
            self.cap = cv2.VideoCapture(src)

        if not self.cap.isOpened():
            print(f"[GRA PIPELINE ERROR] Failed to open video source: {self.source}")
            return False

        # Set lower buffer size to minimize latency
        self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        return True

    def stop(self):
        """Releases video capture and closes windows."""
        self.is_running = False
        if self.cap is not None:
            self.cap.release()
            self.cap = None
        if not self.headless:
            try:
                cv2.destroyAllWindows()
            except Exception:
                pass

    def _read_frame(self) -> Tuple[bool, Optional[np.ndarray]]:
        """Reads frame from camera/video or generates a simulated frame."""
        if str(self.source).lower() == "simulate":
            # Generate synthetic 640x480 test frame
            sim_frame = np.full((480, 640, 3), 35, dtype=np.uint8)
            cv2.putText(sim_frame, "SIMULATED FEED", (20, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (120, 120, 120), 2)
            return True, sim_frame

        if self.cap is None or not self.cap.isOpened():
            return False, None

        ret, frame = self.cap.read()
        if not ret and not isinstance(self.source, int):
            # Loop video file if prerecorded
            self.cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
            ret, frame = self.cap.read()

        return ret, frame

    def process_frame(self, frame: np.ndarray, timestamp: Optional[float] = None) -> Tuple[np.ndarray, GRAResult]:
        """
        Runs YOLO + ByteTrack detection, feeds to GRAEngine, generates overlay.
        """
        h, w = frame.shape[:2]
        raw_detections: List[Dict[str, Any]] = []

        if self.model is not None:
            try:
                # Track persons: classes=[0] (Person class in COCO)
                # persist=True maintains ByteTrack IDs across consecutive frames
                results = self.model.track(
                    source=frame,
                    persist=True,
                    classes=[0],
                    conf=self.config.confidence_threshold,
                    imgsz=self.config.input_image_size,
                    tracker=self.config.bytetrack_config,
                    verbose=False,
                    device="cpu"
                )

                if results and len(results) > 0:
                    boxes = results[0].boxes
                    if boxes is not None and boxes.id is not None:
                        coords = boxes.xyxy.cpu().numpy()
                        track_ids = boxes.id.int().cpu().numpy()
                        confs = boxes.conf.cpu().numpy()

                        for i in range(len(coords)):
                            raw_detections.append({
                                "track_id": int(track_ids[i]),
                                "bbox": coords[i].tolist(),
                                "confidence": float(confs[i]),
                            })
                    elif boxes is not None:
                        # Detections without track ID yet (fallback assign frame-relative ID)
                        coords = boxes.xyxy.cpu().numpy()
                        confs = boxes.conf.cpu().numpy()
                        for i in range(len(coords)):
                            raw_detections.append({
                                "track_id": 9000 + i,
                                "bbox": coords[i].tolist(),
                                "confidence": float(confs[i]),
                            })
            except Exception as e:
                # Graceful handling of tracking failures
                pass

        # Calculate GRA metrics
        result = self.engine.process_detections(
            raw_detections=raw_detections,
            frame_width=w,
            frame_height=h,
            timestamp=timestamp
        )
        self.last_result = result

        # Dispatch newly confirmed alerts via callback
        if self.on_alert_callback and result.active_alerts:
            for alert in result.active_alerts:
                try:
                    self.on_alert_callback(alert)
                except Exception as cb_err:
                    print(f"[GRA PIPELINE ALERT CB ERROR] {cb_err}")

        # Render OpenCV Dashboard Overlay
        annotated_frame = self.visualizer.draw(frame, result, fps=self.fps)
        return annotated_frame, result

    def run(self, max_frames: Optional[int] = None):
        """
        Main execution loop.
        """
        if not self.start_capture():
            return

        self.is_running = True
        window_name = "EventGuardAI - GRA Crowd Risk Assessment"
        if not self.headless:
            cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
            cv2.resizeWindow(window_name, 960, 540)

        prev_time = time.time()
        fps_smoothing = 0.9

        try:
            while self.is_running:
                loop_start = time.time()
                ret, frame = self._read_frame()
                if not ret or frame is None:
                    print("[GRA PIPELINE] Stream ended or frame unavailable.")
                    break

                self.frame_count += 1

                # Process detection & GRA analysis
                annotated_frame, result = self.process_frame(frame, timestamp=loop_start)

                # Compute instantaneous FPS
                elapsed = time.time() - loop_start
                instant_fps = 1.0 / max(1e-4, elapsed)
                self.fps = (fps_smoothing * self.fps) + ((1.0 - fps_smoothing) * instant_fps) if self.fps > 0 else instant_fps

                if not self.headless:
                    cv2.imshow(window_name, annotated_frame)
                    key = cv2.waitKey(1) & 0xFF
                    if key in (27, ord('q'), ord('Q')):
                        print("[GRA PIPELINE] User exit requested.")
                        break

                if max_frames and self.frame_count >= max_frames:
                    break

        except KeyboardInterrupt:
            print("[GRA PIPELINE] Interrupted by user.")
        finally:
            self.stop()
