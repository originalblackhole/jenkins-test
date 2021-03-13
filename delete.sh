#!/usr/bin/env bash

# 停止容器
docker stop $(docker ps | grep jenkins-test | awk '{print $1}')

# 删除旧镜像
docker rmi $(docker images | grep jenkins-test | awk '{print $1}')
