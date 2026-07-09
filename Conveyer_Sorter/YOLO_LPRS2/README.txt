# Garbage Sort - Sistem za detekciju i sortiranje jabuka pomocu YOLOv8 AI

Ovaj projekat predstavlja sistem za automatizovano prepoznavanje i klasifikaciju jabuka na transportnoj traci (Conveyer Sorter) . Sistem koristi kompjuterski vid i **YOLOv8** model za detekciju kvaliteta plodova u realnom vremenu.

Model je obucen da prepoznaje tri klase (definisane u `dataset.yaml`):
- `0: zrela_jabuka`
- `1: trulez`
- `2: nezrela`

---

## Struktura projekta i skripti

Projekat sadrzi skripte za kompletan razvoj – od prikupljanja podataka do testiranja modela:

1. **`save_images.py`** Sluzi za sakupljanje sirovih podataka sa kamere. Prikazuje punu sliku i pritiskom na taster **'s'** cuva originalni frejm u `data/images/train` sa automatskim inkrementalnim brojanjem (`jabuka_0.jpg`, `jabuka_1.jpg`...).

2. **`isecanje.py`** Uzima sve sacuvane slike iz `data/images/train`, iseca definisanu regiju od interesa (ROI) koja obuhvata samo transportnu traku (`Y_START`, `Y_END`, `X_START`, `X_END`), i cuva ociscene slike u `data/images/train_clean` spremne za anotaciju i trening.

3. **`detect_realtime.py`** Inicijalna skripta za testiranje osnovnog pre-trained `yolov8n.pt` modela u realnom vremenu preko eksterne kamere.

4. **`test_model.py`** Pokrece tvoj obuceni model (`best.pt`) u realnom vremenu na video strimu sa kamere, primenjujuci isecanje koordinata trake u hodu, kako bi se detekcija vrsila iskljucivo na ROI regiji.

---

## Treniranje modela (Google Colab)

S obzirom na to da je dataset slika preveliki za direktno push-ovanje na GitHub, obuka modela se vrsi na Google Colab platformi uz koriscenje GPU ubrzanja.

Konfiguracija skupa podataka je definisana u fajlu **`dataset.yaml`**:
```yaml
path: /content/GarbageSort_AI/data  # Putanja na Colab-u nakon raspakivanja
train: images/train_clean
val: images/val

names:
  0: zrela_jabuka
  1: trulez
  2: nezrela
---
## Hardverska realizacija - nije implementirano 

Sistem je povezan sa fizickom transportnom trakom gde se upravljanje i ocitavanje stanja vrsi putem GPIO pinova na Raspberry Pi ploci:
- **GPIO 22, 23, 24** – Koriste se na nivou softvera kao limit prekidaci (limit switches) za detekciju pozicije predmeta na traci.
