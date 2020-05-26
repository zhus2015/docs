## 基础变量介绍

| $0   | 当前脚本的文件名                                             |
| ---- | ------------------------------------------------------------ |
| $n   | 传递给脚本或函数的参数。n 是一个数字，表示第几个参数。例如，第一个参数是$1，第二个参数是$2。 |
| $#   | 传递给脚本或函数的参数个数。                                 |
| $*   | 传递给脚本或函数的所有参数。                                 |
| $@   | 传递给脚本或函数的所有参数。被双引号(" ")包含时，与 $* 稍有不同，下面将会讲到。 |
| $?   | 上个命令的退出状态，或函数的返回值。                         |
| $$   | 当前Shell进程ID。对于 Shell 脚本，就是这些脚本所在的进程ID。 |

变量分为两种：系统变量和用户自定义变量

可以使用env查看系统变量

也可以使用set查看系统变量，set比env显示的变量多

.bashrc 定义用户的命令

变量赋值可以直接使用=赋值

变量不能以数字开头

用echo输出变量值

export 全局变量

unset 取消变量值

\* ：多位通配符

？：一位通配符

\#：注释

\：脱意符号

|：管道符号

$：使用

！$:上条命令的最后一句

~：家目录

&：后台

\>：重定向

\>>：追加重定向

[0-9]:表示其中一个  ls[1-3].txt=ls 1.txt;ls 2.txt;ls 3.txt



## **cut命令**

把一个文件分段

cut -d： -f [段]  /etc/passwd

例：cut -d : -f 1,3,5 /etc/passwd  以：为分隔符 显示1，3，5段信息

cut -c 10:显示每行的第十个字符

例：cut -c 1-10 /etc/passwd  显示passwd文件每行的第1-10个字符



## sort命令

sort：排序 不加参数默认按ACII码排序

sort  -t ： -k3  以冒号为分隔符，第三段排序

sort -n 按数字排序

sort -r 反序排序 一般配置-n 使用

sort -u 去重复排序，配合n之类的使用

## **wc命令**

-l：计算文档有多少行

-w：有多少个单词，以空格为分隔符

-m：有多少个字符，换行符也会计算在内

## **uniq** 

 去重复，如果两个重复行没有相邻就不能去重

 -c：计算重复数量

tee 不仅仅重定向而且打印输出 （覆盖原来内容）

tee用法：echo "1111111" |tee 1.txt 将“1111111”重定向到文件1.txt中并在屏幕上打印内容

## **set**

set指令能设置所使用shell的执行方式，可依照不同的需求来做设置

　-a 　标示已修改的变量，以供输出至环境变量。

　-b 　使被中止的后台程序立刻回报执行状态。

　-C 　转向所产生的文件无法覆盖已存在的文件。

　-d 　Shell预设会用杂凑表记忆使用过的指令，以加速指令的执行。使用-d参数可取消。

　-e 　若指令传回值不等于0，则立即退出shell。　　

　-f　 　取消使用通配符。

　-h 　自动记录函数的所在位置。

　-H Shell 　可利用"!"加<指令编号>的方式来执行history中记录的指令。

　-k 　指令所给的参数都会被视为此指令的环境变量。

　-l 　记录for循环的变量名称。

　-m 　使用监视模式。

　-n 　只读取指令，而不实际执行。

　-p 　启动优先顺序模式。

　-P 　启动-P参数后，执行指令时，会以实际的文件或目录来取代符号连接。

　-t 　执行完随后的指令，即退出shell。

　-u 　当执行时使用到未定义过的变量，则显示错误信息。

　-v 　显示shell所读取的输入值。

　-x 　执行指令后，会先显示该指令及所下的参数。

　+<参数> 　取消某个set曾启动的参数。

## **tr**

tr：字符替换

tr  [options] string1 string2 用string2替换string1

-c   对string1取反，是tr匹配出除了在string1中出现的所有字符

-d   删除与string中指定的字符匹配的字符

ls *.txt|tr 'a-z' 'A-Z'  将txt替换为TXT 仅仅是显示改变并不影响源文件

## **split **

**分割 文件**

-b：按文件大小分割

-l：按行对文件进行分割

例如：split -b 50m 1.txt  50M一个文件

