# clinkのインストール
## ダウンロード
https://github.com/mridgers/clink/releases
.zipばんをっかったほーがフォルダがゎかりゃすくできる
`C:\clink\` に展開することにする

## autorunを設定する
cmd.exeをひらぃて、

```
C:\clink\clink_x64.exe autorun install --profile %userprofile%\dotfiles\clink ^& %userprofile%\dotfiles\init.cmd
```

exeの名前ゎ32/64bitかでちがぅ
なんかclinkゎ設定ファイルがsymlinkだとバグることがぁるっぽぃから、
dotfilesのディレクトリを直接profileディレクトリとしてっかぅ

init.cmdゎclinkにゎぁんま関係なぃんだけど、
このファイルでaliasとかを設定する、.zshrcみたぃなもん
