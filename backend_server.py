"""
BorderGuard AI - Backend Streaming & Detection Server
Integrates Laptop Webcam as CAM-01 with Real-Time AI Models:
- YOLOv11n Detection (Human, Vehicle, Animals)
- Virtual Perimeter Fence Intrusion Detection
- Haar Cascade Facial Detection
- Automatic Number Plate Recognition (ANPR) / OCR
"""

import time
import threading
import os
import json
from datetime import datetime
import cv2
import numpy as np
from flask import Flask, Response, jsonify, request
from flask_cors import CORS
from ultralytics import YOLO

# Optional Tesseract OCR import
try:
    import pytesseract
    # Default common windows path if installed
    tess_path = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
    if os.path.exists(tess_path):
        pytesseract.pytesseract.tesseract_cmd = tess_path
    TESSERACT_AVAILABLE = True
except Exception:
    TESSERACT_AVAILABLE = False

app = Flask(__name__)
CORS(app)

# Load Models
ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
YOLO_MODEL_PATH = os.path.join(ROOT_DIR, "yolo11n.pt")
FACE_CASCADE_PATH = os.path.join(ROOT_DIR, "haarcascade_frontalface_default.xml")

print(f"[INIT] Loading YOLO model from {YOLO_MODEL_PATH}...")
yolo_model = YOLO(YOLO_MODEL_PATH)

face_cascade = None
if os.path.exists(FACE_CASCADE_PATH):
    face_cascade = cv2.CascadeClassifier(FACE_CASCADE_PATH)
    print(f"[INIT] Loaded Face Cascade from {FACE_CASCADE_PATH}")
else:
    print("[WARN] Haar cascade XML not found, facial detection disabled.")

# Detection Configuration
# COCO classes: 0=person, 1=bicycle, 2=car, 3=motorcycle, 5=bus, 7=truck, 15=cat, 16=dog, 17=horse, 18=sheep, 19=cow, 20=elephant, 21=bear, 22=zebra, 23=giraffe
ALLOWED_CLASSES = {
    0: "Person",
    1: "Bicycle", 2: "Car", 3: "Motorcycle", 5: "Bus", 7: "Truck",
    14: "Bird", 15: "Cat", 16: "Dog", 17: "Horse", 18: "Sheep", 19: "Cow", 20: "Elephant", 21: "Bear"
}
VEHICLE_CLASSES = [1, 2, 3, 5, 7]

