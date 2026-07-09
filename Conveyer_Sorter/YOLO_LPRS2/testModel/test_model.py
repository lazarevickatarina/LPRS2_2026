from ultralytics import YOLO
import cv2

model = YOLO('best.pt') #ucitavam model


cap = cv2.VideoCapture(2)

# Koordinate isecanja kao  za trening
Y_START, Y_END = 85, 185
X_START, X_END = 40, 280

print("Dijagnoza preko kamere aktivirana. Pritisni 'q' za izlaz.")

while True:
    ret, frame = cap.read()
    if not ret:
        print("Greška: Ne mogu da pristupim kameri.")
        break
    
    #isecanje slike
    cropped_frame = frame[Y_START:Y_END, X_START:X_END]
    
    # Detekcija na isecenom frejmu
    results = model.predict(source=cropped_frame, conf=0.1, verbose=False)
    
    #  Iscrtavanje kvadrata
    annotated_frame = results[0].plot()
    
    # Prikaz
    cv2.imshow("Garbage Sort uzivo", annotated_frame)
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()