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
                dir('backend') {
                     sh 'mvn clean package'
                }
            }
        }

        stage("Checkstyle Analysis"){
            steps{
                 dir('backend') {
                        sh 'mvn checkstyle:checkstyle'
                 }
               
            }
        }

        stage("sonar Analysis"){
            environment {
                scannerHome = tool 'sonar6.2'
            }
            steps{
                dir('backend') {
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
                dir('backend') {
                    timeout(time: 1, unit: 'HOURS'){
                    waitForQualityGate abortPipeline: true
                }
            }
            }
        }

        stage("Upload Artifacts"){
            steps {
                dir('backend') {
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
            dir('backend') {
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
    }
}