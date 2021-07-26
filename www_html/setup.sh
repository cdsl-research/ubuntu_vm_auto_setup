#!/bin/bash 

LOGFILE=/tmp/setup.log
# You must set 'LOGFILE'
readonly PROCNAME=${0##*/}
function log() {
  local fname=${BASH_SOURCE[1]##*/}
  echo -e "$(date '+%Y-%m-%dT%H:%M:%S') ${PROCNAME} (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $@" | tee -a ${LOGFILE}
}

# sudoをパスワード無し
log "Disable password input on sudo"
sudo sed -e 's/%sudo\sALL=(ALL:ALL) /&NOPASSWD:/' /etc/sudoers | sudo EDITOR=tee visudo >/dev/null

# Zabbix Agentをインストール
# log "Install zabbix-agent"
# wget https://repo.zabbix.com/zabbix/4.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.2-1+bionic_all.deb
# sudo dpkg -i zabbix-release_4.2-1+bionic_all.deb
# sudo apt update -y
# sudo apt install -y zabbix-agent
# sudo cp /etc/zabbix/zabbix_agentd.conf{,.org}
# cat <<EOF | sudo tee /etc/zabbix/zabbix_agentd.conf
# PidFile=/var/run/zabbix/zabbix_agentd.pid
# LogFile=/var/log/zabbix/zabbix_agentd.log
# LogFileSize=0
# Server=192.168.100.9
# ServerActive=192.168.100.9:10051
# HostnameItem=system.hostname
# HostMetadata=CDSL-MonitoredOnZbx
# Include=/etc/zabbix/zabbix_agentd.d/*.conf
# EOF
# sudo systemctl restart zabbix-agent
# sudo systemctl enable zabbix-agent

# Syslogの設定
# log "Add syslog server"
# sudo mkdir /etc/rsyslog/
# sudo bash -c 'echo "*.* @@elasticsearch-edge.a910.tak-cslab.org:5000" >> /etc/rsyslog.d/50-default.conf'
# sudo systemctl restart rsyslog

# SSHログレベルの変更(ログインを記録)
log "Change ssh log level"
sudo sed -i 's/#LogLevel INFO/LogLevel VERBOSE/g' /etc/ssh/sshd_config
sudo systemctl restart sshd

# スクリプト自身を削除
log "Remove script myself"
sudo rm -f /etc/rc.local

# ホスト名を設定 
log "Set hostname"
sudo apt install -y dnsutils
MYIP=$(hostname -I | grep -o 192.168.100.[0-9]*)
MYHOST=$(dig +short @anchor-2.a910.tak-cslab.org -p 30053 -x $MYIP | grep local | cut -f 1 -d '.')
log "ip=$MYIP, hostname=$MYHOST"
[[ $MYHOST == '' ]] || sudo hostnamectl set-hostname $MYHOST 
[[ $MYHOST == '' ]] || sudo netplan apply

# 通知
sudo apt install -y curl
SLACK_WEBHOOK_URL='https://hooks.slack.com/services/XXX/YYY/ZZZ'
SLACK_MESSAGE="[Finish] VM \``hostname`\` have created."
curl -X POST --data-urlencode 'payload={"text": "'"${SLACK_MESSAGE}"'"}' ${SLACK_WEBHOOK_URL} &> /dev/null

# LDAPの設定
sudo apt update
curl -fsSL https://repo.stns.jp/scripts/apt-repo.sh | sh
sudo apt install -y libnss-stns-v2 cache-stnsd
sudo cp /etc/stns/client/stns.conf{,.org}
cat <<EOF | sudo tee /etc/stns/client/stns.conf
api_endpoint = "http://192.168.100.13:1104/v1"
[cached]
enable = true
EOF
sudo service cache-stnsd restart
sudo systemctl enable cache-stnsd

sudo sed -i "s/passwd:         compat systemd/passwd:         compat stns systemd/" /etc/nsswitch.conf
sudo sed -i "s/group:          compat systemd/group:         compat stns systemd/" /etc/nsswitch.conf
sudo sed -i "s/shadow:         compat/shadow:         compat stns/" /etc/nsswitch.conf

sudo sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/" /etc/ssh/sshd_config
sudo sed -i "s|#AuthorizedKeysCommand none|AuthorizedKeysCommand /usr/lib/stns/stns-key-wrapper|" /etc/ssh/sshd_config
sudo sed -i "s/#AuthorizedKeysCommandUser nobody/AuthorizedKeysCommandUser root/" /etc/ssh/sshd_config
sudo service sshd restart

echo 'session    required     pam_mkhomedir.so skel=/etc/skel/ umask=0022' | sudo tee -a /etc/pam.d/sshd

sudo sed -i '$ a %cdsl   ALL=(ALL:ALL) NOPASSWD:NOPASSWD:ALL' /etc/sudoers
