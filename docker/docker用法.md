## docker 

#### docker以root权限进入

```
docker exec -it -u root 'Container ID' /bin/bash
```

#### docker 执行上下文build

```
docker build .  -t ks-apisever:add-pod-level -f ./build/ks-apiserver/Dockerfile 
```

