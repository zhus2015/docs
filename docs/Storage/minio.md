# Minio存储的使用

本文档来自于官网，本人仅对部分内容进行了修改。

官网地址：https://min.io/

官方文档：https://docs.min.io/

## 简介

MinIO 是一个基于Apache License v2.0开源协议的对象存储服务。它兼容亚马逊S3云存储服务接口，非常适合于存储大容量非结构化的数据，例如图片、视频、日志文件、备份数据和容器/虚拟机镜像等，而一个对象文件可以是任意大小，从几kb到最大5T不等。

MinIO是一个非常轻量的服务,可以很简单的和其他应用的结合，类似 NodeJS, Redis 或者 MySQL。



## 安装部署

### Docker部署

#### 稳定版

```shell
Copydocker run -p 9000:9000 \
  -e "MINIO_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE" \
  -e "MINIO_SECRET_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" \
  minio/minio server /data
```

#### 尝鲜版

```shell
Copydocker run -p 9000:9000 \
  -e "MINIO_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE" \
  -e "MINIO_SECRET_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" \
  minio/minio:edge server /data
```

### 二进制部署

#### 下载二进制包

下载连接：https://dl.min.io/server/minio/release/linux-amd64/minio

#### 运行

```shell
chmod +x minio
./minio server /data
```



## 配置说明

### 配置目录

默认的配置目录是 `${HOME}/.minio`，你可以使用`--config-dir`命令行选项重写之。MinIO server在首次启动时会生成一个新的`config.json`，里面带有自动生成的访问凭据。

```
Copyminio server --config-dir /etc/minio /data
```

截止到 MinIO `RELEASE.2018-08-02T23-11-36Z` 版本, MinIO server 的配置文件(`config.json`) 被存储在通过 `--config-dir` 指定的目录或者默认的 `${HOME}/.minio` 目录。 但是从 `RELEASE.2018-08-18T03-49-57Z` 版本之后, 配置文件 (仅仅), 已经被迁移到存储后端 (存储后端指的是启动一个服务器的时候，传递给MinIO server的目录)。

您可以使用`--config-dir`指定现有配置的位置, MinIO 会迁移 `config.json` 配置到你的存储后端。 迁移成功后，你当前 `--config-dir` 目录中的 `config.json` 将被重命名为 `config.json.deprecated`。 迁移后，所有现有配置都将得到保留。

此外，`--config-dir`现在是一个旧配置，计划在将来删除，因此请相应地更新本地startup和ansible脚本。

```
Copyminio server /data
```

MinIO还使用管理员凭据对所有配置，IAM和策略内容进行加密。

### 证书目录

