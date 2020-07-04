## docker-compose详解

**概览**

compose工具是一个用来运行多个容器的应用，通过这个工具，我们仅仅通过一个yaml文件就能配置应用服务的参数。它可以用来产品/开发/测试,/持续化部署。

使用compose很简单：

- 在yaml文件的上下文，使用一个Dockerfile打包你的app代码为镜像【web】
- 在yaml中定义你的其他应用集成【redis】
- 运行docker-compose up

```
version: '2.0'
services:
  web:
    build: .
    ports:
    - "5000:5000"
    volumes:
    - .:/code
    - logvolume01:/var/log
    links:
    - redis
  redis:
    image: redis
volumes:
  logvolume01: {}
```

compose的格式

| **Compose file format** | **Docker Engine release** |
| :---------------------- | :------------------------ |
| 3.8                     | 19.03.0+                  |
| 3.7                     | 18.06.0+                  |
| 3.6                     | 18.02.0+                  |
| 3.5                     | 17.12.0+                  |
| 3.4                     | 17.09.0+                  |
| 3.3                     | 17.06.0+                  |
| 3.2                     | 17.04.0+                  |
| 3.1                     | 1.13.1+                   |
| 3.0                     | 1.13.0+                   |
| 2.4                     | 17.12.0+                  |
| 2.3                     | 17.06.0+                  |
| 2.2                     | 1.13.0+                   |
| 2.1                     | 1.12.0+                   |
| 2.0                     | 1.10.0+                   |
| 1.0                     | 1.9.1.+                   |

compose的其他命令：

```
Commands:
  build              Build or rebuild services
  bundle             Generate a Docker bundle from the Compose file
  config             Validate and view the Compose file
  create             Create services
  down               Stop and remove containers, networks, images, and volumes
  events             Receive real time events from containers
  exec               Execute a command in a running container
  help               Get help on a command
  images             List images
  kill               Kill containers
  logs               View output from containers
  pause              Pause services
  port               Print the public port for a port binding
  ps                 List containers
  pull               Pull service images
  push               Push service images
  restart            Restart services
  rm                 Remove stopped containers
  run                Run a one-off command
  scale              Set number of containers for a service
  start              Start services
  stop               Stop services
  top                Display the running processes
  unpause            Unpause services
  up                 Create and start containers
  version            Show the Docker-Compose version information
```

特征：

在一台主机上部署多个隔离的容器环境，可以使用自定义的项目名称通过使用-p参数。

当所有容器被创建时，如果发现有先前容器运行，会保护先前的挂载数据。

只对配置文件发生改变的容器进行重建。

支持丰富的环境变量和extends扩展。

compose文件（version 3）参考说明：

build部分：

可以指定你的打包代码上下文（一般是yaml文件）的相对路径