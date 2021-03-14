#!/usr/bin/env bash

SERVER_NAME=jenkins-test
BASE_PATH=/usr/local/jenkins/$SERVER_NAME
# 源jar路径  即jenkins构建后存放的路径
SOURCE_PATH=/home/jenkins/workspace/$SERVER_NAME
#docker 镜像/容器名字或者jar名字 这里都命名为这个

docker run --name $SERVER_NAME -d -p 7777:7777 --privileged=true -v :$SOURCE_PATH:$BASE_PATH $SERVER_NAME
#docker run --name jenkins-test -d -p 7777:7777 --privileged=true -v /home/jenkins/workspace/jenkins-test:/usr/local/jenkins/jenkins-test jenkins-test
