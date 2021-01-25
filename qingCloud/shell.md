## shell

#### 判断对象存在问题

```
-e 判断对象是否存在
-d 判断对象是否存在，并且为目录
-f 判断对象是否存在，并且为常规文件
-L 判断对象是否存在，并且为符号链接
-h 判断对象是否存在，并且为软链接
-s 判断对象是否存在，并且长度不为0
-r 判断对象是否存在，并且可读
-w 判断对象是否存在，并且可写
-x 判断对象是否存在，并且可执行
-O 判断对象是否存在，并且属于当前用户
-G 判断对象是否存在，并且属于当前用户组
-nt 判断file1是否比file2新 [ ``"/data/file1"` `-nt ``"/data/file2"` `]
-ot 判断file1是否比file2旧 [ ``"/data/file1"` `-ot ``"/data/file2"` `]
```

#### 判断哪个进程打开的fd最多

```lsof /dev/tty1 | awk -F ' ' '{count[$2]++;} END {for(i in count) {print i count[i]}}'```

#### 带版本号安装软件

```
#查看版本信息
apt-cache policy docker-ce 
apt list --installed |grep docker
#安装
apt install docker-ce=5:19.03.11~3-0~ubuntu-bionic
```

#### 查看GPU信息

```
lspci | grep -i vga #显卡
lspci | grep -i nvidia #GPU
lspci -v -s 00:09.0 
```

