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
        CR_TOKEN = credentials('cr_cred')    
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
        

        stage("SAST - sonar Analysis(aws)"){
            environment {
                scannerHome = tool 'sonar6.2'
            }
            steps {
                script {
                    parallel(
                         "sonar Analysis": {
                                    dir('employeemanager') {
                                        sonarAnalysis('sonar',"${scannerHome}","employee","employee","1.0","src/","http://172.48.16.173/",
                                            "target/test-classes/com/employees/employeemanager/","target/jacoco.exec","target/surefire-reports/","target/site/jacoco/jacoco.xml","target/dependency-check-report/dependency-check-report.json","target/dependency-check-report/dependency-check-report.html","target/checkstyle-result.xml")
                                                
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

        stage("Upload Artifacts(aws)"){
            steps {
                script {
                        dir('employeemanager') {
                                env.JAR_FILE = sh(script: "ls target/employeemanager-*.jar", returnStdout: true).trim()
                                echo "Found JAR File: ${env.JAR_FILE}"
                                nexusUpload("172.48.16.196:8081","argo-jar","employeemgmt","${BUILD_ID}","employee-repo","nexus","${env.JAR_FILE}","jar")
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

        stage("Node.js Image Build") {
                steps {
                        script {
                            // Clean up unused Docker resources
                            sh 'docker system prune -a --volumes --force || true'

                            withCredentials([usernamePassword(credentialsId: 'docker', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                                parallel(
                                    "frontend-image-scan": {
                                        dir('employeemanagerfrontend') {
                                            script {
                                                buildImage("fadhiljr/nginxapp:employee-frontend","${IMAGE_VERSION}")
                                                dockerLogin()
                                                dockerPush("fadhiljr/nginxapp:employee-frontend","${IMAGE_VERSION}")
                                                sh 'cosign version'
                                                signImage("fadhiljr/nginxapp:employee-frontend","${IMAGE_VERSION}","${COSIGN_PRIVATE_KEY}","${COSIGN_PUBLIC_KEY}")
                                            }
                                        }
                                    },
                                    "backend-image-scan": {
                                        dir('employeemanager') {
                                            script {
                                                buildImage("fadhiljr/nginxapp:employee-backend","${IMAGE_VERSION}")
                                                dockerLogin()
                                                dockerPush("fadhiljr/nginxapp:employee-backend","${IMAGE_VERSION}")
                                                sh 'cosign version'
                                                signImage("fadhiljr/nginxapp:employee-backend","${IMAGE_VERSION}","${COSIGN_PRIVATE_KEY}","${COSIGN_PUBLIC_KEY}")
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
                }


        stage("change image in kubeconfig") {
            steps {
                script {
                    parallel(
                        "Change image backend": {           
                                script {
                                    sh '''
                                        sed -i 's/^appVersion: .*/appVersion: employee-backend-v'"$IMAGE_VERSION"'/g' helm/charts/backend/values.yaml
                                        sed -i 's/^appVersion: .*/appVersion: employee-frontend-v'"$IMAGE_VERSION"'/g' helm/charts/frontend/values.yaml
                                        chmod +x chart-version-increment.sh
                                        ./chart-version-increment.sh helm/Chart.yaml
                                        ./chart-version-increment.sh helm/charts/backend/Chart.yaml
                                        ./chart-version-increment.sh helm/charts/frontend/Chart.yaml
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
                                       helm template helm | conftest test -p policy/opa-k8s-security.rego -
                                    '''
                            },
                            "Trivy Scan": { 
                                        sh ''' 
                                            bash scripts/trivy-scan/trivy-k8s-scan.sh fadhiljr/nginxapp:employee-frontend-v$IMAGE_VERSION trivy-frontend.json &
                                            bash scripts/trivy-scan/trivy-k8s-scan.sh fadhiljr/nginxapp:employee-backend-v$IMAGE_VERSION trivy-backend.json &

                                            wait
                                       '''                           
                            },
                            "CIS Benchmark v1.6.0": {
                                        sh '''
                                            bash scripts/trivy-scan/trivy-docker-bench.sh  fadhiljr/nginxapp:employee-frontend-v$IMAGE_VERSION trivy-bench-frontend.json || true &
                                            bash scripts/trivy-scan/trivy-docker-bench.sh  fadhiljr/nginxapp:employee-backend-v$IMAGE_VERSION trivy-bench-backend.json &

                                        wait
                                '''
                            }
                        )
                    }
            }
        }


        stage("commit change for argocd") {
            steps {
                script {
                    sshagent(['git-ssh-auth']) {
                            sh '''
                                mkdir -p ~/.ssh
                                ssh-keyscan -H github.com >> ~/.ssh/known_hosts
                                git remote set-url origin git@github.com:dilafar/anguler-springboot-aws-migration.git
                                git pull origin argocd-aws || true
                                git add .
                                git commit -m "change added from jenkins"
                                git push origin HEAD:argocd-aws
                            '''
                    }
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
                                    sh 'sleep 30'
                                    sh '''
                                        docker run  -v /zap/wrk:/zap/wrk:rw -u 1000:1000 -t ghcr.io/zaproxy/zaproxy:stable \
                                                zap-baseline.py -t https://awsvault.cloud-emgmt.com -g gen.conf -r testreport.html || true
                                    '''
                                },
                                "website-monitor":{
                                    sh 'python3 eks/monitor-website.py'
                                }
                            )
                            
                        }
                    }
        }

         stage('Checkout gh-pages Branch') {
            steps {
                    script {
                        sshagent(['git-ssh-auth']) {
                                sh '''
                                    cr version
                                    git fetch origin
                                    git checkout gh-pages
                                    git pull origin gh-pages || true
                                    ls -la
                                    sed -i 's/^appVersion: .*/appVersion: employee-backend-v'"$IMAGE_VERSION"'/g' helm/charts/backend/values.yaml
                                    sed -i 's/^appVersion: .*/appVersion: employee-frontend-v'"$IMAGE_VERSION"'/g' helm/charts/frontend/values.yaml
                                    chmod +x chart-version-increment.sh
                                    ./chart-version-increment.sh helm/Chart.yaml
                                    ./chart-version-increment.sh helm/charts/backend/Chart.yaml
                                    ./chart-version-increment.sh helm/charts/frontend/Chart.yaml
                                '''                          
                                echo "Switched to gh-pages branch"
                        }
                    }
            }
        }

         stage('chart release') {
            steps {
                dir('helm') {
                    script {
                        sh '''
                                cr package
                                cr upload --owner dilafar --git-repo anguler-springboot-aws-migration  --skip-existing
                                cr index --owner dilafar --git-repo anguler-springboot-aws-migration
                        '''
                    }
                }
            }
         }

        stage("commit change on gh-pages") {
            steps {
                script {
                    sshagent(['git-ssh-auth']) {
                            sh '''
                                mkdir -p ~/.ssh
                                ssh-keyscan -H github.com >> ~/.ssh/known_hosts
                                git remote set-url origin git@github.com:dilafar/anguler-springboot-aws-migration.git
                                git pull origin gh-pages || true
                                git add .
                                git commit -m "change added from jenkins"
                                git push origin HEAD:gh-pages
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