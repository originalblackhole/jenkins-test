pipeline {
    agent any
    stages {
        stage('check') {
            agent {
                docker {
                    image 'maven:3-alpine'
                    args '-v /root/.m2:/root/.m2'
                }
            }
            steps {
                git 'https://github.com/originalblackhole/jenkins-test.git'
                sh 'mvn -B -DskipTests clean package'
            }
        }

        stage('build'){
            agent {
                dockerfile {
                    filename 'Dockerfile'
                }
            }
            steps {
                sh " ./build.sh"
            }
        }

        stage('deploy'){
            steps {
                sh ' ./docker.sh'
            }
        }
    }
}