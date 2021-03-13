#!/usr/bin/env bash

#BASE_PATH=/usr/local/jenkins/jenkins-test
# 源jar路径  即jenkins构建后存放的路径
#SOURCE_PATH=/home/jenkins/workspace
#docker 镜像/容器名字或者jar名字 这里都命名为这个
SERVER_NAME=jenkins-test
#容器id
CID=$(docker ps | grep "$SERVER_NAME" | awk '{print $1}')
#镜像id
IID=$(docker images | grep "$SERVER_NAME" | awk '{print $3}')

if [ -n "$CID" ] ;then
	echo "存在$SERVER_NAME容器，CID=$CID"
	docker stop $SERVER_NAME
fi
#docker run -u root --rm -d -p 7777:7777 --name $SERVER_NAME --privileged=true -v $BASE_PATH:$BASE_PATH jenkins/test:latest
docker run -u root --rm -d -p 7777:7777 --name $SERVER_NAME --privileged=true  jenkins/test:latest

# 删除不运行的镜像
docker rmi IID