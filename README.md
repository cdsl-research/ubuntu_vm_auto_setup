# ubuntu_vm_auto_setup

Ubuntu 18.04のVMを自動セットアップするツール/設定ファイル

## 使い方

### 以下からISOをダウンロード

```shell
wget http://cdimage.ubuntu.com/releases/18.04.3/release/ubuntu-18.04.3-server-amd64.iso
```

### 作業ディレクトリを作成

```shell
mkdir iso_mnt work_iso
```

### ISOファイルをマウント

```shell
sudo mount -t iso9660 -o loop,ro ./ubuntu-18.04-server-amd64.iso ./iso_mnt
```

### ISOファイルの中身を作業ディレクトリへコピー

```shell
cp -r iso_mnt/ work_iso/
```

### 設定ファイルを編集

```shell
vi work_iso/isolinux/isolinux.cfg
```

参照: [isolinux.cfg ファイルの編集](https://qiita.com/wnoguchi/items/9a9092dd23eea88d435f#isolinuxcfg-ファイルの編集)

設定ファイルを配置するパスを状況にあわせて書き換える.

### ISOを作成する.

```shell
sudo genisoimage -N -J -R -D -V "PRESEED.UB1804" -o ubuntu-18.04.4-server-amd64-preseed."$(date +%Y%m%d.%H%M%S)".iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table work_iso/

```

### 設定ファイルをNginxへ配置

isolinux.cfgで指定したサーバーで設定ファイルをhttpで公開する.

```shell
sudo apt -y install nginx

# var_www/ を /var/www/html/ の下へ配置
# Firewalldで80/tcpを許可
```

### ESXiでVMを作成

作成したISOをインストールメディアとして指定して起動する.

[動作の様子](https://drive.google.com/open?id=1Wxj9oQUOgfO6poKI1XvTwWGY4xBQgAyx)

## 参考

- [GPT対応のpreseedの書き方 — mkouhei's blog](https://d.palmtb.net/2012/12/14/writing_preseed_for_gpt.html)
- [PreseedでUbuntu 18.04をProvisioningした作業メモ (UEFI対応版) - Qiita](https://qiita.com/YasuhiroABE/items/135a5507b6d47363ab31)
- [[WIP]Preseed による Ubuntu Server の自動インストール入門（18.04 LTS対応版） - Qiita](https://qiita.com/wnoguchi/items/9a9092dd23eea88d435f#isolinuxcfg-%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E3%81%AE%E7%B7%A8%E9%9B%86)
