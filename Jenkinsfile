pipeline {
    agent any
    stages {
        stage('Build') {
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

        stage('docker build'){
            agent {
                dockerfile {
                    filename 'Dockerfile'
                }
            }
            steps {
                sh "docker build -t jenkins/test:latest ."
            }
        }

        stage('deploy'){
            steps {
                sh ' ./docker.sh'
            }
        }
    }
}