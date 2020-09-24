

## docker-compose详解

## 概览

compose工具是一个用来运行多个容器的应用，通过这个工具，我们仅仅使用一个yaml文件，就能配置整个应用服务。它可以用来产品、开发、测试,、持续化部署。

#### 流程：

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

#### 格式

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

#### 其他命令

```
Commands:
  build              Build or rebuild services
  bundle             Generate a Docker bundle FROM the Compose file
  config             Validate and view the Compose file
  create             Create services
  down               Stop and remove containers, networks, images, and volumes
  events             Receive real time events FROM containers
  exec               Execute a command in a running container
  help               Get help on a command
  images             List images
  kill               Kill containers
  logs               View output FROM containers
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

#### 特征

- 在一台主机上部署多个隔离的容器环境，可以使用自定义的项目名称通过使用-p参数。

- 当所有容器被创建时，如果发现有先前容器运行，会保护先前的挂载数据。

- 只对配置文件发生改变的容器进行重建。

- 支持丰富的环境变量和extends扩展。


## 文件配置

### build

可以指定你需要build的代码的相对路径：

```
version: "3.8"
services:
  webapp:
    build: ./code
```

也可以指定Dockerfile文件来创建

```
version: "3.8"
services:
  webapp:
    build:
      context: ./some-dir
      dockerfile: Dockerfile
      args:
        buildno: 1
```

也可以增加image，将会为你创建一个镜像

```
build: ./dir
image: webapp:tag
```

##### `CONTEXT`

`build`中的`context`字段，可以是一个包含`Dockfile`的文件夹，也可以是一个git仓库url。如果当这个值是一个相对路径，就会被认定是相对于`yaml`文件或者docker daemon的路径。一般来说，在工程目录下放`yaml`文件，这时，工程目录就是`context`的绝对路径。

##### `image`

`build`中的`context`字段，从仓库中拉取的镜像名称

```ymal
image: redis
image: ubuntu:18.04
image: tutum/influxdb
image: example-registry.com:4000/postgresql
image: a4bc65fd
```

##### `args`

`build`环境变量`args`主要作用于build过程

dockerfile中：

```dockerfile
ARG buildno
ARG gitcommithash

RUN echo "Build number: $buildno"
RUN echo "Based on commit: $gitcommithash"
```

`yaml`文件中：

```yaml
build:
  context: .
  args:
    buildno: 1
    gitcommithash: cdc3b19
```

注意，dockerfile中FROM字段之前的ARG，是不会作用于FROM之下的，如果确实需要该变量时，指定在FROM之下即可，你可以理解为FROM之下才是build过程，以下的例子，可以看成是实参传递给形参。

```dockerfile
ARG VERSION=latest
FROM busybox:$VERSION
ARG VERSION
RUN echo $VERSION > image_version
```

##### `CACHE_FROM`

镜像缓存（>=3.2）

```yml
build:
  context: .
  cache_from:
    - alpine:latest
    - corp/web_app:3.14
```

##### `NETWORK`

`build`过程中的`run`指令中网络连接（>=3.4）

```
# host网络
build:
  context: .
  network: host
  
# 自定义网络 
build:
  context: .
  network: custom_network_1

# 禁止访问
build:
  context: .
  network: none
```

##### `SHM_SIZE`

 设置`build`过程中，容器的`/dev/shm`分区的大小 

```yml
build:
  context: .
  shm_size: '2gb'
```

### container_name

服务的容器名称

```
container_name: my-web-container
```

### configs

配置文件（>=3.3）

```yml
version: "3.8"
services:
  redis:
    image: redis:latest
    deploy:
      replicas: 1
    configs:
      - my_config
      - my_other_config
configs:
  my_config:
    file: ./my_config.txt
  my_other_config:
    external: true
```

### depends_on

服务之间的依存关系。（<3.0, 3以上不支持）

下面的例子，运行docker-compose up时，redis和db服务会在web前面启动（不是等到服务真正完全启动，只是一开始即可），运行docker-compose stop时，web会在redis和db服务会前面关闭。

```yml
version: "3.8"
services:
  web:
    build: .
    depends_on:
      - db
      - redis
  redis:
    image: redis
  db:
    image: postgres
