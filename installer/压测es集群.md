#### 安装python环境

ubuntu参考：https://linuxize.com/post/how-to-install-python-3-8-on-ubuntu-18-04/

#### 安装pip3

apt install python3-pip

#### 安装 esrally

pip3 install esrally

#### 压测

https://esrally.readthedocs.io/en/stable/docker.html

for docker:

chown -R :1000 /rally/.rally/*

chmod -R 775 /rally/.rally/*

```
docker run elastic/rally
```

docker run -v /rally/.rally/rally.ini:/rally/.rally/rally.ini -d elastic/rally  race --track=geonames  --challenge=append-no-conflicts  --target-hosts=192.168.88.6:30103 --pipeline=benchmark-only --client-options="timeout:60,use_ssl:false,verify_certs:false,basic_auth_user:'elastic',basic_auth_password:'s32753N2CP2OS4KR0LUe2hRd'"  --report-format=csv --report-file=/rally/benchmarks/result.csv

 docker run  --rm -i  -v 000228f1a7099ab5491ed16fc0f78c172306c7aa2a48f00d119a19bdc28ca6ba::/rallyvolume  -ti python:3.8.2-slim /bin/bash

esrally list tracks

esrally list races



 curl -u elastic:s32753N2CP2OS4KR0LUe2hRd 192.168.88.6:30103/_cluster/health?pretty

docker exec -it 1365 -- sh

