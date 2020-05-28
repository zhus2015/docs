1、Hello World实验
输出Hello World

??? note "答案"

	```
	#/bin/bash
	#Program:
	#这个程序的功能是在终端上显示“Hello World”
	#History:
	#2017/03/21 zhus  First release

	PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
	export PATH
	echo -e "Hello World! \a \n"
	exit 0
	```

2、用户输入一个first name和last name，程序输出“Your name is：”

??? note "答案"

	```shell
	#!/bin/bash
	#Program:
	#User inputs his first name and last name, Program show his full name
	#History:
	#2017/3/21 zhus First release
	PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
	export PATH
	read -p "Please input your first name: " firstname
	read -p "Please input your last name: " lastname
	echo -e "Your full name is :$firstname $lastname"
	exit 0
	```

3、通过touch命令创建三个空文件，以当前日期的前天、昨天、今天的日期来创建这三个文件，

假设今天的日期2017年3月21日
即：filename_20170319、filename_20170319、filename_20170319
??? note "答案"
	```
	###主要练习date命令
	#!/bin/bash
	# Program:
	# Creates three files,which named by user's input and date command
	# History:
	# 2017/03/21 zhus First release
	PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
	​export PATH
	echo -e "I will use 'touch' command create 3 files."
	read -p "Please input your filename: " fileuser
	filename=${fileuser:-"filename"}
	date1=$(date --date='2 day ago' +%Y%m%d)
	date2=$(date --date='1 day ago' +%Y%m%d)
	date3=$(date +%Y%m%d)
	file1=${filename}${date1}
	file2=${filename}${date2}
	file3=${filename}${date3}
	touch "$file1"
	touch "$file2"
	touch "$file3"
	```

4、数值运算，简单的加减乘除

此案例是乘法运算
??? note "答案"
	```
	#!/bin/bash
	#Program:
	#User input 2 numbers;program owill cross these two numbers;
	#History:2017/3/22 zhus First release;
	PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
	export PATH
	echo -e "You ShOULD input 2 numbers,I will cross them! \n"
	read -p "first number: " firstnu
	read -p "second number: " secnu
	total=$(($firstnu*$secnu))
	echo -e "\nThe result of $firstnu x $secnu is ==> $total"
	```

5、输入一个文件名，判断这个文件是否存在，是文件还是目录，判断这个文件的权限

??? note "答案"
	```
	###主要练习简单的判断
	#!/bin/bash
	#Program:
	#       User input a filename ,program will check the flowing:
	#       1.)exist?  2.)file/directory?  3.)file permissions
	#History:
	#2017/3/22 zhus First release
	PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
	export PATH
	echo -e "Please input a filename. I will check it's type\n"
	read -p "Input filename: " filename
	test -z $filename && echo "You must input a filename " && exit 0
	test ! -e $filename && echo "The filename '$filename' DO NOT exit  " && exit 0
	test -f $filename && filetype="regulare file"
	test -d $filename && filetype="directory"
	test -r $filename && perm="r"
	test -w $filename && perm="$perm w"
	test -x $fielname && perm="$perm x"
	​echo "The filename $filename is a $filetype "
	​echo "And the permission are : $perm"
	```
​
6、
a、当执行这个程序的时候，程序会让你选择Y或者N;

b、如果用户输入Y或y时，就会显示“OK,continue”;

c、如果用户输入N或n时，就会显示“Oh，interrupt！”；

d、如果用户输入的不是Y/y/N/n之内的字符，就会显示“I don‘t know what your choice is”。

??? note "答案"

	```
	####主要是练习“[ ]”的判断功能####
	#!/bin/bash
	#Program:
	# This Program shows the user's choice
	#History:
	#2017/3/23 zhus First release

	PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
	export PATH
	read -p "Please input (Y/N) " yn
	[ "$yn" == "Y" -o "$yn" == "y" ] && echo "OK,continue " && exit 0
	[ "$yn" == "N" -o "$yn" == "n" ] && echo "Oh,interrupt" && exit 0
	echo "I don't konw what your choice is " && exit 0
	```


7、执行一个带参数的script，执行脚本后，屏幕会显示如下数据：

a、程序的文件名

b、共有几个参数

c、若参数的个数小于2则告知用户参数数量太少

d、全部的参数内容；

e、第一个参数

f、第二个参数

###这个实例主要是为了学习
$#  代表后接的参数 “个数”
$@  代表 “$1” “$2” “$3” “$4” 之意，每个变量都是独立的
$*  代表“ “$1”c“$2”c“$3”c“$4”  ”,其中c为分割字符，默认为空格键
??? note "答案"

	```shell
	#!/bin/bash
	#Program:
	# Program shows the script name.parameters..
	#Histroy:
	#2017/3/23 zhus First release

	PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
	export PATH

	echo " The script name is    ==> $0 "
	echo " Total parameters nuber is ==> $#"
	[ "$#" -lt 2 ] && echo " The number of parameters is less than 2 . Stop here." && exit 0
	echo " Your whole number is ==> ‘$@’"
	echo " The 1st parameter  ==> $1"
	echo " The 2nd patameter  ==> $2"
	```


8、写一个脚本，实现判断192.168.1.0/24网络里，当前在线的有那些，能ping通则认为在线

??? note "答案"

	```
	#!/bin/bash
	#Program:
	for i in `seq 1 255`
	do
	ping -c 1 192.168.1.$i &>/dev/null
	if [ $? -eq 0 ];then
	echo "192.168.1.$i Yes"
	else
	echo "10.10.10.$i No"
	fi
	done
	```

9、封IP,找到哪些ip请求量不合法，并且还要每隔一段时间把之前封掉的ip（若不再继续请求了）	给解封。 所以该脚本的关键点在于定一个合适的时间段和阈值

??? note "答案"

	```
	#! /bin/bash
	logfile=/home/logs/client/access.log
	d1=`date -d "-1 minute" +%H:%M` d2=`date +%M`
	ipt=/sbin/iptables ips=/tmp/ips.txt
	block() {
	grep "$d1:" $logfile|awk '{print $1}' |sort -n |uniq -c |sort -n >$ips
	for ip in `awk '$1>50 {print $2}' $ips`; do
	$ipt -I INPUT -p tcp --dport 80 -s $ip -j REJECT
	echo "`date +%F-%T` $ip" >> /tmp/badip.txt
	done
	}
	unblock()
	{
	for i in `$ipt -nvL --line-numbers |grep '0.0.0.0/0'|awk '$2<15 {print $1}'|sort -nr`; do
	$ipt -D INPUT $i   	done   	$ipt -Z } 	if [ $d2 == "00" ] || [ $d2 == "30" ]; then
	unblock
	block
	else
	block
	fi
	```
