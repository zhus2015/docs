本文转载于ops-coffee大佬的公众号，如有版权问题，请联系予以删除



**一个站点配置多个域名**

```
server {   
	listen    80;   
	server_name ops-coffee.cn b.ops-coffee.cn; 
}
```

  server_name 后跟多个域名即可，多个域名之间用空格分隔。

**一个服务配置多个站点**

```
server {   
	listen    80;   
	server_name a.ops-coffee.cn; 
    
	location / {     
		root /home/project/pa;     
		index index.html;   
	} 
}

server {   
	listen    80;   
	server_name ops-coffee.cn b.ops-coffee.cn;   
	location / {     
		root /home/project/pb;     
		index index.html;   
	} 
} 

server {   
	listen    80;   
	server_name c.ops-coffee.cn;   
	location / {     
		root /home/project/pc;     
		index index.html;   
	} 
}
```

基于Nginx虚拟主机配置实现，Nginx有三种类型的虚拟主机

**基于IP的虚拟主机：** 需要你的服务器上有多个地址，每个站点对应不同的地址，这种方式使用的比较少

**基于端口的虚拟主机：** 每个站点对应不同的端口，访问的时候使用ip:port的方式访问，可以修改listen的端口来使用

**基于域名的虚拟主机：** 使用最广的方式，上边例子中就是用了基于域名的虚拟主机，前提条件是你有多个域名分别对应每个站点，server_name填写不同的域名即可



**nginx添加账号密码验证**

```
server {   
	location / {     
		auth_basic "please input user&passwd";     
		auth_basic_user_file key/auth.key;   
	} 
}
```

有很多服务通过nginx访问，但本身没有提供账号认证的功能，就可以通过nginx提供的authbase账号密码认证来实现，可以用以下脚本来生成账号的密码

```
# cat pwd.pl 
#!/usr/bin/perl 
use strict; 
my $pw=$ARGV[0] ; 
print crypt($pw,$pw)." 
"; 
使用方法： 
# perl pwd.pl ops-coffee.cn 
opf8BImqCAXww 
# echo "admin:opf8BImqCAXww" > key/auth.key
```

**nginx开启列目录**

当你想让nginx作为文件下载服务器存在时，需要开启nginx列目录

```
server {   
    location download {     
        autoindex on;     
        autoindex_exact_size off;     
        autoindex_localtime on;   
	} 
}
```

**autoindex_exact_size：** 为on(默认)时显示文件的确切大小，单位是byte；改为off显示文件大概大小，单位KB或MB或GB

**autoindex_localtime：** 为off(默认)时显示的文件时间为GMT时间；改为on后，显示的文件时间为服务器时间

默认当访问列出的txt等文件时会在浏览器上显示文件的内容，如果你想让浏览器直接下载，加上下边的配置

```
if ($request_filename ~* ^.*?.(txt|pdf|jpg|png)$) {   
	add_header Content-Disposition 'attachment'; 
	}
```



**配置默认站点**

server {   listen 80 default; }

当一个nginx服务上创建了多个虚拟主机时默认会**从上到下**查找，如果匹配不到虚拟主机则会返回**第一个**虚拟主机的内容，如果你想指定一个默认站点时，可以将这个站点的虚拟主机放在配置文件中第一个虚拟主机的位置，或者在这个站点的虚拟主机上配置listen default。



**不允许通过IP访问**

```
server {   
	listen    80 default;   
	server_name _;   
	return   404; 
}
```

可能有一些未备案的域名或者你不希望的域名将服务器地址指向了你的服务器，这时候就会对你的站点造成一定的影响，需要禁止IP或未配置的域名访问，我们利用上边所说的default规则，将默认流量都转到404去。

上边这个方法比较粗暴，当然你也可以配置下所有未配置的地址访问时直接301重定向到你的网站去，也能为你的网站带来一定的流量。

```
server {   
	rewrite ^/(.*)$ https://ops-coffee.cn/$1  permanent; 
}
```

**直接返回验证文件**

```
location = /XDFyle6tNA.txt {   
	default_type text/plain;   
	return 200 'd6296a84657eb275c05c31b10924f6ea'; 
}
```

很多时候微信等程序都需要我们放一个txt的文件到项目里以验证项目归属，我们可以直接通过上边这种方式修改nginx即可，无需真正的把文件给放到服务器上。

