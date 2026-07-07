# Terraform EC2 Deployment

This repository provisions a simple AWS EC2 instance with Terraform. It creates an EC2 key pair, security group, and instance in the default VPC.

## Prerequisites

- Terraform `>= 1.6.0`
- AWS credentials with permission to manage EC2, VPC security groups, and key pairs
- AWS permissions to create and configure the S3 bucket used for Terraform remote state
- An SSH key pair on the machine running Terraform
- A Linux/Unix Jenkins agent if using the included `Jenkinsfile`

## Terraform State Backend

Terraform state is stored in an S3 remote backend declared in `backend.tf`. A single backend bucket is shared across environments, and each environment uses its own state key:

| Environment | Backend key |
| --- | --- |
| `dev` | `dev/terraform.tfstate` |
| `qa` | `qa/terraform.tfstate` |
| `prod` | `prod/terraform.tfstate` |

The backend is configured during initialization with these environment variables:

| Variable | Description |
| --- | --- |
| `BACKEND_BUCKET` | S3 bucket that stores Terraform state |
| `ENVIRONMENT` | Deployment environment used to generate `<ENVIRONMENT>/terraform.tfstate` |
| `AWS_REGION` | AWS region for the backend bucket and provider |

The Jenkins pipeline checks whether `BACKEND_BUCKET` exists before `terraform init`. If the bucket is missing, Jenkins creates it, waits for it to exist, enables versioning, and enables AES256 default server-side encryption.

## Configure Variables

Review and update `terraform.tfvars` before deployment:

```hcl
aws_region       = "us-east-1"
project_name     = "terraform-ec2"
environment      = "prod"
ami_id           = "ami-051e483428ae60e7d"
instance_type    = "m5.xlarge"
ssh_cidr         = "203.0.113.10/32"
public_key_path  = "~/.ssh/id_rsa.pub"
private_key_path = "~/.ssh/id_rsa"
```

Make sure `public_key_path` points to an existing public key file. Set `ssh_cidr` to the public IP address allowed to connect over SSH with a `/32` suffix. The default `m5.xlarge` instance type is used because the SQL Server Standard AMI is not supported on `t2.micro`.

## Deploy Locally

1. Configure AWS credentials:

   ```bash
   aws configure
   ```

2. Initialize Terraform:

   ```bash
   export BACKEND_BUCKET="your-terraform-state-bucket"
    export ENVIRONMENT="dev"
   export AWS_REGION="us-east-1"

   terraform init \
     -reconfigure \
     -backend-config="bucket=$BACKEND_BUCKET" \
       -backend-config="key=$ENVIRONMENT/terraform.tfstate" \
     -backend-config="region=$AWS_REGION" \
     -backend-config="encrypt=true"
   ```

3. Format and validate the configuration:

   ```bash
   terraform fmt -recursive
   terraform validate
   ```

4. Review the deployment plan:

   ```bash
   terraform plan
   ```

5. Apply the configuration:

   ```bash
   terraform apply
   ```

6. Connect to the instance using the generated output:

   ```bash
   terraform output ssh_command_git_bash
   ```

## Destroy Resources

Run this command when you no longer need the EC2 instance:

```bash
terraform destroy
```

## Jenkins Deployment

The included `Jenkinsfile` runs Terraform from Jenkins with these stages:

1. Checkout
2. Terraform init, including S3 backend bucket check and automatic bucket setup when missing
3. Terraform plan or destroy plan
4. Manual approval
5. Terraform apply the saved plan for either apply or destroy

Create this Jenkins credential before running the pipeline:

| Credential ID | Type | Purpose |
| --- | --- | --- |
| `aws-terraform-prod` | AWS credentials | AWS access key and secret key for Terraform |

Create this credential for the EC2 SSH public key:

| Credential ID | Type | Purpose |
| --- | --- | --- |
| `ec2-ssh-public-key` | Secret file | Public SSH key used to create the EC2 key pair |

Pipeline parameters:

| Parameter | Default | Description |
| --- | --- | --- |
| `AWS_CREDENTIALS_ID` | `aws-terraform-prod` | Jenkins credential ID for AWS access |
| `SSH_PUBLIC_KEY_CREDENTIALS_ID` | `ec2-ssh-public-key` | Jenkins secret file credential containing the public key |
| `AWS_REGION` | `us-east-1` | AWS region for deployment |
| `ENVIRONMENT` | `dev` | Deployment environment. Jenkins uses this to select `<ENVIRONMENT>/terraform.tfstate` and passes it to Terraform as `var.environment` |
| `BACKEND_BUCKET` | empty | S3 bucket for Terraform remote state. This must be set before running the pipeline |
| `TERRAFORM_ACTION` | `apply` | Choose `apply` to create/update the stack or `destroy` to remove it |

Apply and destroy both pass `-var="environment=${ENVIRONMENT}"`, create a saved `tfplan`, pause for manual approval, and then run `terraform apply -auto-approve tfplan`. Destroy uses `terraform plan -destroy` before approval, so the approved saved plan is the exact destroy operation Jenkins applies.

The Jenkins agent must have Terraform installed and available on `PATH`.
It must also have the AWS CLI and `curl` available. The AWS CLI is used to check and configure the S3 backend bucket. `curl` is used to detect the agent's public IP and pass it to Terraform as `ssh_cidr`.

## Required AWS IAM Permissions

The Jenkins AWS credentials need permissions for the Terraform-managed EC2 resources and the S3 remote backend. At minimum, allow the required EC2, VPC, and key pair actions for this configuration, plus these S3 backend actions on the backend bucket:

```json
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Action": [
            "s3:CreateBucket",
            "s3:HeadBucket",
            "s3:GetBucketLocation",
            "s3:GetBucketVersioning",
            "s3:PutBucketVersioning",
            "s3:GetEncryptionConfiguration",
            "s3:PutEncryptionConfiguration",
            "s3:ListBucket"
         ],
         "Resource": "arn:aws:s3:::your-terraform-state-bucket"
      },
      {
         "Effect": "Allow",
         "Action": [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
         ],
         "Resource": "arn:aws:s3:::your-terraform-state-bucket/*/terraform.tfstate"
      }
   ]
}
```

## Push to GitHub

After creating a separate GitHub repository, connect this local repository and push it:

```bash
git remote add origin https://github.com/<your-username>/terraform-mcp.git
git push -u origin terraform-mcp
```

Replace `<your-username>` with your GitHub username or organization name.