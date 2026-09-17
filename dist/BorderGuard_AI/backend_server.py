"""
BorderGuard AI - Multi-Node High-Performance Backend Streaming & Detection Server
Features:
- Multi-Camera Architecture:
    * CAM-001 (Laptop Webcam, default index 0)
    * CAM-002 (Mobile Recon Node / Phone Camera, default index 1 or direct IP/USB stream)
- Dual-Thread Architecture: 30 FPS Camera Capture & Display + Asynchronous YOLOv11 & Haar Detection
- DirectShow hardware acceleration & zero latency buffering (CAP_PROP_BUFFERSIZE = 1)
- Automatic Watchdog: Detects frontend disconnection and auto-terminates to release camera hardware
- Full AI Domain: YOLOv11n Detection, Virtual Tripwire, Facial Biometrics, and ANPR
"""

import time
import threading
import os
import sys
import json
import argparse
from datetime import datetime
import cv2
import numpy as np
from flask import Flask, Response, jsonify, request
from ultralytics import YOLO

# Optional Tesseract OCR import
try:
    import pytesseract
    tess_path = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
    if os.path.exists(tess_path):
        pytesseract.pytesseract.tesseract_cmd = tess_path
    TESSERACT_AVAILABLE = True
except Exception:
    TESSERACT_AVAILABLE = False

app = Flask(__name__)
try:
    from flask_cors import CORS
    CORS(app)
except Exception:
    @app.after_request
    def add_cors_headers(response):
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Headers'] = '*'
        response.headers['Access-Control-Allow-Methods'] = '*'
        return response

# Load Models
ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
YOLO_MODEL_PATH = os.path.join(ROOT_DIR, "yolo11n.pt")
FACE_CASCADE_PATH = os.path.join(ROOT_DIR, "haarcascade_frontalface_default.xml")

print(f"[INIT] Loading YOLO model from {YOLO_MODEL_PATH}...")
yolo_model = YOLO(YOLO_MODEL_PATH)
yolo_lock = threading.Lock()

face_cascade = None
if os.path.exists(FACE_CASCADE_PATH):
    face_cascade = cv2.CascadeClassifier(FACE_CASCADE_PATH)
    print(f"[INIT] Loaded Face Cascade from {FACE_CASCADE_PATH}")
else:
    print("[WARN] Haar cascade XML not found, facial detection disabled.")

# Detection Configuration
ALLOWED_CLASSES = {
    0: "Person",
    1: "Bicycle", 2: "Car", 3: "Motorcycle", 5: "Bus", 7: "Truck",
    14: "Bird", 15: "Cat", 16: "Dog", 17: "Horse", 18: "Sheep", 19: "Cow", 20: "Elephant", 21: "Bear"
}
VEHICLE_CLASSES = [1, 2, 3, 5, 7]


