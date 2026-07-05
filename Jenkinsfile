pipeline {
    agent any

    parameters {
        string(name: 'AWS_CREDENTIALS_ID', defaultValue: 'aws-terraform-prod', description: 'Jenkins AWS credentials ID with permission to manage the EC2 stack.')
        string(name: 'SSH_PUBLIC_KEY_CREDENTIALS_ID', defaultValue: 'ec2-ssh-public-key', description: 'Jenkins secret file credential containing the EC2 SSH public key.')
        string(name: 'AWS_REGION', defaultValue: 'us-east-1', description: 'AWS region for the EC2 deployment.')
        booleanParam(name: 'AUTO_APPROVE', defaultValue: false, description: 'Apply Terraform without a manual approval prompt.')
    }

    environment {
        TF_IN_AUTOMATION = 'true'
        TF_INPUT = 'false'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init -input=false'
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform fmt -check -recursive'
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS_CREDENTIALS_ID],
                    file(credentialsId: params.SSH_PUBLIC_KEY_CREDENTIALS_ID, variable: 'SSH_PUBLIC_KEY_FILE')
                ]) {
                    sh '''
                                                CURRENT_PUBLIC_IP=$(curl -fsS https://checkip.amazonaws.com | tr -d '\r\n')

                        terraform plan \
                          -input=false \
                          -out=tfplan \
                          -var="aws_region=${AWS_REGION}" \
                                                    -var="ssh_cidr=${CURRENT_PUBLIC_IP}/32" \
                          -var="public_key_path=${SSH_PUBLIC_KEY_FILE}"
                    '''
                }
            }
        }

        stage('Approve Apply') {
            when {
                expression { return !params.AUTO_APPROVE }
            }
            steps {
                input message: 'Apply this Terraform plan and deploy the EC2 instance?', ok: 'Apply'
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS_CREDENTIALS_ID]]) {
                    sh 'terraform apply -input=false -auto-approve tfplan'
                }
            }
        }
    }

}