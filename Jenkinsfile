pipeline {
    agent any

    environment {
        AWS_REGION         = 'sa-east-1'
        AWS_DEFAULT_REGION = 'sa-east-1'
        TF_IN_AUTOMATION   = 'true'
        TF_WORKSPACE       = 'lab-3b'
    }

    options {
        timestamps()
        ansiColor('xterm')
        timeout(time: 60, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'lab-3b', url: 'https://github.com/tiqsclass6/aws-armageddon-class-7.0'
            }
        }

        stage('Verify Tools') {
            steps {
                sh '''
                    terraform --version
                    aws --version
                '''
            }
        }

        stage('Terraform Format') {
            steps {
                sh 'terraform fmt -check -recursive -no-color || true'
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'armageddon',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        set +x
                        aws sts get-caller-identity
                        terraform init -no-color
                    '''
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate -no-color'
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'armageddon',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        set +x
                        terraform plan -no-color -out=tfplan
                    '''
                }
                archiveArtifacts artifacts: 'tfplan', allowEmptyArchive: true
            }
        }

        stage('Terraform Apply') {
            when {
                beforeInput true
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                script {
                    def userChoice = input(
                        message: 'Terraform Apply Decision',
                        ok: 'Proceed',
                        parameters: [
                            choice(
                                name: 'ACTION',
                                choices: ['Apply', 'Skip'],
                                description: 'Choose "Apply" to deploy changes, or "Skip" to proceed directly to destroy without applying.'
                            )
                        ]
                    )

                    if (userChoice == 'Apply') {
                        withCredentials([[
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: 'armageddon',
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]]) {
                            sh '''
                                set +x
                                terraform apply -no-color -auto-approve tfplan
                            '''
                        }
                    } else {
                        echo 'Apply stage skipped by user. Proceeding to destroy stage.'
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                beforeInput true
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                input message: 'Do you want to destroy the Terraform infrastructure?', ok: 'Destroy'
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'armageddon',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        set +x
                        terraform destroy -no-color -auto-approve
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
            echo '📌 Pipeline execution finished.'
        }
        success {
            echo '✅ Terraform pipeline completed successfully.'
        }
        failure {
            echo '❌ Terraform pipeline failed.'
        }
    }
}