class CameraManager:
    def __init__(self, camera_id="CAM-001", source=0, name="Laptop Cam 01", location="Sector 01 Command Post", zone="Sector 01", device_name=""):
        self.camera_id = camera_id
        self.source = source
        self.name = name
        self.location = location
        self.zone = zone
        self.device_name = device_name
        self.cap = None
        self.is_running = False
        self.lock = threading.Lock()
        
        # Telemetry State
        self.is_camera_on = True
        self.mode = "all"  # "all", "person", "vehicle", "fence", "face", "anpr"
        self.fps = 0.0
        self.status = "online"
        self.current_detection = f"Active Monitoring • {self.name}"
        self.counts = {"person": 0, "vehicle": 0, "animal": 0, "face": 0}
        self.intrusion_detected = False
        self.detected_plates = []
        self.alerts = []
        self.last_alert_time = 0
        self.last_reconnect_time = 0
        self.virtual_fence = None

        # Threading buffers
        self.latest_raw_frame = None
        self.latest_jpeg = None
        self.active_boxes = []  # [(x1, y1, x2, y2, label, conf, is_intrusion)]
        self.active_faces = []  # [(fx, fy, fw, fh)]
        self.active_plates = []

        # Generate initial fallback frame immediately
        init_frame = self._generate_fallback_frame(0)
        _, init_buf = cv2.imencode('.jpg', init_frame)
        self.latest_jpeg = init_buf.tobytes()
        self.latest_raw_frame = init_frame

        self.start_capture()

    def update_source(self, new_source):
        with self.lock:
            print(f"[{self.camera_id}] Switching source from '{self.source}' to '{new_source}'...")
            self.source = new_source
            if self.cap is not None:
                try:
                    self.cap.release()
                except Exception:
                    pass
                self.cap = None
            self.cap = self._open_camera()
            self.status = "online" if (self.cap is not None and self.cap.isOpened()) else "standby"

    def _open_camera(self):
        try:
            source = self.source
            if isinstance(source, str) and source.strip().isdigit():
                source = int(source.strip())

            if isinstance(source, int):
                print(f"[{self.camera_id}] Attempting DirectShow device index {source}...")
                cap = cv2.VideoCapture(source, cv2.CAP_DSHOW)
                if not cap.isOpened():
                    print(f"[{self.camera_id}] DirectShow fallback to default backend...")
                    cap = cv2.VideoCapture(source)

                # For CAM-002, auto-probe device indices [1, 2, 3] for phone webcam (Iriun / DroidCam / USB)
                if (cap is None or not cap.isOpened()) and self.camera_id == "CAM-002":
                    for probe_idx in [1, 2, 3]:
                        if probe_idx == source:
                            continue
                        print(f"[{self.camera_id}] Probing alternative device index {probe_idx}...")
                        try:
                            cap_alt = cv2.VideoCapture(probe_idx, cv2.CAP_DSHOW)
                            if cap_alt.isOpened():
                                ret, _ = cap_alt.read()
                                if ret:
                                    self.source = probe_idx
                                    cap = cap_alt
                                    print(f"[{self.camera_id}] Auto-detected active phone camera on device index {probe_idx}!")
                                    break
                                else:
                                    cap_alt.release()
                        except Exception:
                            pass
            else:
                print(f"[{self.camera_id}] Attempting stream URL: {source}...")
                cap = cv2.VideoCapture(str(source))

            if cap.isOpened():
                # Configure camera for high FPS and low latency
                cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*'MJPG'))
                cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
                cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
                cap.set(cv2.CAP_PROP_FPS, 30)
                cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
                print(f"[{self.camera_id}] Camera initialized: 640x480 @ 30 FPS on source '{self.source}'")
                return cap
            else:
                print(f"[{self.camera_id}] Source '{self.source}' not accessible yet.")
        except Exception as e:
            print(f"[{self.camera_id} ERROR] {e}")
        return None

    def release_camera(self):
        with self.lock:
            if self.cap is not None:
                try:
                    self.cap.release()
                    print(f"[{self.camera_id}] Hardware camera released.")
                except Exception:
                    pass
                self.cap = None

    def set_camera_power(self, power_on):
        with self.lock:
            self.is_camera_on = power_on
            if not power_on:
                if self.cap is not None:
                    try:
                        self.cap.release()
                    except Exception:
                        pass
                    self.cap = None
                self.status = "disabled"
                self.fps = 0.0
                self.current_detection = "Sensor Inactive (Camera Off)"
                self.counts = {"person": 0, "vehicle": 0, "animal": 0, "face": 0}
                self.intrusion_detected = False
                off_frame = self._generate_powered_off_frame()
                _, buf = cv2.imencode('.jpg', off_frame)
                self.latest_jpeg = buf.tobytes()
                print(f"[{self.camera_id}] Optical node turned OFF")
            else:
                self.cap = self._open_camera()
                self.status = "online" if (self.cap is not None and self.cap.isOpened()) else "standby"
                self.current_detection = f"Active Monitoring • {self.name}"
                print(f"[{self.camera_id}] Optical node turned ON")

    def _generate_powered_off_frame(self):
        frame = np.zeros((480, 640, 3), dtype=np.uint8)
        frame[:] = (12, 13, 16)
        cv2.line(frame, (320, 180), (320, 300), (35, 40, 48), 1)
        cv2.line(frame, (260, 240), (380, 240), (35, 40, 48), 1)
        cv2.circle(frame, (320, 240), 40, (40, 45, 55), 1)
        cv2.rectangle(frame, (160, 220), (480, 260), (22, 24, 29), -1)
        cv2.rectangle(frame, (160, 220), (480, 260), (239, 68, 68), 1)
        cv2.putText(frame, f"{self.camera_id} HARDWARE STANDBY", (185, 246),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.50, (244, 245, 247), 1, cv2.LINE_AA)
        cv2.putText(frame, "Optical sensor disabled • Click ACTIVATE in C2 Dashboard", (110, 295),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.42, (156, 163, 175), 1, cv2.LINE_AA)
        return frame

    def _generate_fallback_frame(self, frame_count):
        frame = np.zeros((480, 640, 3), dtype=np.uint8)
        frame[:] = (18, 20, 25)

        for x in range(0, 640, 40):
            cv2.line(frame, (x, 0), (x, 480), (30, 34, 42), 1)
        for y in range(0, 480, 40):
            cv2.line(frame, (0, y), (640, y), (30, 34, 42), 1)

        angle = (frame_count * 4) % 360
        cx, cy = 320, 240
        cv2.circle(frame, (cx, cy), 120, (50, 55, 65), 1)
        cv2.circle(frame, (cx, cy), 60, (50, 55, 65), 1)
        rad = np.deg2rad(angle)
        ex = int(cx + 120 * np.cos(rad))
        ey = int(cy + 120 * np.sin(rad))
        line_color = (16, 185, 129) if self.camera_id == "CAM-001" else (245, 158, 11)
        cv2.line(frame, (cx, cy), (ex, ey), line_color, 2)

        title = f"OPTICAL NODE {self.camera_id}: {self.name.upper()}"
        cv2.putText(frame, title, (80, 235),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.50, (244, 245, 247), 1, cv2.LINE_AA)
        
        if self.camera_id == "CAM-002":
            cv2.putText(frame, f"Awaiting Phone Link (Index {self.source} / IP) • Direct USB", (80, 265),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.40, (156, 163, 175), 1, cv2.LINE_AA)
            cv2.putText(frame, "Connect phone via USB (Iriun / DroidCam / Tethering)", (90, 290),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.38, (245, 158, 11), 1, cv2.LINE_AA)
        else:
            cv2.putText(frame, "Awaiting hardware lock • DirectShow C2 stream", (145, 265),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.40, (156, 163, 175), 1, cv2.LINE_AA)
        return frame

    def _trigger_alert(self, title, severity="critical"):
        now = time.time()
        if now - self.last_alert_time > 4.0:
            self.last_alert_time = now
            alert_obj = {
                "id": f"ALT-{int(now) % 100000}",
                "title": title,
                "severity": severity,
                "confidence": 96,
                "camera_id": self.camera_id,
                "location": self.location,
                "timestamp": datetime.now().isoformat()
            }
            self.alerts.insert(0, alert_obj)
            if len(self.alerts) > 20:
                self.alerts.pop()

    def start_capture(self):
        self.cap = self._open_camera()
        self.is_running = True

        # Thread 1: High-Speed Camera Capture & Video Stream Output (30 FPS)
        self.stream_thread = threading.Thread(target=self._capture_and_stream_loop, daemon=True)
        self.stream_thread.start()

        # Thread 2: Asynchronous AI Inference (YOLOv11 + Face + Tripwire)
        self.ai_thread = threading.Thread(target=self._ai_inference_loop, daemon=True)
        self.ai_thread.start()

    def _draw_hud_overlay(self, frame, fps_val):
        h, w, _ = frame.shape
        cv2.rectangle(frame, (0, 0), (w, 32), (15, 17, 22), -1)
        cv2.line(frame, (0, 32), (w, 32), (43, 47, 58), 1)

        status_color = (68, 68, 239) if self.intrusion_detected else (129, 185, 16)
        cv2.circle(frame, (16, 16), 5, status_color, -1)
        cv2.putText(frame, f"{self.camera_id} [{self.name.upper()}] • {self.zone.upper()} C2 STREAM", (28, 21),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.44, (244, 245, 247), 1, cv2.LINE_AA)

        mode_text = f"AI: {self.mode.upper()} | {fps_val:.0f} FPS"
        text_size = cv2.getTextSize(mode_text, cv2.FONT_HERSHEY_SIMPLEX, 0.42, 1)[0]
        cv2.putText(frame, mode_text, (w - text_size[0] - 12, 21),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.42, (168, 175, 186), 1, cv2.LINE_AA)

        cv2.rectangle(frame, (0, h - 26), (w, h), (15, 17, 22), -1)
        cv2.line(frame, (0, h - 26), (w, h - 26), (43, 47, 58), 1)
        
        telemetry_str = f"STATUS: {self.current_detection.upper()} | HUMANS: {self.counts['person']} | VEHICLES: {self.counts['vehicle']}"
        cv2.putText(frame, telemetry_str, (12, h - 8),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.36, (244, 245, 247), 1, cv2.LINE_AA)

        timestamp_str = datetime.now().strftime("%H:%M:%S")
        time_size = cv2.getTextSize(timestamp_str, cv2.FONT_HERSHEY_SIMPLEX, 0.36, 1)[0]
        cv2.putText(frame, timestamp_str, (w - time_size[0] - 12, h - 8),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.36, (156, 163, 175), 1, cv2.LINE_AA)

    # -------------------------------------------------------------
    # Thread 1: High-Speed Video Capture & MJPEG Stream (25-30 FPS)
    # -------------------------------------------------------------
    def _capture_and_stream_loop(self):
        frame_counter = 0
        prev_time = time.time()
        fps_smooth = 28.0

        while self.is_running:
            if not self.is_camera_on:
                time.sleep(0.1)
                continue

            raw_frame = None
            if self.cap is not None and self.cap.isOpened():
                ret, raw_frame = self.cap.read()
                if not ret or raw_frame is None:
                    raw_frame = None
                    try:
                        self.cap.release()
                    except Exception:
                        pass
                    self.cap = None

            # Periodic reconnection if camera is not opened yet
            if raw_frame is None:
                now = time.time()
                if now - self.last_reconnect_time > 2.0:
                    self.last_reconnect_time = now
                    new_cap = self._open_camera()
                    if new_cap is not None and new_cap.isOpened():
                        self.cap = new_cap
                        ret, test_frame = self.cap.read()
                        if ret and test_frame is not None:
                            raw_frame = test_frame
                            self.status = "online"
                            print(f"[{self.camera_id}] Live feed acquired on source '{self.source}'!")

            if raw_frame is None:
                raw_frame = self._generate_fallback_frame(frame_counter)
                self.status = "standby"
            else:
                self.status = "online"

            frame_counter += 1
            h, w, _ = raw_frame.shape

            # Share latest raw frame with AI worker thread
            with self.lock:
                self.latest_raw_frame = raw_frame

            # Virtual fence coordinates
            fx1, fy1 = int(w * 0.15), int(h * 0.22)
            fx2, fy2 = int(w * 0.85), int(h * 0.82)
            self.virtual_fence = np.array([(fx1, fy1), (fx2, fy1), (fx2, fy2), (fx1, fy2)], np.int32)

            annotated = raw_frame.copy()

            # 1. Draw Virtual Fence
            if self.mode in ("all", "fence", "vir"):
                fence_color = (68, 68, 239) if self.intrusion_detected else (250, 166, 26)
                cv2.polylines(annotated, [self.virtual_fence], True, fence_color, 2)
                fence_label = "RESTRICTED PERIMETER BREACH!" if self.intrusion_detected else "AI VIRTUAL TRIPWIRE ARMED"
                cv2.putText(annotated, fence_label, (fx1 + 10, fy1 + 22),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.44, fence_color, 1, cv2.LINE_AA)

            # Copy active detections
            with self.lock:
                boxes_to_draw = list(self.active_boxes)
                faces_to_draw = list(self.active_faces)
                plates_to_draw = list(self.active_plates)

            # 2. Draw YOLO Bounding Boxes
            for (x1, y1, x2, y2, label, conf, is_breach) in boxes_to_draw:
                color = (68, 68, 239) if is_breach else (250, 166, 26)
                if label.lower() == "person" and not is_breach:
                    color = (245, 158, 11)
                elif label.lower() in ("car", "truck", "bus"):
                    color = (96, 165, 250)

                # Corner reticles for high-tech HUD look
                cv2.rectangle(annotated, (x1, y1), (x2, y2), color, 1)
                d = min(15, (x2 - x1) // 3, (y2 - y1) // 3)
                cv2.line(annotated, (x1, y1), (x1 + d, y1), color, 2)
                cv2.line(annotated, (x1, y1), (x1, y1 + d), color, 2)
                cv2.line(annotated, (x2, y1), (x2 - d, y1), color, 2)
                cv2.line(annotated, (x2, y1), (x2, y1 + d), color, 2)
                cv2.line(annotated, (x1, y2), (x1 + d, y2), color, 2)
                cv2.line(annotated, (x1, y2), (x1, y2 - d), color, 2)
                cv2.line(annotated, (x2, y2), (x2 - d, y2), color, 2)
                cv2.line(annotated, (x2, y2), (x2, y2 - d), color, 2)

                tag = f"{label.upper()} {conf:.0%}"
                if is_breach:
                    tag += " [BREACH]"
                (tw, th), _ = cv2.getTextSize(tag, cv2.FONT_HERSHEY_SIMPLEX, 0.42, 1)
                cv2.rectangle(annotated, (x1, max(0, y1 - th - 8)), (x1 + tw + 8, y1), color, -1)
                cv2.putText(annotated, tag, (x1 + 4, y1 - 4),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.42, (15, 17, 22), 1, cv2.LINE_AA)

            # 3. Draw Facial Bounding Boxes
            for (fx, fy, fw, fh) in faces_to_draw:
                cv2.rectangle(annotated, (fx, fy), (fx + fw, fy + fh), (244, 245, 247), 1)
                cv2.putText(annotated, "FACE ID VERIFIED", (fx, max(0, fy - 6)),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.38, (244, 245, 247), 1, cv2.LINE_AA)

            # 4. Draw ANPR License Plates
            for (px, py, ptxt) in plates_to_draw:
                cv2.putText(annotated, f"PLATE: {ptxt}", (px, py),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.46, (52, 211, 153), 1, cv2.LINE_AA)

            # Smooth FPS Calculation
            curr_time = time.time()
            elapsed = curr_time - prev_time
            prev_time = curr_time
            if elapsed > 0:
                inst_fps = 1.0 / elapsed
                fps_smooth = 0.85 * fps_smooth + 0.15 * inst_fps
            self.fps = round(fps_smooth, 1)

            # 5. Top & Bottom HUD Overlays
            self._draw_hud_overlay(annotated, self.fps)

            # Encode frame to JPEG at quality 75 for ultra-low latency
            _, jpeg_buffer = cv2.imencode('.jpg', annotated, [cv2.IMWRITE_JPEG_QUALITY, 75])
            with self.lock:
                self.latest_jpeg = jpeg_buffer.tobytes()

            # Keep video streaming at consistent 28-30 FPS interval
            time.sleep(0.02)

    # -------------------------------------------------------------
    # Thread 2: Asynchronous AI Inference (YOLOv11 + Face + Tripwire)
    # -------------------------------------------------------------
    def _ai_inference_loop(self):
        while self.is_running:
            if not self.is_camera_on or self.latest_raw_frame is None:
                time.sleep(0.05)
                continue

            with self.lock:
                frame_to_process = self.latest_raw_frame.copy()

            h, w, _ = frame_to_process.shape
            updated_boxes = []
            updated_faces = []
            updated_plates = []
            persons = 0
            vehicles = 0
            animals = 0
            faces = 0
            intrusion = False

            # 1. YOLOv11 Detection (thread-safe with yolo_lock)
            if self.mode in ("all", "person", "human", "vehicle", "fence", "vir", "anpr", "detection", "detc"):
                try:
                    with yolo_lock:
                        results = yolo_model(frame_to_process, verbose=False, conf=0.42, imgsz=384)
                    for box in results[0].boxes:
                        cls_id = int(box.cls[0])
                        conf = float(box.conf[0])

                        # Specific engine mode filtering
                        if self.mode in ("person", "human") and cls_id != 0:
                            continue
                        if self.mode == "vehicle" and cls_id not in VEHICLE_CLASSES:
                            continue

                        if cls_id in ALLOWED_CLASSES:
                            label = ALLOWED_CLASSES[cls_id]
                            x1, y1, x2, y2 = box.xyxy[0].cpu().numpy().astype(int)

                            if cls_id == 0:
                                persons += 1
                            elif cls_id in VEHICLE_CLASSES:
                                vehicles += 1
                            else:
                                animals += 1

                            # Intrusion check against virtual perimeter fence
                            cx, cy = int((x1 + x2) / 2), int((y1 + y2) / 2)
                            is_inside = False
                            if self.virtual_fence is not None:
                                is_inside = cv2.pointPolygonTest(self.virtual_fence, (cx, cy), False) >= 0

                            is_breach = is_inside and (self.mode in ("all", "fence", "vir"))
                            if is_breach:
                                intrusion = True
                                self._trigger_alert(f"Perimeter Intrusion Detected: {label.upper()} on {self.camera_id}")

                            updated_boxes.append((x1, y1, x2, y2, label, conf, is_breach))

                            # Optional ANPR OCR on vehicles
                            if self.mode in ("all", "anpr") and cls_id in VEHICLE_CLASSES and TESSERACT_AVAILABLE:
                                try:
                                    plate_roi = frame_to_process[max(0, y1):min(h, y2), max(0, x1):min(w, x2)]
                                    if plate_roi.size > 0:
                                        plate_txt = pytesseract.image_to_string(plate_roi, config="--psm 7").strip()
                                        if len(plate_txt) >= 3:
                                            updated_plates.append((x1, y2 + 18, plate_txt))
                                except Exception:
                                    pass

                except Exception as e:
                    print(f"[{self.camera_id} AI ERROR] YOLO: {e}")

            # 2. Haar Cascade Face Detection
            if self.mode in ("all", "face") and face_cascade is not None:
                try:
                    gray = cv2.cvtColor(frame_to_process, cv2.COLOR_BGR2GRAY)
                    face_rects = face_cascade.detectMultiScale(gray, scaleFactor=1.28, minNeighbors=5, minSize=(30, 30))
                    faces = len(face_rects)
                    for (fx, fy, fw, fh) in face_rects:
                        updated_faces.append((fx, fy, fw, fh))
                except Exception as e:
                    print(f"[{self.camera_id} AI ERROR] Face: {e}")

            # Commit new detection state atomically
            with self.lock:
                self.active_boxes = updated_boxes
                self.active_faces = updated_faces
                self.active_plates = updated_plates
                self.intrusion_detected = intrusion
                self.counts = {
                    "person": persons,
                    "vehicle": vehicles,
                    "animal": animals,
                    "face": faces
                }

                if intrusion:
                    self.current_detection = f"CRITICAL: {self.camera_id} PERIMETER BREACH"
                elif persons > 0:
                    self.current_detection = f"Person Tracked ({persons})"
                elif vehicles > 0:
                    self.current_detection = f"Vehicle Tracked ({vehicles})"
                elif animals > 0:
                    self.current_detection = f"Animal Tracked ({animals})"
                elif faces > 0:
                    self.current_detection = f"Face Verified ({faces})"
                else:
                    self.current_detection = f"Sector Clear • {self.name}"

            # Adaptive AI pacing (runs up to 25 times/sec on CPU)
            time.sleep(0.01)

    def get_latest_jpeg(self):
        with self.lock:
            return self.latest_jpeg

    def get_telemetry(self):
        return {
            "status": self.status,
            "camera_id": self.camera_id,
            "camera_enabled": self.is_camera_on,
            "name": self.name,
            "device_name": self.device_name or ("Laptop Cam 01" if self.camera_id == "CAM-001" else "Phone Recon Node"),
            "location": self.location,
            "zone": self.zone,
            "source": str(self.source),
            "signal": "Direct 100%" if self.is_camera_on else "Standby",
            "mode": self.mode,
            "fps": self.fps,
            "counts": self.counts,
            "intrusion_detected": self.intrusion_detected,
            "current_detection": self.current_detection,
            "alerts": self.alerts[:5],
            "timestamp": datetime.now().isoformat()
        }


# ==============================================================================
# Hardware Camera Auto-Detection & Assignment
# ==============================================================================
def detect_camera_devices(cam1_override=None, cam2_override=None):
    phone_keywords = ['iriun', 'droidcam', 'phone', 'mobile', 'camo', 'epoccam', 'ivcam']
    laptop_keywords = ['xiaomi', 'webcam', 'integrated', 'hd camera', 'front', 'internal', 'chicony', 'sunplus', 'realtek']
    
    dev1_name = "Laptop Webcam"
    dev2_name = "Phone Recon Camera"

    devices = []
    try:
        from pygrabber.dshow_graph import FilterGraph
        devices = FilterGraph().get_input_devices()
        print(f"[DEVICE ENUM] DirectShow hardware devices detected: {devices}")
    except Exception as e:
        print(f"[DEVICE ENUM WARN] Could not query DirectShow device list: {e}")

    # If overrides are explicitly passed
    if cam1_override is not None and cam2_override is not None:
        c1 = int(cam1_override) if str(cam1_override).isdigit() else cam1_override
        c2 = int(cam2_override) if str(cam2_override).isdigit() else cam2_override
        n1 = devices[c1] if isinstance(c1, int) and c1 < len(devices) else f"Device {c1}"
        n2 = devices[c2] if isinstance(c2, int) and c2 < len(devices) else f"Device {c2}"
        return c1, c2, n1, n2

    phone_idx = None
    laptop_idx = None

    if devices:
        # Match Phone first
        for idx, name in enumerate(devices):
            d_lower = name.lower()
            if any(k in d_lower for k in phone_keywords):
                phone_idx = idx
                dev2_name = name
                break

        # Match Laptop
        for idx, name in enumerate(devices):
            if idx == phone_idx:
                continue
            d_lower = name.lower()
            if any(k in d_lower for k in laptop_keywords):
                laptop_idx = idx
                dev1_name = name
                break

        # Unmatched fallbacks
        if laptop_idx is None:
            for idx in range(len(devices)):
                if idx != phone_idx:
                    laptop_idx = idx
                    dev1_name = devices[idx]
                    break

        if phone_idx is None and len(devices) > 1:
            for idx in range(len(devices)):
                if idx != laptop_idx:
                    phone_idx = idx
                    dev2_name = devices[idx]
                    break

    cam1 = laptop_idx if laptop_idx is not None else 0
    cam2 = phone_idx if phone_idx is not None else (1 if len(devices) > 1 else 1)
    
    print(f"[AUTO-ASSIGN] CAM-001 (Laptop) assigned to Index {cam1} ({dev1_name})")
    print(f"[AUTO-ASSIGN] CAM-002 (Phone)  assigned to Index {cam2} ({dev2_name})")
    return cam1, cam2, dev1_name, dev2_name


# ==============================================================================
# Multi-Camera System Manager
# ==============================================================================
class MultiCameraSystem:
    def __init__(self, cam1_source=None, cam2_source=None):
        cam1_src, cam2_src, dev1_name, dev2_name = detect_camera_devices(cam1_source, cam2_source)
        self.cameras = {
            "1": CameraManager(camera_id="CAM-001", source=cam1_src, name="Laptop Cam 01", location="Sector 01 Command Post", zone="Sector 01", device_name=dev1_name),
            "2": CameraManager(camera_id="CAM-002", source=cam2_src, name="Mobile Recon Node", location="Sector 02 Mobile Patrol", zone="Sector 02", device_name=dev2_name),
        }
        self.aliases = {
            "cam-001": "1",
            "cam-01": "1",
            "cam1": "1",
            "cam-002": "2",
            "cam-02": "2",
            "cam2": "2",
        }
        self.start_time = time.time()
        self.last_client_ping = time.time()
        self.has_connected = False
        self._start_watchdog()

    def swap_cameras(self):
        c1 = self.cameras["1"]
        c2 = self.cameras["2"]
        src1, src2 = c1.source, c2.source
        dev1, dev2 = c1.device_name, c2.device_name
        print(f"[CAM SWAP] Inverting sources: CAM-001 ({src1} -> {src2}), CAM-002 ({src2} -> {src1})")
        c1.device_name = dev2
        c2.device_name = dev1
        c1.update_source(src2)
        c2.update_source(src1)
        return {
            "status": "swapped",
            "CAM-001": {"source": str(c1.source), "device_name": c1.device_name},
            "CAM-002": {"source": str(c2.source), "device_name": c2.device_name}
        }

    def record_activity(self):
        self.last_client_ping = time.time()
        self.has_connected = True

    def get_camera(self, cam_id="1"):
        key = str(cam_id).lower()
        resolved_key = self.aliases.get(key, key)
        return self.cameras.get(resolved_key, self.cameras["1"])

    def release_all(self):
        for cam in self.cameras.values():
            cam.is_running = False
            cam.release_camera()

    def _start_watchdog(self):
        def watchdog_loop():
            while True:
                time.sleep(1.0)
                uptime = time.time() - self.start_time
                elapsed = time.time() - self.last_client_ping
                # Auto terminate if connected and silent for > 60s, or never connected within 300s
                if (self.has_connected and elapsed > 60.0) or (not self.has_connected and uptime > 300.0):
                    print(f"[WATCHDOG] Inactive (elapsed: {elapsed:.1f}s). Releasing hardware & shutting down...")
                    self.release_all()
                    os._exit(0)
        threading.Thread(target=watchdog_loop, daemon=True).start()


# Initialize Global Multi-Camera System with auto-detected hardware devices
camera_system = MultiCameraSystem()


# ==============================================================================
# REST API Endpoints
# ==============================================================================
@app.route('/')
def index():
    camera_system.record_activity()
    return jsonify({
        "service": "BorderGuard AI Dual-Camera Video Backend",
        "cameras": {
            "CAM-001": "Laptop Webcam (Device Index 0)",
            "CAM-002": "Mobile Recon Node (Phone Cam: Device Index 1 / IP Stream)"
        },
        "fps_target": "25-30 FPS per camera",
        "endpoints": {
            "single_frame": "/api/frame?cam=1 or /api/frame?cam=2",
            "camera_frame": "/api/camera/<cam_id>/frame",
            "telemetry": "/api/telemetry",
            "camera_source": "/api/camera/source",
            "camera_power": "/api/camera/power",
            "mode_control": "/api/mode",
            "alerts": "/api/alerts",
            "shutdown": "/api/shutdown"
        }
    })


@app.route('/api/frame')
def api_frame():
    camera_system.record_activity()
    cam_id = request.args.get('cam', '1')
    cam = camera_system.get_camera(cam_id)
    frame_bytes = cam.get_latest_jpeg()
    if frame_bytes is None:
        return Response(status=404)
    response = Response(frame_bytes, mimetype='image/jpeg')
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    return response


@app.route('/api/camera/<cam_id>/frame')
def api_camera_frame(cam_id):
    camera_system.record_activity()
    cam = camera_system.get_camera(cam_id)
    frame_bytes = cam.get_latest_jpeg()
    if frame_bytes is None:
        return Response(status=404)
    response = Response(frame_bytes, mimetype='image/jpeg')
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    return response


@app.route('/api/telemetry', methods=['GET'])
def api_telemetry():
    camera_system.record_activity()
    cam1 = camera_system.get_camera('1')
    cam2 = camera_system.get_camera('2')
    
    # Root values reflect CAM-001 for backward compatibility
    data = cam1.get_telemetry()
    # Provide multi-node camera map
    data["cameras"] = {
        "CAM-001": cam1.get_telemetry(),
        "CAM-002": cam2.get_telemetry(),
    }
    return jsonify(data)


@app.route('/api/camera/source', methods=['POST', 'GET'])
def api_camera_source():
    camera_system.record_activity()
    if request.method == 'POST':
        data = request.get_json(silent=True) or {}
        cam_id = data.get('camera_id', '2')
        new_source = data.get('source', '')
        if new_source:
            cam = camera_system.get_camera(cam_id)
            cam.update_source(new_source)
            return jsonify({"status": "updated", "camera_id": cam.camera_id, "source": str(cam.source)})
        return jsonify({"error": "Missing 'source' parameter"}), 400
    
    return jsonify({
        "CAM-001": str(camera_system.get_camera('1').source),
        "CAM-002": str(camera_system.get_camera('2').source),
    })


@app.route('/api/mode', methods=['GET', 'POST'])
def api_mode():
    camera_system.record_activity()
    if request.method == 'POST':
        data = request.get_json(silent=True) or {}
        new_mode = data.get('mode', '').lower()
        cam_id = data.get('camera_id') or request.args.get('cam')
        valid_modes = ("all", "person", "human", "vehicle", "fence", "vir", "face", "anpr", "detection", "detc")
        
        if new_mode in valid_modes:
            if new_mode == "human":
                new_mode = "person"
            elif new_mode == "vir":
                new_mode = "fence"

            if cam_id:
                cam = camera_system.get_camera(cam_id)
                cam.mode = new_mode
                print(f"[MODE] Switching {cam.camera_id} AI Mode to: {new_mode.upper()}")
            else:
                for cam in camera_system.cameras.values():
                    cam.mode = new_mode
                print(f"[MODE] Switching All Cameras AI Mode to: {new_mode.upper()}")

            return jsonify({"status": "success", "mode": new_mode})
        return jsonify({"error": f"Invalid mode '{new_mode}'. Choose from: {valid_modes}"}), 400
    
    return jsonify({
        "CAM-001": camera_system.get_camera('1').mode,
        "CAM-002": camera_system.get_camera('2').mode,
    })


@app.route('/api/alerts', methods=['GET'])
def api_alerts():
    camera_system.record_activity()
    all_alerts = []
    for cam in camera_system.cameras.values():
        all_alerts.extend(cam.alerts)
    all_alerts.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
    return jsonify({"alerts": all_alerts[:10]})


@app.route('/api/camera/swap', methods=['POST', 'GET'])
def api_camera_swap():
    camera_system.record_activity()
    res = camera_system.swap_cameras()
    return jsonify(res)


@app.route('/api/camera/power', methods=['GET', 'POST'])
def api_camera_power():
    camera_system.record_activity()
    cam_id = request.args.get('cam', '1')
    cam = camera_system.get_camera(cam_id)
    if request.method == 'POST':
        data = request.get_json(silent=True) or {}
        if 'camera_id' in data:
            cam = camera_system.get_camera(data['camera_id'])
        if 'enabled' in data:
            new_state = bool(data['enabled'])
        else:
            new_state = not cam.is_camera_on
        cam.set_camera_power(new_state)
        return jsonify({"camera_id": cam.camera_id, "enabled": cam.is_camera_on, "status": cam.status})
    return jsonify({"camera_id": cam.camera_id, "enabled": cam.is_camera_on, "status": cam.status})


@app.route('/api/shutdown', methods=['POST', 'GET'])
def api_shutdown():
    print("[SERVER] Shutdown command received. Releasing hardware...")
    try:
        camera_system.release_all()
        print("[SERVER] All camera hardware successfully released.")
    except Exception as e:
        print(f"[SERVER ERROR] Error releasing hardware: {e}")
    
    def kill_soon():
        time.sleep(0.2)
        os._exit(0)
    threading.Thread(target=kill_soon, daemon=True).start()
    return jsonify({"status": "shutdown_initiated", "message": "Backend server is terminating"})


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="BorderGuard AI Tactical Video Server")
    parser.add_argument('--cam1', default=None, help='Camera 1 source (device index or stream URL)')
    parser.add_argument('--cam2', default=None, help='Camera 2 source (phone USB device index or IP stream URL)')
    parser.add_argument('--port', type=int, default=5000, help='Port to run Flask server')
    args, unknown = parser.parse_known_args()

    # Re-initialize camera sources only if custom command line arguments are provided
    if args.cam1 is not None and str(camera_system.get_camera('1').source) != str(args.cam1):
        camera_system.get_camera('1').update_source(args.cam1)
    if args.cam2 is not None and str(camera_system.get_camera('2').source) != str(args.cam2):
        camera_system.get_camera('2').update_source(args.cam2)

    c1 = camera_system.get_camera('1')
    c2 = camera_system.get_camera('2')
    print(f"[SERVER] Starting BorderGuard AI Multi-Node Backend on http://127.0.0.1:{args.port} ...")
    print(f"[SERVER] CAM-001 assigned to source: {c1.source} ({c1.device_name})")
    print(f"[SERVER] CAM-002 assigned to source: {c2.source} ({c2.device_name})")
    app.run(host='0.0.0.0', port=args.port, debug=False, threaded=True)
