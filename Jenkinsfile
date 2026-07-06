pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }

    parameters {
        string(name: 'AWS_CREDENTIALS_ID', defaultValue: 'aws-terraform-prod', description: 'Jenkins AWS credentials ID with permission to manage the EC2 stack.')
        text(name: 'SSH_PUBLIC_KEY', defaultValue: '', description: 'Optional EC2 SSH public key text. If set, this takes precedence over the secret file credential below.')
        string(name: 'SSH_PUBLIC_KEY_CREDENTIALS_ID', defaultValue: 'ec2-ssh-public-key', description: 'Jenkins secret file credential containing the EC2 SSH public key. Used only if SSH_PUBLIC_KEY is left blank.')
        string(name: 'AWS_REGION', defaultValue: 'us-east-1', description: 'AWS region for the EC2 deployment.')
        choice(name: 'TERRAFORM_ACTION', choices: ['apply', 'destroy'], description: 'Choose whether to create/update or destroy the Terraform-managed EC2 stack.')
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
                retry(3) {
                    sh '''
                        mkdir -p "$HOME/.terraform.d/plugin-cache"
                        TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache" terraform init -input=false
                    '''
                }
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
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS_CREDENTIALS_ID]]) {
                    script {
                        def runPlan = { publicKeyPath ->
                            def destroyFlag = params.TERRAFORM_ACTION == 'destroy' ? '-destroy' : ''

                            sh """
                                CURRENT_PUBLIC_IP=\$(curl -fsS https://checkip.amazonaws.com | tr -d '\\r\\n')

                                terraform plan ${destroyFlag} \\
                                  -input=false \\
                                  -out=tfplan \\
                                  -var="aws_region=${params.AWS_REGION}" \\
                                  -var="ssh_cidr=\${CURRENT_PUBLIC_IP}/32" \\
                                  -var="public_key_path=${publicKeyPath}"
                            """
                        }

                        if (params.SSH_PUBLIC_KEY?.trim()) {
                            def publicKeyPath = "${pwd()}/.jenkins_ec2_key.pub"
                            writeFile file: publicKeyPath, text: "${params.SSH_PUBLIC_KEY.trim()}\n"
                            runPlan(publicKeyPath)
                        } else {
                            withCredentials([file(credentialsId: params.SSH_PUBLIC_KEY_CREDENTIALS_ID, variable: 'SSH_PUBLIC_KEY_FILE')]) {
                                runPlan(env.SSH_PUBLIC_KEY_FILE)
                            }
                        }
                    }
                }
            }
        }

        stage('Approve Apply') {
            when {
                expression { return !params.AUTO_APPROVE || params.TERRAFORM_ACTION == 'destroy' }
            }
            steps {
                script {
                    input message: "Apply this Terraform ${params.TERRAFORM_ACTION} plan?", ok: 'Apply'
                }
            }
        }

        stage('Terraform Apply/Destroy') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS_CREDENTIALS_ID]]) {
                    sh 'terraform apply -input=false -auto-approve tfplan'
                }
            }
        }
    }
}