pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
        disableConcurrentBuilds()
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
            name: 'ENVIRONMENT',
            choices: ['dev', 'qa', 'prod'],
            description: 'Deployment environment'
        )

        string(
            name: 'BACKEND_BUCKET',
            defaultValue: '',
            description: 'S3 bucket for Terraform remote state'
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
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: params.AWS_CREDENTIALS_ID]
                ]) {
                    sh '''
                        mkdir -p "$TF_PLUGIN_CACHE_DIR"

                        if [ -z "$BACKEND_BUCKET" ]; then
                            echo "BACKEND_BUCKET is required."
                            exit 1
                        fi

                        STATE_KEY="${ENVIRONMENT}/terraform.tfstate"

                        if aws s3api head-bucket --bucket "$BACKEND_BUCKET" 2>/dev/null; then
                            echo "Terraform backend bucket already exists: $BACKEND_BUCKET"
                        else
                            echo "Creating Terraform backend bucket: $BACKEND_BUCKET"

                            if [ "$AWS_REGION" = "us-east-1" ]; then
                                aws s3api create-bucket \
                                  --bucket "$BACKEND_BUCKET" \
                                  --region "$AWS_REGION"
                            else
                                aws s3api create-bucket \
                                  --bucket "$BACKEND_BUCKET" \
                                  --region "$AWS_REGION" \
                                  --create-bucket-configuration LocationConstraint="$AWS_REGION"
                            fi

                            aws s3api wait bucket-exists --bucket "$BACKEND_BUCKET"
                        fi

                        aws s3api put-bucket-versioning \
                          --bucket "$BACKEND_BUCKET" \
                          --versioning-configuration Status=Enabled

                        aws s3api put-bucket-encryption \
                          --bucket "$BACKEND_BUCKET" \
                          --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

                        terraform init \
                          -reconfigure \
                          -backend-config="bucket=$BACKEND_BUCKET" \
                          -backend-config="key=$STATE_KEY" \
                          -backend-config="region=$AWS_REGION" \
                          -backend-config="encrypt=true"
                    '''
                }
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
                                -var="environment=${ENVIRONMENT}" \
                                -var="ssh_cidr=${CURRENT_PUBLIC_IP}/32" \
                                -var="public_key_path=${SSH_PUBLIC_KEY_LOCAL_PATH}"

                        else

                            terraform plan \
                                -input=false \
                                -out=tfplan \
                                -var="aws_region=${AWS_REGION}" \
                                -var="environment=${ENVIRONMENT}" \
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
        }
    }
}