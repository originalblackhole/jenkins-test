#!/usr/bin/env bash

SERVER_NAME=jenkins-test
BASE_PATH=/usr/local/jenkins/$SERVER_NAME
# 源jar路径  即jenkins构建后存放的路径
SOURCE_PATH=/home/jenkins/workspace/$SERVER_NAME
#docker 镜像/容器名字或者jar名字 这里都命名为这个

#容器id
CID=$(docker ps | grep "$SERVER_NAME" | awk '{print $1}')
#镜像id
IID=$(docker images | grep "$SERVER_NAME" | awk '{print $3}')

if [ -n "$CID" ] ;then
	echo "存在$SERVER_NAME容器，CID=$CID"
	docker stop $SERVER_NAME
	docker rm $SERVER_NAME
	docker rm jenkins-test
fi
#docker run -u root --rm -d -p 7777:7777 --name $SERVER_NAME --privileged=true -v $BASE_PATH:$BASE_PATH jenkins/test:latest
#docker run -u root --rm -d -p 7777:7777 --name jenkins-test --privileged=true  jenkins/test:latest
docker run --name $SERVER_NAME -d -p 7777:7777 --privileged=true -v $BASE_PATH:$BASE_PATH $SERVER_NAME

# 删除不运行的镜像
docker rmi IID