class CameraManager:
    def __init__(self, camera_index=0):
        self.camera_index = camera_index
        self.cap = None
        self.is_running = False
        self.lock = threading.Lock()
        
        # Telemetry State
        self.is_camera_on = True
        self.mode = "all"  # "all", "detection", "fence", "face", "anpr"
        self.fps = 0.0
        self.status = "online"
        self.current_detection = "Active Monitoring • Lap Cam 01"
        self.counts = {"person": 0, "vehicle": 0, "animal": 0, "face": 0}
        self.intrusion_detected = False
        self.detected_plates = []
        self.alerts = []
        self.last_alert_time = 0
        self.virtual_fence = None

        # Pre-populate latest_jpeg with an initial tactical frame immediately
        init_frame = self._generate_fallback_frame(0)
        _, init_buf = cv2.imencode('.jpg', init_frame)
        self.latest_jpeg = init_buf.tobytes()
        self.latest_raw_frame = init_frame
        
        # Model warmup so first request is instant
        try:
            print("[WARMUP] Warming up YOLOv11 engine...")
            yolo_model(np.zeros((320, 320, 3), dtype=np.uint8), verbose=False)
            print("[WARMUP] YOLOv11 engine warmed up and ready.")
        except Exception as e:
            print(f"[WARMUP] Warning during warmup: {e}")

        self.start_capture()

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
                print("[HARDWARE] Laptop Webcam (CAM-01) turned OFF")
            else:
                try:
                    self.cap = cv2.VideoCapture(self.camera_index, cv2.CAP_DSHOW)
                    if not self.cap.isOpened():
                        self.cap = cv2.VideoCapture(self.camera_index)
                except Exception as e:
                    print(f"[REOPEN ERROR] {e}")
                self.status = "online"
                self.current_detection = "Active Monitoring • Lap Cam 01"
                print("[HARDWARE] Laptop Webcam (CAM-01) turned ON")

    def _generate_powered_off_frame(self):
        """Tactical HUD standby screen when webcam is turned off by user."""
        frame = np.zeros((480, 640, 3), dtype=np.uint8)
        frame[:] = (12, 13, 16)
        cv2.line(frame, (320, 180), (320, 300), (35, 40, 48), 1)
        cv2.line(frame, (260, 240), (380, 240), (35, 40, 48), 1)
        cv2.circle(frame, (320, 240), 40, (40, 45, 55), 1)
        cv2.rectangle(frame, (170, 220), (470, 260), (22, 24, 29), -1)
        cv2.rectangle(frame, (170, 220), (470, 260), (239, 68, 68), 1)
        cv2.putText(frame, "CAM-01 HARDWARE STANDBY", (195, 246),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.52, (244, 245, 247), 1, cv2.LINE_AA)
        cv2.putText(frame, "Optical sensor disabled • Click ACTIVATE CAMERA in Dashboard", (85, 295),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.42, (156, 163, 175), 1, cv2.LINE_AA)
        return frame

    def start_capture(self):
        # Open camera with DirectShow on Windows for fast startup
        try:
            self.cap = cv2.VideoCapture(self.camera_index, cv2.CAP_DSHOW)
            if not self.cap.isOpened():
                print(f"[WARN] DirectShow failed for Cam {self.camera_index}, retrying default backend...")
                self.cap = cv2.VideoCapture(self.camera_index)
        except Exception as e:
            print(f"[ERROR] Could not open camera {self.camera_index}: {e}")
            self.cap = None

        self.is_running = True
        self.worker_thread = threading.Thread(target=self._capture_and_process_loop, daemon=True)
        self.worker_thread.start()

    def _draw_hud_overlay(self, frame, fps_val):
        h, w, _ = frame.shape
        # Top HUD bar
        cv2.rectangle(frame, (0, 0), (w, 36), (15, 17, 22), -1)
        cv2.line(frame, (0, 36), (w, 36), (43, 47, 58), 1)

        # Left indicator: CAM-01 LIVE
        status_color = (68, 68, 239) if self.intrusion_detected else (129, 185, 16)  # BGR
        cv2.circle(frame, (18, 18), 6, status_color, -1)
        cv2.putText(frame, "CAM-01 [LAPTOP WEBCAM] • LIVE SURVEILLANCE", (32, 23),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (244, 245, 247), 1, cv2.LINE_AA)

        # Right indicator: Mode & FPS
        mode_text = f"AI MODE: {self.mode.upper()}  |  {fps_val:.1f} FPS"
        text_size = cv2.getTextSize(mode_text, cv2.FONT_HERSHEY_SIMPLEX, 0.45, 1)[0]
        cv2.putText(frame, mode_text, (w - text_size[0] - 14, 23),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.45, (168, 175, 186), 1, cv2.LINE_AA)

        # Bottom HUD bar
        cv2.rectangle(frame, (0, h - 30), (w, h), (15, 17, 22), -1)
        cv2.line(frame, (0, h - 30), (w, h - 30), (43, 47, 58), 1)
        
        telemetry_str = f"STATUS: {self.current_detection.upper()} | PERSONS: {self.counts['person']} | VEHICLES: {self.counts['vehicle']}"
        cv2.putText(frame, telemetry_str, (14, h - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.42, (244, 245, 247), 1, cv2.LINE_AA)

        timestamp_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        time_size = cv2.getTextSize(timestamp_str, cv2.FONT_HERSHEY_SIMPLEX, 0.42, 1)[0]
        cv2.putText(frame, timestamp_str, (w - time_size[0] - 14, h - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.42, (156, 163, 175), 1, cv2.LINE_AA)

    def _generate_fallback_frame(self, frame_count):
        """Creates a realistic tactical simulated frame if webcam hardware is in use or unavailable."""
        frame = np.zeros((480, 640, 3), dtype=np.uint8)
        frame[:] = (18, 20, 25) # Dark tactical gray

        # Grid lines
        for x in range(0, 640, 40):
            cv2.line(frame, (x, 0), (x, 480), (30, 34, 42), 1)
        for y in range(0, 480, 40):
            cv2.line(frame, (0, y), (640, y), (30, 34, 42), 1)

        # Radar sweep animation
        angle = (frame_count * 3) % 360
        cx, cy = 320, 240
        cv2.circle(frame, (cx, cy), 120, (50, 55, 65), 1)
        cv2.circle(frame, (cx, cy), 60, (50, 55, 65), 1)
        rad = np.deg2rad(angle)
        ex = int(cx + 120 * np.cos(rad))
        ey = int(cy + 120 * np.sin(rad))
        cv2.line(frame, (cx, cy), (ex, ey), (16, 185, 129), 2)

        cv2.putText(frame, "LAPTOP WEBCAM STANDBY / SYNCHRONIZING", (120, 245),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (244, 245, 247), 1, cv2.LINE_AA)
        cv2.putText(frame, "Optical sensor initializing or reserved by OS", (140, 275),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.45, (156, 163, 175), 1, cv2.LINE_AA)
        return frame

    def _trigger_alert(self, title, severity="critical"):
        now = time.time()
        if now - self.last_alert_time > 4.0:  # throttle alerts
            self.last_alert_time = now
            alert_obj = {
                "id": f"ALT-{int(now) % 100000}",
                "title": title,
                "severity": severity,
                "confidence": 95,
                "camera_id": "CAM-001",
                "location": "Command Post - Lap Cam 01",
                "timestamp": datetime.now().isoformat()
            }
            self.alerts.insert(0, alert_obj)
            if len(self.alerts) > 20:
                self.alerts.pop()

    def _capture_and_process_loop(self):
        frame_counter = 0
        prev_time = time.time()
        fps_smooth = 25.0

        while self.is_running:
            if not self.is_camera_on:
                time.sleep(0.1)
                continue

            raw_frame = None
            if self.cap is not None and self.cap.isOpened():
                ret, raw_frame = self.cap.read()
                if not ret or raw_frame is None:
                    raw_frame = None

            if raw_frame is None:
                raw_frame = self._generate_fallback_frame(frame_counter)
                self.status = "standby"
            else:
                self.status = "online"

            frame_counter += 1
            h, w, _ = raw_frame.shape

            # Define virtual fence polygon relative to frame dimensions
            # (centered box representing restricted perimeter)
            fx1, fy1 = int(w * 0.15), int(h * 0.25)
            fx2, fy2 = int(w * 0.85), int(h * 0.82)
            self.virtual_fence = np.array([(fx1, fy1), (fx2, fy1), (fx2, fy2), (fx1, fy2)], np.int32)

            annotated = raw_frame.copy()
            detected_classes = []
            persons = 0
            vehicles = 0
            animals = 0
            faces = 0
            intrusion = False
            detected_plates_in_frame = []

            # 1. Virtual Fence Overlay
            if self.mode in ("all", "fence", "vir"):
                fence_color = (68, 68, 239) if self.intrusion_detected else (250, 166, 26)  # Amber or Red
                cv2.polylines(annotated, [self.virtual_fence], True, fence_color, 2)
                cv2.putText(annotated, "RESTRICTED PERIMETER ZONE", (fx1 + 10, fy1 + 22),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.5, fence_color, 1, cv2.LINE_AA)

            # 2. YOLO Inference (Humans, Vehicles, Animals)
            if self.mode in ("all", "detection", "detc", "fence", "vir", "anpr"):
                try:
                    # Run inference on resized image for max speed, or direct
                    results = yolo_model(annotated, verbose=False, conf=0.45)
                    for box in results[0].boxes:
                        cls_id = int(box.cls[0])
                        conf = float(box.conf[0])
                        
                        if cls_id in ALLOWED_CLASSES:
                            label = ALLOWED_CLASSES[cls_id]
                            x1, y1, x2, y2 = box.xyxy[0].cpu().numpy().astype(int)
                            detected_classes.append(label)

                            if cls_id == 0:
                                persons += 1
                            elif cls_id in VEHICLE_CLASSES:
                                vehicles += 1
                            else:
                                animals += 1

                            # Intrusion check
                            cx, cy = int((x1 + x2) / 2), int((y1 + y2) / 2)
                            is_inside = cv2.pointPolygonTest(self.virtual_fence, (cx, cy), False) >= 0

                            if is_inside and (self.mode in ("all", "fence", "vir")):
                                intrusion = True
                                box_color = (68, 68, 239) # Alert Red
                                cv2.putText(annotated, "! INTRUSION BREACH !", (x1, max(25, y1 - 28)),
                                            cv2.FONT_HERSHEY_SIMPLEX, 0.6, (68, 68, 239), 2, cv2.LINE_AA)
                                self._trigger_alert(f"Perimeter Intrusion Detected: {label.upper()} in Sector 01")
                            else:
                                box_color = (16, 185, 129) if cls_id == 0 else (250, 166, 26)

                            # Draw bounding box
                            cv2.rectangle(annotated, (x1, y1), (x2, y2), box_color, 2)
                            badge_text = f"{label} {int(conf * 100)}%"
                            cv2.rectangle(annotated, (x1, y1 - 20), (x1 + len(badge_text) * 10, y1), box_color, -1)
                            cv2.putText(annotated, badge_text, (x1 + 3, y1 - 5),
                                        cv2.FONT_HERSHEY_SIMPLEX, 0.42, (0, 0, 0), 1, cv2.LINE_AA)

                            # Optional ANPR OCR
                            if self.mode in ("all", "anpr") and cls_id in VEHICLE_CLASSES and TESSERACT_AVAILABLE:
                                try:
                                    plate_roi = raw_frame[max(0, y1):min(h, y2), max(0, x1):min(w, x2)]
                                    if plate_roi.size > 0:
                                        plate_txt = pytesseract.image_to_string(plate_roi, config="--psm 7").strip()
                                        if len(plate_txt) >= 3:
                                            detected_plates_in_frame.append(plate_txt)
                                            cv2.putText(annotated, f"PLATE: {plate_txt}", (x1, y2 + 18),
                                                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 0), 2)
                                except Exception:
                                    pass

                except Exception as e:
                    print(f"[INFERENCE ERROR] {e}")

            # 3. Haar Cascade Face Detection
            if self.mode in ("all", "face") and face_cascade is not None:
                try:
                    gray = cv2.cvtColor(annotated, cv2.COLOR_BGR2GRAY)
                    face_rects = face_cascade.detectMultiScale(gray, scaleFactor=1.25, minNeighbors=5, minSize=(30, 30))
                    faces = len(face_rects)
                    for (fx, fy, fw, fh) in face_rects:
                        cv2.rectangle(annotated, (fx, fy), (fx + fw, fy + fh), (245, 158, 11), 2)
                        cv2.putText(annotated, "FACE DETECTED", (fx, max(20, fy - 8)),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.45, (245, 158, 11), 1, cv2.LINE_AA)
                except Exception as e:
                    print(f"[FACE ERROR] {e}")

            # Update Detection Telemetry
            self.intrusion_detected = intrusion
            self.counts = {
                "person": persons,
                "vehicle": vehicles,
                "animal": animals,
                "face": faces
            }

            if intrusion:
                self.current_detection = "CRITICAL: PERIMETER BREACH"
            elif persons > 0:
                self.current_detection = f"Person Detected ({persons})"
            elif vehicles > 0:
                self.current_detection = f"Vehicle Detected ({vehicles})"
            elif animals > 0:
                self.current_detection = f"Animal Detected ({animals})"
            elif faces > 0:
                self.current_detection = f"Face Verified ({faces})"
            else:
                self.current_detection = "No Threat • Sector Clear"

            # Calculate FPS
            curr_time = time.time()
            fps = 1.0 / max(0.001, (curr_time - prev_time))
            prev_time = curr_time
            fps_smooth = fps_smooth * 0.9 + fps * 0.1
            self.fps = round(fps_smooth, 1)

            # Draw HUD overlays on frame
            self._draw_hud_overlay(annotated, self.fps)

            # Encode frame to JPEG
            ret, buffer = cv2.imencode('.jpg', annotated, [cv2.IMWRITE_JPEG_QUALITY, 80])
            if ret:
                with self.lock:
                    self.latest_jpeg = buffer.tobytes()
                    self.latest_raw_frame = annotated

            time.sleep(0.01)  # small yield for CPU cooling

    def get_latest_jpeg(self):
        with self.lock:
            return self.latest_jpeg

    def get_telemetry(self):
        return {
            "status": self.status,
            "camera_id": "CAM-001",
            "camera_enabled": self.is_camera_on,
            "name": "Laptop Cam 01",
            "location": "North Border Sector 01 (Laptop)",
            "zone": "North",
            "signal": "Direct 100%" if self.is_camera_on else "Standby",
            "mode": self.mode,
            "fps": self.fps,
            "counts": self.counts,
            "intrusion_detected": self.intrusion_detected,
            "current_detection": self.current_detection,
            "alerts": self.alerts[:5],
            "timestamp": datetime.now().isoformat()
        }

# Global Camera Instance
camera_manager = CameraManager(camera_index=0)

@app.route('/')
def index():
    return jsonify({
        "service": "BorderGuard AI Video Backend",
        "camera": "CAM-001 (Laptop Webcam)",
        "endpoints": {
            "video_feed": "/video_feed",
            "single_frame": "/api/frame",
            "telemetry": "/api/telemetry",
            "camera_power": "/api/camera/power",
            "mode_control": "/api/mode",
            "alerts": "/api/alerts"
        }
    })

def generate_mjpeg_stream():
    """Generator for MJPEG stream."""
    while True:
        frame_bytes = camera_manager.get_latest_jpeg()
        if frame_bytes is not None:
            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
        time.sleep(0.04)  # ~25 fps

@app.route('/video_feed')
def video_feed():
    return Response(generate_mjpeg_stream(),
                    mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/api/frame')
def api_frame():
    frame_bytes = camera_manager.get_latest_jpeg()
    if frame_bytes is None:
        return Response(status=404)
    response = Response(frame_bytes, mimetype='image/jpeg')
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    return response

@app.route('/api/telemetry', methods=['GET'])
def api_telemetry():
    return jsonify(camera_manager.get_telemetry())

@app.route('/api/mode', methods=['GET', 'POST'])
def api_mode():
    if request.method == 'POST':
        data = request.get_json(silent=True) or {}
        new_mode = data.get('mode', '').lower()
        if new_mode in ("all", "detection", "detc", "fence", "vir", "face", "anpr"):
            camera_manager.mode = new_mode
            return jsonify({"status": "success", "mode": camera_manager.mode})
        return jsonify({"error": f"Invalid mode. Choose from: all, detection, fence, face, anpr"}), 400
    return jsonify({"mode": camera_manager.mode})

@app.route('/api/alerts', methods=['GET'])
def api_alerts():
    return jsonify({"alerts": camera_manager.alerts})

@app.route('/api/camera/power', methods=['GET', 'POST'])
def api_camera_power():
    if request.method == 'POST':
        data = request.get_json(silent=True) or {}
        if 'enabled' in data:
            new_state = bool(data['enabled'])
        else:
            new_state = not camera_manager.is_camera_on
        camera_manager.set_camera_power(new_state)
        return jsonify({"enabled": camera_manager.is_camera_on, "status": camera_manager.status})
    return jsonify({"enabled": camera_manager.is_camera_on, "status": camera_manager.status})

@app.route('/api/shutdown', methods=['POST', 'GET'])
def api_shutdown():
    print("[SERVER] Shutdown requested by Flutter app. Releasing hardware...")
    try:
        camera_manager.is_running = False
        if camera_manager.cap is not None:
            camera_manager.cap.release()
            print("[SERVER] Camera hardware successfully released.")
    except Exception as e:
        print(f"[SERVER] Error releasing camera: {e}")
    
    def kill_soon():
        time.sleep(0.3)
        os._exit(0)
    threading.Thread(target=kill_soon, daemon=True).start()
    return jsonify({"status": "shutdown_initiated", "message": "Backend server is terminating"})

if __name__ == '__main__':
    print("[SERVER] Starting BorderGuard AI Backend on http://127.0.0.1:5000 ...")
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)
