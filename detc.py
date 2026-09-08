# human_vehicle_animal_detection.py
from ultralytics import YOLO
import cv2

# Load YOLOv11 model
model = YOLO("yolo11n.pt")

# Open webcam or CCTV stream
cap = cv2.VideoCapture(0)  # replace with RTSP/HTTP stream if needed

# Allowed classes: person + vehicles + animals
allowed_classes = [
    0,   # person
    1, 2, 3, 5, 7,   # bicycle, car, motorcycle, bus, truck
    16, 17, 18, 19, 20, 21, 22, 23  # bird, cat, dog, horse, sheep, cow, elephant, bear
]

while True:
    ret, frame = cap.read()
    if not ret:
        break

    # Run YOLOv11 inference
    results = model(frame)

    # Annotate detections
    annotated = frame.copy()
    for box in results[0].boxes:
        cls = int(box.cls[0])  # class ID
        if cls in allowed_classes:
            x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
            label = results[0].names[cls]
            cv2.rectangle(annotated, (int(x1), int(y1)), (int(x2), int(y2)), (0,255,0), 2)
            cv2.putText(annotated, label, (int(x1), int(y1)-10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0,255,0), 2)

    cv2.imshow("Human, Vehicle & Animal Detection", annotated)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
