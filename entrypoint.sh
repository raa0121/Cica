#!/bin/bash
git clone https://github.com/miiton/Cica.git tmp
cp -a tmp/.git Cica/
cd Cica
git checkout -- .
curl -L https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.zip -o hack.zip
unar hack.zip
cp ttf/* ./sourceFonts/
curl -LO https://osdn.jp/downloads/users/8/8598/rounded-mgenplus-20150602.7z
unar rounded-mgenplus-20150602.7z
cp rounded-mgenplus-20150602/rounded-mgenplus-1m-regular.ttf ./sourceFonts
cp rounded-mgenplus-20150602/rounded-mgenplus-1m-bold.ttf ./sourceFonts
curl -L https://github.com/googlei18n/noto-emoji/raw/master/fonts/NotoEmoji-Regular.ttf -o sourceFonts/NotoEmoji-Regular.ttf
curl -LO http://sourceforge.net/projects/dejavu/files/dejavu/2.37/dejavu-fonts-ttf-2.37.zip
unar dejavu-fonts-ttf-2.37.zip
mv dejavu-fonts-ttf-2.37/ttf/DejaVuSansMono.ttf ./sourceFonts/
mv dejavu-fonts-ttf-2.37/ttf/DejaVuSansMono-Bold.ttf ./sourceFonts/
fontforge -lang=py -script cica.py
