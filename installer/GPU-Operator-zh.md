

## GPU-Operator

#### 官方代码仓库

- GitHub: https://github.com/NVIDIA/gpu-operator
- GitLab: https://gitlab.com/nvidia/kubernetes/gpu-operator

#### 官方文档

- https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/getting-started.html#install-nvidia-gpu-operator


#### K8s Runtime 架构图

![img](https://raw.githubusercontent.com/zhu733756/bedpic/main/images1334952-20190610155423745-506706065.png)

#### GPU-Operator 架构图

![../_images/nvidia-docker-arch.png](https://docs.nvidia.com/datacenter/cloud-native/_images/nvidia-docker-arch.png)

#### 组件

```
├─ nvidia-docker2
│    ├─ docker-ee (>= 18.06.0~ce~3-0~ubuntu)
│    ├─ docker.io (>= 18.06.0)
│    └─ nvidia-container-runtime (>= 3.3.0)
|        └─ nvidia-container-toolkit (<< 2.0.0)
|             └─ libnvidia-container-tools (<< 2.0.0)
│		          └─ libnvidia-container1 (>= 1.2.0~rc.3)
```

###### `nvidia-docker2`

- docker-specific package of the hierarchy
-  takes the script associated with the `nvidia-container-runtime` and installs it into docker’s `/etc/docker/daemon.json` file. 

###### `nvidia-container-runtime`

- takes a `runC` spec as input, injects the `nvidia-container-toolkit` script as a `prestart hook` into it, and then calls out to the native `runC`, passing it the modified `runC` spec with that hook set.

###### `nvidia-container-toolkit`

- a script that implements the interface required by a `runC` `prestart` hook

- takes information contained in the `config.json` and uses it to invoke the `libnvidia-container` CLI with an appropriate set of flags. 

###### `libnvidia-container`

- a simple CLI utility to automatically configure GNU/Linux containers leveraging NVIDIA GPUs

#### 组件仓库

- [nvidia-docker2](https://github.com/NVIDIA/nvidia-docker/tree/gh-pages/)

- [nvidia-container-toolkit](https://github.com/NVIDIA/nvidia-container-runtime/tree/gh-pages/)

- [libnvidia-container](https://github.com/NVIDIA/libnvidia-container/tree/gh-pages/)

#### 安装说明

##### 前提条件

在安装operator之前，请配置好安装环境如下：

1. 所有节点**不需要**预先安装NVIDIA组件(driver, container runtime, device plugin)；

2. 所有节点必须配置Docker , `cri-o`, 或者 `containerd`. 对于doker来说，可以参考[这里](https://docs.docker.com/engine/install/)；

3. 如果使用HWE内核(e.g. kernel 5.x) 的·Ubuntu 18.04 LTS环境下,需要给 `nouveau driver` 添加黑名单，需要更新 `initramfs`；`cpu`型号为`Broadwell`:

   ```
   $ sudo vim /etc/modprobe.d/blacklist.conf
   blacklist nouveau
   options nouveau modeset=0
   $ sudo update-initramfs -u
   $ reboot
   $ lsmod | grep nouveau # 验证nouveau是否已禁用
   ```

   ```
   $ cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c  #本文测试时cpu型号为Broadwell
   16 Intel Core Processor (Broadwell)
   ```

4. 节点发现(NFD) 需要在每个节点上配置，默认情况会直接安装，如果已经配置，请在 `Helm chart `变量设置`nfd.enabled` 为 `false` , 再安装;

5. 如果使用Kubernetes 1.13和1.14, 需要激活 [KubeletPodResources](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/)；

   

##### 支持的linux版本

支持的linux版本如下：

| OS Name / Version    | Identifier  | amd64 / x86_64 | ppc64le | arm64 / aarch64 |
| -------------------- | ----------- | -------------- | ------- | --------------- |
| Amazon Linux 1       | amzn1       | X              |         |                 |
| Amazon Linux 2       | amzn2       | X              |         |                 |
| Amazon Linux 2017.09 | amzn2017.09 | X              |         |                 |
| Amazon Linux 2018.03 | amzn2018.03 | X              |         |                 |
| Open Suse Leap 15.0  | sles15.0    | X              |         |                 |
| Open Suse Leap 15.1  | sles15.1    | X              |         |                 |
| Debian Linux 9       | debian9     | X              |         |                 |
| Debian Linux 10      | debian10    | X              |         |                 |
| Centos 7             | centos7     | X              | X       |                 |
| Centos 8             | centos8     | X              | X       | X               |
| RHEL 7.4             | rhel7.4     | X              | X       |                 |
| RHEL 7.5             | rhel7.5     | X              | X       |                 |
| RHEL 7.6             | rhel7.6     | X              | X       |                 |
| RHEL 7.7             | rhel7.7     | X              | X       |                 |
| RHEL 8.0             | rhel8.0     | X              | X       | X               |
| RHEL 8.1             | rhel8.1     | X              | X       | X               |
| RHEL 8.2             | rhel8.2     | X              | X       | X               |
| Ubuntu 16.04         | ubuntu16.04 | X              | X       |                 |
| Ubuntu 18.04         | ubuntu18.04 | X              | X       | X               |
| Ubuntu 20.04         | ubuntu20.04 | X              | X       | X               |

##### 容器运行时

支持的容器运行时：

| OS Name / Version    | amd64 / x86_64 | ppc64le | arm64 / aarch64 |
| -------------------- | -------------- | ------- | --------------- |
| Docker 18.09         | X              | X       | X               |
| Docker 19.03         | X              | X       | X               |
| RHEL/CentOS 8 podman | X              |         |                 |
| CentOS 8 Docker      | X              |         |                 |
| RHEL/CentOS 7 Docker | X              |         |                 |

##### 配置doker环境

参考[这里](https://docs.docker.com/engine/install/)

##### 安装 NVIDIA Container Toolkit

配置`stable` 仓库 和GPG key:

```
$ distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
   && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
   && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
```

更新软件仓库后安装`nvidia-docker2`:

```
$ sudo apt-get update
```

```shell
$ sudo apt-get install -y nvidia-docker2
-----
   What would you like to do about it ?  Your options are:
    Y or I  : install the package maintainer's version
    N or O  : keep your currently-installed version
      D     : show the differences between the versions
      Z     : start a shell to examine the situation
-----
chooses "N" if you have custom settings, the configuration below will override your settings.
{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
```

重启`docker`

```
$ sudo systemctl restart docker
```

##### [自定义环境变量 (OCI spec)](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/user-guide.html#environment-variables-oci-spec)

#### 安装NVIDIA GPU Operator

##### 安装Helm

```
$ curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
   && chmod 700 get_helm.sh \
   && ./get_helm.sh
```

添加`NVIDIA Helm`仓库

```
$ helm repo add nvidia https://nvidia.github.io/gpu-operator \
   && helm repo update
```

##### 安装 GPU Operator

###### docker as runtime

```
$ helm install --wait --generate-name nvidia/gpu-operator
```

如果需要指定驱动版本，可参考如下：

```
$ cat /proc/driver/nvidia/version 
NVRM version: NVIDIA UNIX x86_64 Kernel Module  450.80.02  Wed Sep 23 01:13:39 UTC 2020
GCC version:  gcc version 7.5.0 (Ubuntu 7.5.0-3ubuntu1~18.04)
$ helm install --wait --generate-name nvidia/gpu-operator \
--set driver.version="450.80.02"
```

###### crio as runtime

```
helm install --wait --generate-name \
   nvidia/gpu-operator \
   --set operator.defaultRuntime=crio
```

###### containerd as runtime

```
helm install --wait --generate-name \
   nvidia/gpu-operator \
   --set operator.defaultRuntime=containerd
```

```
Furthermore, when setting containerd as the defaultRuntime the following options are also available:

toolkit:
  env:
  - name: CONTAINERD_CONFIG
    value: /etc/containerd/config.toml
  - name: CONTAINERD_SOCKET
    value: /run/containerd/containerd.sock
  - name: CONTAINERD_RUNTIME_CLASS
    value: nvidia
  - name: CONTAINERD_SET_AS_DEFAULT
    value: true
```

**如果安装过程中出现超时，请检查你的镜像是否在拉取中**！

##### [考虑无缝安装](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/getting-started.html#considerations-to-install-in-air-gapped-clusters)

##### 使用 `values.yaml`安装

```
$ helm install --wait --generate-name \
   nvidia/gpu-operator -f values.yaml
```

#### 检查已部署operator服务状态

##### 检查pods

```
$ kubectl get pods -n gpu-operator-resources
NAME                                       READY   STATUS      RESTARTS   AGE
gpu-feature-discovery-ff4ng                1/1     Running     2          11h
nvidia-container-toolkit-daemonset-2vxjz   1/1     Running     0          11h
nvidia-dcgm-exporter-pqwfv                 1/1     Running     0          64m
nvidia-device-plugin-daemonset-42n74       1/1     Running     0          64m
nvidia-device-plugin-validation            0/1     Completed   0          64m
nvidia-driver-daemonset-dvd9r              1/1     Running     3          11h
```

```
$ kubectl get pods -n default
NAME                                                              READY   STATUS    RESTARTS   AGE
gpu-operator-1611672791-node-feature-discovery-master-bf8dmj6f8   1/1     Running   1          11h
gpu-operator-1611672791-node-feature-discovery-worker-79wkd       1/1     Running   1          11h
gpu-operator-1611672791-node-feature-discovery-worker-rmx9w       1/1     Running   2          11h
gpu-operator-7d6d75f67c-kbmms                                     1/1     Running   1          11h
```

##### 检查节点资源是否处于可分配

```
$ kubectl describe node worker-gpu-001
---
Allocatable:
  cpu:                15600m
  ephemeral-storage:  82435528Ki
  hugepages-2Mi:      0
  memory:             63649242267
  nvidia.com/gpu:     1  #check this
  pods:               110
---
```

#### 两个实例

##### 官方文档中的两个实例

```
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
   name: dcgmproftester
spec:
   restartPolicy: OnFailure
   containers:
   - name: dcgmproftester11
   image: nvidia/samples:dcgmproftester-2.0.10-cuda11.0-ubuntu18.04
   args: ["--no-dcgm-validation", "-t 1004", "-d 120"]
   resources:
      limits:
         nvidia.com/gpu: 1
   securityContext:
      capabilities:
         add: ["SYS_ADMIN"]

EOF
```

```
$ curl -LO https://nvidia.github.io/gpu-operator/notebook-example.yml
$ cat notebook-example.yml
apiVersion: v1
kind: Service
metadata:
  name: tf-notebook
  labels:
    app: tf-notebook
spec:
  type: NodePort
  ports:
  - port: 80
    name: http
    targetPort: 8888
    nodePort: 30001
  selector:
    app: tf-notebook
---
apiVersion: v1
kind: Pod
metadata:
  name: tf-notebook
  labels:
    app: tf-notebook
spec:
  securityContext:
    fsGroup: 0
  containers:
  - name: tf-notebook
    image: tensorflow/tensorflow:latest-gpu-jupyter
    resources:
      limits:
        nvidia.com/gpu: 1
    ports:
    - containerPort: 8
```

##### 部署

```
$ kubectl apply -f cuda-loader-generator.yaml 
pod/dcgmproftester created
$ kubectl apply -f notebook-example.yml       
service/tf-notebook created
pod/tf-notebook created
```

```
$ kubectl describe node worker-gpu-001
---
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests     Limits
  --------           --------     ------
  cpu                1087m (6%)   1680m (10%)
  memory             1440Mi (2%)  1510Mi (2%)
  ephemeral-storage  0 (0%)       0 (0%)
  nvidia.com/gpu     1            1 #check this
Events:              <none>
```

![image-20210127104932704](https://raw.githubusercontent.com/zhu733756/bedpic/main/imagesimage-20210127104932704.png)

![image-20210127105037194](https://raw.githubusercontent.com/zhu733756/bedpic/main/imagesimage-20210127105037194.png)

从上面的部署过程可知，当有GPU任务发布给平台时，GPU资源从可分配状态转变为已分配状态，安装任务发布的先后顺序，第二个任务在第一个任务运行结束后开始运行

##### 使用Jupyter Notebook

```
$ kubectl get svc # get the nodeport of the svc, 30001
gpu-operator-1611672791-node-feature-discovery   ClusterIP   10.233.10.222   <none>        8080/TCP       12h
kubernetes                                       ClusterIP   10.233.0.1      <none>        443/TCP        12h
tf-notebook                                      NodePort    10.233.53.116   <none>        80:30001/TCP   7m52s

$ kubectl logs tf-notebook 
[I 21:50:23.188 NotebookApp] Writing notebook server cookie secret to /root/.local/share/jupyter/runtime/notebook_cookie_secret
[I 21:50:23.390 NotebookApp] Serving notebooks from local directory: /tf
[I 21:50:23.391 NotebookApp] The Jupyter Notebook is running at:
[I 21:50:23.391 NotebookApp] http://tf-notebook:8888/?token=3660c9ee9b225458faaf853200bc512ff2206f635ab2b1d9
[I 21:50:23.391 NotebookApp]  or http://127.0.0.1:8888/?token=3660c9ee9b225458faaf853200bc512ff2206f635ab2b1d9
[I 21:50:23.391 NotebookApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
[C 21:50:23.394 NotebookApp]

   To access the notebook, open this file in a browser:
      file:///root/.local/share/jupyter/runtime/nbserver-1-open.html
   Or copy and paste one of these URLs:
      http://tf-notebook:8888/?token=3660c9ee9b225458faaf853200bc512ff2206f635ab2b1d9
   or http://127.0.0.1:8888/?token=3660c9ee9b225458faaf853200bc512ff2206f635ab2b1d9
```

通过使用登录口令，我们可以进入notebook开发环境：

```
http:://<your-machine-ip>:30001/?token=3660c9ee9b225458faaf853200bc512ff2206f635ab2b1d9
```

#### GPU测试

##### 安装Prometheus

- 可以参考[这里](https://github.com/prometheus-operator/kube-prometheus.git)安装kube-prometheus
- `kubesphere`平台将在后续版本支持更好用户体验的可观察性

##### 部署ServiceMonitor

`gpu-operator`帮我们提供了 `nvidia-dcgm-exporter` 这个`exportor`,只需要将它集成到`Prometheus`的可采集对象中，也就是`ServiceMonitor`中，我们就能获取GPU监控数据了:

```
$ kubectl get pods -n gpu-operator-resources
NAME                                       READY   STATUS      RESTARTS   AGE
gpu-feature-discovery-ff4ng                1/1     Running     2          15h
nvidia-container-toolkit-daemonset-2vxjz   1/1     Running     0          15h
nvidia-dcgm-exporter-pqwfv                 1/1     Running     0          5h27m #here
nvidia-device-plugin-daemonset-42n74       1/1     Running     0          5h27m
nvidia-device-plugin-validation            0/1     Completed   0          5h27m
nvidia-driver-daemonset-dvd9r              1/1     Running     3          15h
```

为了方便演示，本文将`nvidia-dcgm-exporter`的`svc`设为`NodePort`类型:

```
$ kubectl get svc -n gpu-operator-resources
NAME                   TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
nvidia-dcgm-exporter   NodePort   10.233.28.200   <none>        9400:31129/TCP   5h31m
$ curl http://[your node ip]:31129/metrics
----
DCGM_FI_DEV_SM_CLOCK{gpu="0",UUID="GPU-eeff7856-475a-2eb7-6408-48d023d9dd28",device="nvidia0",container="tf-notebook",namespace="default",pod="tf-notebook"} 405
DCGM_FI_DEV_MEM_CLOCK{gpu="0",UUID="GPU-eeff7856-475a-2eb7-6408-48d023d9dd28",device="nvidia0",container="tf-notebook",namespace="default",pod="tf-notebook"} 715
DCGM_FI_DEV_GPU_TEMP{gpu="0",UUID="GPU-eeff7856-475a-2eb7-6408-48d023d9dd28",device="nvidia0",container="tf-notebook",namespace="default",pod="tf-notebook"} 30
DCGM_FI_DEV_POWER_USAGE{gpu="0",UUID="GPU-eeff7856-475a-2eb7-6408-48d023d9dd28",device="nvidia0",container="tf-notebook",namespace="default",pod="tf-notebook"} 24.124000
DCGM_FI_DEV_PCIE_REPLAY_COUNTER{gpu="0",UUID="GPU-eeff7856-475a-2eb7-6408-48d023d9dd28",device="nvidia0",container="tf-notebook",namespace="default",pod="tf-notebook"} 0
DCGM_FI_DEV_GPU_UTIL{gpu="0",UUID="GPU-eeff7856-475a-2eb7-6408-48d023d9dd28",device="nvidia0",container="tf-notebook",namespace="default",pod="tf-notebook"} 0
DCGM_FI_DEV_MEM_COPY_UTIL{gpu="0",UUID="GPU-eeff7856-475a-2eb7-6408-48d023d9dd28",device="nvidia0",container="tf-notebook",namespace="default",pod="tf-notebook"} 0
DCGM_FI_DEV_ENC_UTIL{gpu="0",UUID="GPU-eeff7856-475a-2eb7-6408-48d023d9dd28",device="nvidia0",container="tf-notebook",namespace="default",pod="tf-notebook"} 0
DCGM_FI_DEV_DEC_UTIL{gpu="0",UUID="GPU-eeff7856-475a-2eb7-6408-48d023d9dd28",device="nvidia0",container="tf-notebook",namespace="default",pod="tf-notebook"} 0
----
```

查看`nvidia-dcgm-exporter`暴露的`svc`和`ep`：

```
root@master:~/gpu/samples# kubectl describe svc nvidia-dcgm-exporter -n gpu-operator-resources
Name:                     nvidia-dcgm-exporter
Namespace:                gpu-operator-resources
Labels:                   app=nvidia-dcgm-exporter
Annotations:              prometheus.io/scrape: true
Selector:                 app=nvidia-dcgm-exporter
Type:                     NodePort
IP:                       10.233.28.200
Port:                     gpu-metrics  9400/TCP
TargetPort:               9400/TCP
NodePort:                 gpu-metrics  31129/TCP
Endpoints:                10.233.84.54:9400
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
```

配置`ServiceMonitor`定义清单:

```
$ cat custom/gpu-cm.yaml 
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: nvidia-dcgm-exporter
  namespace: monitoring
  labels:
     app: nvidia-dcgm-exporter
spec:
  jobLabel: nvidia-gpu
  endpoints:
  - port: gpu-metrics
    interval: 15s
  selector:
    matchLabels:
      app: nvidia-dcgm-exporter
  namespaceSelector:
    matchNames:
    - gpu-operator-resources
```

将它提交给`k8s`平台后，我们可以在`Prometheus`的`UI`上看到采集到的内容：

![image-20210127153611937](https://raw.githubusercontent.com/zhu733756/bedpic/main/imagesimage-20210127153611937.png)

##### 使用Grafana

通过配置和设计，本文制作了一个简陋的`dashboard`如下：

![image-20210127150716255](../../../../../AppData/Roaming/Typora/typora-user-images/image-20210127150716255.png)

通过运行一个AI任务后，我们可以清晰地捕捉到`GPU`的监控:

![](https://raw.githubusercontent.com/zhu733756/bedpic/main/imagesimagesimage-20210127153816691.png)

#### 卸载

```
$ helm list
NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
gpu-operator-1611672791 default         1               2021-01-26 14:53:18.189686371 +0000 UTC deployed        gpu-operator-1.5.1      1.5.1      
$ helm uninstall gpu-operator-1611672791
```

#### 重启无法使用CPU这件事

关于部署好`gpu-operator`和`AI`的集群，重启时可能会出现插件还没加载，应用优先载入的情况，这时会出现用不上gpu的问题，需要重新部署应用才行。