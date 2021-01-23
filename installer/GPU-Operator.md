## GPU-Operator

#### GPU-Operator Architecture

![../_images/nvidia-docker-arch.png](https://docs.nvidia.com/datacenter/cloud-native/_images/nvidia-docker-arch.png)

#### K8s Runtime Architecture

![img](https://img2018.cnblogs.com/blog/1334952/201906/1334952-20190610155423745-506706065.png)

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

```
$ sudo apt-get install -y nvidia-docker2
```

Restart the Docker daemon to complete the installation after setting the default runtime:

```
$ sudo systemctl restart docker
```

At this point, a working setup can be tested by running a base CUDA container:

```
$ sudo docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

##### Adding the NVIDIA Runtime

**Do not follow this section if you installed the `nvidia-docker2` package below, it already registers the runtime. So just jump to next step!**

###### Systemd drop-in file

```
$ sudo mkdir -p /etc/systemd/system/docker.service.d
```

```
$ sudo tee /etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --host=fd:// --add-runtime=nvidia=/usr/bin/nvidia-container-runtime
EOF
```

```
$ sudo systemctl daemon-reload \
  && sudo systemctl restart docker
```

###### Daemon configuration file

The `nvidia` runtime can also be registered with Docker using the `daemon.json` configuration file:

```
$ sudo tee /etc/docker/daemon.json <<EOF
{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF
```

```
sudo pkill -SIGHUP dockerd
```

###### Command Line

Use `dockerd` to add the `nvidia` runtime:

```
$ sudo dockerd --add-runtime=nvidia=/usr/bin/nvidia-container-runtime [...]
```

##### [Environment variables (OCI spec)](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/user-guide.html#environment-variables-oci-spec)

Users can control the behavior of the NVIDIA container runtime using environment variables - especially for enumerating the GPUs and the capabilities of the driver. Each environment variable maps to an command-line argument for `nvidia-container-cli` from [libnvidia-container](https://github.com/NVIDIA/libnvidia-container). These variables are already set in the NVIDIA provided base [CUDA images](https://ngc.nvidia.com/catalog/containers/nvidia:cuda).

##### Troubleshooting

###### Generating debugging logs

For most common issues, debugging logs can be generated and can help us root cause the problem. In order to generate these:

- Edit your runtime configuration under `/etc/nvidia-container-runtime/config.toml` and uncomment the `debug=...` line.
- Run your container again, thus reproducing the issue and generating the logs.

#### Prerequisites

Before installing the GPU Operator, you should ensure that the Kubernetes cluster meets some prerequisites.

1. Nodes must not be pre-configured with NVIDIA components (driver, container runtime, device plugin).
2. Nodes must be configured with Docker CE/EE, `cri-o`, or `containerd`. For docker, follow the official install [instructions](https://docs.docker.com/engine/install/).
3. If the HWE kernel (e.g. kernel 5.x) is used with Ubuntu 18.04 LTS, then the `nouveau` driver for NVIDIA GPUs must be blacklisted before starting the GPU Operator. Follow the steps in the CUDA installation [guide](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#runfile-nouveau-ubuntu) to disable the nouveau driver and update `initramfs`.
4. Node Feature Discovery (NFD) is required on each node. By default, NFD master and worker are automatically deployed. If NFD is already running in the cluster prior to the deployment of the operator, set the Helm chart variable `nfd.enabled` to `false` during the Helm install step.
5. For monitoring in Kubernetes 1.13 and 1.14, enable the kubelet `KubeletPodResources` [feature](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/) gate. From Kubernetes 1.15 onwards, its enabled by default.

Before installing the GPU Operator on NVIDIA vGPU, ensure the following.

1. The NVIDIA vGPU Host Driver is pre-installed on all hypervisors hosting NVIDIA vGPU accelerated Kubernetes worker node virtual machines. Please refer to [NVIDIA vGPU Documentation](https://docs.nvidia.com/grid/12.0/index.html) for details.
2. A NVIDIA vGPU License Server is installed and reachable from all Kubernetes worker node virtual machines.
3. A private registry is available to upload the NVIDIA vGPU specific driver container image.
4. Each Kubernetes worker node in the cluster has access to the private registry. Private registry access is usually managed through imagePullSecrets. See the Kubernetes Documentation for more information. The user is required to provide these secrets to the NVIDIA GPU-Operator in the driver section of the values.yaml file.
5. Git and Docker/Podman are required to build the vGPU driver image from source repository and push to local registry.

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

##### Considerations to Install in Air-Gapped Clusters

###### Local Image Registry

- Get the values.yaml

```
$ curl -sO https://raw.githubusercontent.com/NVIDIA/gpu-operator/master/deployments/gpu-operator/values.yaml
```

- Update `values.yaml` with repository, image details as applicable
- replace <repo.example.com:port> below with your local image registry url and port

```
operator:
  repository: <repo.example.com:port>
  image: gpu-operator
  version: 1.4.0
  imagePullSecrets: []
  validator:
    image: cuda-sample
    repository: <my-repository:port>
    version: vectoradd-cuda10.2
    imagePullSecrets: []

driver:
  repository: <repo.example.com:port>
  image: driver
  version: "450.80.02"
  imagePullSecrets: []

toolkit:
  repository: <repo.example.com:port>
  image: container-toolkit
  version: 1.4.0-ubuntu18.04
  imagePullSecrets: []

devicePlugin:
  repository: <repo.example.com:port>
  image: k8s-device-plugin
  version: v0.7.1
  imagePullSecrets: []

dcgmExporter:
  repository: <repo.example.com:port>
  image: dcgm-exporter
  version: 2.0.13-2.1.2-ubuntu20.04
  imagePullSecrets: []

gfd:
  repository: <repo.example.com:port>
  image: gpu-feature-discovery
  version: v0.2.2
  imagePullSecrets: []

node-feature-discovery:
  imagePullSecrets: []
  image:
    repository: <repo.example.com:port>
    tag: "v0.6.0"
```

###### Local Package Repository

The `Driver` container deployed as part of GPU operator require certain packages to be available as part of driver installation. In Air-Gapped installations, users are required to create a mirror repository for their OS distribution and make following packages available:

KERNEL_VERSION is the underlying running kernel version on the GPU node GCC_VERSION is the gcc version matching the one used for building underlying kernel

```
ubuntu:
   linux-headers-${KERNEL_VERSION}
   linux-image-${KERNEL_VERSION}
   linux-modules-${KERNEL_VERSION}

centos:
   elfutils-libelf.x86_64
   elfutils-libelf-devel.x86_64
   kernel-headers-${KERNEL_VERSION}
   kernel-devel-${KERNEL_VERSION}
   kernel-core-${KERNEL_VERSION}
   gcc-${GCC_VERSION}

rhel/rhcos:
   kernel-headers-${KERNEL_VERSION}
   kernel-devel-${KERNEL_VERSION}
   kernel-core-${KERNEL_VERSION}
   gcc-${GCC_VERSION}
```

```
kubectl create configmap repo-config -n gpu-operator-resources --from-file=<path-to-repo-list-file>
```

Once the ConfigMap is created using above command, update `values.yaml` with this information, to let GPU Operator mount the repo configiguration within `Driver` container to pull required packages.

###### Ubuntu

```
driver:
   repoConfig:
      configMapName: repo-config
      destinationDir: /etc/apt/sources.list.d
```

###### CentOS/RHEL/RHCOS

```
driver:
   repoConfig:
      configMapName: repo-config
      destinationDir: /etc/yum.repos.d
```

##### Deploy GPU Operator with updated `values.yaml`

```
$ helm install --wait --generate-name \
   nvidia/gpu-operator -f values.yaml
```

Check the status of the pods to ensure all the containers are running:

```
$ kubectl get pods -n gpu-operator-resources
```