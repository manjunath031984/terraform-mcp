# Terraform EC2 Deployment

This repository provisions a simple AWS EC2 instance with Terraform. It creates an EC2 key pair, security group, and instance in the default VPC.

## Prerequisites

- Terraform `>= 1.6.0`
- AWS credentials with permission to manage EC2, VPC security groups, and key pairs
- An SSH key pair on the machine running Terraform
- A Linux/Unix Jenkins agent if using the included `Jenkinsfile`

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
   terraform init
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
2. Terraform init
3. Terraform format check and validate
4. Terraform plan
5. Manual approval
6. Terraform apply

Create this Jenkins credential before running the pipeline:

| Credential ID | Type | Purpose |
| --- | --- | --- |
| `aws-terraform-prod` | AWS credentials | AWS access key and secret key for Terraform |

For the EC2 SSH public key, either paste the public key into the `SSH_PUBLIC_KEY` build parameter or create this optional credential:

| Credential ID | Type | Purpose |
| --- | --- | --- |
| `ec2-ssh-public-key` | Secret file | Public SSH key used to create the EC2 key pair when `SSH_PUBLIC_KEY` is empty |

Pipeline parameters:

| Parameter | Default | Description |
| --- | --- | --- |
| `AWS_CREDENTIALS_ID` | `aws-terraform-prod` | Jenkins credential ID for AWS access |
| `SSH_PUBLIC_KEY` | empty | Optional EC2 SSH public key text. If set, no SSH public key credential is required |
| `SSH_PUBLIC_KEY_CREDENTIALS_ID` | `ec2-ssh-public-key` | Jenkins secret file credential containing the public key when `SSH_PUBLIC_KEY` is empty |
| `AWS_REGION` | `us-east-1` | AWS region for deployment |
| `AUTO_APPROVE` | `false` | Set to `true` to skip the manual approval step |

The Jenkins agent must have Terraform installed and available on `PATH`.
It must also have `curl` available so the pipeline can detect the agent's public IP and pass it to Terraform as `ssh_cidr`.

## Push to GitHub

After creating a separate GitHub repository, connect this local repository and push it:

```bash
git remote add origin https://github.com/<your-username>/terraform-mcp.git
git push -u origin terraform-mcp
```

Replace `<your-username>` with your GitHub username or organization name.