# virtual_fence.py
import cv2
import numpy as np
from ultralytics import YOLO

model = YOLO("yolo11n.pt")
cap = cv2.VideoCapture(0)

# Define virtual fence polygon
virtual_fence = [(100,100), (500,100), (500,400), (100,400)]

def check_intrusion(x, y):
    return cv2.pointPolygonTest(np.array(virtual_fence, np.int32), (x,y), False) >= 0

while True:
    ret, frame = cap.read()
    if not ret:
        break

    results = model(frame)
    annotated = results[0].plot()

    for box in results[0].boxes:
        x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
        cx, cy = int((x1+x2)/2), int((y1+y2)/2)

        if check_intrusion(cx, cy):
            cv2.putText(annotated, "INTRUSION!", (cx, cy),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0,0,255), 3)

    cv2.polylines(annotated, [np.array(virtual_fence, np.int32)], True, (255,0,0), 2)
    cv2.imshow("Virtual Fence Intrusion", annotated)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
