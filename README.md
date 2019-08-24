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
