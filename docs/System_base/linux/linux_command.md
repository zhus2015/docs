# Linux常用命令

## Curl

curl  -o /dev/null -s -w %{time_namelookup}::%{time_connect}::%{time_starttransfer}::%{time_total}::%{speed_download}"\n" -d  "param1=value1&param2=value2" "http://127.0.0.1:8081/detail"

-  -w：按照后面的格式写出rt
- time_namelookup：DNS 解析域名[www.taobao.com]的时间 
- time_commect：client和server端建立TCP 连接的时间
- time_starttransfer：从client发出请求；到web的server 响应第一个字节的时间
- time_total：client发出请求；到web的server发送会所有的相应数据的时间
- speed_download：下周速度 单位 byte/s



设置POST Header

```shell
-H "Accept: application/json" -H "Content-type: application/json" -X POST -d 
```