pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
        timestamps()
    }

    parameters {
        string(
            name: 'AWS_CREDENTIALS_ID',
            defaultValue: 'aws-terraform-prod',
            description: 'Jenkins AWS Credentials ID'
        )

        string(
            name: 'SSH_PUBLIC_KEY_CREDENTIALS_ID',
            defaultValue: 'ec2-ssh-public-key',
            description: 'Jenkins Secret File Credential containing EC2 SSH public key'
        )

        string(
            name: 'AWS_REGION',
            defaultValue: 'us-east-1',
            description: 'AWS Region'
        )

        choice(
            name: 'TERRAFORM_ACTION',
            choices: ['apply', 'destroy'],
            description: 'Terraform Action'
        )
    }

    environment {
        TF_IN_AUTOMATION = 'true'
        TF_INPUT = 'false'
        TF_PLUGIN_CACHE_DIR = "${HOME}/.terraform.d/plugin-cache"
        SSH_PUBLIC_KEY_LOCAL_PATH = "${WORKSPACE}/ec2_key.pub"
    }

    stages {

        stage('Terraform Init') {
            steps {
                sh '''
                    mkdir -p "$TF_PLUGIN_CACHE_DIR"

                    terraform init \
                      -input=false
                '''
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    file(credentialsId: params.SSH_PUBLIC_KEY_CREDENTIALS_ID, variable: 'SSH_PUBLIC_KEY_FILE'),
                    [$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: params.AWS_CREDENTIALS_ID]
                ]) {

                    sh '''
                        cp "$SSH_PUBLIC_KEY_FILE" "$SSH_PUBLIC_KEY_LOCAL_PATH"

                        CURRENT_PUBLIC_IP=$(curl -fsS https://checkip.amazonaws.com | tr -d '\\r\\n')

                        if [ "${TERRAFORM_ACTION}" = "destroy" ]; then

                            terraform plan \
                                -destroy \
                                -input=false \
                                -out=tfplan \
                                -var="aws_region=${AWS_REGION}" \
                                -var="ssh_cidr=${CURRENT_PUBLIC_IP}/32" \
                                -var="public_key_path=${SSH_PUBLIC_KEY_LOCAL_PATH}"

                        else

                            terraform plan \
                                -input=false \
                                -out=tfplan \
                                -var="aws_region=${AWS_REGION}" \
                                -var="ssh_cidr=${CURRENT_PUBLIC_IP}/32" \
                                -var="public_key_path=${SSH_PUBLIC_KEY_LOCAL_PATH}"

                        fi

                        terraform show tfplan
                    '''
                }
            }
        }

        stage('Manual Approval') {
            steps {
                script {
                    if (params.TERRAFORM_ACTION == 'apply') {
                        input(
                            message: 'Approve Terraform Apply?',
                            ok: 'Apply'
                        )
                    } else {
                        input(
                            message: 'Approve Terraform Destroy?',
                            ok: 'Destroy'
                        )
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression {
                    params.TERRAFORM_ACTION == 'apply'
                }
            }

            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: params.AWS_CREDENTIALS_ID]
                ]) {
                    sh '''
                        terraform apply \
                          -input=false \
                          -auto-approve \
                          tfplan
                    '''
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression {
                    params.TERRAFORM_ACTION == 'destroy'
                }
            }

            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: params.AWS_CREDENTIALS_ID]
                ]) {
                    sh '''
                        terraform apply \
                          -input=false \
                          -auto-approve \
                          tfplan
                    '''
                }
            }
        }
    }

    post {
        always {
            sh '''
                rm -f tfplan || true
                rm -f "$SSH_PUBLIC_KEY_LOCAL_PATH" || true
            '''
            cleanWs()
        }
    }
}