# プログラミング用フォント Cica

![on MacVim](screenshots/ss1.png)

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

# ライセンス

* [LICENSE.txt](LICENSE.txt)
