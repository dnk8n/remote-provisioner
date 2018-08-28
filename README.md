# remote-provisioner

Designed to be used within a hosted CI tool, this set of configs allows temporary provisioning infrastructure to be launched from within your own AWS VPC.

One of the benefits of this is that secrets can be managed within your amazon account and nowhere else. It is also easy to choose the infrastructure specs you desire for your provisioning.

**Hello World (executed from local machine)**

- Install docker
- Install docker-compose
- Configure aws credentials as you would for the aws-cli
- `cd src/docker && docker-compose up`

**Usage(from CI tool):**

- The following environment variables must be set:
  - `AWS_ACCESS_KEY_ID` 
  - `AWS_SECRET_ACCESS_KEY`

- Your CI tool needs the following information:
```
image: hashicorp/terraform:latest
    working_directory: ${project_root_directory}
    commands:
      - wget https://raw.githubusercontent.com/dnk8n/remote-provisioner/master/src/terraform/terraform.aws.main.tf
      - terraform init
      - terraform apply -auto-approve=true -var-file=${terraform_var_file}
      - terraform destroy -auto-approve=true -var-file=${terraform_var_file}
```
where `project_root_directory` contains a directory or file (script/s, config/s, etc) which are to be copied on to the temporary provisioning infrastructure.
where `terraform_var_file` contains the optional extra variables that will be explained below.

- `terraform_var_file` options with their defaults:
```
vpc_id = ""
subnet_id = ""
ami_owners = ["amazon"]
ami_name_regex = "amzn-ami-*"
ami_most_recent = true
ssh_user = "ec2-user"
instance_type = "t2.nano"
iam_instance_profile = ""
region = "us-east-1"
zone = ""
timeout_minutes = 1
file_or_dir_source = "terraform.aws.main.tf"
file_or_dir_dest = "/tmp/terraform.aws.main.tf"
remote_command = ["echo 'Hello World!' && ls -lah /tmp/terraform.aws.main.tf"]
security_group_id = ""
ingress_security_groups = []
ingress_security_groups_from_port = 0
ingress_security_groups_to_port = 0
```
A minimal example of a `terraform_var_file` can be found at `src/terraform/conf/terraform.aws.demo.tfvars`.
Note: Any of the aforementioned default variables can be overridden in `terraform_var_file`