TLS证书存在`${HOME}/.minio/certs`目录下，你需要将证书放在该目录下来启用`HTTPS` 。如果你是一个乐学上进的好青年，这里有一本免费的秘籍传授一你: [如何使用TLS安全的访问minio](https://docs.min.io/cn/how-to-secure-access-to-minio-server-with-tls).

以下是一个具有TLS证书的MinIO server的目录结构。

```
Copy$ mc tree --files ~/.minio
/home/user1/.minio
└─ certs
   ├─ CAs
   ├─ private.key
   └─ public.crt
```

你可以使用`--certs-dir`命令行选项提供自定义certs目录。

#### 凭据

只能通过环境变量`MINIO_ACCESS_KEY` 和 `MINIO_SECRET_KEY` 更改MinIO的admin凭据和root凭据。使用这两个值的组合，MinIO加密存储在后端的配置

```
Copyexport MINIO_ACCESS_KEY=minio
export MINIO_SECRET_KEY=minio13
minio server /data
```

##### 使用新的凭据轮换加密

另外，如果您想更改管理员凭据，则MinIO将自动检测到该凭据，并使用新凭据重新加密，如下所示。一次只需要设置如下所示的环境变量即可轮换加密配置。

> 旧的环境变量永远不会在内存中被记住，并且在使用新凭据迁移现有内容后立即销毁。在服务器再次成功重启后，你可以安全的删除它们。

```
Copyexport MINIO_ACCESS_KEY=newminio
export MINIO_SECRET_KEY=newminio123
export MINIO_ACCESS_KEY_OLD=minio
export MINIO_SECRET_KEY_OLD=minio123
minio server /data
```

迁移完成后, 服务器会自动的取消进程空间中的`MINIO_ACCESS_KEY_OLD` and `MINIO_SECRET_KEY_OLD`设置。

> **注意: 在下一次服务重新启动前，要确保移除脚本或者服务文件中的 `MINIO_ACCESS_KEY_OLD` and `MINIO_SECRET_KEY_OLD`， 避免现有的内容被双重加密**

#### 区域

```
CopyKEY:
region  服务器的物理位置标记

ARGS:
name     (string)    服务器的物理位置名字，例如 "us-west-rack2"
comment  (sentence)  为这个设置添加一个可选的注释
```

或者通过环境变量

```
CopyKEY:
region  服务器的物理位置标记

ARGS:
MINIO_REGION_NAME     (string)    服务器的物理位置名字，例如  "us-west-rack2"
MINIO_REGION_COMMENT  (sentence)  为这个设置添加一个可选的注释
```

示例:

```
Copyexport MINIO_REGION_NAME="my_region"
minio server /data
```

### 存储类型

默认情况下，标准存储类型的奇偶校验值设置为N/2，低冗余的存储类型奇偶校验值设置为2。在[此处](https://github.com/minio/minio/blob/master/docs/zh_CN/erasure/storage-class/README.md)了解有关MinIO服务器存储类型的更多信息。

```
CopyKEY:
storage_class  定义对象级冗余

ARGS:
standard  (string)    设置默认标准存储类型的奇偶校验计数，例如"EC:4"
rrs       (string)    设置默认低冗余存储类型的奇偶校验计数，例如"EC:2"
comment   (sentence)  为这个设置添加一个可选的注释
```

或者通过环境变量

```
CopyKEY:
storage_class  定义对象级冗余

ARGS:
MINIO_STORAGE_CLASS_STANDARD  (string)    设置默认标准存储类型的奇偶校验计数，例如"EC:4"
MINIO_STORAGE_CLASS_RRS       (string)    设置默认低冗余存储类型的奇偶校验计数，例如"EC:2"
MINIO_STORAGE_CLASS_COMMENT   (sentence)  为这个设置添加一个可选的注释
```

### 缓存

MinIO为主要的网关部署提供了缓存存储层，使您可以缓存内容以实现更快的读取速度，并节省从云中重复下载的成本。

```
CopyKEY:
cache  添加缓存存储层

ARGS:
drives*  (csv)       逗号分隔的挂载点，例如 "/optane1,/optane2"
expiry   (number)    缓存有效期限（天），例如 "90"
quota    (number)    以百分比限制缓存驱动器的使用，例如 "90"
exclude  (csv)       逗号分隔的通配符排除模式，例如 "bucket/*.tmp,*.exe"
after    (number)    缓存对象之前的最小可访问次数
comment  (sentence)  为这个设置添加一个可选的注释
```

或者通过环境变量

```
CopyKEY:
cache  添加缓存存储层

ARGS:
MINIO_CACHE_DRIVES*  (csv)       逗号分隔的挂载点，例如 "/optane1,/optane2"
MINIO_CACHE_EXPIRY   (number)    缓存有效期限（天），例如 "90"
MINIO_CACHE_QUOTA    (number)    以百分比限制缓存驱动器的使用，例如 "90"
MINIO_CACHE_EXCLUDE  (csv)       逗号分隔的通配符排除模式，例如 "bucket/*.tmp,*.exe"
MINIO_CACHE_AFTER    (number)    缓存对象之前的最小可访问次数
MINIO_CACHE_COMMENT  (sentence)  为这个设置添加一个可选的注释
```

#### Etcd

MinIO支持在etcd上存储加密的IAM assets和Bucket DNS记录。

> NOTE: if *path_prefix* is set then MinIO will not federate your buckets, namespaced IAM assets are assumed as isolated tenants, only buckets are considered globally unique but performing a lookup with a *bucket* which belongs to a different tenant will fail unlike federated setups where MinIO would port-forward and route the request to relevant cluster accordingly. This is a special feature, federated deployments should not need to set *path_prefix*.

```
CopyKEY:
etcd  为IAM and Bucket DNS联合多个集群

ARGS:
endpoints*       (csv)       以逗号分隔的etcd endpoint列表，例如 "http://localhost:2379"
path_prefix      (path)      为隔离租户提供的命名控件前缀,例如 "customer1/"
coredns_path     (path)      共享bucket DNS记录, 默认是 "/skydns"
client_cert      (path)      用于mTLS身份验证的客户端证书
client_cert_key  (path)      用于mTLS身份验证的客户端证书密钥
comment          (sentence)  为这个设置添加一个可选的注释
```

或者通过环境变量

```
CopyKEY:
etcd  为IAM and Bucket DNS联合多个集群

ARGS:
MINIO_ETCD_ENDPOINTS*       (csv)       以逗号分隔的etcd endpoint列表，例如 "http://localhost:2379"
MINIO_ETCD_PATH_PREFIX      (path)      为隔离租户提供的命名控件前缀,例如 "customer1/"
MINIO_ETCD_COREDNS_PATH     (path)      共享bucket DNS记录, 默认是 "/skydns"
MINIO_ETCD_CLIENT_CERT      (path)      用于mTLS身份验证的客户端证书
MINIO_ETCD_CLIENT_CERT_KEY  (path)      用于mTLS身份验证的客户端证书密钥
MINIO_ETCD_COMMENT          (sentence)  为这个设置添加一个可选的注释
```

### API

默认情况下，服务器/集群同时处理的并发请求数没有限制。 但是，可以使用API子系统强加这种限制。 在[此处](https://github.com/minio/minio/blob/master/docs/zh_CN/throttle/README.md)阅读有关MinIO服务器中限制限制的更多信息。

```
CopyKEY:
api  管理全局HTTP API调用的特定功能，例如限制，身份验证类型等.

ARGS:
requests_max       (number)    设置并发请求的最大数量，例如 "1600"
requests_deadline  (duration)  设置等待处理的API请求的期限，例如 "1m"
ready_deadline     (duration)  设置健康检查API /minio/health/ready的期限，例如 "1m"
cors_allow_origin  (csv)       设置CORS请求允许的来源列表,以逗号分割,例如 "https://example1.com,https://example2.com"
```

或者通过环境变量

```
CopyMINIO_API_REQUESTS_MAX       (number)    设置并发请求的最大数量，例如 "1600"
MINIO_API_REQUESTS_DEADLINE  (duration)  设置等待处理的API请求的期限，例如 "1m"
MINIO_API_CORS_ALLOW_ORIGIN  (csv)       设置CORS请求允许的来源列表,以逗号分割,例如 "https://example1.com,https://example2.com"
```

#### 通知

MinIO支持如下列表中的通知。要配置单个目标，请参阅[此处](https://docs.min.io/cn/minio-bucket-notification-guide.html)的更多详细文档

```
Copynotify_webhook        发布 bucket 通知到 webhook endpoints
notify_amqp           发布 bucket 通知到 AMQP endpoints
notify_kafka          发布 bucket 通知到 Kafka endpoints
notify_mqtt           发布 bucket 通知到 MQTT endpoints
notify_nats           发布 bucket 通知到 NATS endpoints
notify_nsq            发布 bucket 通知到 NSQ endpoints
notify_mysql          发布 bucket 通知到 MySQL databases
notify_postgres       发布 bucket 通知到 Postgres databases
notify_elasticsearch  发布 bucket 通知到 Elasticsearch endpoints
notify_redis          发布 bucket 通知到 Redis datastores
```

### 访问配置

可以使用[`mc admin config` get/set/reset/export/import commands](https://github.com/minio/mc/blob/master/docs/minio-admin-complete-guide.md)命令应用所有配置的更改.

#### 列出所有可用的配置key

```
Copy~ mc admin config set myminio/
```

#### 获取每个key的帮助

```
Copy~ mc admin config set myminio/ <key>
```

例如: `mc admin config set myminio/ etcd` 会返回 `etcd` 可用的配置参数

```
Copy~ mc admin config set play/ etcd
KEY:
etcd  federate multiple clusters for IAM and Bucket DNS

ARGS:
endpoints*       (csv)       comma separated list of etcd endpoints e.g. "http://localhost:2379"
path_prefix      (path)      namespace prefix to isolate tenants e.g. "customer1/"
coredns_path     (path)      shared bucket DNS records, default is "/skydns"
client_cert      (path)      client cert for mTLS authentication
client_cert_key  (path)      client cert key for mTLS authentication
comment          (sentence)  optionally add a comment to this setting
```

要获取每个配置参数的等效ENV，请使用`--env`标志

```
Copy~ mc admin config set play/ etcd --env
KEY:
etcd  federate multiple clusters for IAM and Bucket DNS

ARGS:
MINIO_ETCD_ENDPOINTS*       (csv)       comma separated list of etcd endpoints e.g. "http://localhost:2379"
MINIO_ETCD_PATH_PREFIX      (path)      namespace prefix to isolate tenants e.g. "customer1/"
MINIO_ETCD_COREDNS_PATH     (path)      shared bucket DNS records, default is "/skydns"
MINIO_ETCD_CLIENT_CERT      (path)      client cert for mTLS authentication
MINIO_ETCD_CLIENT_CERT_KEY  (path)      client cert key for mTLS authentication
MINIO_ETCD_COMMENT          (sentence)  optionally add a comment to this setting
```

此行为在所有key中都是一致的，每个key都带有可用的示例文档。

### 环境变量仅有的配置 (配置文件中没有)

#### 使用情况采集器

> 注意: 数据使用情况采集器不支持网关部署模式。

数据使用情况采集器默认是启用的，通过Envs可以设置更多的交错延迟。

采集器能适应系统速度，并在系统负载时完全暂停。 可以调整采集器的速度，从而达到延迟更新的效果。 每次采集操作之间的延迟都可以通过环境变量`MINIO_DISK_USAGE_CRAWL_DELAY`来调整。 默认情况下，该值为10。 这意味着采集每次操作都将休眠*10x*的时间。

大多数设置要让采集器足够慢，这样不会影响整体的系统性能。
设置 `MINIO_DISK_USAGE_CRAWL_DELAY` 为一个 *较低* 的值可以让采集器更快，并且设置为0的时候，可以让采集器全速运行（不推荐）。 设置一个较高的值可以让采集器变慢，进一步减少资源的消耗。

示例: 如下设置将使采集器的速度降低三倍, 减少了系统资源的使用，但是反映到更新的延迟会增加。

```
Copyexport MINIO_DISK_USAGE_CRAWL_DELAY=30
minio server /data
```

### 浏览器

开启或关闭浏览器访问，默认是开启的，你可以通过`MINIO_BROWSER`环境变量进行修改。

示例:

```
Copyexport MINIO_BROWSER=off
minio server /data
```

### 域名

默认情况下，MinIO支持格式为 http://mydomain.com/bucket/object 的路径类型请求。
`MINIO_DOMAIN` 环境变量被用来启用虚拟主机类型请求。 如果请求的`Host`头信息匹配 `(.+).mydomain.com`，则匹配的模式 `$1` 被用作 bucket， 并且路径被用作object. 更多路径类型和虚拟主机类型的信息参见[这里](http://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAPI.html)
示例:

```
Copyexport MINIO_DOMAIN=mydomain.com
minio server /data
```

`MINIO_DOMAIN`环境变量支持逗号分隔的多域名配置

```
Copyexport MINIO_DOMAIN=sub1.mydomain.com,sub2.mydomain.com
```





## MinIO 存储类型快速入门 

在纠删码模式下,MinIO server支持存储类型. 这可以指定每个对象的数据和奇偶校验盘，其实就是可以为对象选择不同的存储类型.

### 概述

MinIO 支持两种存储类型, 低冗余存储和标准存储。 这些存储类型可以在MinIO服务器启动之前通过环境变量定义。 在通过环境变量定义了每个存储类型的数据和奇偶校验盘的数量后， 你可以通过请求中的元数据字段`x-amz-storage-class`来设置一个对象的存储类型。然后，MinIO服务器通过将对象保存在特定数量的数据和奇偶校验盘中来兑现存储类型。

### 可用存储空间

选择不同的数据和奇偶校验盘的数量会直接影响到存储空间的使用。通过存储类型，你能优化以实现高冗余或者是更好的空间利用率。

让我们以在16个盘的MinIO部署中存储100M文件为例，来了解数据和奇偶校验盘数量的不同组合是如何影响可用存储空间的。如果你使用8个数据盘和8个奇偶校验盘，文件空间使用量约为两倍， 即100M文件将占用200M空间。但是，如果你是用10个数据盘和6个奇偶校验盘，则同样的100M文件大约需要160M的空间。如果你是用14个数据盘和2个奇偶校验盘，100M文件仅仅需要约114M空间。

以下是一张16盘的MinIO部署，数据/奇偶校验盘数量和相应的 *近似* 存储储空间使用情况列表。*空间使用率* 约等于纠删编码下的使用空间除以文件的实际大小。

| 盘总个数 (N) | 数据盘个数 (D) | 奇偶校验码个数 (P) | 空间使用率 |
| ------------ | -------------- | ------------------ | ---------- |
| 16           | 8              | 8                  | 2.00       |
| 16           | 9              | 7                  | 1.79       |
| 16           | 10             | 6                  | 1.60       |
| 16           | 11             | 5                  | 1.45       |
| 16           | 12             | 4                  | 1.34       |
| 16           | 13             | 3                  | 1.23       |
| 16           | 14             | 2                  | 1.14       |

你可以使用公式: `盘总个数 (N)/数据盘个数 (D)`来计算 *大概的* 空间使用率。

#### 标准(STANDARD)存储类型的允许值

`STANDARD`存储类型意味着奇偶校验盘比`REDUCED_REDUNDANCY`多。 所以, `STANDARD`的奇偶校验盘数量应该

- 如果`REDUCED_REDUNDANCY`的奇偶校验盘未设置的话，应该大于等于2。
- 如果已设置的话，应该大于`REDUCED_REDUNDANCY`的奇偶校验盘数量。

奇偶校验块不能大于数据块，所以`STANDARD`存储类型的奇偶校验块不能大于N/2。（N是盘总个数）

`STANDARD`存储类型的默认值是`N/2`（N是盘总个数）。

#### 低冗余(REDUCED_REDUNDANCY)存储类型的允许值

`REDUCED_REDUNDANCY`存储类型意味着奇偶校验盘比`REDUCED_REDUNDANCY`少。 所以, `REDUCED_REDUNDANCY`的奇偶校验盘数量应该

- 如果`STANDARD`的奇偶校验盘未设置的话，应该小于2。
- 如果设置的话，应该小于`STANDARD`的奇偶校验盘数量。

因为不建议奇偶校验盘数量低于2， 所以4个盘组成的纠删码模式部署是不支持`REDUCED_REDUNDANCY`存储类型的。

`REDUCED_REDUNDANCY`存储类型的默认值是`2`。

### 存储类型入门

#### 设置存储类型

设置存储类型环境变量的格式如下

```
MINIO_STORAGE_CLASS_STANDARD=EC:parity` `MINIO_STORAGE_CLASS_RRS=EC:parity
```

例如, 设置 `MINIO_STORAGE_CLASS_RRS` 奇偶校验盘为2 以及设置 `MINIO_STORAGE_CLASS_STANDARD` 奇偶校验盘为3

```
export MINIO_STORAGE_CLASS_STANDARD=EC:3
export MINIO_STORAGE_CLASS_RRS=EC:2
```

也可以通过`mc admin config` get/set 命令来设置存储类型。参考 [存储类型](https://github.com/minio/minio/tree/master/docs/zh_CN/config#存储类型) 获取更多详细信息。

*注意*

- 如果通过环境变量或`mc admin config` get/set命令设置了`STANDARD`存储类型，并且请求元数据中不存在`x-amz-storage-class`，则MinIO服务器会将`STANDARD`存储类型应用于该对象。这意味着将按照`STANDARD`存储类型中的设置使用数据和奇偶校验盘数量。	
- 如果在启动MinIO服务器之前未定义存储类型，并且随后的PutObject元数据字段中存在`x-amz-storage-class`，其值为`REDUCED_REDUNDANCY`或`STANDARD`，则MinIO服务器将使用默认的奇偶校验值。

#### 设置元数据

如下`minio-go`的示例中，存储类型被设置为`REDUCED_REDUNDANCY`。这意味着对象被拆分为6个数据块和2个奇偶校验块(按照上一步骤中的存储类型设置)。

```
s3Client, err := minio.New("localhost:9000", "YOUR-ACCESSKEYID", "YOUR-SECRETACCESSKEY", true)
if err != nil {
	log.Fatalln(err)
}

object, err := os.Open("my-testfile")
if err != nil {
	log.Fatalln(err)
}
defer object.Close()
objectStat, err := object.Stat()
if err != nil {
	log.Fatalln(err)
}

n, err := s3Client.PutObject("my-bucketname", "my-objectname", object, objectStat.Size(), minio.PutObjectOptions{ContentType: "application/octet-stream", StorageClass: "REDUCED_REDUNDANCY"})
if err != nil {
	log.Fatalln(err)
}
log.Println("Uploaded", "my-objectname", " of size: ", n, "Successfully.")
```