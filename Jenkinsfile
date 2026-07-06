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
        booleanParam(name: 'DELETE_ORPHANED_SECURITY_GROUP', defaultValue: false, description: 'If true, deletes an existing AWS security group (by name+VPC) not tracked in Terraform state before planning.')
        string(name: 'ORPHANED_SG_NAME', defaultValue: 'terraform-ec2-prod-sg', description: 'Name of the security group to check/delete if DELETE_ORPHANED_SECURITY_GROUP is true.')
        string(name: 'ORPHANED_SG_VPC_ID', defaultValue: 'vpc-07fafa65dcf62033f', description: 'VPC ID to scope the security group lookup.')
    }

    environment {
        TF_IN_AUTOMATION = 'true'
        TF_INPUT = 'false'
        SSH_PUBLIC_KEY_LOCAL_PATH = "${WORKSPACE}/.jenkins_ec2_key.pub"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Delete Orphaned Security Group') {
            when {
                expression { return params.DELETE_ORPHANED_SECURITY_GROUP }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS_CREDENTIALS_ID]]) {
                    sh """
                        SG_ID=\$(aws ec2 describe-security-groups \\
                            --region ${params.AWS_REGION} \\
                            --filters "Name=group-name,Values=${params.ORPHANED_SG_NAME}" "Name=vpc-id,Values=${params.ORPHANED_SG_VPC_ID}" \\
                            --query 'SecurityGroups[0].GroupId' \\
                            --output text)

                        if [ "\$SG_ID" != "None" ] && [ -n "\$SG_ID" ]; then
                            echo "Found orphaned security group \$SG_ID (${params.ORPHANED_SG_NAME}) — deleting..."
                            aws ec2 delete-security-group --region ${params.AWS_REGION} --group-id "\$SG_ID"
                            echo "Deleted \$SG_ID."
                        else
                            echo "No matching security group found for name=${params.ORPHANED_SG_NAME}, vpc=${params.ORPHANED_SG_VPC_ID}. Skipping."
                        fi
                    """
                }
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
                script {
                    if (params.SSH_PUBLIC_KEY?.trim()) {
                        writeFile file: env.SSH_PUBLIC_KEY_LOCAL_PATH, text: "${params.SSH_PUBLIC_KEY.trim()}\n"
                    } else {
                        withCredentials([file(credentialsId: params.SSH_PUBLIC_KEY_CREDENTIALS_ID, variable: 'SSH_PUBLIC_KEY_FILE')]) {
                            sh '''
                                rm -f "$SSH_PUBLIC_KEY_LOCAL_PATH" 2>/dev/null || true
                                cp "$SSH_PUBLIC_KEY_FILE" "$SSH_PUBLIC_KEY_LOCAL_PATH"
                            '''
                        }
                    }
                }

                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS_CREDENTIALS_ID]]) {
                    script {
                        def destroyFlag = params.TERRAFORM_ACTION == 'destroy' ? '-destroy' : ''

                        sh """
                            CURRENT_PUBLIC_IP=\$(curl -fsS https://checkip.amazonaws.com | tr -d '\\r\\n')

                            terraform plan ${destroyFlag} \\
                              -input=false \\
                              -out=tfplan \\
                              -var="aws_region=${params.AWS_REGION}" \\
                              -var="ssh_cidr=\${CURRENT_PUBLIC_IP}/32" \\
                              -var="public_key_path=${env.SSH_PUBLIC_KEY_LOCAL_PATH}"
                        """
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

    post {
        always {
            cleanWs()
        }
    }
}