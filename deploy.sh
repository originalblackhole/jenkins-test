#!/usr/bin/env bash

SERVER_NAME=jenkins-test
BASE_PATH=/usr/local/jenkins/$SERVER_NAME
# 源jar路径  即jenkins构建后存放的路径
SOURCE_PATH=/home/jenkins/workspace/$SERVER_NAME
#docker 镜像/容器名字或者jar名字 这里都命名为这个

docker run --name $SERVER_NAME --rm -d -p 7777:7777 --privileged=true -v $BASE_PATH:$SOURCE_PATH $SERVER_NAME
