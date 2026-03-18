pipeline {
    agent any

    environment {
        AWS_REGION         = 'sa-east-1'
        AWS_DEFAULT_REGION = 'sa-east-1'
        TF_IN_AUTOMATION   = 'true'
    }

    options {
        timestamps()
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'lab-3b', url: 'https://github.com/tiqsclass6/aws-armageddon-class-7.0'
            }
        }

        stage('Terraform Format') {
            steps {
                sh 'terraform fmt -check -recursive'
            }
        }

        stage('Terraform Init') {
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

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
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

        stage('Terraform Apply') {
            steps {
                input message: 'Approve Terraform Apply?', ok: 'Apply'
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

        stage('Terraform Destroy') {
            steps {
                input message: 'Do you want to destroy the Terraform infrastructure?', ok: 'Destroy'
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'armageddon'
                ]]) {
                    sh '''
                        set +x
                        terraform destroy -auto-approve
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Terraform pipeline completed successfully.'
        }
        failure {
            echo '❌ Terraform pipeline failed.'
        }
        always {
            echo '📌 Pipeline execution finished.'
        }
    }
}