# Jenkins参数化构建

**安装需要的插件**

安装方法不在叙述

插件名称Git Parameter

**配置项目**

1、在这里建立一个新的项目

![img](../images/image1-1590997112010.png)

2、选中“参数化构建过程”->点击“Add Parameter”->选择“Git Parameter”

![img](../images/image2-1590997112011.png)

3、填写基础参数信息

![img](../images/image3-1590997112011.png)

4、填写Git仓库信息

注意红色方框内的参数值

![img](../images/image4-1590997112011.png)

5、填写编译参数

![img](../images/image5-1590997112011.png)

6、保存即可

![img](../images/image6-1590997112011.png)

7、点击构建进行测试

点击“Build with Parameters”可以看到现在弹出了一个二级菜单模式的选择框，这里可以看到我们git仓库现在所有的分支和tag，选择需要构建的仓库进行构建即可

![img](../images/image7-1590997112011.png)