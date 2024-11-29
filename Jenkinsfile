pipeline{
    agent any

    tools {
        maven 'maven3'
    }

    environment {
        AWS_S3_BUCKET = 'cicdbeans3'
        AWS_EB_APP_NAME = 'employee-test'
        AWS_EB_ENVIRONMENT = 'Employee-test-env'
        AWS_EB_APP_VERSION = "${BUILD_ID}"
        ARTIFACT_NAME = "employeemanager-v${BUILD_ID}.jar"
    }

    stages{
        stage("Build"){
            steps{
                dir('employeemanager') {
                     sh 'mvn clean package'
                }
            }
        }

        stage("Checkstyle Analysis"){
            steps{
                 dir('employeemanager') {
                        sh 'mvn checkstyle:checkstyle'
                 }
               
            }
        }

        stage("sonar Analysis"){
            environment {
                scannerHome = tool 'sonar6.2'
            }
            steps{
                dir('employeemanager') {
                    script {
                        withSonarQubeEnv('sonar') {
                                sh '''${scannerHome}/bin/sonar-scanner \
                                            -Dsonar.projectKey=employee \
                                            -Dsonar.projectName=employee \
                                            -Dsonar.projectVersion=1.0 \
                                            -Dsonar.sources=src/ \
                                            -Dsonar.host.url=http://172.48.16.144/ \
                                            -Dsonar.java.binaries=target/test-classes/com/employees/employeemanager/ \
                                            -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml

                                        '''
                             }            
                    }
            }
        }

            }

        stage("Quality Gate"){
            steps{
                dir('employeemanager') {
                    timeout(time: 1, unit: 'HOURS'){
                    waitForQualityGate abortPipeline: true
                }
            }
            }
        }

        stage("Upload Artifacts"){
            steps {
                dir('employeemanager') {
                    nexusArtifactUploader(
                                nexusVersion: 'nexus3',
                                protocol: 'http',
                                nexusUrl: '172.48.16.120:8081',
                                groupId: 'QA',
                                version: "${BUILD_ID}",
                                repository: 'employee-repo',
                                credentialsId: 'nexus',
                                artifacts: [
                                        [artifactId: 'employeemgmt',
                                        classifier: '',
                                        file: 'target/employeemanager-0.0.1-SNAPSHOT.jar',
                                        type: 'jar']
                                    ]
                )
                }
                    
            }
        }

        stage("Deploy to stage bean"){
           steps {
                dir('employeemanager') {
                    withAWS(credentials: 'awsbeancreds', region: 'us-east-1') {
                        sh 'aws s3 cp ./target/employeemanager-0.0.1-SNAPSHOT.jar s3://$AWS_S3_BUCKET/$ARTIFACT_NAME'
                        sh 'aws elasticbeanstalk create-application-version --application-name $AWS_EB_APP_NAME --version-label $AWS_EB_APP_VERSION --source-bundle S3Bucket=$AWS_S3_BUCKET,S3Key=$ARTIFACT_NAME'
                        sh 'aws elasticbeanstalk update-environment --application-name $AWS_EB_APP_NAME --environment-name $AWS_EB_ENVIRONMENT --version-label $AWS_EB_APP_VERSION'
                }
            }
             
           }
        }

        stage("ansible deployment") {
                    steps {
                       ansiblePlaybook([
                                playbook: 'ansible/ebs-deploy.yml',
                                inventory: 'ansible/stage.inventory',
                                installation: 'ansible',
                                credentialsId: 'ec2-server-key',
                                colorized: true,
                                disableHostKeyChecking: true,
                                ]
                               )
                    }
                }

        stage("ssh agent") {
            steps {
                script {
                    def command = 'bash ./git-command.sh'
                    sshagent(['ec2-server-key']) {
                        sh "scp git-command.sh ubuntu@172.48.16.90:/home/ubuntu"
                        sh "ssh -o StrictHostKeyChecking=no ubuntu@172.48.16.90 sudo chmod +x git-command.sh"
                        sh "ssh -o StrictHostKeyChecking=no ubuntu@172.48.16.90 '${command}'"
                    }
                }
            }
        }

        stage("nodejs image build") {
            steps{
                dir('employeemanagerfrontend') {
                    script {
                        withCredentials([usernamePassword(credentialsId: 'docker-hub', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                            sh 'docker build -t fadhiljr/nginxapp:employee-frontend-v30 .'
                            sh "echo $PASS | docker login -u $USER --password-stdin"
                            sh 'docker push fadhiljr/nginxapp:employee-frontend-v30'
                        }         
                    }
              }
           }
        }

        stage("change image in kubeconfig") {
            steps{
                dir('kustomization') {
                    script {
                        sh "sed -i 's#replace#fadhiljr/nginxapp:employee-frontend-v30#g' frontend-deployment.yml" 
                        sh "cat frontend-deployment.yml"   
                               
                    }
              }
           }
        }

          stage("commit change") {
            steps {
                script {
                    sshagent(['git-ssh-auth']) {
                            sh '''
                                mkdir -p ~/.ssh
                                ssh-keyscan -H github.com >> ~/.ssh/known_hosts
                                git remote set-url origin git@github.com:dilafar/anguler-springboot-aws-migration.git
                                git pull origin master || true
                                git add .
                                git commit -m "change added"
                                git push origin HEAD:master
                            '''
                    }
                }
            }
        }

        stage("Kubernetes Apply") {
            environment {
                AZURE_SUBSCRIPTION_ID = credentials('azure-subscription-id')
                AZURE_CLIENT_ID = credentials('azure-client-id')
                AZURE_CLIENT_SECRET = credentials('azure-client-secret')
                AZURE_TENANT_ID = credentials('azure-tenant-id')
            }
            steps {
                script {
                    sh "az login --service-principal --username $AZURE_CLIENT_ID --password $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID"
                    sh "az aks get-credentials --resource-group aks-rg1 --name aks-demo"
                    sh '''
                        if [ ! -f kubernetes-script.sh ]; then
                            echo "kubernetes-script.sh file is missing!" >&2
                            exit 1
                        fi

                        chmod +x kubernetes-script.sh
                    '''
                    sh "./kubernetes-script.sh"
                    sh "kubectl config view"
                    sh "cat kustomization/frontend-deployment.yml"
                    sh "cat kustomization/frontend-service.yml"
                    sh "kubectl apply -k kustomization/"
                    sh "kubectl get pods -n employee"
                }
            }
        }

      

    }
}