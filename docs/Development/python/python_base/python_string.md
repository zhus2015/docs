# 字符串

- ython中单引号和双引号使用完全相同。
- 使用三引号('''或""")可以指定一个多行字符串。
- 转义符 '\'
- 反斜杠可以用来转义，使用r可以让反斜杠不发生转义。。 如 r"this is a line with \n" 则\n会显示，并不是换行。
- 按字面意义级联字符串，如"this " "is " "string"会被自动转换为this is string。
- 字符串可以用 + 运算符连接在一起，用 * 运算符重复。
- Python 中的字符串有两种索引方式，从左往右以 0 开始，从右往左以 -1 开始。
- Python中的字符串不能改变。
- Python 没有单独的字符类型，一个字符就是长度为 1 的字符串。
- 字符串的截取的语法格式如下：**变量[头下标:尾下标:步长]**

示例：

```python
>>> st = 'hello kitty'
#统计元素个数
>>> print(st.count('l'))
2
#首字母大写
>>> print(st.capitalize())
Hello kitty
#居中输出
>>> print(st.center(30,'*'))
*********hello kitty**********
#以某个内容为结尾，返回一个布尔型的参数
>>> print(st.endswith('y'))
True
#以某个内容为结尾，返回一个布尔型的参数
>>> print(st.startswith('h'))
True
#查找到第一个元素并将索引值返回
>>> print(st.find('t'))
8
>>> st2 = 'My name is {name},job is {job}'
#格式化输出
>>> print(st2.format(name='zhangsan',job='IT'))
My name is zhangsan,job is IT
>>> print(st2.format_map({'name':'zhangsan','job':'Linx'}))
My name is zhangsan,job is Linx
#格式化输出,参数是字典
#查找到第一个元素并将索引值返回
>>> print(st.index('o'))     
4
#判断是不是数字或者字母
>>> print('asdkjhfna'.isalnum())
True
#检查字符串是否只包含十进制字符
>>> print('12314'.isdecimal())
True
#判断是不是一个整型数字
>>> print('12344'.isdigit())
True
#检测变量是否为数字或数字字符串
>>> print('12134'.isnumeric())
True
#检测是不是非法变量
>>> print('123asdfa'.isidentifier())
False
#检测变量元素是不是全部是小写
>>> print('abc'.islower())
True
#检测变量元素是不是全部是大写
>>> print('ABC'.isupper())
True
#检测变量元素是不是空格
>>> print('  '.isspace())
True
#检测是不是标题，即每个单词的首字母全是大写，返回True
>>> print('My Name Is '.istitle())
True
#大写变小写
>>> print('ASDFASDF'.lower())
asdfasdf
#小写变大写
>>> print('asdfasdf'.upper())
ASDFASDF
#大小写反转
>>> print('ASDasdf'.swapcase())
asdASDF
#去除前后的换行符和空格
>>> print(' My name is'.strip())
My name is
#替换操作,1是代表替换1次，如果不写表示全部替换
>>> print('My title is title'.replace('title','asdadf',1))
My asdadf is title
#将字符串按照指定的分隔符进行分割，成为一个列表
>>> print('My title is title'.split(' '))
['My', 'title', 'is', 'title']
#将字符修改为title格式，首字母大写
>>> print('My title is title'.title())
My Title Is Title
```





**1、“+"**

示例：

  a = **'123'**

 b = **'456'**

 c = a + b

 print(c)

**2、join**

用法  '连接符'.join([连接变量])

示例：

 a = **'123'**

 b = **'456'**

 c = **''**.join([a,b])

 print(c)

运行结果：

 123*****456