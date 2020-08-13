# ELK数据安全

## 免费方案

- 设置Nginx反向代理
- 安装免费的Security
  - Search Guard
  - ReadOnly REST
- X-Pack的Basic版本
  - 从ES6.8&7.0开始，Security纳入x-pack的Basic版本中，免费使用一些基本的功能



## 身份认证

- 认证体系中的几种类型
  - 提供用户名或密码
  - 提供密钥或kerberos票据
- Realms：X-Pack中的认证服务
  - 内置Realms（免费）
    - File/Native(用户名密码保存在Elasticsearch中)
  - 外部Realms（收费）
    - LDAP/Active Directory/PKI/SAML/Kerberos

## 用户权限管理-RBAC

RBAC：Role Based Access Control

