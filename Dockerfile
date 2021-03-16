# 下载maven与java的镜像
FROM hub.c.163.com/wuxukun/maven-aliyun:3-jdk-8
# 指定当前操作目录
WORKDIR /var/jenkins/jenkins-test

#RUN yum update -y

#RUN yum install vim -y

ARG PRO_ENV=prod

#指定对外端口号
EXPOSE 7777
ADD ./target/jenkins-test-0.0.1-SNAPSHOT.jar app.jar
#启动java程序
#--spring.profiles.active=dev 多环境下指定环境 。 -c为清除以前启动的数据
ENTRYPOINT ["java","-jar","app.jar"]