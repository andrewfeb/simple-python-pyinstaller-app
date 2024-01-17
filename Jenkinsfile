node {
    stage('Build') {
        docker.image('python:3.12.1-alpine3.19').inside {
            sh 'python -m py_compile sources/add2vals.py sources/calc.py'
            stash(name: 'compiled-results', includes: 'sources/*.py*')
        }
    }
    stage('Test') {
       
        docker.image('qnib/pytest').inside {
            try {
                sh 'py.test --verbose --junit-xml test-reports/results.xml sources/test_calc.py'            
            } catch(e) {

            } finally {
                junit 'test-reports/results.xml'
            }
        }
    }
    stage('Manual Approval') {
        input message: 'Lanjutkan ke tahap Deploy? (Klik "Proceed" untuk lanjut ke tahap Deploy)'
    }

    stage('Deploy') {
        withEnv(['VOLUME=$(pwd)/sources:/src',
                'IMAGE=cdrx/pyinstaller-linux:python2']) {
            try {
                dir(path: env.BUILD_ID) { 
                    unstash(name: 'compiled-results') 
                    sh "docker run --rm -v ${VOLUME} ${IMAGE} 'pyinstaller -F add2vals.py'" 
                }
                sh 'sleep 60s'
                archiveArtifacts "${env.BUILD_ID}/sources/dist/add2vals" 
                sh "docker run --rm -v ${VOLUME} ${IMAGE} 'rm -rf build dist'"
            } catch(e) {

            }           
        }
    }
    stage('Deploy to cloud') {
        input message: 'Lanjutkan deploy ke Azure? (klik "Process" untuk lanjut)'

        withEnv([
            'registryName=simplepython',
            'registryCredential=ACR-PYTHON',
            'dockerImage= ',
            'registryUrl=simplepython.azurecr.io',
            'containerName=python-app'
        ]) {
            script {
                dockerImage = docker.build registryName
                docker.withRegistry("http://${registryUrl}", registryCredential) {
                    dockerImage.push()
                }
            }
            withCredentials([
                usernamePassword(credentialsId: 'AZ-LOGIN', passwordVariable: 'az_pwd', usernameVariable: 'az_usr'),
                string(credentialsId: 'AZ-TENANT', variable: 'az_tenant')
            ]) {
                docker.image('mcr.microsoft.com/azure-cli:latest').inside('-it -v ${HOME}:/home/az -e HOME=/home/az') {
                    sh 'az login --service-principal --username ${az_usr} --password ${az_pwd} --tenant ${az_tenant} --output table'
                    sh 'az container create --resource-group CICDResources --name ${containerName} --image ${registryUrl}/${registryName}:latest --registry-login-server ${registryUrl} --registry-username ${az_usr} --registry-password ${az_pwd} --ip-address Public --protocol TCP --ports 8080 --dns-name-label ${containerName} --query "{FQDN:ipAddress.fqdn, IpAddress:ipAddress.ip, Port:ipAddress.ports[0].port}" --output table'
                }
            }
        }
    }
}