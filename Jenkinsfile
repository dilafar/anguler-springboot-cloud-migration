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
        CLOUDSDK_CORE_PROJECT = 'single-portal-443110-r7'
        CLIENT_EMAIL = 'jenkins-gcloud@single-portal-443110-r7.iam.gserviceaccount.com'
        GCLOUD_CRDS = credentials('gcloud-crds')
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
        

        stage("SAST - sonar Analysis(gcp)"){
            environment {
                scannerHome = tool 'sonar6.2'
            }
            steps {
                script {
                    parallel(
                         "sonar Analysis": {
                                    dir('employeemanager') {
                                        sonarAnalysis('sonar',"${scannerHome}","employee-gcp","employee-gcp","1.0","src/","http://172.48.16.173/",
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

        stage("Upload Artifacts(gcp)"){
            steps {
                script {
                        dir('employeemanager') {
                                env.JAR_FILE = sh(script: "ls target/employeemanager-*.jar", returnStdout: true).trim()
                                echo "Found JAR File: ${env.JAR_FILE}"
                                nexusUpload("172.48.16.196:8081","gcp-jar","employeemgmt","${BUILD_ID}","employee-repo","nexus","${env.JAR_FILE}","jar")
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
                                "Trivy Scan": {
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
                                "opa-back": {
                                       dir('employeemanager') {
                                        sh '''
                                            docker run --rm \
                                                -v $(pwd):/project \
                                                openpolicyagent/conftest test --policy dockerfile-security.rego Dockerfile 
                                        '''
                                    }     
                                },
                                "opa-front": {
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
                            sh 'docker system prune -a --volumes --force || true'
                            sh '''
                                    gcloud auth activate-service-account --key-file=$GCLOUD_CRDS
                                    gcloud auth configure-docker us-east1-docker.pkg.dev

                            '''
                                parallel(
                                    "frontend-image-scan": {
                                        dir('employeemanagerfrontend') {
                                            script {
                                                buildCloudImage("us-east1-docker.pkg.dev/single-portal-443110-r7/nginxapp/employee-frontend","v${IMAGE_VERSION}")
                                                dockerCloudPush("us-east1-docker.pkg.dev/single-portal-443110-r7/nginxapp/employee-frontend","v${IMAGE_VERSION}")
                                                sh 'cosign version'
                                                signCloudImage("us-east1-docker.pkg.dev/single-portal-443110-r7/nginxapp/employee-frontend","v${IMAGE_VERSION}","${COSIGN_PRIVATE_KEY}","${COSIGN_PUBLIC_KEY}")
                                            }
                                        }
                                    },
                                    "backend-image-scan": {
                                        dir('employeemanager') {
                                            script {
                                                 buildCloudImage("us-east1-docker.pkg.dev/single-portal-443110-r7/nginxapp/employee-backend","v${IMAGE_VERSION}")
                                                 dockerCloudPush("us-east1-docker.pkg.dev/single-portal-443110-r7/nginxapp/employee-backend","v${IMAGE_VERSION}")
                                                 sh 'cosign version'
                                                 signCloudImage("us-east1-docker.pkg.dev/single-portal-443110-r7/nginxapp/employee-backend","v${IMAGE_VERSION}","${COSIGN_PRIVATE_KEY}","${COSIGN_PUBLIC_KEY}")
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
                        //    }
                        }
                    }
                }


        stage("change image in kubeconfig") {
            steps {
                script {
                    parallel(
                        "update image version": {           
                                script {
                                    sh '''
                                        sed -i "/containers:/,/^[^ ]/s|image:.*|image: us-east1-docker.pkg.dev/single-portal-443110-r7/nginxapp/employee-backend:v$IMAGE_VERSION|g" kustomization/base/backend-deployment.yml
                                        sed -i "s|image:.*|image: us-east1-docker.pkg.dev/single-portal-443110-r7/nginxapp/employee-frontend:v$IMAGE_VERSION|g" kustomization/base/frontend-deployment.yml
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
                                       conftest test -p opa-k8s-security.rego kustomization/base/*
                                    '''
                            },
                            "Trivy Scan": {
                                        sh ''' 
                                            bash trivy-k8s-scan.sh us-east1-docker.pkg.dev/single-portal-443110-r7/nginxapp/employee-frontend:v$IMAGE_VERSION trivy-frontend.json &
                                            bash trivy-k8s-scan.sh us-east1-docker.pkg.dev/single-portal-443110-r7/nginxapp/employee-backend:v$IMAGE_VERSION trivy-backend.json &

                                            wait
                                       '''                           
                            },
                            "CIS Benchmark v1.6.0": {
                                sh '''
                                    bash trivy-docker-bench.sh  us-east1-docker.pkg.dev/single-portal-443110-r7/nginxapp/employee-frontend:v$IMAGE_VERSION trivy-bench-frontend.json || true &
                                    bash trivy-docker-bench.sh  us-east1-docker.pkg.dev/single-portal-443110-r7/nginxapp/employee-backend:v$IMAGE_VERSION trivy-bench-backend.json &

                                    wait
                                '''
                            }
                        )
                    }
            }
        }

        stage("Kubernetes deploy(gke)") {
                steps {
                    script {
                            sh '''
                                        gcloud auth activate-service-account --key-file=$GCLOUD_CRDS
                                        gcloud container clusters get-credentials standered-gke --region us-central1 --project single-portal-443110-r7
                            '''
                            sh '''
                                        if [ ! -f kubernetes-script.sh ]; then
                                            echo "kubernetes-script.sh file is missing!" >&2
                                            exit 1
                                        fi

                                        chmod +x kubernetes-script.sh
                                        chmod +x kubernetes-apply.sh
                            '''
                            sh "./kubernetes-script.sh"
                            sh "./kubernetes-apply.sh"
                            sh 'sleep 60'

                        }
                }
        }

        stage ("kubernetes cluster check(gke)") {
                steps {
                    script {
                            sh '''
                                        gcloud auth activate-service-account --key-file=$GCLOUD_CRDS
                                        gcloud container clusters get-credentials standered-gke --region us-central1 --project single-portal-443110-r7
                            '''
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

        stage("DAST-ZAP") {
                    steps {
                        script {
                            parallel (
                                "DAST": {
                                    sh '''
                                        docker run -v /home/ubuntu:/zap/wrk:rw -u 1000:1000 -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t https://gcpdev.employee-mgmt.com -g gen.conf | tee reports/zap.conf || true
                                    '''
                                },
                                "website-monitor":{
                                    sh 'python3 gke/monitor-website.py'
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
                                git pull origin gcp || true
                                git add .
                                git commit -m "change added from jenkins"
                                git push origin HEAD:gcp
                            '''
                    }
                }
            }
        }

      

    }

    post {
        always {
            script {
                    sh "gcloud auth revoke $CLIENT_EMAIL"
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