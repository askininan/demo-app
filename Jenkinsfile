pipeline {
  agent {
    kubernetes {
      yamlFile 'kaniko.yaml'
    }
  }
  environment {
    NEXUS_URL = '20.166.244.154' // Replace with your Nexus URL
    REPO_PORT = ':8082'
    NEXUS_REPO = '/repository/docker/'
    IMAGE_NAME = 'demo' // Replace with your image name
    // DOCKER_CONFIG = "${WORKSPACE}/.docker"
    CONTAINERD_CONFIG= "${WORKDIR}/containerd"
    HELM_RELEASE_NAME = 'demo-app' // Name of your Helm release
    CHART_PATH = './app' // Path to your Helm chart
    // KUBE_CONFIG = credentials('kubeconfig')
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
        // container(name: 'kaniko', shell: '/busybox/sh') {
        //     sh '''
        //       echo "Creating Docker config for insecure registry"
        //       mkdir -p ${DOCKER_CONFIG}
        //       cat <<EOF > ${DOCKER_CONFIG}/daemon.json
        //       { 
        //       "insecure-registries": ["${NEXUS_URL}:8082"] 
        //       }
        //     '''
        //     sh 'cat ${DOCKER_CONFIG}/daemon.json'
        //   withCredentials([usernamePassword(credentialsId: 'nexus', passwordVariable: 'PSW', usernameVariable: 'USERNAME')]){
        //     sh '''
        //       echo "Creating Docker config for Nexus authentication"
        //       auth="${USERNAME}:${PSW}"
        //       encoded_auth=$(echo -n "$auth" | base64)
        //       cat <<EOF > ${DOCKER_CONFIG}/config.json
        //       {
        //         "auths": {
        //             "${NEXUS_URL}:${REPO_PORT}": {
        //                 "auth": "$encoded_auth"
        //             }
        //         }
        //       }
        //     '''
        //     sh 'cat ${DOCKER_CONFIG}/config.json'
          

        //   }
        // }

        container(name: 'kaniko', shell: '/busybox/sh') {
          withCredentials([usernamePassword(credentialsId: 'nexus', passwordVariable: 'PSW', usernameVariable: 'USERNAME')]){
            sh '''
              echo "Creating Containerd config for insecure registry"
              mkdir -p ${CONTAINERD_CONFIG}
              cat <<EOF > ${CONTAINERD_CONFIG}/config.toml
              [plugins."io.containerd.grpc.v1.cri".registry]
                config_path = "${CONTAINERD_CONFIG}/certs.d"
              [plugins."io.containerd.grpc.v1.cri".registry.configs]
                [plugins."io.containerd.grpc.v1.cri".registry.configs."${NEXUS_URL}${REPO_PORT}"]
                  [plugins."io.containerd.grpc.v1.cri".registry.configs."${NEXUS_URL}${REPO_PORT}".auth]
                    username = "${USERNAME}"
                    password = "${PSW}"
              '''
            sh 'cat ${CONTAINERD_CONFIG}/config.toml'
            sh '''
              mkdir -p ${CONTAINERD_CONFIG}/certs.d/docker.io/
              cat <<EOF > ${CONTAINERD_CONFIG}/certs.d/docker.io/hosts.toml
              server = "https://registry-1.docker.io"
              [host."https://{docker.mirror.url}"]
                capabilities = ["pull", "resolve"]
              '''
            sh 'cat ${CONTAINERD_CONFIG}/certs.d/docker.io/hosts.toml'
            sh ''' 
              mkdir -p ${CONTAINERD_CONFIG}/certs.d/${NEXUS_URL}${REPO_PORT}/
              cat <<EOF > ${CONTAINERD_CONFIG}/certs.d/${NEXUS_URL}${REPO_PORT}/hosts.toml
              server = "https://registry-1.docker.io"
              [host."http://${NEXUS_URL}${REPO_PORT}"]
                capabilities = ["pull", "resolve", "push"]
                skip_verify = true
              '''
            sh 'cat ${CONTAINERD_CONFIG}/certs.d/${NEXUS_URL}${REPO_PORT}/hosts.toml'
          }
          sh '''
            /kaniko/executor --dockerfile `pwd`/dockerfile --context `pwd` \
            --destination ${NEXUS_URL}${REPO_PORT}/${IMAGE_NAME}:${BUILD_ID} \
            --destination ${NEXUS_URL}${REPO_PORT}/${IMAGE_NAME}:latest \
            --verbosity=debug --insecure --skip-tls-verify
          '''
       }
      }
    }
    //Deploy app by Helm to k8 cluster
    // stage('Deploy Image from Nexus repo to Kubernetes') {
    //   steps {
    //     env.KUBECONFIG = KUBE_CONFIG
    //     sh '''
    //         helm upgrade --install $HELM_RELEASE_NAME $CHART_PATH \
    //         --set image.repository=$NEXUS_URL:$REPO_PORT/$IMAGE_NAME:latest} \
    //         --set imagePullSecrets[0].name=nexus-docker-secret
    //     '''
    //   }
    // }
  }
}
