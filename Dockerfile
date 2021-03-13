# 下载maven与java的镜像
FROM hub.c.163.com/wuxukun/maven-aliyun:3-jdk-8
# 指定当前操作目录
WORKDIR /home/jenkins/workspace/jenkins-test
#指定对外端口号
EXPOSE 7777
COPY ./target/jenkins-test-0.0.1-SNAPSHOT.jar app.jar
#启动java程序
#--spring.profiles.active=dev 多环境下指定环境 。 -c为清除以前启动的数据
ENTRYPOINT ["java","-jar","app.jar"]