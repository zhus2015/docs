# 列表

序列是Python中最基本的数据结构。序列中的每个元素都分配一个数字 - 它的位置，或索引，第一个索引是0，第二个索引是1，依此类推。

Python有6个序列的内置类型，但最常见的是列表和元组。

序列都可以进行的操作包括索引，切片，加，乘，检查成员。

此外，Python已经内置确定序列的长度以及确定最大和最小的元素的方法。

列表是最常用的Python数据类型，它可以作为一个方括号内的逗号分隔值出现。

列表的数据项不需要具有相同的类型



## 列表切片

列表切片的特性是顾头不顾尾

步长-1代表真正的从右往左走

```python
>>> str=['a', 'b', 'c', 'd', 'e', 'r']
>>> str
['a', 'b', 'c', 'd', 'e', 'r']
>>> str[-1:-6:-1]
['r', 'e', 'd', 'c', 'b']
```

例：

```python
>>> names = ['zhangsan','lisi','wangwu','zhaoliu']
```

> 从左往右打印所有元素

```python
>>> print(names[1:])
['lisi', 'wangwu', 'zhaoliu']
```

> 从左往右从第一个元素打印到倒数第二个元素

```python
>>> print(names[1:-1])
['lisi', 'wangwu']
```

> 从左往右从第一个元素到最后一个元素间隔一个打印

```python
>>> print(names[1::1])
['lisi', 'wangwu','zhaoliu']
```

> 从左往右从第一个元素到最后一个元素间隔两个打印

```python
>>> print(names[1::2])
['lisi', 'zhaoliu']
```

> 从右往左从最后一个元素到第一个元素间隔两个打印

```python
>>> print(names[::-2])
['zhaoliu', 'lisi']
```





## 增加元素

### append

> 在列表最后增加一个元素

```python
>>> names.append('qianba') 
>>> print(names)
['zhangsan', 'lisi', 'wangwu', 'zhaoliu', 'qianba']
```

> 在列表的指定位置插入一个元素

```python
>>> names.insert(1,'zhubajie')
>>> print(names)
['zhangsan', 'zhubajie', 'lisi', 'wangwu', 'zhaoliu']
```



### extend 

添加元素

程序：

```python
>>> a = [1,2,3]
>>> b = [4,5,6]
>>> a.extend(b)
>>> print(a)
[1, 2, 3, 4, 5, 6]
>>> print(b)
[4, 5, 6]
```





## 删除元素

### remove 

删除列表中指定的元素

例：

```python
>>> name.remove('zhangsan')  
>>> print(name)
['lisi', 'wangwu', 'zhaoliu']
```

如果有重复元素，删除第一个元素

如果元素不存在，会报错



### pop 

删除列表中指定位置的值，并且返回删除的元素内容

例：

```python
>>> names2 = names.pop(1)
>>> print(names)
['zhangsan', 'wangwu', 'zhaoliu']
>>> print(names2)
lisi
```

names2.pop() #默认删除最后一个值

空列表无法使用



### del

直接删除

del  names[0]  #删除指定元素

del  names  #从内存中将元素删除



### clear 

清空

清空列表

numes.clear()



## count

#计算元素出现次数

例：

```python
>>> t = ['to','be','or','not','to','be']
>>> n = t.count('to')
>>> print(n)
2
```





**index **

取出指定变量的索引值

例：

```python
>>> names = ['zhangsan','lisi','wangwu','zhaoliu']
>>> print(names.index('lisi'))
1
```



## 列表排序

### reverse

列表倒序

例：

```python
>>> names = ['zhangsan','lisi','wangwu','zhaoliu']
>>> names.reverse()
>>> print(names)
['zhaoliu', 'wangwu', 'lisi', 'zhangsan']
```



### sort 

列表元素排序

例：

```python
>>> nums = [2,6,3,4,5]
>>> nums.sort()
>>> print(nums)
[2, 3, 4, 5, 6]
```



## replace

将字符串中的old（旧字符串）替换成new(新字符串)，如果指定第三个参数max，则替换不超过max次s

语法：str.replace(old, new[, max])

例：

```python
>>> str = "this is string example....wow!!! this is really string";
>>> print str.replace("is", "was");
thwas was string example....wow!!! thwas was really string
>>> print str.replace("is", "was", 3);
thwas was string example....wow!!! thwas is really string
```

str = str.replace("\n", "")  #去除字符串最后的换行符