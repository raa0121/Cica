# プログラミング用フォント Cica

![on MacVim](screenshots/ss1.png)

## ダウンロード

[リリースページ](https://github.com/miiton/Cica/releases/latest)にビルド済みのフォントを配置しています。

## 概要

Ricty生成スクリプトをフォークして生成したプログラミング用の等幅フォントです。
[Ubuntu Mono](http://font.ubuntu.com/) と
[Rounded Mgen+](http://jikasei.me/font/rounded-mgenplus/) を合成して少し調整しています。

派生として [Noto Emoji](https://www.google.com/get/noto/) と
[DevIcon](http://devicon.fr/) を追加合成したものを CicaE ファミリーとして生成しました。

```
o CicaE
|\
* * DevIcon
|\
| * Noto Emoji
|
o Cica
|\
* * Ubuntu Mono
 \
  * Rounded Mgen+
  |\
  | * 源の角ゴシック
  |
  * Rounded M+
  |
  * M+ OUTLINE FONTS
```

## Rictyからの変更点

* 英数字に Ubutnu Mono を使用しています
* それ以外の文字に Rounded Mgen+ ゴシック を使用しています
* 非HiDPI（非Retina）のWindowsでも文字が欠けません
* [Powelineパッチ](https://github.com/powerline/fontpatcher)適用済みです


## バリエーション

| ファイル名        | 説明                                 |
| ----              | ----                                 |
| Cica-Regular.ttf  | 通常                                 |
| Cica-Bold.ttf     | 太字                                 |
| CicaE-Regular.ttf | Cica-Regularに絵文字類を合成したもの |
| CicaE-Bold.ttf    | Cica-Boldに絵文字類を合成したもの    |

※CicaEファミリーのPowerlineやDevIconのグリフは [pua.html](pua.html) で一覧が確認出来ます。

## ビルド手順

2016-10-12時点、Ubuntu 16.04 にて

```sh
sudo apt-get -y install fontforge unar
git clone --recursive git@github.com:miiton/Cica.git
wget http://font.ubuntu.com/download/ubuntu-font-family-0.83.zip
unar ubuntu-font-family-0.83.zip
cp ubuntu-font-family-0.83/UbuntuMono-R.ttf ./sourceFonts
wget https://osdn.jp/downloads/users/8/8598/rounded-mgenplus-20150602.7z
unar rounded-mgenplus-20150602.7z
cp rounded-mgenplus-20150602/rounded-mgenplus-1m-regular.ttf ./sourceFonts
cp rounded-mgenplus-20150602/rounded-mgenplus-1m-bold.ttf ./sourceFonts
wget https://github.com/konpa/devicon/raw/master/fonts/devicon.ttf -O ./sourceFonts/devicon.ttf
mkdir tmp
mkdir Cica
./cica_generator.sh auto
```

[fontforge のバージョンが古いと正常に動作しません #6](https://github.com/miiton/Cica/issues/6)

```
% fontforge --version

Copyright (c) 2000-2012 by George Williams.
 Executable based on sources from 14:57 GMT 31-Jul-2012-ML.
 Library based on sources from 14:57 GMT 31-Jul-2012.
fontforge 20120731
libfontforge 20120731-ML
```


# ライセンス

* [LICENSE.txt](LICENSE.txt)
