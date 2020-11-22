# Jenkins配置LDAP



![image-20200924223224234](../images/image-20200924223224234.png)

可以配置权限管理插件使用

(&(|(uid={0})(mail={0}))(memberof=cn=jenkins-admin,ou=Jenkins,ou=Group,dc=loding,dc=com))

(&(|(uid={0})(mail={0}))(|(memberof=cn=jenkins-admin,ou=Jenkins,ou=Group,dc=loding,dc=com)(memberof=cn=jenkins-user,ou=Jenkins,ou=Group,dc=loding,dc=com)))





![image-20200924224035842](../images/image-20200924224035842.png)