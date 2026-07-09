import cv2
import os

# Putanje
folder_path = 'data/images/train'
os.makedirs(folder_path, exist_ok=True)

# SIGURNA LOGIKA ZA BROJANJE
files = [f for f in os.listdir(folder_path) if f.startswith("jabuka_") and f.endswith(".jpg")]
if files:
    numbers = [int(f.split('_')[1].split('.')[0]) for f in files]
    count = max(numbers) + 1
else:
    count = 0

cap = cv2.VideoCapture(2)

print("--------------------------------------------------")
print(f"Sistem spreman. Sledeća slika: jabuka_{count}.jpg")
print("Pritisni 's' za snimanje, 'q' za izlaz.")
print("--------------------------------------------------")

while True:
    ret, frame = cap.read()
    if not ret:
        print("Greška: Ne mogu da uhvatim frejm.")
        break

    # Prikazujemo punu, originalnu sliku
    cv2.imshow("Sakupljanje podataka - GarbageSort (Original)", frame)
   
    key = cv2.waitKey(1) & 0xFF
    
    if key == ord('s'):
        # Snimamo pun frejm bez isecanja
        filename = os.path.join(folder_path, f"jabuka_{count}.jpg")
        cv2.imwrite(filename, frame)
        print(f"Sačuvano: {filename}")
        count += 1
    elif key == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()