```

### deploy

 指定与服务的部署和运行有关的配置。这仅在通过docker stack deploy部署到集群时才生效，并且被docker-compose up和docker-compose run忽略（>=3.0）。 

```yml
version: "3.8"
services:
  redis:
    image: redis:alpine
    deploy:
      replicas: 6
      placement:
        max_replicas_per_node: 1
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure
```

##### replicas

分片数量

##### ` placement`

 设置`constraints` 和`preferences`。 

```yaml
version: "3.8"
services:
  db:
    image: postgres
    deploy:
      placement:
        constraints:
          - "node.role==manager"
          - "engine.labels.operatingsystem==ubuntu 18.04"
        preferences:
          - spread: node.labels.zone
```

##### `update_config`

更新配置文件的策略：

- `parallelism`: The number of containers to update at a time.
- `delay`: The time to wait between updating a group of containers.
- `failure_action`: What to do if an update fails. One of `continue`, `rollback`, or `pause` (default: `pause`).
- `monitor`: Duration after each task update to monitor for failure `(ns|us|ms|s|m|h)` (default 0s).
- `max_failure_ratio`: Failure rate to tolerate during an update.
- `order`: Order of operations during updates. One of `stop-first` (old task is stopped before starting new one), or `start-first` (new task is started first, and the running tasks briefly overlap) (default `stop-first`) **Note**: Only supported for v3.4 and higher.

##### `restart_policy`

是否配置以及怎样重启：

- `condition`: One of `none`, `on-failure` or `any` (default: `any`).
- `delay`: How long to wait between restart attempts, specified as a [duration](https://docs.docker.com/compose/compose-file/#specifying-durations) (default: 0).
- `max_attempts`: How many times to attempt to restart a container before giving up (default: never give up). If the restart does not succeed within the configured `window`, this attempt doesn’t count toward the configured `max_attempts` value. For example, if `max_attempts` is set to ‘2’, and the restart fails on the first attempt, more than two restarts may be attempted.
- `window`: How long to wait before deciding if a restart has succeeded, specified as a [duration](https://docs.docker.com/compose/compose-file/#specifying-durations) (default: decide immediately).

##### `ENDPOINT_MODE`

 为连接到群集的外部客户端指定服务发现方法。 

-  `endpoint_mode: vip`，Docker为服务分配了虚拟IP（VIP），该虚拟IP充当客户端访问网络上服务的前端 ；
-  `endpoint_mode: dnsrr` ， 对服务名称的DNS查询返回IP地址列表，并且客户端直接连接到其中一个，如果需要负载均衡时，比较有用 。

```
version: "3.8"

services:
  wordpress:
    image: wordpress
    ports:
      - "8080:80"
    networks:
      - overlay
    deploy:
      mode: replicated
      replicas: 2
      endpoint_mode: vip

  mysql:
    image: mysql
    volumes:
       - db-data:/var/lib/mysql/data
    networks:
       - overlay
    deploy:
      mode: replicated
      replicas: 2
      endpoint_mode: dnsrr

volumes:
  db-data:

networks:
  overlay:
```

##### `LABELS`

一组或者多组key-value的元数据，用来区分标识其他软件中的类似镜像（>=3.3）。

### env_file

环境变量配置文件路径。如果配置有多个`env_file`值，当环境变量值有重复时，位于下面的`.env`文件中的变量值将会覆盖上面的。

```
services:
  some-service:
    env_file:
      - ./common.env
      - ./apps/web.env
      - /opt/runtime_opts.env
```

### environment

添加环境变量，以下两种写法都可以。

```yml
environment:
  RACK_ENV: development
  SHOW: 'true'
  SESSION_SECRET:
```

```yml
environment:
  - RACK_ENV=development
  - SHOW=true
  - SESSION_SECRET
```

注意，这些环境变量不会在build过程生效（如果添加了build字段的话），如果需要在`build`过程可见，可以使用`ARG`。

### external_links

链接到当前部署服务的外部容器 `CONTAINER: ALIAS`

```yaml
external_links:
  - redis_1
  - project_db_1:mysql
  - project_db_1:postgresql
```

### extra_hosts

添加hosts

```
extra_hosts:
  - "somehost:162.242.195.82"
  - "otherhost:50.31.209.229"
```

相当于在容器的`/etc/hosts`添加了下面配置

```
162.242.195.82  somehost
50.31.209.229   otherhost
```

### healthcheck

监测容器健康：

```yml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost"]
  interval: 1m30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

关闭监测，相当于`test:["NONE"]`：

```yml
healthcheck:
  disable: true
```

### links

连接另一个服务中的容器，需要指定` SERVICE:ALIAS `。如果同时定义了`networks`和`links`，则至少要指定一个网络进行通信。另外，官方说这个字段后面可能被移除。

