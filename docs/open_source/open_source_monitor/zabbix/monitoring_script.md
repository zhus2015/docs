# Zabbix监控脚本



## TCP连接数统计



```shell
#!/bin/bash

function tcp_conn_status(){
    TCP_STAT=$1
    #TCP_STAT=`echo $TCP_STAT | tr "[:lower:]" "[:upper:]"`
    TCP_STAT=`echo $TCP_STAT | tr 'a-z' 'A-Z'`
    ss -ant | awk 'NR>1 {++s[$1]} END {for(k in s) print k,s[k]}' > /tmp/tcp_status_monitoring.txt
    TCP_NUM=$(grep "$TCP_STAT" /tmp/tcp_status_monitoring.txt | cut -d ' ' -f2)
    if [ -z $TCP_NUM ];then
        TCP_NUM=0
    fi
    echo $TCP_NUM
}

function main(){
    case $1 in
        tcp_status)
            tcp_conn_status $2;
            ;;
        *)
         echo "请输出正确的参数"
    esac
}

main $1 $2
```

