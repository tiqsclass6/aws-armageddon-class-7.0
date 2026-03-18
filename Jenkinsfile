pipeline {
    agent any

    environment {
        AWS_REGION = 'sa-east-1'
        AWS_DEFAULT_REGION = 'sa-east-1'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'lab-3b', url: 'https://github.com/tiqsclass6/aws-armageddon-class-7.0'
            }
        }

        stage('Initialize Terraform') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'armageddon'
                ]]) {
                    sh '''
                    set +x
                    aws sts get-caller-identity
                    terraform init
                    '''
                }
            }
        }

        stage('Plan Terraform') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'armageddon'
                ]]) {
                    sh '''
                    set +x
                    terraform plan -out=tfplan
                    '''
                }
            }
        }

        stage('Apply Terraform') {
            steps {
                input message: 'Approve Terraform Apply?', ok: 'Deploy'
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'armageddon'
                ]]) {
                    sh '''
                    set +x
                    terraform apply -auto-approve tfplan
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Terraform deployment completed successfully!'
        }
        failure {
            echo 'Terraform deployment failed!'
        }
    }
}