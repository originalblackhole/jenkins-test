node {

    //定义mvn环境
    def mvnHome = tool 'M3'
    env.PATH = "${mvnHome}/bin:${env.PATH}"

    stage('build') {

        checkout scm
        sh 'mvn -B -DskipTests clean package'

    }

    stage('docker build') {

        // 停止容器
        sh "docker stop $(docker ps | grep jenkins-test | awk '{print $1}')"
        // 删除旧镜像
        sh "docker rmi $(docker images | grep jenkins-test | awk '{print $1}')"
        //构建镜像
        def customImage = docker.build("jenkins-test:latest")

    }

    stage("deploy") {

        sh ' ./deploy.sh'

    }
}