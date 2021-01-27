## ubuntu安装docker-ce

#### ubuntu安装docker-ce

u buntu 20（使用 apt-get 进行安装）
###### step 1: 安装必要的一些系统工具
sudo apt-get update
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common

###### step 2: 安装GPG证书

1.  如果发现报错：[gpg: can't connect to the agent: IPC connect call failed](https://phpsolved.com/gpg-cant-connect-to-the-agent-ipc-connect-call-failed/)

   `sudo apt remove gpg`
   `sudo apt install gnupg1`

2. curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -

###### Step 3: 写入软件源信息
sudo add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"

如果`/etc/apt/sources.list.d/`不存在`docker.list`

```
echo  deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic stable >  /etc/apt/sources.list.d/docker.list 
```

###### Step 4: 更新并安装Docker-CE
sudo apt-get -y update
sudo apt-get -y install docker-ce