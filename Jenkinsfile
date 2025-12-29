pipeline {
    agent {
        kubernetes {
            namespace 'jenkins'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  namespace: jenkins
  name: jenkins-agent-spree
spec:
  serviceAccountName: jenkins-k8s
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command: ['cat']
    tty: true
  - name: kubectl
    image: beli/kubectl-shell
    command: ['cat']
    tty: true
"""
        }
    }
    stages {
        stage('Build & Push Docker Image') {
            steps {
                container('kaniko') {
                    // Make sure you have 'docker_hub' credentials in Jenkins
                    withCredentials([usernamePassword(credentialsId: 'docker_hub', passwordVariable: 'DOCKERHUB_PASSWORD', usernameVariable: 'DOCKERHUB_USERNAME')]) {
                        script {
                            def dockerHubUsername = 'zakariamestour' 
                            def imageName = "${dockerHubUsername}/spree-starter"
                            def imageTag = "1.0.${env.BUILD_NUMBER}"

                            // Configure Docker Hub Auth
                            withEnv(["DOCKER_CONFIG=/tmp/.docker"]) {
                                sh """
                                mkdir -p /tmp/.docker
                                echo '{"auths":{"https://index.docker.io/v1/":{"username":"${env.DOCKERHUB_USERNAME}","password":"${env.DOCKERHUB_PASSWORD}"}}}' > /tmp/.docker/config.json
                                
                                /kaniko/executor \
                                --dockerfile=Dockerfile \
                                --context=. \
                                --destination=${imageName}:${imageTag} \
                                --destination=${imageName}:latest \
                                --cache=true
                                """
                            }
                            echo "Image pushed: ${imageName}:${imageTag}"
                        }
                    }
                }
            }
        }

        stage('Deploy to K8s') {
            steps {
                container('kubectl') {
                    script {
                        def imageTag = "1.0.${env.BUILD_NUMBER}"
                        def dockerHubUsername = 'zakariamestour'
                        
                        // We assume you have a folder named 'k8s' in your git repo
                        dir('k8s') {
                            // Update the image tag in the deployment.yaml file dynamically
                            sh "sed -i 's|${dockerHubUsername}/spree-starter:latest|${dockerHubUsername}/spree-starter:${imageTag}|g' deployment.yaml"
                            
                            // Apply the configuration to the 'dev' namespace
                            sh "kubectl apply -f deployment.yaml"
                            
                            // Wait for the rollout to finish
                            sh "kubectl rollout status deployment/spree-web -n dev"
                        }
                    }
                }
            }
        }
    }
}