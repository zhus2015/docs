# Jenkins中的pipeline语法说明

官方文档参考地址：https://www.jenkins.io/zh/doc/book/pipeline/

语法格式：

```groovy
pipeline {
  agent any
    stages {
      stage('pull') {
        steps {
          sh "git clone ${params.git_repo} ${params.app_name}/${env.BUILD_NUMBER} && cd ${params.app_name}/${env.BUILD_NUMBER} && git checkout ${params.git_ver}"
            } 
        }
    }
}
```





  ${params.arge_name}  引用自定义的变量，即引用参数化构建定义的变量

  ${env.BUILD_NUMBER} 引入系统内置变量，即jenkins的内置变量，[Jenkins内置变量说明](jenkins_inlay_arge.md)