​           split -l  100 1.txt  100行一个文件

Shell中的命令连接符

[命令1]&&[命令2]： 如果执行命令1成功才会执行命令2

[命令1]||[命令2] ：命令1执行不成功才会执行命令2

[命令1]；[命令2]命令1执行成功与否都会执行命令2 

## **grep命令**

grep [参数] [关键字] [文件名]

grep ‘root’ /etc/passwd

grep -E ==egrep 可以不使用\符号

--color:将匹配关键字使用颜色标注

-c：关键字出现了几行

-n：显示行号

-v：取反	不显示颜色

-A num: 显示匹配行的同时显示下方[num]行

-B num : 显示匹配行的同时显示上方[num]行

-C num:显示匹配行同时显示上下[num]行

-r：寻找包含关键字的文件和所在行

-rh：寻找包含关键字的文件和所在行(不显示文件名)

-'[条件]' ：匹配[条件]的行

 	例如：grep '[A-Z]'  1.txt ：列出包含字母A--Z的行

![img](F:/Git/docs/docs/system_base/images/clipboard-1590459286794.png)

 grep  '[0-9]'  1.txt ：列出包含数字的行

\- '^[条件]' :列出以"条件"开头的行

![img](F:\Git\docs\docs\system_base\images\clipboard-1590459314228.png)

-'[^条件]'：列出除去"条件"的行

   例如:grep --color '[^0-9]' 1.txt 

![img](F:\Git\docs\docs\system_base\images\clipboard-1590459325836.png)

-'[r.o]':表示匹配.前后的任意一个字符

![img](F:\Git\docs\docs\system_base\images\clipboard-1590459332028.png)

-'r*o':表示0个或多个*前面的字符

-'r.*o':匹配到任意r开头o结尾的行（贪婪匹配）

![img](F:\Git\docs\docs\system_base\images\clipboard-1590459344565.png)

-'r\?o': 0或1个？前面的字符(\是为了对？进行脱意)  必须使用egrep或者grep -E

-'r+o'一个或多个+前面的字符  必须使用egrep或者grep -E

-'(rr)+' 出现了1个或多个rrd

-'(rr){1,3}' 出现了1-3次rr的

-'[root|nologin]' 或者命令

## **sed命令**

sed -n '10'p 1.txt 打印1.txt前10行

sed -n ‘20,$’p 1.txt 打印从20行开始到尾行

sed -n  ‘/root/'p 1.txt 打印包含root的行

grep    能使用的正则表达式sed都可以使用

sed -i '1,19'd     删除文档的1-19行，对文件进行操作

sed -r    可以省略\符号

sed '1,10s/nologin/login/g' 1.txt  在文件1.txt的1-10行将nologin替换为login

sed 's/nologin/login/g' 1.txt  在文件1.txt中将所有行将nologin替换为login

^.*$代表一整行

sed 's#^.*$#&login#g'  1.txt  将文件1.txt所有行的末尾增加一个login

sed 's/^.*$/&login/g'  1.txt  将文件1.txt所有行的末尾增加一个login

可以使用#代替/

sed -r 's#(^[a-z0-9]+)(:.*:)(.*$)#\3\2\1#g' 1.txt 将1.txt文档所有行（以：为分隔符）第一段和最后一段交还位置

\1. 把每个单词的第一个小写字母变大写：

sed 's/\b[a-z]/\u&/g' filename

\2. 把所有小写变大写：

sed 's/[a-z]/\u&/g' filename

\3. 大写变小写：

sed 's/[A-Z]/\l&/g' filename

## **awk命令**

awk -F ':' '{print $3}' 2.txt  以：为分隔符，显示第3段运行结果如图：

![img](F:\Git\docs\docs\system_base\images\clipboard-1590459366136.png)

awk -F ':' '{print $3,$4}' 2.txt 运行结果如图：

![img](F:\Git\docs\docs\system_base\images\clipboard-1590459370829.png)

awk -F ':' 'OFS=":"  {print $3,$4}' 2.txt 指定3段和4段之间的分隔符是： 运行结果如图：

![img](F:\Git\docs\docs\system_base\images\clipboard-1590459379538.png)

awk  '/user/' 2.txt 匹配2.txt中包含user的行 运行结果如图：

