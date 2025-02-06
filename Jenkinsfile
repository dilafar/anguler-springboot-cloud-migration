#!/usr/bin/env groovy
import groovy.json.JsonSlurper

library identifier: "jenkins-shared-library@master" , retriever: modernSCM([
        $class: "GitSCMSource",
        remote: "https://github.com/dilafar/jenkins-shared-library.git",
        credentialsId: "github",
])

pipeline{
    agent any

    tools {
        maven 'maven3'
    }

    environment {     
        ARTIFACT_NAME = "employeemanager-v${BUILD_ID}.jar"
        COSIGN_PASSWORD = credentials('cosign-password') 
        COSIGN_PRIVATE_KEY = credentials('cosign-private-key') 
        COSIGN_PUBLIC_KEY = credentials('cosign-public-key')
        SEMGREP_APP_TOKEN = credentials('SEMGREP_APP_TOKEN')
        SEMGREP_PR_ID = "${env.CHANGE_ID}"     
        DOCKER_REPO = "aksemployeerepo.azurecr.io/employee/azure-fullstack"
        DOCKER_REPO_SERVER = "aksemployeerepo.azurecr.io"
        AZURE_SUBSCRIPTION_ID = credentials('azure-subscription-id')
        AZURE_CLIENT_ID = credentials('azure-client-id')
        AZURE_CLIENT_SECRET = credentials('azure-client-secret')
        AZURE_TENANT_ID = credentials('azure-tenant-id')
    }

    stages{
        stage("secret scan"){
            steps {
                script {
                   sh '''
                        docker run --rm -v $(pwd):/pwd trufflesecurity/trufflehog:latest github --repo https://github.com/dilafar/anguler-springboot-aws-migration.git

                   '''
                }
            }
        }
        stage("increment version"){
            steps {
                script {
                    parallel(
                        "Maven Increment": {
                            dir('employeemanager') {
                                    echo "incrimenting app version ..."
                                    incrementPatchVersion()
                                    def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'
                                    def version = matcher[1][1]       
                                    env.IMAGE_VERSION = "$version-$BUILD_NUMBER"
                                    
                            }
                        },
                        "NPM Increment": {
                            dir('employeemanagerfrontend') {                          
                                    sh 'npm version patch --no-git-tag-version'
                                    def packageFile = readFile('package.json')
                                    def jsonParser = new JsonSlurper()
                                    def packageJson = jsonParser.parseText(packageFile)
                                    def appVersion = packageJson.version
                                    echo "Application version: ${appVersion}"    
                            }
                        }
                    )
                         
                }
            }
        }
        stage("Build"){
            steps {
                  script {
                    parallel(
                        "MVN Build": {
                            dir('employeemanager') {
                                    sh 'mvn clean package'
                            }
                        },
                        "NPM Build": {
                            dir('employeemanagerfrontend') {
                                
                                        sh "npm install"
                                
                            }
                        }
                    )
                  }
            }
        }

        stage('Unit Tests - JUnit and JaCoCo'){
           steps {
               dir('employeemanager') {
                    sh "mvn test"
                }
            }
        }

        stage("Code Quality Analysis"){
            steps {
                script {
                    parallel(
                        "Checkstyle Analysis": {
                            dir('employeemanager') {
                                sh 'mvn checkstyle:checkstyle'
                            }
                        },
                        "njsscan": {
                            dir('employeemanagerfrontend') {
                                sh '''
                                         pip3 install --upgrade njsscan
                                         export PATH=$PATH:$HOME/.local/bin
                                         njsscan --exit-warning . --sarif -o njsscan.sarif
                                   '''
                            }
                        }
                    )    
                    }
                }
                post {
                    always {
                        archiveArtifacts artifacts: '**/employeemanagerfrontend/njsscan.sarif', allowEmptyArchive: true
                        archiveArtifacts artifacts: '**/target/checkstyle-result.xml', allowEmptyArchive: true
                    }
                }             
            }
        

        stage("SAST - sonar Analysis"){
            environment {
                scannerHome = tool 'sonar6.2'
            }
            steps {
                script {
                    parallel(
                         "sonar Analysis": {
                                    dir('employeemanager') {
                                                withSonarQubeEnv('sonar') {
                                                    sh '''${scannerHome}/bin/sonar-scanner \
                                                                -Dsonar.projectKey=employee \
                                                                -Dsonar.projectName=employee \
                                                                -Dsonar.projectVersion=1.0 \
                                                                -Dsonar.sources=src/ \
                                                                -Dsonar.host.url=http://172.48.16.173/ \
                                                                -Dsonar.java.binaries=target/test-classes/com/employees/employeemanager/ \
                                                                -Dsonar.jacoco.reportsPath=target/jacoco.exec \
                                                                -Dsonar.junit.reportsPath=target/surefire-reports/ \
                                                                -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
                                                                -Dsonar.dependencyCheck.jsonReportPath=target/dependency-check-report/dependency-check-report.json \
                                                                -Dsonar.dependencyCheck.htmlReportPath=target/dependency-check-report/dependency-check-report.html \
                                                                -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml

                                                        '''
                                                }   
                                                timeout(time: 1, unit: 'HOURS'){
                                                            waitForQualityGate abortPipeline: true
                                                }         
                                    }
                                },
                                "Semgrep": {                     
                                           sh '''
                                                    docker pull semgrep/semgrep && \
                                                    docker run \
                                                        -e SEMGREP_APP_TOKEN=$SEMGREP_APP_TOKEN \
                                                        -e SEMGREP_PR_ID=$SEMGREP_PR_ID \
                                                        -v "$(pwd):$(pwd)" --workdir $(pwd) \
                                                    semgrep/semgrep semgrep ci --json --output semgrep.json
                                              '''   
                                }

                    )
                }
            }
            post {
                    always {
                        archiveArtifacts artifacts: '**/semgrep.json', allowEmptyArchive: true
                    }
                }   

        }

        stage("Upload Artifacts"){
            steps {
                script {
                        dir('employeemanager') {
                                env.JAR_FILE = sh(script: "ls target/employeemanager-*.jar", returnStdout: true).trim()
                                echo "Found JAR File: ${env.JAR_FILE}"
                                nexusUpload("172.48.16.196:8081","azure-jar","employeemgmt","${BUILD_ID}","employee-repo","nexus","${env.JAR_FILE}","jar")
                            }               
                        }
                    }
                }





        stage("Vulnerability Scan - Docker") {
            steps {
                script {
                    parallel(
                        "Dependency Scan": {
                            dir('employeemanager') {
                                sh "mvn org.owasp:dependency-check-maven:check"
                            }
                        },
                        "Trivy Scan": {
                            parallel(
                                "Trivy Scan backend": {
                                    dir('employeemanager') {
                                       sh '''
                                           bash trivy-docker-image-scan.sh
                                       '''
                                    }
                                },
                                "Trivy Scan frontend": {
                                    dir('employeemanagerfrontend') {
                                       sh '''
                                           bash trivy-docker-image-scan.sh
                                       '''
                                    }
                                }
                            )
                        },
                        "OPA Conftest":{
                             parallel(
                                "opa-front": {
                                       dir('employeemanager') {
                                        sh '''
                                            docker run --rm \
                                                -v $(pwd):/project \
                                                openpolicyagent/conftest test --policy dockerfile-security.rego Dockerfile 
                                        '''
                                    }     
                                },
                                "opa-back": {
                                                dir("employeemanagerfrontend") {
                                                sh '''
                                                    docker run --rm \
                                                        -v $(pwd):/project \
                                                        openpolicyagent/conftest test --policy dockerfile-security.rego Dockerfile
                                                '''
                                    }

                                }
                             )
                        },
                        "lint dockerfile":{
                             parallel(
                                "opa-front-lint": {
                                    dir('employeemanager') {
                                        sh '''
                                            docker run --rm -i hadolint/hadolint < Dockerfile | tee hadolint_lint.txt
                                        '''
                                    }
                                },
                                "opa-back-lint": {
                                    dir("employeemanagerfrontend") {
                                    sh '''
                                        docker run --rm -i hadolint/hadolint < Dockerfile | tee hadolint_lint_front.txt
                                    '''
                                }
                            }
                             )     
                        },
                        "RetireJs":{
                                dir('employeemanagerfrontend') {
                                    cache(
                                            maxCacheSize: 250, 
                                            caches: [
                                                arbitraryFileCache(
                                                    path: 'node_modules', 
                                                    cacheValidityDecidingFile: 'package-lock.json' 
                                                )
                                            ]
                                    ) {
                                         sh '''
                                            npm install  retire
                                            npm install
                                            npx retire --path . --outputformat json --outputpath retire.json
                                        '''
                                    }
                                }
                            }
                        )
                    }
            }
            post {
                    always {
                        archiveArtifacts artifacts: '**/employeemanagerfrontend/retire.json', allowEmptyArchive: true
                        archiveArtifacts artifacts: '**/employeemanager/target/dependency-check-report/dependency-check-report.json', allowEmptyArchive: true
                    }
                } 
        }

        stage("Docker Image Build") {
                steps {
                        script {
                            // Clean up unused Docker resources
                            sh 'docker system prune -a --volumes --force || true'
                                parallel(
                                    "frontend-image-scan": {
                                        dir('employeemanagerfrontend') {
                                            script {
                                                buildImage("${DOCKER_REPO}:frontend","${IMAGE_VERSION}")
                                                dockerLoginPrivateCloudAzure("${DOCKER_REPO_SERVER}")
                                                dockerPush("${DOCKER_REPO}:frontend","${IMAGE_VERSION}")
                                                signCloudImage("${DOCKER_REPO}:frontend","${IMAGE_VERSION}","${COSIGN_PRIVATE_KEY}","${COSIGN_PUBLIC_KEY}")
                                            }
                                        }
                                    },
                                    "backend-image-scan": {
                                        dir('employeemanager') {
                                            script {
                                                buildImage("${DOCKER_REPO}:backend","${IMAGE_VERSION}")
                                                dockerLoginPrivateCloudAzure("${DOCKER_REPO_SERVER}")
                                                dockerPush("${DOCKER_REPO}:backend","${IMAGE_VERSION}")
                                                signCloudImage("${DOCKER_REPO}:backend","${IMAGE_VERSION}","${COSIGN_PRIVATE_KEY}","${COSIGN_PUBLIC_KEY}")
                                            }
                                        }
                                    },
                                     "copy reports": {
                                            sh '''
                                                cp employeemanagerfrontend/njsscan.sarif  reports/njsscan.sarif
                                                cp employeemanagerfrontend/retire.json reports/retire.json
                                                cp semgrep.json  reports/semgrep.json
                                                cp employeemanager/target/dependency-check-report/dependency-check-report.json reports/dependency-check-report.json
                                                cp employeemanagerfrontend/hadolint_lint_front.txt reports/hadolint_lint_frontend.txt
                                                cp employeemanager/hadolint_lint.txt reports/hadolint_lint_backend.txt
                                            '''
                                     }
                            )
                        }
                    }
            }
        stage("change image in kubeconfig") {
            steps {
                script {
                    parallel(
                        "Change image backend": {           
                                script {
                                    sh '''
                                        sed -i "/containers:/,/^[^ ]/s|image:.*|image: $DOCKER_REPO:backend-v$IMAGE_VERSION|g" kustomization/base/backend-deployment.yml
                                        sed -i "s|image:.*|image: $DOCKER_REPO:frontend-v$IMAGE_VERSION|g" kustomization/base/frontend-deployment.yml
                                        cat kustomization/base/backend-deployment.yml
                                        cat kustomization/base/frontend-deployment.yml
                                    '''
                                }
                        },
                        "DefectDojo Uploader": {
                                dir('reports') {
                                    script {
                                            sh '''                                           
                                                python3 upload-reports.py njsscan.sarif
                                                python3 upload-reports.py retire.json
                                                python3 upload-reports.py semgrep.json
                                                python3 upload-reports.py dependency-check-report.json
                                            '''
                                    }
                            }
                        }
                    )
                }
            }

        }

        stage("Vulnerability Scan - kubernetes") {
            steps {
                script {
                        parallel (
                            "OPA Scan helm chart": {
                                    sh '''
                                       conftest test -p policy/opa-k8s-security.rego kustomization/base/*
                                    '''
                            },
                            "Trivy Scan": { 
                                        sh ''' 
                                            bash scripts/trivy-scan/trivy-k8s-scan.sh $DOCKER_REPO:frontend-v$IMAGE_VERSION trivy-frontend.json &
                                            bash scripts/trivy-scan/trivy-k8s-scan.sh $DOCKER_REPO:backend-v$IMAGE_VERSION trivy-backend.json &

                                            wait
                                       '''                           
                            },
                            "CIS Benchmark v1.6.0": {
                                        sh '''
                                            bash scripts/trivy-scan/trivy-docker-bench.sh $DOCKER_REPO:frontend-v$IMAGE_VERSION trivy-bench-frontend.json || true &
                                            bash scripts/trivy-scan/trivy-docker-bench.sh $DOCKER_REPO:backend-v$IMAGE_VERSION trivy-bench-backend.json &

                                        wait
                                '''
                            }
                        )
                    }
            }
        }

        stage("Kubernetes Apply") {
            steps {
                script {
                            sh '''
                                az login --service-principal --username $AZURE_CLIENT_ID --password $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
                                az aks get-credentials --resource-group aks-rg --name aks-demo --overwrite-existing
                                
                                if [ ! -f scripts/kubernetes/kubernetes-script.sh ]; then
                                    echo "kubernetes-script.sh file is missing!" >&2
                                    exit 1
                                fi
                                kubectl get nodes
                                chmod +x scripts/kubernetes/kubernetes-script.sh
                                chmod +x scripts/kubernetes/kubernetes-apply.sh
                                ./scripts/kubernetes/kubernetes-apply.sh
                                sleep 300
                            '''

                        }
                }
            
        }

        stage ("kubernetes cluster check") {
                steps {
                    script {
                        sh '''
                            docker system prune -a --volumes --force || true                           
                        '''
                        withAWS(credentials: 'awseksadmin', region: 'us-east-1') {
                            sh "aws eks update-kubeconfig --name eks-terraform-2 --region us-east-1"
                            parallel (
                                "kubernetes CIS benchmark": {
                                    echo "Starting Kubernetes CIS Benchmark scan"
                                    sh '''
                                        kubescape scan framework all
                                    '''
                                    echo "Kubernetes CIS Benchmark scan completed"
                                }
                            )
                        }
                    }
                }

        }

        stage("DAST-ZAP") {
                    steps {
                        script {
                            parallel (
                                "DAST": {
                                    sh '''
                                        docker run -v /home/ubuntu:/zap/wrk:rw -u 1000:1000 -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t https://awsdev.cloud-emgmt.com -g gen.conf | tee reports/zap.conf || true
                                    '''
                                }
                            )
                            
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
                                git pull origin aws-helm || true
                                git add .
                                git commit -m "change added from jenkins"
                                git push origin HEAD:azure
                            '''
                    }
                }
            }
        }

      

    }

    post {
        always {
           script {
                    def jobName = env.JOB_NAME
                    def buildNumber = env.BUILD_NUMBER
                    def pipelineStatus = currentBuild.result ?: 'UNKNOWN'
                    def bannerColor = pipelineStatus.toUpperCase() == 'SUCCESS' ? 'green' : 'red'
                    def buildUrl = env.BUILD_URL

                    def body = """
                        <html>
                        <body>
                        <div style="border: 4px solid ${bannerColor}; padding: 10px;">
                            <h2>${jobName} - Build ${buildNumber}</h2>
                            <div style="background-color: ${bannerColor}; padding: 10px;">
                                <h3 style="color: white;">Pipeline Status: ${pipelineStatus.toUpperCase()}</h3>
                            </div>
                            <p>Check the <a href="${buildUrl}">console output</a>.</p>
                        </div>
                        </body>
                        </html>
                    """

                    emailext(
                        subject: "${jobName} - Build ${buildNumber} - ${pipelineStatus.toUpperCase()}",
                        body: body,
                        to: 'fadhilahamed98@gmail.com',
                        from: 'jenkins@example.com',
                        replyTo: 'jenkins@example.com',
                        mimeType: 'text/html',
                    )
                 }
            }
        
         }
    }