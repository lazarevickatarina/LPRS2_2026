#!/bin/bash


sudo apt -y install \
    python3-virtualenv \
    imagemagick \
    python3-pip \
    ipython3

PREFIX=$HOME/.local/opt/YOLO/v8/
mkdir -p $PREFIX
virtualenv $PREFIX

source $PREFIX/bin/activate

pip install labelImg
pip install ultralytics
pip install lap==0.5.12


sudo ubuntu-drivers list
sudo ubuntu-drivers install
sudo apt -y install nvidia-utils-570