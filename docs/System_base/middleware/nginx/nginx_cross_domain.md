# nginx处理前后端分离跨域问题

## 配置方法一

```shell
if ($request_method = 'OPTIONS') {
    add_header 'Access-Control-Allow-Origin' '*';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
    #add_header 'Access-Control-Allow-Headers' '*';
    add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';

    add_header 'Access-Control-Max-Age' 1728000;
    add_header 'Content-Type' 'text/plain charset=UTF-8';
    add_header 'Content-Length' 0;
    return 204;
}

if ($request_method = 'POST') {
    add_header 'Access-Control-Allow-Origin' '*';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
    #add_header 'Access-Control-Allow-Headers' '*';
    add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
}

if ($request_method = 'GET') {
    add_header 'Access-Control-Allow-Origin' '*';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
    #add_header 'Access-Control-Allow-Headers' '*';
    add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
}
```



## 配置方法二

不去判断什么访问类型全部允许就是了

```shell
add_header Access-Control-Allow-Methods *;
add_header Access-Control-Max-Age 3600;
add_header Access-Control-Allow-Credentials true;
add_header Access-Control-Allow-Origin $http_origin;
add_header Access-Control-Allow-Headers $http_access_control_request_headers;
if ($request_method = OPTIONS){
    return 204;}
```