```
web:
  links:
    - "db"
    - "db:database"
    - "redis"
```

#### logging

服务的日志, 默认`driver`是`json-file`，还有`syslog`以及`none`。

为日志驱动指定一个日志选项，相当于docker run中参数 `--log-opt`  。

```
logging:
  driver: syslog
  options:
    syslog-address: "tcp://192.168.0.42:123"
```

对于`json-file`, 可以支持以下配置：

```
options:
  max-size: "200k"
  max-file: "10"
```

### network_mode

网络模式，同docker client中的参数 `--network`

```
network_mode: "bridge"
network_mode: "host"
network_mode: "none"
network_mode: "service:[service name]"
network_mode: "container:[container name/id]"
```

### networks

申明整个服务的网络

```
services:
  some-service:
    networks:
     - some-network
     - other-network
```

### ports

暴露的端口映射，这与network_mode中的host模式不兼容，因为host模式中，容器直接占用的是虚拟机端口，也就不需要构建映射了。

```
ports:
  - "3000"
  - "3000-3005"
  - "8000:8000"
  - "9090-9091:8080-8081"
  - "49100:22"
  - "127.0.0.1:8001:8001"
  - "127.0.0.1:5000-5010:5000-5010"
  - "6060:6060/udp"
  - "12400-12500:1240"
```

以下这种配置模式中:

- `target`: 容器端口
- `published`:公开端口
- `protocol`: 传输协议
- `mode`: `host`将在每个节点上发布一个host端口， `ingress`  使群集模式端口达到负载平衡 。

```
ports:
  - target: 80
    published: 8080
    protocol: tcp
    mode: host
```

### restart

- no，在任何突发情况下都不会重启
- always，容器经常重启
- on-failure， 退出代码指示失败错误 
- unless-stopped,  除非容器停止，将一直重启

```
restart: "no"
restart: always
restart: on-failure
restart: unless-stopped
```

### volumes

挂载多个host路径给容器，如果你希望复用一个`volumes`的话，可以放在顶层。

```yaml
version: "3.8"
services:
  web:
    image: nginx:alpine
    volumes:
      - type: volume
        source: mydata
        target: /data
        volume:
          nocopy: true
      - type: bind
        source: ./static
        target: /opt/app/static

  db:
    image: postgres:latest
    volumes:
      - "/var/run/postgres/postgres.sock:/var/run/postgres/postgres.sock"
      - "dbdata:/var/lib/postgresql/data"

volumes:
  mydata:
  dbdata:
```

`volumes`短语法：

```
volumes:
  # Just specify a path and let the Engine create a volume
  - /var/lib/mysql

  # Specify an absolute path mapping
  - /opt/data:/var/lib/mysql

  # Path on the host, relative to the Compose file
  - ./cache:/tmp/cache

  # User-relative path
  - ~/configs:/etc/configs/:ro

  # Named volume
  - datavolume:/var/lib/mysql
```

`volumes`长语法：

- `type`: `volume`, `bind`, `tmpfs` or `npipe`

- `source`: 主机上给容器绑定的挂载点路径, 或者是定义在顶层的`volumes`

- `target`: 容器上路径

- `read_only`: 把挂载点设置成只读

- ```
  bind: 
  ```

  - `propagation`:  用于绑定的传播模式 

- ```
  volume: 
  ```

  - `nocopy`: 是否禁止复制容器数据 

- ```
  tmpfs:
  ```

  - `size`:  tmpfs挂载的大小（以字节为单位） 

- `consistency`

```
version: "3.8"
services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - type: volume
        source: mydata
        target: /data
        volume:
          nocopy: true
      - type: bind
        source: ./static
        target: /opt/app/static

networks:
  webnet:

volumes:
  mydata:
```

如上所示，当最外层的volumes可以为空。这时，将由默认驱动`local`配置host上的挂载点（一般情况下，在`/var/lib/docker/volumes/`下，具体参考 https://docs.docker.com/storage/volumes/#start-a-container-with-a-volume ****）。

当然，也可以用`driver_opts`指定：

```
volumes:
  example:
    driver_opts:
      type: "nfs"
      o: "addr=10.40.0.199,nolock,soft,rw"
      device: ":/docker/example"
```

如果设置`external`为true，表示这个挂载点已经被创建过了，如果没有在外部找到，将会报错：

```
version: "3.8"

services:
  db:
    image: postgres
    volumes:
      - data:/var/lib/postgresql/data

volumes:
  data:
    external: true
```

更多，参考官方文档 https://docs.docker.com/compose/compose-file/ 。