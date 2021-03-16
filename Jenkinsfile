import groovy.json.JsonSlurper

node {

    // 需要手动赋值的变量(是否需要全部移到config.json)
    def appointWorkDir = false                        // 是否指定挂载目录
    def projectName = 'jenkins-test'                  // 项目名称
    def hostWorkDir = '/var/jenkins/jenkins-test'     // 宿主机目录(随便设置)
    def workDir = '/var/jenkins/jenkins-test'         // 容器目录(Dockerfile中的WORKDIR目录)
    def openPort = '7777'                             // 开发的端口(Dockerfile中的EXPOSE,使用该端口映射)
    def otherArgs = "--name ${projectName}"           // 自定义其他启动参数(默认启动参数格式为: docker run -d -p 8080:8080 -e pro_env=dev)
    def mvnCMD = "mvn -B -DskipTests clean package"   // maven打包命令


    // 系统变量
    def imageName = ''
    def inputResult // 用户输入项
    def inputImage // 用户输入项
    def mvnHome = tool 'M3'
    env.host = ''
    env.registryName = ''
    env.credentialsId = ''
    env.VERSION = '1.0.0'
    env.PATH = "${mvnHome}/bin:${env.PATH}"
    currentBuild.result = "SUCCESS"

    try {
        stage('config') {

            inputResult = input message: '请选择部署环境', ok: '确认', parameters: [
                booleanParam(name: 'dev', defaultValue: true),
                booleanParam(name: 'test', defaultValue: false),
                booleanParam(name: 'deploy', defaultValue: false)

//                 booleanParam(name: '192.168.3.165-dev', defaultValue: true),
//                 booleanParam(name: '192.168.3.63-test', defaultValue: false),
//                 booleanParam(name: '1.15.123.16-deploy', defaultValue: false)
            ]

            inputImage = input message: '推送镜像至仓库并部署', ok: '确认', parameters: [
                booleanParam(name: 'push', defaultValue: true),
                booleanParam(name: 'deploy', defaultValue: false)
            ]

            // 判断发布环境
            if (inputResult.dev) {
                env.PRO_ENV = "dev"
            }
            if (inputResult.test) {
                env.PRO_ENV = "test"
            }
            if (inputResult.deploy) {
                env.PRO_ENV = "deploy"
            }
            echo "Branch: ${env.BRANCH_NAME}, Environment: ${env.PRO_ENV}"
            sh 'echo $env'
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

            // checkout测试时使用,jenkins上面直接使用SCM
            // checkout([$class: 'GitSCM', branches: [[name: '*/dev']], extensions: [], userRemoteConfigs: [[credentialsId: 'e761309f-146f-4c5f-b7fd-1debf91fef38', url: 'https://gitee.com/original-blackhole/jenkins-test.git']]])
            withEnv(["MVN_HOME=$mvnHome"]) {
                if (isUnix()) {
                    sh '$mvnCMD'
                } else {
                    bat(/$mvnCMD/)
                }
            }
        }

        stage('build'){

            // 构建镜像并上传到容器仓库
            sh 'echo $imageName'
            sh 'echo $(env)'
            def customImage = docker.build(imageName, " --build-arg pro_env=${env.PRO_ENV} .")
            if(inputImage.push) {
                docker.withRegistry("https://${env.registryName}", env.registry_credentials_id) {
                    customImage.push()
                }
            }
        }

        stage('Deploy'){
            if(inputImage.deploy) {

                // 远程服务器部署
                // ansiColor('xterm') {
                docker.withRegistry("https://${env.registryName}", env.registry_credentials_id){

                    // 部署集群
                    //for (item in ipList.tokenize(',')){
                        def sshServer = getServer(env.host)

                        // 更新或下载镜像
                        sshCommand remote: sshServer, command: "docker pull $imageName"

                        try{
                            // 停止容器
                            sshCommand remote: sshServer, command: "docker stop ${projectName}"
                            // 删除容器
                            sshCommand remote: sshServer, command: "docker rm -f ${projectName}"
                            // sshCommand remote: remote, command: "docker rm \$(docker stop \$(docker ps -a | grep ${projectName} | awk '{print \$1}'))"

                        }catch(ex){}

                        // 启动参数
                        def serverArgs = "docker run -d -p ${env.port}:${openPort} -e pro_env=${env.PRO_ENV}"
                        if(appointWorkDir){
                            serverArgs = "${serverArgs} -v ${hostWorkDir}:${openPort}"
                        }
                        sh 'echo $serverArgs $otherArgs $imageName'

                        // 启动容器
                        sshCommand remote: remote, command: "$serverArgs $otherArgs $imageName"

                        // 删除远程服务器的上两个版本镜像(只保留最新的两个版本镜像)
                        sshCommand remote: sshServer, command: "docker rmi -f ${imageName.replaceAll("_${BUILD_NUMBER}", "_${BUILD_NUMBER.toInteger() - 2}")}"
                        // 清理none镜像
                        // def clearNoneSSH = "n=`docker images | grep  '<none>' | wc -l`; if [ \$n -gt 0 ]; then docker rmi `docker images | grep  '<none>' | awk '{print \$3}'`; fi"
                        // sshCommand remote: sshServer, command: "${clearNoneSSH}"
                        sshCommand remote: sshServer, command: "docker rmi -f \$(docker images | grep none | awk '{print \$3}')"
                    //}


                }
                //}
            }else{
                // 本地部署
                try {
                    // 停止删除旧容器并启动
                    sh "docker rm \$(docker stop \$(docker ps -a | grep ${projectName} | awk '{print \$1}'))"
                    docker.image(imageName).run('-p ${env.port}:${openPort} --name ${projectName} -d')
                } catch (err) {}
            }
        }
        stage('delete'){
            // 删除本服务器的上两个版本镜像(只保留最新的两个版本镜像)
            try {
                sh "docker rmi -f ${imageName.replaceAll("_${BUILD_NUMBER}", "_${BUILD_NUMBER.toInteger() - 2}")}"
            } catch (err) {}
        }
    }
    catch (err) {
        currentBuild.result = "FAILURE"
        throw err
    }
}
// 声明一个获取服务的函数,我这里所有服务的密码都是一样的,如有区别可自行修改函数
def getServer(ip){
    def remote = [:]
    remote.name = "server-${ip}"
    remote.host = ip
    remote.port = 22
    remote.allowAnyHosts = true
    withCredentials([usernamePassword(credentialsId: 'ServiceServer', passwordVariable: 'password', usernameVariable: 'userName')]) {
    //withCredentials([sshUserPrivateKey(credentialsId: 'ServiceServer', keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'userName')]) {
        remote.user = "${userName}"
        remote.password = "${password}"
    }
    return remote
}