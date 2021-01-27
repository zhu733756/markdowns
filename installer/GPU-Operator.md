## GPU-Operator

#### Code Repositories:

- GitHub: https://github.com/NVIDIA/gpu-operator
- GitLab: https://gitlab.com/nvidia/kubernetes/gpu-operator

#### Documents：

- https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/getting-started.html#install-nvidia-gpu-operator


#### K8s Runtime Architecture

![img](https://raw.githubusercontent.com/zhu733756/bedpic/main/images1334952-20190610155423745-506706065.png)

#### GPU-Operator Architecture

![../_images/nvidia-docker-arch.png](https://docs.nvidia.com/datacenter/cloud-native/_images/nvidia-docker-arch.png)

#### Components and Packages

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

#### Package Repo

- [nvidia-docker2](https://github.com/NVIDIA/nvidia-docker/tree/gh-pages/)

- [nvidia-container-toolkit](https://github.com/NVIDIA/nvidia-container-runtime/tree/gh-pages/)

- [libnvidia-container](https://github.com/NVIDIA/libnvidia-container/tree/gh-pages/)

#### Installation Guide

##### Prerequisites

Before installing the GPU Operator, you should ensure that the Kubernetes cluster meets some prerequisites.

1. Nodes must not be pre-configured with NVIDIA components (driver, container runtime, device plugin).
2. Nodes must be configured with Docker CE/EE, `cri-o`, or `containerd`. For docker, follow the official install [instructions](https://docs.docker.com/engine/install/).
3. If the HWE kernel (e.g. kernel 5.x) is used with Ubuntu 18.04 LTS, then the `nouveau` driver for NVIDIA GPUs must be blacklisted before starting the GPU Operator. Follow the steps in the CUDA installation [guide](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#runfile-nouveau-ubuntu) to disable the nouveau driver and update `initramfs`.
4. Node Feature Discovery (NFD) is required on each node. By default, NFD master and worker are automatically deployed. If NFD is already running in the cluster prior to the deployment of the operator, set the Helm chart variable `nfd.enabled` to `false` during the Helm install step.
5. For monitoring in Kubernetes 1.13 and 1.14, enable the kubelet `KubeletPodResources` [feature](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/) gate. From Kubernetes 1.15 onwards, its enabled by default.

##### Linux Distributions

Supported Linux distributions are listed below:

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

##### Container Runtimes

Supported container runtimes are listed below:

| OS Name / Version    | amd64 / x86_64 | ppc64le | arm64 / aarch64 |
| -------------------- | -------------- | ------- | --------------- |
| Docker 18.09         | X              | X       | X               |
| Docker 19.03         | X              | X       | X               |
| RHEL/CentOS 8 podman | X              |         |                 |
| CentOS 8 Docker      | X              |         |                 |
| RHEL/CentOS 7 Docker | X              |         |                 |

##### Platform Requirements

The list of prerequisites for running NVIDIA Container Toolkit is described below:

1. GNU/Linux x86_64 with kernel version > 3.10
2. Docker >= 19.03 (recommended, but some distributions may include older versions of Docker. The minimum supported version is 1.12)
3. NVIDIA GPU with Architecture > Fermi (or compute capability 2.1)
4. [NVIDIA drivers](http://www.nvidia.com/object/unix.html) ~= 361.93 (untested on older versions)

##### Setting up Docker

##### Setting up NVIDIA Container Toolkit

Setup the `stable` repository and the GPG key:

```
$ distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
   && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
   && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
```

Install the `nvidia-docker2` package (and dependencies) after updating the package listing:

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

Restart the Docker daemon to complete the installation after setting the default runtime:

```
$ sudo systemctl restart docker
```

##### [Environment variables (OCI spec)](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/user-guide.html#environment-variables-oci-spec)

Users can control the behavior of the NVIDIA container runtime using environment variables - especially for enumerating the GPUs and the capabilities of the driver. Each environment variable maps to an command-line argument for `nvidia-container-cli` from [libnvidia-container](https://github.com/NVIDIA/libnvidia-container). These variables are already set in the NVIDIA provided base [CUDA images](https://ngc.nvidia.com/catalog/containers/nvidia:cuda).

#### Install NVIDIA GPU Operator

##### Install Helm

The preferred method to deploy the GPU Operator is using `helm`.

```
$ curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
   && chmod 700 get_helm.sh \
   && ./get_helm.sh
```

Now, add the NVIDIA Helm repository:

```
$ helm repo add nvidia https://nvidia.github.io/gpu-operator \
   && helm repo update
```

##### Install the GPU Operator

###### docker as runtime

```
helm install --wait --generate-name nvidia/gpu-operator
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

**If the installation process times out, you can check whether the docker images are pulling or not.**

##### [Considerations to Install in Air-Gapped Clusters](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/getting-started.html#considerations-to-install-in-air-gapped-clusters)

##### Deploy GPU Operator with updated `values.yaml`

```
$ helm install --wait --generate-name \
   nvidia/gpu-operator -f values.yaml
```

#### Check the status of your deployments

##### Check the health status of the pods

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

##### Check if the resource exists

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

#### Running Sample GPU Applications

##### Two examples from the official document

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

##### Deploy the two applications

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

##### Jupyter Notebook

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

Take the token to access the jupyter notebook online service, you can  enjoy your jobs now.

```
http:://<your-machine-ip>:30001/?token=3660c9ee9b225458faaf853200bc512ff2206f635ab2b1d9
```

#### GPU Telemetry

##### Setting up Prometheus

- you can deploy your Prometheus system by following [here](https://github.com/prometheus-operator/kube-prometheus.git)
- A better Prometheus on the kubesphere platform will provide support in subsequent versions

##### Deploy your own ServiceMonitor

Show the exportor `nvidia-dcgm-exporter` deployed by the operator

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

Edit the `svc` to `NodePort` type,  so we can get the metrics like this:

```
$ kubectl get svc -n gpu-operator-resources
NAME                   TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
nvidia-dcgm-exporter   NodePort   10.233.28.200   <none>        9400:31129/TCP   5h31m
$ curl http://[your node ip]:31129/gpu/metrics
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

Get the service and endpoint:

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

So we can edit a servicemonitor like this:

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

After applying it, we can see the metrics like this below:

![image-20210127153611937](https://raw.githubusercontent.com/zhu733756/bedpic/main/imagesimage-20210127153611937.png)

###### Using Grafana

By configuration and decoration, you can see your own dashboard on the Grafana interface:

![image-20210127150716255](../../../../../AppData/Roaming/Typora/typora-user-images/image-20210127150716255.png)

After running a AI task, you can see the changes below:

![](https://raw.githubusercontent.com/zhu733756/bedpic/main/imagesimagesimage-20210127153816691.png)