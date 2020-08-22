# 实用脚本



remote_sh.sh

expect需要单独安装expect软件包

```sh
#!/bin/bash
##password 服务器密码
password="redhat"
for ip in `cat ip.list`
do
  echo $ip
  /usr/bin/expect << EOF
  spawn /usr/bin/ssh root@$ip

  expect {
   "yes/no" { send "yes\r"}
  }

  expect {
    "password:" { send "${password}\r" }
  }

  expect "]*"
  send "curl -sSL http://10.4.7.45/init.sh | sh\r"
  expect "]*"
  send "exit\r"
  expect eof
EOF
done
```



init.sh

```sh
#!/bin/bash
download_host=10.4.7.45

function ssh_authorized() {
  [ -d /root/.ssh ] || mkdir /root/.ssh
  curl -o /root/.ssh/authorized_keys http://$download_host/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
}

function install_zabbix() {
  rpm -ivh http://$download_host/zabbix-agent-5.0.2-1.el7.x86_64.rpm
  sed -i 's/Server=localhost/Server=10.10.10.10/g' /etc/zabbix/zabbix_agentd.conf
  systemctl enable zabbix-agent && systemctl start zabbix-agent
}

function main() {
  ssh_authorized
  #install_zabbix
}
main
```