**nginx配置upstream反向代理**

```
http {   
	...   
	upstream tomcats {     
		server 192.168.106.176 weight=1;     
		server 192.168.106.177 weight=1;   
	}
    
server {     
	location /ops-coffee/ {       
		proxy_pass http://tomcats;        
		proxy_set_header Host $host;       
		proxy_set_header X-Real-IP $remote_addr;       
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;       
		proxy_set_header X-Forwarded-Proto $scheme;     
		}   
	} 
}
```

稍不注意可能会落入一个proxy_pass加杠不加杠的陷阱，这里详细说下proxy_pass http://tomcats与proxy_pass http://tomcats/的区别：

虽然只是一个/的区别但结果确千差万别。分为以下两种情况：

1. 目标地址中不带uri（proxy_pass http://tomcats）。此时新的目标url中，匹配的uri部分不做修改，原来是什么就是什么。

```
location /ops-coffee/ {   
	proxy_pass http://192.168.106.135:8181; 
}
```

http://domain/ops-coffee/  -->   http://192.168.106.135:8181/ops-coffee/

http://domain/ops-coffee/action/abc  -->   http://192.168.106.135:8181/ops-coffee/action/abc

2. 目标地址中带uri（proxy_pass http://tomcats/，/也是uri）,此时新的目标url中，匹配的uri部分将会被修改为该参数中的uri。

```
location /ops-coffee/ {   
	proxy_pass http://192.168.106.135:8181/; 
}
```

http://domain/ops-coffee/  -->   http://192.168.106.135:8181

http://domain/ops-coffee/action/abc  -->   http://192.168.106.135:8181/action/abc



**nginx upstream开启keepalive**

```
upstream tomcat {   
	server ops-coffee.cn:8080;   
	keepalive 1024; 
} 

server {   
	location / {     
		proxy_http_version 1.1;     
		proxy_set_header Connection "";     
		proxy_pass http://tomcat;   
	} 
}
```

nginx在项目中大多数情况下会作为反向代理使用，例如nginx后接tomcat，nginx后接php等，这时我们开启nginx和后端服务之间的keepalive能够减少频繁创建TCP连接造成的资源消耗，配置如上

**keepalive：** 指定每个nginxworker可以保持的最大连接数量为1024，默认不设置，即nginx作为client时keepalive未生效

**proxy_http_version 1.1：** 开启keepalive要求HTTP协议版本为HTTP 1.1

**proxy_set_header Connection ""：** 为了兼容老的协议以及防止http头中有Connection close导致的keepalive失效，这里需要及时清掉HTTP头部的Connection

**404自动跳转到首页**

server {   location / {    error_page 404 = @ops-coffee;   }   location @ops-coffee {    rewrite .* / permanent;   } }

网站出现404页面不是特别友好，我们可以通过上边的配置在出现404之后给自动跳转到首页去。

**301跳转设置：**

```
server { 
	listen 80; 
	server_name abc.com; 
	rewrite ^/(.*) http://edf.com/$1 permanent; 
	access_log off; 
}
```

**302跳转设置：**

```
server { 
	listen 80; 
	server_name abc.com; 
	rewrite ^/(.*) http://edf.com/$1 redirect; 
	access_log off; 
}
```

**nginx 301 302跳转的详细说明文档**

server { server_name test.com; rewrite ^/(.*) http://www.test1.com/$1 permanent; }

last – 基本上都用这个Flag。

break – 中止Rewirte，不在继续匹配

redirect – 返回临时重定向的HTTP状态302

permanent – 返回永久重定向的HTTP状态301

Nginx的重定向用到了Nginx的HttpRewriteModule，下面简单解释以下如何使用的方法：

rewrite命令

nginx的rewrite相当于apache的rewriterule(大多数情况下可以把原有apache的rewrite规则加上引号就可以直接使用)，它可以用在server,location 和IF条件判断块中,命令格式如下：

rewrite 正则表达式 替换目标 flag标记

flag标记可以用以下几种格式：

last – 基本上都用这个Flag。

break – 中止Rewirte，不在继续匹配

redirect – 返回临时重定向的HTTP状态302

permanent – 返回永久重定向的HTTP状态301