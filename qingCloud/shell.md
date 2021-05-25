

## shell

单引号中使用单引号'"'"'

```
kubectl get pods -A -o wide |grep "edgenode" | awk '{printf "$(kubectl describe pod %s -n %s |grep \"Controlled By\"|awk '"'"'{print $3}'"'"')\n\n", $2, $1 }'
```

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

#### **系统**

```
# uname -a               # 查看内核/操作系统/CPU信息
# lsb_release -a         # 查看操作系统版本 (适用于所有的linux，包括Redhat、SuSE、Debian等发行版，但是在debian下要安装lsb)   
# cat /proc/cpuinfo      # 查看CPU信息
# cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c
# hostname               # 查看计算机名
# lspci -tv              # 列出所有PCI设备
# lsusb -tv              # 列出所有USB设备
# lsmod                  # 列出加载的内核模块
# env                    # 查看环境变量
```

#### **资源**

```
# free -m                # 查看内存使用量和交换区使用量
# df -h                  # 查看各分区使用情况
# du -sh <目录名>        # 查看指定目录的大小
# grep MemTotal /proc/meminfo   # 查看内存总量
# grep MemFree /proc/meminfo    # 查看空闲内存量
# uptime                 # 查看系统运行时间、用户数、负载
# cat /proc/loadavg      # 查看系统负载
```

#### **磁盘和分区**

```
# mount | column -t      # 查看挂接的分区状态
# fdisk -l               # 查看所有分区
# swapon -s              # 查看所有交换分区
# hdparm -i /dev/hda     # 查看磁盘参数(仅适用于IDE设备)
# dmesg | grep IDE       # 查看启动时IDE设备检测状况
```

#### **网络**

```
# ifconfig               # 查看所有网络接口的属性
# iptables -L            # 查看防火墙设置
# route -n               # 查看路由表
# netstat -lntp          # 查看所有监听端口
# netstat -antp          # 查看所有已经建立的连接
# netstat -s             # 查看网络统计信息
```

#### **进程**

```
# ps -ef                 # 查看所有进程
# top                    # 实时显示进程状态
```

#### **用户**

```
# w                      # 查看活动用户
# id <用户名>            # 查看指定用户信息
# last                   # 查看用户登录日志
# cut -d: -f1 /etc/passwd   # 查看系统所有用户
# cut -d: -f1 /etc/group    # 查看系统所有组
# crontab -l             # 查看当前用户的计划任务
```

#### **服务**

```
# chkconfig --list       # 列出所有系统服务
# chkconfig --list | grep on    # 列出所有启动的系统服务
```

#### **程序**

```
# rpm -qa                # 查看所有安装的软件包
```

#### **环境变量**

```shell
printenv
```

```
echo $[variable name]
```

## docker

#### 清理

docker container prune

docker image prune

docker volume prune

#### builder &  build

```
FROM golang:1.14-alpine3.11 AS builder

ARG GO_LDFLAGS

COPY . /go/src/github.com/kubeedge/kubeedge

RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -v -o /usr/local/bin/cloudcore -ldflags "$GO_LDFLAGS -w -s" \
github.com/kubeedge/kubeedge/cloud/cmd/cloudcore


FROM alpine:3.11

COPY --from=builder /usr/local/bin/cloudcore /usr/local/bin/cloudcore

# ENTRYPOINT ["cloudcore"]
```

```
# 创新新的buildx实例
$ docker buildx create --name ks-all
$ docker buildx use ks-all
$ docker buildx inspect --bootstrap
# build
$ docker buildx build --push --platform linux/amd64,linux/arm64 -f cmd/notification-manager/Dockerfile . -t ${NM_IMG}
```

```
docker push pixiake/kube-apiserver-amd64:v1.15.12
docker push pixiake/kube-apiserver-arm64:v1.15.12
docker manifest create pixiake/kube-apiserver:v1.15.12  \
                       pixiake/kube-apiserver-amd64:v1.15.12 \
                       pixiake/kube-apiserver-arm64:v1.15.12 --amend
#查看                   
docker manifest inspect  pixiake/kube-apiserver:v1.15.12
#修正
docker manifest annotate --arch arm64 \
       pixiake/kube-apiserver:v1.15.12 \
       pixiake/kube-apiserver-arm64:v1.15.12
#push
docker manifest push pixiake/kube-apiserver:v1.15.12
```



#### dockerfile goproxy

```
ENV GOPROXY=https://goproxy.cn
```

## awk

#### 忽略第一行

```
lsof -i:9092 |awk 'NR == 1 {next} {print $2}' | uniq
```



## helm

```
# dry-run:
helm install --dry-run --debug ./prometheus-example-app --generate-name
```

## Kubectl

#### patch

```

PatchJson='{"spec":{"template":{"spec":{"nodeSelector":{"node-role.kubernetes.io/master": "","node-role.kubernetes.io/worker": ""}}}}}'
#PatchJson='{"spec":{"template":{"spec":{"nodeSelector":{}}}}}'

NoShedulPathJson='{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"node-role.kubernetes.io/edge","operator":"DoesNotExist"}]}]}}}}}'

edgenode="edgenode"
namespaces=($(kubectl get pods -A -o wide |grep $edgenode | awk '{print $1}' ))
pods=($(kubectl get pods -A -o wide |grep $edgenode | awk '{print $2}' ))

echo ${namespaces[@]}
echo ${pods[@]}
length=${#namespaces[@]}
for((i=0;i<$length;i++));  
do
 ns=${namespaces[$i]}
 pod=${pods[$i]}
 resources=$(kubectl -n $ns describe pod $pod | grep "Controlled By" |awk '{print $3}')
 echo "Patchig for ns:"${namespaces[$i]}",resources:"$resources
 kubectl -n $ns patch $resources --patch "$NoShedulPathJson"
done
```

#### delete

##### pods

```
$ kubectl delete pods <pod> --grace-period=0 --force
```

```
$ kubectl patch pod <pod> -p '{"metadata":{"finalizers":null}}'
```

##### ns

```
$ curl -k -H "Content-Type: application/json" -X PUT -d '{"metadata":{"name":"istio-system"},"spec":{"finalizers":[]}}' http://127.0.0.1:8001/api/v1/namespaces/istio-system /finalize
```

#### restart

##### single

###### deployment

```
kubectl -n kubesphere-system rollout restart deploy $(kubectl get deployment -n kubesphere-system |egrep "console" |awk '{print $1}')
```

###### pods

```
 kubectl -n kubesphere-system delete pods $(kubectl get deployment -n kubesphere-system |egrep "console" |awk '{print $1}')
```

##### multi

###### deployment

```
kubectl get deployment -n kubesphere-system |egrep "console|apiserver" | awk '{print $1}'|xargs kubectl -n kubesphere-system rollout restart deploy
```

###### pods

```
kubectl get pods -n kubesphere-system |egrep "console|apiserver" | awk '{print $1}'|xargs kubectl -n kubesphere-system delete pods {}
```

## Git

#### upstream

```
git remote add upstream https://github.com/kubesphere/kubesphere
```

跟进上游更新：

```
git fetch upstream
git merge upstream/master
```

常见回退和`rebase`：

```
1. git reset --hard head^n
2. git remote add upstream https://github.com/kubeedge/kubeedge.git
3. git fetch upstream
4. git rebase upstream/master
```

## useful

```
 version=$(tr -d '\0' < $entry | grep -Pzo "(version:.*)|(versions:\n.*name:.*)" | sed 'N;s/\n/ /' | awk '{ n=split($0, a,":"); print a[n] }')
```

