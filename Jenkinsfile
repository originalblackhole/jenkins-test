node {
    //定义mvn环境
    def mvnHome = tool 'M3'
    env.PATH = "${mvnHome}/bin:${env.PATH}"
    stage('build') {
        checkout scm
        sh 'mvn -B -DskipTests clean package'
    }

    stage('Example') {
        def customImage = docker.build("jenkins-test:${env.BUILD_ID}")
        sh "echo ${env.BUILD_ID}"
    }

    stage(deploy) {
        sh "pwd"
        sh ' ./deploy.sh'
    }
}