import cv2
import os

# Putanje
input_folder = 'data/images/train'
output_folder = 'data/images/train_clean'
os.makedirs(output_folder, exist_ok=True)

# KOORDINATE KOJE TREBA DA PRILAGODIŠ
# Na osnovu tvoje slike, probaj ove vrednosti:
# frame[y1:y2, x1:x2]
Y_START, Y_END = 85, 185
X_START, X_END = 40, 280 # Prilagodi ove X koordinate da uhvatiš samo jednu traku

files = [f for f in os.listdir(input_folder) if f.startswith("jabuka_") and f.endswith(".jpg")]

print(f"Započinjem obradu {len(files)} slika...")

for filename in files:
    img_path = os.path.join(input_folder, filename)
    img = cv2.imread(img_path)
    
    if img is not None:
        # Isecanje
        cropped = img[Y_START:Y_END, X_START:X_END]
        
        # Čuvanje
        cv2.imwrite(os.path.join(output_folder, filename), cropped)
    else:
        print(f"Greška pri čitanju: {filename}")

print(f"Spremno! Sve isečene slike su u: {output_folder}")