![img](F:\Git\docs\docs\system_base\images\clipboard-1590459391306.png)

awk  '/root|user/' 2.txt  匹配2.txt文件中包含user或者root 的行 

![img](F:\Git\docs\docs\system_base\images\clipboard-1590459395843.png)

awk -F ':' '$1~/r*o/' 1.txt  匹配1.txt中以：分割第一段中包含r或者o的行

![img](F:\Git\docs\docs\system_base\images\clipboard-1590459406326.png)

awk -F ':' '$3>=500' 1.txt   匹配第三段数字大于等于500的行，注意数字不能加“”

![img](F:\Git\docs\docs\system_base\images\clipboard-1590459413975.png)

awk -F ':' 'NR<10' 1.txt   匹配小于10行

![img](F:\Git\docs\docs\system_base\images\clipboard-1590459419621.png)

awk练习

1、用awk 打印整个test.txt （以下操作都是用awk工具实现，针对test.txt）

 awk '$0' test.txt

2、查找所有包含 ‘bash’ 的行

awk '/bash/' test.txt

3、用 ‘:’ 作为分隔符，查找第三段等于0的行

 awk -F ':' '$3==0' test.txt

4、用 ‘:’ 作为分隔符，查找第一段为 ‘root’ 的行，并把该段的 ‘root’ 换成 ‘toor’ (可以连同sed一起使用)

  awk -F ':' '$1=="root"' test.txt|sed 's/root/toor/'

5、用 ‘:’ 作为分隔符，打印最后一段

 awk -F ':' '{print $NF}' test.txt

6、打印行数大于20的所有行

  awk -F ':' 'NR>20' test.txt

7、用 ‘:’ 作为分隔符，打印所有第三段小于第四段的行

 awk -F ':' '$3<$4' test.txt

8、用 ‘:’ 作为分隔符，打印第一段以及最后一段，并且中间用 ‘@’ 连接 （例如，第一行应该是这样的形式 'root@/bin/bash‘ ）

 awk -F ':' 'OFS="@" {print $1,$NF}' test.txt

9、用 ‘:’ 作为分隔符，把整个文档的第四段相加，求和

 awk -F ':' '{sum+=$4};END {print sum}' test.txt

sed练习题

1. 把/etc/passwd 复制到/root/test.txt，用sed打印所有行

​        cp /etc/passwd /root/test.txt;sed -n '1,$'p test.txt

1. 打印test.txt的3到10行

​         sed -n '3,10'p test.txt

1. 打印test.txt 中包含 ‘root’ 的行

   	sed -n '/root/'p test.txt

1. 删除test.txt 的15行以及以后所有行

​        sed '15,$'d test.txt

1. 删除test.txt中包含 ‘bash’ 的行

​        sed '/bash/'d test.txt

1. 替换test.txt 中 ‘root’ 为 ‘toor’

 	sed 's/root/toor/g' test.txt

1. 替换test.txt中 ‘/sbin/nologin’ 为 ‘/bin/login’

sed 's#sbin/noloin#bin/login#g' test.txt

1. 删除test.txt中5到10行中所有的数字

sed  '5,10s/[0-9]//g' test.txt

1. 删除test.txt 中所有特殊字符（除了数字以及大小写字母）

sed  's/[^0-9a-zA-Z]//g' test.txt

1. 把test.txt中第一个单词和最后一个单词调换位置

​    sed's/\(^[a-zA-Z][a-zA-Z]*\)\([^a-zA-Z].*\)\([^a-zA-Z]\)\([a-zA-Z][a-zA-Z]*$\)/\4\2\3\1/' test.txt

1. 把test.txt中出现的第一个数字和最后一个单词替换位置

sed's#\([^0-9][^0-9]*\)\([0-9][0-9]*\)\([^0-9].*\)\([^a-zA-Z]\)\([a-zA-Z][a-zA-Z]*$\)#\1\5\3\4\2#' test.txt

1. 把test.txt 中第一个数字移动到行末尾

 sed 's#\([^0-9][^0-9]*\)\([0-9][0-9]*\)\([^0-9].*$\)#\1\3\2#' test.txt

1. 在test.txt 20行到末行最前面加 ‘aaa:’

 sed '20,$s/^.*$/aaa:&/' test.txt