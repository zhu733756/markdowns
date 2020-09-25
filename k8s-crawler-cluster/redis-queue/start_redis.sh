#! /bin/bash

if [ ! -e "/usr/local/bin/redis" ];then
    echo "未找到redis-cli, 现在去安装..."
    wget http://download.redis.io/releases/redis-5.0.3.tar.gz
    tar -xvzf redis-5.0.3.tar.gz
    cd ./redis* && make && make install
fi

echo "创建redis master"

redis-cli --cluster create redis-app-0.redis-service.datacrawl.svc.cluster.local:6379


echo "输入redis master id"

read hash_id

redis-cli --cluster add-node redis-app-1.redis-service.datacrawl.svc.cluster.local:6379 --cluster-slave --cluster-master-id $hash_id