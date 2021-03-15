import groovy.json.JsonSlurper

node {

    currentBuild.result = "SUCCESS"
    // 默认设置
    env.VERSION = '1.0.0'
    env.credentialsId = ''
    env.host = ''
    env.registryName = ''
    def imageName = ''
    def input_result // 用户输入项
    def input_image // 用户输入项
    def mvnHome = tool 'M3'
    env.PATH = "${mvnHome}/bin:${env.PATH}"

    try {
        stage('config') {

            input_result = input message: '请选择部署环境', ok: '确认', parameters: [
                booleanParam(name: 'dev', defaultValue: true),
                booleanParam(name: 'test', defaultValue: false),
                booleanParam(name: 'deploy', defaultValue: false)
            ]

            input_image = input message: '推送镜像至仓库并部署', ok: '确认', parameters: [
                booleanParam(name: 'push', defaultValue: true),
                booleanParam(name: 'deploy', defaultValue: false)
            ]

            // 判断发布环境
            if (input_result.dev) {
                env.PRO_ENV = "dev"
            }
            if (input_result.test) {
                env.PRO_ENV = "test"
            }
            if (input_result.deploy) {
                env.PRO_ENV = "deploy"
            }
            echo "Branch: ${env.BRANCH_NAME}, Environment: ${env.PRO_ENV}"
            sh 'echo $(env)'
        }
        
        stage('package') {

            // 读取配置信息
            if(fileExists('config.json')) {
                def str = readFile 'config.json'
                def jsonSlurper = new JsonSlurper()
                def obj = jsonSlurper.parseText(str)

                env.registryName = obj.registryName
                def envConifg = obj.env[env.PRO_ENV]
                echo "envConifg: ${envConifg}"

                env.VERSION = obj.version
                env.credentialsId = envConifg.credentialsId
                env.host = envConifg.host
                env.port = envConifg.port
                env.name = envConifg.name

                imageName = "${env.registryName}:${env.VERSION}_${env.PRO_ENV}_${BUILD_NUMBER}"

                echo "VERSION: ${env.VERSION} ${imageName}"
            }

            //checkout([$class: 'GitSCM', branches: [[name: '*/dev']], extensions: [], userRemoteConfigs: [[credentialsId: 'e761309f-146f-4c5f-b7fd-1debf91fef38', url: 'https://gitee.com/original-blackhole/jenkins-test.git']]])
            withEnv(["MVN_HOME=$mvnHome"]) {
                if (isUnix()) {
                    sh 'mvn -B -DskipTests clean package'
                } else {
                    bat(/mvn -B -DskipTests clean package/)
                }
            }
        }

        stage('build'){

            // 构建上传镜像到容器仓库
            sh 'echo $(imageName)'
            sh 'echo $(env)'
            def customImage = docker.build(imageName, " --build-arg pro_env=${env.PRO_ENV} .")
            if(input_image.push) {
                //docker.withRegistry("https://ccr.ccs.tencentyun.com", 'a5613adf-a89a-443e-932c-d31dff210b76') {
                docker.withRegistry("https://${env.registryName}", 'a5613adf-a89a-443e-932c-d31dff210b76') {
                    customImage.push()
                }
            }
        }

        stage('Deploy'){
            if(input_image.deploy) {
                // wechat服务器
                withCredentials([usernamePassword(credentialsId: env.credentialsId, usernameVariable: 'USER', passwordVariable: 'PWD')]) {
                    def otherArgs = '-p 8080:8080' // 区分不同环境的启动参数
                    def remote = [:]
                    remote.name = 'ssh-deploy'
                    remote.allowAnyHosts = true
                    remote.host =  '1.15.123.16' //env.host
                    remote.user = 'root' //USER
                    remote.password = 'gm152688..'  //PWD

                    //sshCommand remote: remote, command: "ifconfig |grep inet"
                
                    if(env.PRO_ENV == "pro") {
                        otherArgs = '-p 8888:8888'
                    }

                    /* docker.withServer("tcp://192.168.3.63:2345", env.credentialsId){
                        //sh "docker rm \$(docker stop \$(docker ps -a | grep jenkins-test | awk '{print \$1}'))"
                        //docker.image(imageName).pull()
                        //docker.image(imageName).run('-p 8088:7777 --name jenkins-test -d')
                        //docker.image(imageName).run('docker ps -a')
                        sh 'docker ps -a'
                    } */

                    try {
                        sshCommand remote: remote, command: "docker rm $(docker stop $(docker ps -a | grep jenkins-test | awk '{print $1}'))"

                        //sudo docker login --username=100018063721 ccr.ccs.tencentyun.com
                        sshCommand remote: remote, command: "docker login -u 100018063721 -p gm152688 ccr.ccs.tencentyun.com"
                        sshCommand remote: remote, command: "docker pull $imageName"

                    } catch (err) {

                    }

                    sshCommand remote: remote, command: "docker run -d --name jenkins-test -v /var/jenkins/jenkins-test:/var/jenkins/jenkins-test -e PRO_ENV='${env.PRO_ENV}' ${otherArgs} ${imageName}"
                }
            }else{
                try {
                    sh "docker rm \$(docker stop \$(docker ps -a | grep jenkins-test | awk '{print \$1}'))"
                    docker.image(imageName).run('-p 8080:7777 --name jenkins-test -d')
                } catch (err) {

                }
            }
        }
        stage('delete'){
            // 删除旧的镜像
            try {
                //docker rmi $(docker images | grep ccr.ccs.tencentyun.com/blackhole/jenkins-test | awk '{print $3}')
                sh "docker rmi -f ${imageName.replaceAll("_${BUILD_NUMBER}", "_${BUILD_NUMBER.toInteger() - 1}")}"
            } catch (err) {

            }
        }
    }
    catch (err) {
        currentBuild.result = "FAILURE"
        throw err
    }

}
