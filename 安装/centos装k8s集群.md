时间设置

- date
- systemctl restart chronyd

- 关闭iptables或者防火墙服务

  - 防火墙
    - systemctl status firewalld
    - systemctl stop firewalld.service
  - iptables
    - systemctl status iptables
    - systemctl disable iptables.service

- 关闭并且禁用selinux

  - getenforce
  - setenforce  0/1/2
  - /etc/sysconfig/selinux

- 关闭分区交换

  - free -m
  - swapoff -a【临时有效】
  - /etc/fstab【修改配置，永久有效】

- 启动ipvs内核模块

  - vim /etc/sysconfig/modules/ipvs.modules

    ```
    #! /bin/bash
    pvs_mods_dir="/usr/lib/modules/$(uname -r)/kernel/net/netfilter/ipvs"
    for mod in $(ls $ipvs_mods_dir | grep -o "^[^.]*"); do 
         /sbin/modinfo -F filename $mod &> /dev/null
        if [ $? -eq 0 ]; then
            /sbin/modprobe $mod
        fi
    done
    ```

- 安装docker并启动docker服务

- 修改docker.services【Service】配置

  - vim  /usr/lib/systemd/system/docker.service增加
    - Environment="NO_PROXY=127.0.0.0/8,192.168.1.0/24"  #本地ip忽略
    - Environment="HTTPS_PROXY=http://www.ik8s.io:10070"  
    - ExecStartPost=/usr/sbin/iptables -P FORWARD ACCEPT
  - 配置完后
    - systemctl daemon-reload
    - systemctl start docker
  - 保证bridge两个值为1
    - sysctl -a| grep bridge
    -  vim /etc/sysctl.d/k8s.conf
      - net.bridge.bridge-nf-call-arptables = 1
      - net.bridge.bridge-nf-call-ip6tables = 1
    -  sysctl -p /etc/sysctl.d/k8s.conf    

-  \#创建kubernetes阿里云源 

  -  cd /etc/yum.repos.d/ 

  -  vim kubernetes.repo

    ```
    [kubernetes]
    name=Kubernetes Repository
    baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
    gpgcheck=1
    gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg 
    ```

  -   yum install kubelet kubectl kubeadm -y 

  - systemctl enable docker kubelet   #将docker和kubelet设置开机自启动

- 初始化集群

  - 局域网

    - flannel：10.244.0.0/16
    - calico: 192.168.0.0/16

  - 默认方式查看：

    - kubeadm config print init-defaults

  - 【master】配置

    -  vim /etc/sysconfig/kubelet 

      -  KUBELET_EXTRA_ARGS="--fail-swap-on=false" 

    - 拉去镜像

      -  执行`kubeadm config images pull` 

      - 如果报错，可以自定义shell

        #!/bin/bash

        images=(
            kube-apiserver:v1.18.0
            kube-controller-manager:v1.18.0
            kube-scheduler:v1.18.0
            kube-proxy:v1.18.0
            pause:3.2
            etcd:3.4.3-0
            coredns:1.6.7
        )

        for imageName in ${images[@]} ; do
            docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/$imageName
            docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/$imageName k8s.gcr.io/$imageName
        done

    - 主节点初始化

      ```
      #初始化
      kubeadm init --kubernetes-version="v1.18.0" --pod-network-cidr="10.244.0.0/16" --ignore-preflight-errors=Swap
      【--image-repository registry.aliyuncs.com/google_containers 这个没有测试过】
      # 必要的配置
      mkdir -p $HOME/.kube
      sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
      sudo chown $(id -u):$(id -g) $HOME/.kube/config
      ## 将kubectl join命令保存下来，后面要用！
    ```
  
    - 安装finnel网络插件
      -  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml 
      - 也可以通过附件apply
  - kubectl get pods -n kube-system
  
- 【node节点】
  
    -  vim /etc/sysconfig/kubelet 
      -  KUBELET_EXTRA_ARGS="--fail-swap-on=false" 
    - 参考master拉去镜像
    - kubeadm join 172.16.110.246:6443 --token xxx  --ignore-preflight-errors=Swap
  
- 主机管理分机节点

  - metrics-server

    - https://github.com/kubernetes-incubator/metrics-server

    - ```
      $ git clone https://github.com.cnpmjs.org/kubernetes-sigs/metrics-server.git
      $ git checkout -b release-v0.3 origin/release-v0.3
      $ git pull
      下载完成后还需要对 metrics-server/deploy/1.8+/resource-reader.yaml文件进行修改
           image: registry.cn-hangzhou.aliyuncs.com/medo/metrics-server-amd64:v0.3.6
            commands:
            # 新增
            - --kubelet-insecure-tls
            - --kubelet-preferred-address-types=InternalIP
      ```