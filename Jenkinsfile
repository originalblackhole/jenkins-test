import groovy.json.JsonSlurper

node {

    // 需要手动赋值的变量(是否需要全部移到config.json)
    def appointWorkDir = false                              // 是否指定挂载目录
    def projectName = 'jenkins-test'                        // 项目名称
    def hostWorkDir = '/var/jenkins/jenkins-test'           // 宿主机目录(随便设置)
    def workDir = '/var/jenkins/jenkins-test'               // 容器目录(Dockerfile中的WORKDIR目录)
    def openPort = '7777'                                   // 开放的端口(Dockerfile中的EXPOSE,使用该端口映射)
    def otherArgs = "--name ${projectName}"                 // 自定义其他启动参数(默认启动参数格式为: docker run -d -p 8080:8080 -e pro_env=dev)
    def buildArgs = " --build-arg PRO_ENV=${env.PRO_ENV} ." // 自定义其他构建镜像参数(默认参数格式为: docker build -t imageName:tag .)
    def mvnCMD = "mvn -B -DskipTests clean package"         // maven打包命令


    // 系统变量
    def imageName = ''
    def inputResult // 用户输入项
    def mvnHome = tool 'M3'
    env.host = ''
    env.VERSION = '1.0.0'
    env.registryName = ''
    env.credentialsId = ''
    env.registry_credentials_id = ''
    env.PATH = "${mvnHome}/bin:${env.PATH}"
    currentBuild.result = "SUCCESS"

    try {
        stage('choice') {

            inputResult = input message: '请选择部署环境', ok: '确认', parameters: [
                booleanParam(name: 'dev', defaultValue: true),
                booleanParam(name: 'test', defaultValue: false),
                booleanParam(name: 'prod', defaultValue: false)
            ]
            // 判断发布环境
            if (inputResult.dev) {
                env.PRO_ENV = "dev"
            }
            if (inputResult.test) {
                env.PRO_ENV = "test"
            }
            if (inputResult.prod) {
                env.PRO_ENV = "prod"
            }
            sh 'env $env'
        }
        
        stage('package') {

            // checkout测试时使用,jenkins上面直接使用SCM
            // checkout([$class: 'GitSCM', branches: [[name: '*/dev']], extensions: [], userRemoteConfigs: [[credentialsId: 'e761309f-146f-4c5f-b7fd-1debf91fef38', url: 'https://gitee.com/original-blackhole/jenkins-test.git']]])
            withEnv(["MVN_HOME=$mvnHome"]) {
                if (isUnix()) {
                    sh "${mvnCMD}"
                } else {
                    bat(/${mvnCMD}/)
                }
            }

            // 读取配置信息
            if(fileExists('config.json')) {
                def str = readFile 'config.json'
                def jsonSlurper = new JsonSlurper()
                def obj = jsonSlurper.parseText(str)
                echo "config.json: ${str}"

                env.VERSION = obj.version
                env.registryName = obj.registryName
                env.registry_credentials_id = obj.registry_credentials_id
                def envConifg = obj.env[env.PRO_ENV]
                echo "envConifg: ${envConifg}"

                env.credentialsId = envConifg.credentialsId
                env.host = envConifg.host
                env.port = envConifg.port
                env.name = envConifg.name

                imageName = "${env.registryName}:${env.VERSION}_${env.PRO_ENV}_${BUILD_NUMBER}"
                echo "VERSION: ${env.VERSION} ,imageName: ${imageName}"
            }
        }

        stage('build'){

            // 构建镜像并上传到容器仓库
            echo "imageName: ${imageName}"
            def customImage = docker.build(imageName, " --build-arg PRO_ENV=${env.PRO_ENV} .")
            if(!(inputResult.dev)) {
                echo "registry_credentials_id: ${env.registry_credentials_id} "
                docker.withRegistry("https://${env.registryName}", env.registry_credentials_id) {
                    customImage.push()
                }
            }
            sh 'env $env'
        }

        stage('deploy'){
            if(inputResult.dev) {

                // 本地部署
                echo "start local deploy, host: ${env.host}"
                try {

                    result = sh(script: "docker ps -a | grep ${projectName} | awk '{print \$1}'", returnStdout: true).trim()
                    echo "result : ${result}"
                    if(result){
                        sh "docker stop ${projectName}"
                        sh "docker rm -f ${projectName}"
                    }

                } catch (err) {}
                // 启动容器
                def serverArgs = "-p ${env.port}:${openPort} --name ${projectName}"
                echo "serverArgs: docker run -d ${serverArgs}"
                docker.image(imageName).run("${serverArgs}")
                echo 'deploy finish'
            }else{
                // 远程服务器部署
                echo "start remote deploy, host: ${env.host}"
                // ansiColor('xterm') {
                docker.withRegistry("https://${env.registryName}", env.registry_credentials_id){

                    // 部署集群
                    //for (item in ipList.tokenize(',')){
                        def sshServer = getServer(env.credentialsId,env.host,false,projectName)

                        // 更新或下载镜像
                        sshCommand remote: sshServer, command: "docker pull ${imageName}"

                        try{
                            // 停止容器
                            def stopSSH = sshCommand remote: sshServer, command: "docker ps -a | grep ${projectName} | awk '{print \$1}'"
                            if(stopSSH){
                                sshCommand remote: sshServer, command: "docker stop ${projectName}"
                                sshCommand remote: sshServer, command: "docker rm -f ${projectName}"
                            }

                        }catch(err){}

                        // 启动参数
                        def serverArgs = "docker run -d -p ${env.port}:${openPort} -e PRO_ENV=${env.PRO_ENV}"
                        if(appointWorkDir){
                            serverArgs = "${serverArgs} -v ${hostWorkDir}:${openPort}"
                        }
                        echo "serverArgs: ${serverArgs} ${otherArgs} ${imageName}"

                        // 启动容器
                        sshCommand remote: sshServer, command: "${serverArgs} ${otherArgs} ${imageName}"

                        // 删除远程服务器的上两个版本镜像(只保留最新的两个版本镜像)
                        sshCommand remote: sshServer, command: "docker rmi -f ${imageName.replaceAll("_${BUILD_NUMBER}", "_${BUILD_NUMBER.toInteger() - 1}")}"
                        // 清理none镜像
                        def clearNoneSSH = "n=`docker images | grep  '<none>' | wc -l`; if [ \$n -gt 0 ]; then docker rmi `docker images | grep  '<none>' | awk '{print \$3}'`; fi"
                        sshCommand remote: sshServer, command: "${clearNoneSSH}"
                        // sshCommand remote: sshServer, command: "docker rmi -f \$(docker images | grep none | awk '{print \$3}')"
                    //}


                }
              //}
            }
        }
        stage('delete'){
            // 删除本服务器的上两个版本镜像(只保留最新的两个版本镜像)
            try {
                sh "docker rmi -f ${imageName.replaceAll("_${BUILD_NUMBER}", "_${BUILD_NUMBER.toInteger() - 1}")}"
            } catch (err) {}
        }
    }
    catch (err) {
        currentBuild.result = "FAILURE"
        throw err
    }
}
// 声明一个获取服务的函数(默认端口22)
def getServer(credentialsId,ip,port,projectName){
    def remote = [:]
    remote.name = "${projectName}"
    remote.host = ip
    remote.port = 22
    remote.allowAnyHosts = true
    if(port){
        remote.port = port
    }
    withCredentials([usernamePassword(credentialsId: credentialsId, passwordVariable: 'password', usernameVariable: 'userName')]) {
        remote.user = "${userName}"
        remote.password = "${password}"
    }
    return remote
}
