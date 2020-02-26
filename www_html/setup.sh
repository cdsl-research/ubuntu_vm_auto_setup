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
log "Install zabbix-agent"
wget https://repo.zabbix.com/zabbix/4.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.2-1+bionic_all.deb
sudo dpkg -i zabbix-release_4.2-1+bionic_all.deb
sudo apt update -y
sudo apt install -y zabbix-agent
sudo cp /etc/zabbix/zabbix_agentd.conf{,.org}
cat <<EOF | sudo tee /etc/zabbix/zabbix_agentd.conf
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=192.168.100.9
ServerActive=192.168.100.9:10051
HostnameItem=system.hostname
HostMetadata=XXXXXXXXXXXXXXXXXXX
Include=/etc/zabbix/zabbix_agentd.d/*.conf
EOF
sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent

# LDAPの設定
# TBD

# Syslogの設定
log "Add syslog server"
sudo mkdir /etc/rsyslog/
sudo bash -c 'echo "*.* @@elasticsearch-edge.a910.tak-cslab.org:5000" >> /etc/rsyslog.d/50-default.conf'
sudo systemctl restart rsyslog

# SSHログレベルの変更(ログインを記録)
log "Change ssh log level"
sudo sed -i 's/#LogLevel INFO/LogLevel VERBOSE/g' /etc/ssh/sshd_config
sudo systemctl restart sshd

# スクリプト自身を削除
log "Remove script myself"
sudo rm -f /etc/rc.local
