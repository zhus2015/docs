# mkdocs使用

## 安装使用

```sh
# 安装
pip install mkdocs

# 安装插件
pip install mkdocs-material markdown mkdocs-bootstrap

# 创建新的项目
mkdocs new project

# 开启本地服务器
mkdocs serve
注意：这是是serve不是server

#生成静态网站
mkdocs build
```





## mkdocs的个性标签

!!! info "信息"

\!!! info "文本内容"

??? info "隐藏内容"
    注意此行有四个英文空格的缩进，使用typora编辑的时候不被识别不知道怎么回事。




!!! question "问题"

\!!! question "文本内容"

??? question "隐藏内容"
    注意此行有四个英文空格的缩进，使用typora编辑的时候不被识别不知道怎么回事。



!!! warning "警告"

\!!! warning "文本内容"



!!! danger "危险"

\!!! danger "文本内容"



??? danger "危险"
    此行有四个英文空格缩进



!!! tip "提示"
    此行有四个英文空格缩进

\!!! tip "文本内容"

??? tip "隐藏内容"
    注意此行有四个英文空格的缩进，使用typora编辑的时候不被识别不知道怎么回事。

!!! note "内容"

\!!! note "内容"



```mermaid
graph TD
    A --> B
```



