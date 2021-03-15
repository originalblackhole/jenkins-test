#!/usr/bin/env bash

# 删除旧镜像
#IID=$(docker images | grep jenkins-test | awk '{print $3}')
IID=docker rmi $(docker images | grep ${env.registryName} | awk '{print \$3}')
if [ -n "$IID" ] ;then
    docker rmi $IID
fi

