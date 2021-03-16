import groovy.json.JsonSlurper

node {

    // 需要手动赋值的变量(是否需要全部移到config.json)
    def appointWorkDir = false                        // 是否指定挂载目录
    def projectName = 'jenkins-test'                  // 项目名称
    def hostWorkDir = '/var/jenkins/jenkins-test'     // 宿主机目录(随便设置)
    def workDir = '/var/jenkins/jenkins-test'         // 容器目录(Dockerfile中的WORKDIR目录)
    def openPort = '7777'                             // 开发的端口(Dockerfile中的EXPOSE,使用该端口映射)
    def otherArgs = "--name ${projectName}"           // 自定义其他启动参数(默认启动参数格式为: docker run -d -p 8080:8080 -e pro_env=dev)
    def mvnCMD = "mvn -B -DskipTests clean package"   // maven打包命令 暂时先不用这个字段


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
        stage('config') {

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
            if (inputResult.deploy) {
                env.PRO_ENV = "prod"
            }
            sh 'env $env'
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
                env.registry_credentials_id = envConifg.registry_credentials_id
                env.host = envConifg.host
                env.port = envConifg.port
                env.name = envConifg.name

                imageName = "${env.registryName}:${env.VERSION}_${env.PRO_ENV}_${BUILD_NUMBER}"
                echo "VERSION: ${env.VERSION} ,imageName: ${imageName}"
            }

            // checkout测试时使用,jenkins上面直接使用SCM
            // checkout([$class: 'GitSCM', branches: [[name: '*/dev']], extensions: [], userRemoteConfigs: [[credentialsId: 'e761309f-146f-4c5f-b7fd-1debf91fef38', url: 'https://gitee.com/original-blackhole/jenkins-test.git']]])
            withEnv(["MVN_HOME=$mvnHome"]) {
                if (isUnix()) {
                    sh 'mvn -B -DskipTests clean package'
                } else {
                    bat(/mvn -B -DskipTests clean package/)
                }
            }
        }

        stage('build'){

            // 构建镜像并上传到容器仓库
            echo "imageName: ${imageName}"
            def customImage = docker.build(imageName, " --build-arg pro_env=${env.PRO_ENV} .")
            if(!(inputResult.dev)) {
                docker.withRegistry("https://${env.registryName}", env.registry_credentials_id) {
                    customImage.push()
                }
            }
            sh 'env $env'
        }

        stage('Deploy'){
            if(inputResult.dev) {

                // 本地部署
                echo "start local deploy, host: ${env.host}"
                try {
                    // 停止删除容器
                    // sh "docker rm \$(docker stop \$(docker ps -a | grep ${projectName} | awk '{print \$1}'))"  //没有容器时会报错
                    // 停止容器
                    sh "docker stop ${projectName}"   //TODO 没有容器时会报错 但是不影响执行流程先不改了
                    // 删除容器
                    sh "docker rm ${projectName}"
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
                        def sshServer = getServer(env.credentialsId,env.host,false)

                        // 更新或下载镜像
                        sshCommand remote: sshServer, command: "docker pull ${imageName}"

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
                        echo 'serverArgs: ${serverArgs} ${otherArgs} ${imageName}'

                        // 启动容器
                        sshCommand remote: sshServer, command: "${serverArgs} ${otherArgs} $imageName}"

                        // 删除远程服务器的上两个版本镜像(只保留最新的两个版本镜像)
                        sshCommand remote: sshServer, command: "docker rmi -f ${imageName.replaceAll("_${BUILD_NUMBER}", "_${BUILD_NUMBER.toInteger() - 1}")}"
                        // 清理none镜像
                        // def clearNoneSSH = "n=`docker images | grep  '<none>' | wc -l`; if [ \$n -gt 0 ]; then docker rmi `docker images | grep  '<none>' | awk '{print \$3}'`; fi"
                        // sshCommand remote: sshServer, command: "${clearNoneSSH}"
                        sshCommand remote: sshServer, command: "docker rmi -f \$(docker images | grep none | awk '{print \$3}')"
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
// 声明一个获取服务的函数,我这里所有服务的密码都是一样的,如有区别可自行修改函数
def getServer(ip){
    def remote = [:]
    remote.name = "server-${ip}"
    remote.host = ip
    remote.port = 22
    remote.allowAnyHosts = true
    withCredentials([usernamePassword(credentialsId: '8a0eadde-27ec-424f-97e3-aefcf54e5caf', passwordVariable: 'password', usernameVariable: 'userName')]) {
    //withCredentials([sshUserPrivateKey(credentialsId: 'ServiceServer', keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'userName')]) {
        remote.user = "${userName}"
        remote.password = "${password}"
    }
    return remote
}
def getServer(credentialsId,ip,port){
    def remote = [:]
    remote.name = "server-${ip}"
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
