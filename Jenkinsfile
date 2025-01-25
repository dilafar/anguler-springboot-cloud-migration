#!/usr/bin/env groovy
import groovy.json.JsonSlurper

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
        DOCKER_REPO = "522814728991.dkr.ecr.us-east-1.amazonaws.com/aws-fullstack"
        DOCKER_REPO_SERVER = "522814728991.dkr.ecr.us-east-1.amazonaws.com"
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
                                    sh 'mvn build-helper:parse-version versions:set \
                                        -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} \
                                        versions:commit'
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
                                nexusArtifactUploader(
                                            nexusVersion: 'nexus3',
                                            protocol: 'http',
                                            nexusUrl: '172.48.16.196:8081',
                                            groupId: 'QA',
                                            version: "${BUILD_ID}",
                                            repository: 'employee-repo',
                                            credentialsId: 'nexus',
                                            artifacts: [
                                                    [artifactId: 'employeemgmt',
                                                    classifier: '',
                                                    file: "${env.JAR_FILE}",
                                                    type: 'jar']
                                                ]
                                )
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
                                        docker run --rm -i hadolint/hadolint < Dockerfile | tee hadolint_lint_front.tx
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

                            withCredentials([usernamePassword(credentialsId: 'ecr-credentials', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                                parallel(
                                    "frontend-image-scan": {
                                        dir('employeemanagerfrontend') {
                                            script {
                                                sh '''
                                                    docker build -t $DOCKER_REPO:frontend-v$IMAGE_VERSION .
                                                    echo $PASS | docker login -u $USER --password-stdin $DOCKER_REPO_SERVER
                                                    docker push $DOCKER_REPO:frontend-v$IMAGE_VERSION
                                                '''
                                                sh 'cosign version'
                                                sh '''
                                                    IMAGE_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' $DOCKER_REPO:frontend-v$IMAGE_VERSION)
                                                    echo "Image Digest: $IMAGE_DIGEST"
                                                    export COSIGN_TLOG_UPLOAD=false
                                                    cosign sign --key $COSIGN_PRIVATE_KEY $IMAGE_DIGEST
                                                    cosign verify --key $COSIGN_PUBLIC_KEY --private-infrastructure=true $IMAGE_DIGEST
                                                '''
                                            }
                                        }
                                    },
                                    "backend-image-scan": {
                                        dir('employeemanager') {
                                            script {
                                                sh '''
                                                    docker build -t $DOCKER_REPO:backend-v$IMAGE_VERSION .
                                                    echo $PASS | docker login -u $USER --password-stdin $DOCKER_REPO_SERVER
                                                    docker push $DOCKER_REPO:backend-v$IMAGE_VERSION
                                                '''
                                                sh 'cosign version'
                                                sh '''
                                                    IMAGE_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' $DOCKER_REPO:backend-v$IMAGE_VERSION)
                                                    echo "Image Digest: $IMAGE_DIGEST"
                                                    export COSIGN_TLOG_UPLOAD=false
                                                    cosign sign --key $COSIGN_PRIVATE_KEY $IMAGE_DIGEST
                                                    cosign verify --key $COSIGN_PUBLIC_KEY --private-infrastructure=true $IMAGE_DIGEST
                                                '''
                                            }
                                        }
                                    },
                                    "copy reports": {
                                            sh '''
                                                cp employeemanagerfrontend/njsscan.sarif  reports/njsscan.sarif
                                                cp employeemanagerfrontend/retire.json reports/retire.json
                                                cp semgrep.json  reports/semgrep.json
                                                cp employeemanager/target/dependency-check-report/dependency-check-report.json reports/dependency-check-report.json
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
                                        sed -i "/containers:/,/^[^ ]/s|image:.*|image: $DOCKER_REPO:backend-v$IMAGE_VERSION|g" kustomization/base/backend-deployment.yml
                                        sed -i "s|image:.*|image: $DOCKER_REPO:frontend-v$IMAGE_VERSION|g" kustomization/base/frontend-deployment.yml
                                        cat kustomization/base/frontend-deployment.yml
                                        cat kustomization/base/backend-deployment.yml
                                    '''
                                }
                        },
                        "DefectDojo Uploader": {
                          //  script {
                          //      sh '''
                          //          pip install --upgrade urllib3 chardet requests
                          //      '''
                          // }
                            parallel(
                                "Frontend Reports Upload": {
                                    dir('reports') {
                                        script {
                                            // python3 upload-reports.py semgrep.json
                                            sh '''                                           
                                                python3 upload-reports.py njsscan.sarif
                                                python3 upload-reports.py retire.json
                                                python3 upload-reports.py semgrep.json
                                                python3 upload-reports.py dependency-check-report.json
                                            '''
                                        }
                                    }
                                },
                                "Backend Reports Upload": {
                                    dir('employeemanager') {
                                        script {
                                            sh '''
                                               echo "python3 upload-reports.py /target/dependency-check-report/dependency-check-report.json"
                                            '''
                                        }
                                    }
                                }
                            )
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
                                       helm template helm | conftest test -p opa-k8s-security.rego -
                                    '''
                            },
                            "Trivy Scan": {
                                        sh ''' 
                                            bash trivy-k8s-scan.sh $DOCKER_REPO:frontend-v$IMAGE_VERSION &
                                            bash trivy-k8s-scan.sh $DOCKER_REPO:backend-v$IMAGE_VERSION &

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
                        withAWS(credentials: 'awseksadmin', region: 'us-east-1') {
                            sh "aws eks update-kubeconfig --name eks-terraform-2 --region us-east-1"
                            sh '''
                                        if [ ! -f kubernetes-script.sh ]; then
                                            echo "kubernetes-script.sh file is missing!" >&2
                                            exit 1
                                        fi
                                        chmod +x kubernetes-script.sh
                                        chmod +x kubernetes-apply.sh
                            '''
                //            sh "kubectl apply -f kustomization/ingress.yml -n employee"
                            sh "kubectl config current-context"
                //            sh "kubectl apply -f kustomization/externalDNS.yml"
                            sh "./kubernetes-script.sh"
                            sh "./kubernetes-apply.sh"
                            sh 'sleep 90'
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
                              //  "kubernetes cluster scan": {
                              //      sh '''
                              //          kubescape scan
                              //      '''
                              //  }
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
                                        docker run  -v /zap/wrk:/zap/wrk:rw -u 1000:1000 -t ghcr.io/zaproxy/zaproxy:stable \
                                                zap-baseline.py -t https://awsdev.cloud-emgmt.com -g gen.conf -r testreport.html || true
                                    '''
                                },
                                "website-monitor":{
                                    sh 'python3 eks/monitor-website.py'
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
                                git push origin HEAD:aws-helm
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