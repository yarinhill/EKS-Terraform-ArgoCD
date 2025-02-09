# Deploy AWS Kubernetes Service (EKS) using Terraform, GitHub Actions and Argo CD

## 1. Installation Process

### 01.

Install Terraform & aws-cli on your Workstation

### 02.

Create a User in AWS IAM for your workstation with the Permissions found in the custom_policy.json file

### 03.

Create Access Key & Secret key for that IAM user and enter them in your workstation with the command:

```
aws configure
```

## 2. Infrastructure Setup (Terraform)

### 01. (Optional)

Create an s3 bucket for storing the Terraform State File

```
aws s3api create-bucket --bucket <your_bucket_name> --region <your_region> --acl private --create-bucket-configuration LocationConstraint=<your_region>
```

Uncomment the lines in terraform/s3.tf file, and edit the details to suit your created bucket 

```
vim terraform/s3.tf
```

### 02.

To connect to the Bastion Instance, you need to generate an SSH key pair. Use the following command in your terminal:

```
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_ter
```

### 03.

Navigate to the terraform directory and edit the variables.tf file to suit your enviorment (These components will be created by terraform):

```
vim variables.tf
```


### 04.

Run the following commands to initialize, and apply the terraform files

```
terraform init
terraform apply
```

### 05.

Copy the values displayed at the end of the Terraform creation process.


## 2. Deployment Process (GitHub Actions)

### 01.

Navigate to the .github/workflows directory and edit the aws.yml file, change the IMAGE_TAG value

### 02.

Create an AWS user for GitHub with the following permissions:

```
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "Statement1",
			"Effect": "Allow",
			"Action": [
				"ecr:GetDownloadUrlForLayer",
				"ecr:BatchGetImage",
				"ecr:BatchCheckLayerAvailability",
				"ecr:GetAuthorizationToken",
				"ecr:InitiateLayerUpload",
				"ecr:PutImage",
				"ecr:UploadLayerPart",
				"ecr:CompleteLayerUpload"
			],
			"Resource": [
				"*"
			]
		}
	]
}
```

Go to the GitHub Repository -- > Settings -- > Secrets and variables 

### 03.

Add the following Repository secrets in your GitHub repository:
   + AWS_ACCESS_KEY_ID
   + AWS_SECRET_ACCESS_KEY
   + ECR_REGISTRY_URL
   + AWS_REGION

### 04.

Commit and push the .github/workflows/aws.yaml file to trigger the GitHub Actions workflow with the new IMAGE_TAG value


## 3. Cluster Configuration (ArgoCD)

### 01.

configure kubectl to work with your Amazon EKS cluster with the command

```
eksctl utils write-kubeconfig --cluster=<your_cluster_name>
```
### 02.

Access ArgoCD using the Load Balancer DNS provided by Terraform (ARGOCD_LB_DNS)

### 03.

Use the following credentials to log in to ArgoCD:

```
Username: admin
Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode
```

### 04.

Deploy MongoDB by navigating to Create Application -> Edit as YAML, and paste the contents from argocd/mongodb.yaml, change the value parameters 

### 05.

Deploy Node App by navigating to Create Application -> Edit as YAML, and paste the contents from argocd/node-app.yaml, change the value parameters 

### 06.

Access the Node App using the Load Balancer DNS by running the command:

```
kubectl get svc node-app
```

You should see "Successfully connected to DB ✅" from the web server.
