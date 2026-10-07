# pyrefly: ignore [missing-import]
import cv2
# pyrefly: ignore [missing-import]
import pytesseract
from ultralytics import YOLO

# ✅ Configure Tesseract path
pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
# Load YOLOv11 model
model = YOLO("yolo11n.pt")

cap = cv2.VideoCapture(0)  # webcam or CCTV stream

vehicle_classes = [1, 2, 3, 5, 7]  # bicycle, car, motorcycle, bus, truck

while True:
    ret, frame = cap.read()
    if not ret:
        break

    results = model(frame)
    annotated = frame.copy()

    plate_texts = []  # collect all detected plates

    for box in results[0].boxes:
        cls = int(box.cls[0])
        if cls in vehicle_classes:
            x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
            label = results[0].names[cls]

            cv2.rectangle(annotated, (int(x1), int(y1)), (int(x2), int(y2)), (0,255,0), 2)
            cv2.putText(annotated, label, (int(x1), int(y1)-10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0,255,0), 2)

            # OCR with error handling
            plate_roi = frame[int(y1):int(y2), int(x1):int(x2)]
            try:
                text = pytesseract.image_to_string(plate_roi, config="--psm 7")
                if text.strip():
                    plate_texts.append(text.strip())
            except Exception as e:
                print("OCR error:", e)

    # Show all detected plate numbers in the top-right corner
    y_offset = 30
    for plate in plate_texts:
        cv2.putText(annotated, f"Plate: {plate}", (annotated.shape[1]-300, y_offset),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255,255,0), 2)
        y_offset += 30

    cv2.imshow("Vehicle Detection & ANPR", annotated)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
