pipeline {
  agent {
    kubernetes {
      yamlFile 'kaniko.yaml'
    }
  }
  environment {
    NEXUS_URL = '172.205.80.142' // Replace with your Nexus URL
    NEXUS_REPO = 'v1/repository/docker/hosted/dock'
    IMAGE_NAME = 'demo' // Replace with your image name
    DOCKER_CONFIG = "${WORKSPACE}/.docker" // Path for Docker config
  }
  stages {
    stage("Cleanup Workspace") {
      steps {
        cleanWs()
      }
    }
    stage('Checkout') {
        steps {
            checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/askininan/demo-project']])
        }
    }
    stage('Restore') {
      steps {
          // Restore dependencies
          container('dotnet') {
              sh 'dotnet restore'
          }
      }
    }
    stage('Build') {
        steps {
            // Build the project
            container('dotnet') {
                sh 'dotnet build --configuration Release'
            }
        }
    }
    stage('Publish') {
      steps {
          // Publish the project
          container('dotnet') {
              sh 'dotnet publish --configuration Release --output ./publish'
          }
      }
    }
    stage('Run Tests') {
      steps {
          container('dotnet') {
              dir('Tests') {
                  sh 'dotnet test --configuration Release --no-build --logger "console;verbosity=detailed"'
              }
          }
      }
    }
    stage('Build & Push with Kaniko') {
      steps {
        container(name: 'kaniko', shell: '/busybox/sh') {
          withCredentials([usernamePassword(credentialsId: 'nexus', passwordVariable: 'PSW', usernameVariable: 'USERNAME')]){
            sh '''
              echo "Creating Docker config for Nexus authentication"
              auth="${USERNAME}:${PSW}"
              encoded_auth=$(echo -n "$auth" | base64)
              mkdir -p ${DOCKER_CONFIG}
              cat <<EOF > ${DOCKER_CONFIG}/config.json
              {
                "auths": {
                    "${NEXUS_URL}:8083": {
                        "auth": "$encoded_auth"
                    }
                }
              }
              EOF
              '''
          }
          sh 'cat ${DOCKER_CONFIG}/config.json'
          sh 'cat /kaniko/.docker/config.json'
          sh '''
            /kaniko/executor --dockerfile `pwd`/dockerfile --context `pwd` \
            --destination ${NEXUS_URL}:8083/${IMAGE_NAME}:${BUILD_ID}
            --verbosity=debug | tee kaniko.log
          '''
       }
      }
    }
  }
}
