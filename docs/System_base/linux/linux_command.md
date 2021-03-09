# Linux常用命令

## Curl

### curl执行POST

curl  -o /dev/null -s -w %{time_namelookup}::%{time_connect}::%{time_starttransfer}::%{time_total}::%{speed_download}"\n" -d  "param1=value1&param2=value2" "http://127.0.0.1:8081/detail"

-  -w：按照后面的格式写出rt
- time_namelookup：DNS 解析域名[www.taobao.com]的时间 
- time_commect：client和server端建立TCP 连接的时间
- time_starttransfer：从client发出请求；到web的server 响应第一个字节的时间
- time_total：client发出请求；到web的server发送会所有的相应数据的时间
- speed_download：下周速度 单位 byte/s



设置POST Header

```shell
-H "Accept: application/json" 
-H "Content-type: application/json" 
-X POST -d 
```

### Curl下载文件

使用方法

```shell
curl -O http://10.7.201.94/rpm/node_exporter-1.0.2-2.x86_64.rpm
或
curl -o node_export.rpm http://10.7.201.94/rpm/node_exporter-1.0.2-2.x86_64.rpm
```

O：可以直接输出文件，如果文件名字重复会直接覆盖文件

o：必须指定文件名称



### Curl执行远程脚本

获取脚本并在本地服务器上执行

```
curl -fsSL http://10.243.32.110:90/openssh.sh | bash
```

