from ultralytics import YOLO
import cv2

model = YOLO('best.pt')


print("--- DIJAGNOZA ---")
print("Model prepoznaje ove klase:", model.names)


#cap = cv2.VideoCapture(2)
print("Uključi kameru, čekam... (pritisni 'q' za izlaz)")
i = 89

while i < 412:
    #ret, frame = cap.read()
    putanjaa= "/home/katarina/LPRS2_2026/Conveyer_Sorter/YOLO_LPRS2/yolo_datasets/data/images/train_clean/jabuka_" + str(i) + ".jpg"
    frame = cv2.imread(putanjaa)
    i+=1
   # if not ret: break
    

    results = model.predict(source=frame, conf=0.1, verbose=False)
    
 
    for r in results:
        if len(r.boxes) > 0:
            print(f"Pronađeno {len(r.boxes)} objekata!")
            for box in r.boxes:
                klasa_id = int(box.cls[0])
                print(f"Klasa ID: {klasa_id}, Naziv: {model.names[klasa_id]}, Poverenje: {box.conf[0]:.2f}")
    
    annotated_frame = results[0].plot()
    cv2.imshow("Katarina - Dijagnoza", annotated_frame)
    if cv2.waitKey(20) & 0xFF == ord('q'):
        break

#cap.release()
cv2.destroyAllWindows()