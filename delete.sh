#!/usr/bin/env bash

# 停止容器   删除非运行的容器 docker rm `docker ps -a -q`  删除docker无引用的镜像 docker rmi -f `docker images | grep'<none>' | awk '{print $3}'`
CID=$(docker ps | grep jenkins-test | awk '{print $1}')
if [ -n "$CID" ] ;then
    docker stop $CID
fi


# 删除旧镜像
IID=$(docker images | grep "$SERVER_NAME" | awk '{print $3}')
if [ -n "$IID" ] ;then
    docker rmi $IID
fi
