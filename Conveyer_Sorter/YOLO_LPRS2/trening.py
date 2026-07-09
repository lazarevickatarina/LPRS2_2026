
import os
from ultralytics import YOLO
from roboflow import Roboflow

#preuzimanje podataka sa roboflow
#podaci koji se mijenjaju
rf = Roboflow(api_key="VPYie6fHxhir57xMVi22")
project = rf.workspace("garbagesortapples").project("apples-zwrgh")
version = project.version(3)
dataset = version.download("yolov8")

#ucitavanje pocetnog modela
model = YOLO('yolov8s.pt')

putanja_do_yaml = dataset.location + '/data.yaml'

#trening na preuzetim podacima
rezultati_treninga = model.train(
    data=putanja_do_yaml,
    epochs=25,
    imgsz=240,
    plots=True
)

#ocjenjivanje uspjesnosti modela
metrike = model.val()

#test na novim slikama
putanja_do_test_slika = dataset.location + '/test/images'

predikcije = model.predict(
    source=putanja_do_test_slika,
    conf=0.25,
    save=True
)
