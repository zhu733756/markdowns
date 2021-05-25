#### keadm update version

```
# upgrade v1.6.1 to v1.6.2, 需要检查当前tag下的commit与下面文件有没有冲突

git checkout origin/kubesphere-release-1.6.1 -- ./keadm/cmd/keadm/app/cmd/common/constant.go

git checkout origin/kubesphere-release-1.6.1 -- ./keadm/cmd/keadm/app/cmd/common/types.go
git checkout origin/kubesphere-release-1.6.1 -- ./keadm/cmd/keadm/app/cmd/edge/join.go
git checkout origin/kubesphere-release-1.6.1 -- ./keadm/cmd/keadm/app/cmd/util/common.go

git checkout origin/kubesphere-release-1.6.1 -- ./keadm/cmd/keadm/app/cmd/util/edgecoreinstaller.go
git checkout origin/kubesphere-release-1.6.1 -- ./hack/lib/golang.sh

# 打上一个tag
git tag kubesphere-release-1.6.2
```

#### keadm bin build && cp

```
# amd
make all WHAT=keadm
mv _output/local/bin/keadm  /root/packages/
cd /root/packages/ && file keadm
tar cvf  keadm-v1.6.2-linux-amd64.tar.gz  ./keadm #注意修改arch部分

# arm
make crossbuild WHAT=keadm
mv _output/local/bin/keadm  /root/packages/
cd /root/packages/ && file keadm
tar cvf  keadm-v1.6.2-linux-arm64.tar.gz  ./keadm
```

#### 拷贝tar文件进行测试

```
scp 
```

#### qsctl同步

```
# 确保/root/packages/kubeedge与qingstor文件中kubeedge buckets一致
# 更新keadm压缩包
cd /root/packages/kubeedge/bin && mkdir v1.6.2
cd v1.6.2 && mkdir arm64 && mkdir x86_64
mv /root/packages/keadm-v1.6.2-linux-amd64.tar.gz ./x86_64/
cd ./x86_64/ && cp keadm-v1.6.2-linux-amd64.tar.gz  keadm-v1.6.2-linux-x86_64.tar.gz
mv /root/packages/keadm-v1.6.2-linux-arm64.tar.gz ./arm64/
 
# 同步
qsctl cp ./v1.6.2 qs://kubeedge/bin/ -r

# 更新相关依赖，kubeedge 压缩包和checksum,
cd /root/packages/kubeedge/releases/download && mkdir v1.6.2
# 将https://github.com/kubeedge/kubeedge/releases/tag/v1.6.2页面所有文件copy下来，除了keadm相关外
wget xxx
qsctl cp ./v1.6.2 qs://kubeedge/releases/download/ -r

# 更新services
cd /root/packages/kubeedge/releases/service && mkdir 1.6.2
wget https://raw.githubusercontent.com/kubeedge/kubeedge/v1.6.2/build/tools/cloudcore.service
wget https://raw.githubusercontent.com/kubeedge/kubeedge/v1.6.2/build/tools/edgecore.service
qsctl cp ./1.6.2 qs://kubeedge/releases/service/ -r
```

