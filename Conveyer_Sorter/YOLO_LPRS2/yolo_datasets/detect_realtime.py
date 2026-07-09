import cv2
from ultralytics import YOLO


model = YOLO('models/yolov8n.pt') # Učitavamo model koji smo stavili u folder models


cap = cv2.VideoCapture(2) # Pokrećemo kameru - 0 za kameru an laptopu 

print("Kamera je spremna! Pritisni 'q' na tastaturi kada želiš da izađeš.")

while True:
    ret, frame = cap.read() #hvatamo sliku i smestamo je u frame
    if not ret:
        break

    # Ovde model radi analizu slike (detekciju)
    results = model(frame, verbose=False)
    #results = model.predict(source=frame, conf=0.15, imgsz=320, verbose=False)

    # Ovo iscrtava pravougaonike oko detektovanih objekata
    annotated_frame = results[0].plot()

    # Prikazuje sliku sa detekcijama
    cv2.imshow("GarbageSort AI - Detekcija", annotated_frame)

    # Ako pritisneš 'q', gasi se kamera
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()