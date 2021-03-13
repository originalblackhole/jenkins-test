node {

    //定义mvn环境
    def mvnHome = tool 'M3'
    env.PATH = "${mvnHome}/bin:${env.PATH}"

    stage('build') {

        // 打包源码
        checkout scm
        sh 'mvn -B -DskipTests clean package'

    }

    stage('docker build') {

        //构建镜像
        def customImage = docker.build("jenkins-test:latest")

    }

    stage("deploy") {

        // 项目部署
        sh ' ./deploy.sh'

    }
}