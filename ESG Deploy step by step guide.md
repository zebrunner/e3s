# ESG Deploy step by step guide

The purpose of this guide is to show how to create an AWS infrastructure for ESG. 
The guide lists the necessary infrastructure elements and describes the processes for creating and configuring them, where required.

**Attachments to the guide**: IAM policy templates, user data for EC2 launch template.

*The guide only covers the creation of basic AWS infrastructure; it does not cover the complete configuration of ESG.*
___
### Necessary precondition 

This guide assumes that you already have an AWS VPC set up that meets your organization's requirements and will be used for ESG.
### List of required infrastructure elements and suggested names

For AWS ESG infrastructure, it is recommended to follow a consistent naming convention. 
Use the same prefix for all infrastructure element names, and apply a descriptive suffix at the end (for example: **esg-qa**-<u>cluster</u>). This practice helps maintain a clean and organized environment, making it clear which elements belong to ESG. In addition, this allows you to create IAM rules that grant access only to specified resources.

The guide uses the prefix ==esg-qa==, which is applied to the name of each infrastructure element created, as well as to IAM roles. You may change the prefix to any preferred value. Later, you will need to set the prefix value in ESG config.

>If you use a different naming pattern, update the IAM roles accordingly to handle these changes.

List of infrastructure elements and their suggested names:
1. **ECS cluster** (esg-qa-cluster)
2. **EC2 instance** *for ESG* (esg-qa-server)
3. **Security group** *for worker nodes* (esg-qa-node-sg)
4. **IAM role** *for worker nodes* (esg-qa-node-role)
5. **Launch template** (esg-qa-lt)
6. **Auto Scaling group** (esg-qa-asg)
7. **Capacity provider** (esg-qa-capacity-provider)
8. **s3 bucket** (esg-qa-bucket)
9. **Security group** *for ESG server instance* (esg-qa-server-sg)
10. **Target group** (esg-qa-tg)
11. **Load balancer** (esg-qa-lb)
12. **IAM role** *for ECS tasks*  (esg-qa-task-role)
13. **IAM role** *for ESG server instance* (esg-qa-server-role)
---
### Infrastructure elements creation and configuration

#### 1. Create an ECS cluster
In AWS Elastic Container Service, when creating a cluster via the GUI interface, unnecessary "FARGATE" capacity providers are being created. Therefore, to create a working cluster, we will use the **AWS CLI**. Below you can find the command to create a cluster.

Use this command to create a cluster, but replace `<region>` with your region.

```
aws ecs create-cluster \
  --cluster-name esg-qa-cluster \
  --region <region>
```

#### 2. Create EC2 instance for ESG server
This step is about creating an EC2 instance for the ESG server. You can skip this step if you've already set up an instance as described here. 

EC2 instance creation:
1. Navigate to EC2 service. Launch new EC2 instance (Suggested name: ==esg-qa-server==)
2. Use AMI ubuntu 22.04 LTS or AMI required by your organization.
3. For storage is recommended to have 100GB.
4. The remaining settings can be filled in at your preference.
5. Configure instance, install AWS CLI and Docker.
    
Configuration snippet for ubuntu:
   
```
#!/bin/bash
user="ubuntu"

sudo apt-get update && sudo apt-get upgrade

# install jq
sudo apt-get -y install jq unzip

# insall aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Add Docker's official GPG key:
sudo apt-get -y install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker "$user"
# Grant admin rights
sudo usermod -aG sudo "$user"
```

#### 3. Create/check a security group for worker node
This step is about creating a security group for the worker node. You can skip this step if you already have a security group as described here.

>This security group contains the rules necessary to enable communication between the ESG server instance and the worker nodes.

Security group creation:
1. Navigate to EC2 service. Go to Security Groups. 
   Create security group (Suggested name: ==esg-qa-node-sg==).
2. While creating security group, select your VPC and add required rules provided below:

Required **Inbound** rule:

| Name | Security group rule ID | IP version | Type       | Protocol | Port range    | Source      | Description                                 |
| ---- | ---------------------- | ---------- | ---------- | -------- | ------------- | ----------- | ------------------------------------------- |
| esg  | -                      | IPv4       | Custom TCP | TCP      | 32768 - 64536 | 10.0.0.5/32 | docker port range to access from esg server |

> **Important note**: Source is your ESG server instance ip address (ip/32).
> Instead of *10.0.0.5/32* use your ESG server instance ip.

**Outbound** rules: default, allow all traffic. 

#### 4. Create worker node IAM role.
This *Role/Policy* is required for worker nodes. It gives basic access needed to run ECS tasks.

>The template policy file `esg-node-role-policy.json` defines the cluster name with a `<ZEBRUNNER_ENV>` prefix placeholder and a predefined suffix. Update the prefix while keeping the suffix unchanged, or replace the entire cluster name with your own custom name.

Role creation:
1. Navigate to IAM service.
2. Create a new role (Suggested name: ==esg-qa-node-role==)
3. Attach policy from template provided in file: ==`esg-node-role-policy.json`==.
   Replace `<REGION>` with your region and `<ACCOUNT_ID>` with account id.
   Replace `<ZEBRUNNER_ENV>` with the prefix you choose to use or replace the entire cluster name with your own custom name.
4. Check/modify trust relations to be as provided bellow:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```   
#### 5. Create/modify launch template
This step is about creating a launch template for your worker nodes. The `user data` used in the launch template connects the created worker nodes to the cluster and provides the basic configuration.

>The user data file `node-launch-template-user-data.bash` defines the cluster name with a `<ZEBRUNNER_ENV>` prefix placeholder and a predefined suffix. Update the prefix while keeping the suffix unchanged, or replace the entire cluster name with your own custom name.

Launch template creation:
1. Navigate to EC2 service, launch templates.
2. Create new launch template (Suggested name: ==esg-qa-lt==).
   * Use AMI: ==Zebrunner-ESG-Agent-v2.8.0== (browse for it)
   * Instance type: Don't include in launch template.
   * Key pair: Add yours if you want ssh access to worker nodes.
   * Subnet and Availability Zone: Don't include in launch template.
   * Security groups: ==esg-qa-node-sg== (or your security group from Step 3)
   * Advanced details - IAM instance profile: ==esg-qa-node-role== (or your role from Step 4)
   * Advanced details - User Data: copy from file ==`node-launch-template-user-data.bash`==.
    Replace `<ZEBRUNNER_ENV>` with the prefix you choose to use or replace the entire cluster  name with your own custom name.

#### 6. Create Auto Scaling group
This step is about creating an auto-scaling group to manage your worker nodes and use it in the ECS capacity provider.

Auto Scaling group creation:
1. Navigate to EC2 service, Auto Scaling groups.
2. Create new Auto Scaling group (Suggested name: ==esg-qa-asg==)
   * Launch template: ==esg-qa-lt== (or your launch template from Step 5)
   * Instance type requirements -> Manually add instance types:
     c5a.2xlarge - weight: 1
     c5a.4xlarge  - weight: 2
   * Instance purchase options: 100% On-Demand.
   * Network: your VPC and private subnets.
   * Health check grace period - 10 sec.
   * Scaling, Max desired capacity - 30 (adjust if you need)
   * Other settings leave default.
3. Go to created Auto Scaling group, advanced configurations and set:
   * Enable scale-in protection
   * Termination policies - Allocation Strategy
   * Default cooldown - 10 sec

#### 7. Create Capacity provider
Capacity provider creation:
1. Navigate to ECS service, ==esg-qa-cluster== cluster (or your cluster from Step 1), Infrastructure.
2. Create new Capacity Provider (Suggested name: ==esg-qa-capacity-provider==):
   * Auto Scaling group: ==esg-qa-asg== (or your auto scaling group form Step 6)
   * Other options leave default.

>After creating the Capacity provider, you need to go back and configure your Auto Scaling group that you created earlier.
##### 7.1 Modify Auto Scaling group
Auto Scaling group configuration:
1. Navigate to EC2 service, Auto Scaling groups.
2. Open auto scaling group ==esg-qa-asg== (or your auto scaling group form Step 6)
3. Navigate to Automatic scaling
4.1. Change Dynamic scaling policies (optional, if you want additional EC2 instances control from AWS side)
   Change field ***Instances need*** with value - 10 seconds to warm up before including in metric.
4.2. Change Dynamic scaling policies -> Select -> Actions -> Disable (**recommended**, only ESG control EC2 instances)
5. Create Predictive scaling policies (optional): 
   Turn on scaling - on.
   Metrics and target utilization - cpu 100%.
   Other options leave default.

#### 8. Create s3 bucket
S3 bucket creation:
1. Navigate to s3 service, create s3 bucket (Suggested name: ==esg-qa-bucket==)
2. Use default settings (block all public access).

#### 9. Create/check a security group for ESG server instance
This step is about creating a security group for the ESG server instance. You can skip this step if you already have a security group as described here.

>This security group contains the rules necessary to ensure communication between the outside world and the ESG server.
>
  ==Important note:== the `Source` may be different depending on your VPC configuration and your organization's security requirements/configuration.

Security group creation:
1. Navigate to EC2 service. Go to Security Groups. 
   Create security group (Suggested name: ==esg-qa-server-sg==).
2. While creating security group, select your VPC and add required rules provided below:

Required **Inbound** rules:

| Name | Security group rule ID | IP version | Type       | Protocol | Port range  | Source    | Description  |
| ---- | ---------------------- | ---------- | ---------- | -------- | ----------- | --------- | ------------ |
| e3s  | -                      | IPv4       | SSH        | TCP      | 22          | 0.0.0.0/0 | ssh          |
| e3s  | -                      | IPv4       | Custom TCP | TCP      | 4444 - 4445 | 0.0.0.0/0 | router_ports |
| e3s  | -                      | IPv6       | SSH        | TCP      | 22          | ::/0      | ssh          |
| e3s  | -                      | IPv4       | HTTPS      | TCP      | 443         | 0.0.0.0/0 | –            |

>The SSH access rules should be configured in accordance with your company's requirements.

**Outbound** rules: default, allow all traffic. 
##### 9.1 Attach security group to ESG server instance
1. Navigate to EC2 service, find your ESG server instance.
2. Attach security group ==esg-qa-server-sg== (or your security group form Step 9) to your ESG server instance (instance from Step 2).

#### 10. Create target group
Target group creation:
1. Navigate to EC2 service, target groups.
2. Create target group (Suggested name: ==esg-qa-tg==):
   * Target type - Instances
   * Protocol - HTTP, Port 4444
   * Ip adress iPv4
   * VPC - your VPC
   * Protocol version - HTTP1
   * Health-check - default
   * Target - select your ESG server instance.

#### 11. Create Load Balancer
Load Balancer creation:
1. Navigate to EC2 service, Load balancers.
2. Create new Load balancer (Suggested name: ==esg-qa-lb==):
   * Type: application.
   * Scheme: Select according to your organization's security requirements/configuration. (default: internet facing)
   * Network: select your VPC and subnet where your ESG server instance located, and minimum one additional subnet.
   * Security group ==esg-qa-server-sg== (or your security group from Step 9)
   * Listeners and routing: protocol HTTPS, port 443, Default action - select ==esg-qa-tg== (or your target group form step 10).
   * Select the certificate source from ACM, if applicable.
   * Other options left default.
3. Select recently created load balancer, navigate to Attributes panel, set Connection idle timeout = 630 seconds.  

#### 12. Create ECS task IAM role.
This *Role/Policy* is required for ECS tasks. It gives basic access needed to send artifacts to s3 bucket. 

>The template file `esg-task-role-policy.json` defines the bucket name with a `<ZEBRUNNER_ENV>` prefix placeholder and a predefined suffix. Update the prefix while keeping the suffix unchanged, or replace the entire bucket name with your own custom name.

ECS task IAM role creation:
1. Navigate to IAM service.
2. Create a new role (Suggested name: ==esg-qa-task-role==)
3. Attach policy from template provided in file: ==`esg-task-role-policy.json`==.
   Replace `<ZEBRUNNER_ENV>` with the prefix you choose to use or replace the entire bucket name with your own custom name.
4. Check/modify trust relations to be as provided bellow:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```
#### 13. Create ESG server instance IAM role.
This *role/policy* is required for the ESG server. It provides the ESG server with access to manage the necessary resources to run and monitor QA automated tests.

>The template file `esg-server-role-policy.json` defines the names of infrastructure elements with a `<ZEBRUNNER_ENV>`prefix placeholder and predefined suffixes. Update the prefix while keeping the suffixes unchanged, or replace the entire names with your own custom names.

ESG server instance IAM role creation:
1. Navigate to IAM service.
2. Create a new role (Suggested name: ==esg-qa-server-role==)
3. Attach policy from template provided in file: ==`esg-server-role-policy.json`==.
   Replace `<REGION>` with your region and `<ACCOUNT_ID>` with account id.
   Replace `<ZEBRUNNER_ENV>` with the prefix you choose to use or replace the entire names with your own custom names.
4. Check/modify trust relations to be as provided bellow:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```   
##### 13.1. Attach server IAM role.
1. Navigate to EC2 service, find your server instance.
2. Attach IAM ==esg-qa-server-role== (or your IAM from step 13) to your ESG server instance (instance from Step 2).
---
### (Optional) How to fill config (.env) files on ESG server instance

##### 1. Config.env

Example how ==config.env== will look, if you used suggested infrastructure elements names

```env
IDLE_TIMEOUT=
MAX_TIMEOUT=
RECORDING_SHUTDOWN_GRACE_PERIOD=0s

# AWS settings
AWS_REGION=<YOUR_REGION>
AWS_RETRY=10
AWS_CLUSTER=esg-qa-cluster
AWS_ACESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_TASK_ROLE=esg-qa-task-role

# S3 settings
S3_BUCKET=esg-qa-bucket
S3_REGION=<YOUR_REGION_BUCKET_REGION>
S3_AWS_ACESS_KEY_ID=
S3_AWS_SECRET_ACCESS_KEY=

# Log level: trace, debug, info, error etc
LOG_LEVEL=info
AWS_LOGS_GROUP=

# Zebrunner Testing Platform integration
ZEBRUNNER_HOST=
ZEBRUNNER_INTEGRATION_USER=
ZEBRUNNER_INTEGRATION_PASSWORD=

ZEBRUNNER_ENV=esg-qa
```

You need to replace <YOUR_REGION> and <YOUR_REGION_BUCKET_REGION> placeholders with your AWS region. 
For example: AWS_REGION=us-east-1 and S3_REGION=us-east-1.

##### 2. Router.env

Example how ==router.env== will look, if you used suggested infrastructure elements names

```env
# Router settings
API_ACCESS_KEY=
USE_PUBLIC_IP=false

# Timeoouts limitations in time.Duration format, for example: 1m0s
SESSION_DELETE_TIMEOUT=
SERVICE_STARTUP_TIMEOUT=

# AWS settings
AWS_LINUX_CAPACITY_PROVIDER=esg-qa-capacity-provider
#AWS_WIN_CAPACITY_PROVIDER=
AWS_TARGET_GROUP=esg-qa-tg

# Should be Specified only if AWS_TARGET_GROUP is empty
E3S_URL=
```

> NOTE: AS you not using windows images, it CAPACITY_PROVIDER is commented and not used.

##### 3. Scaler.env

Example how ==scaler.env== will look, if you used suggested infrastructure elements names

```env
# Scaler settings
RESERVE_INSTANCES_PERCENT=
RESERVE_MAX_CAPACITY=

# Timeoouts limitations in time.Duration format, for example: 1m0s
INSTANCE_COOLDOWN_TIMEOUT=
LOST_TASK_COOLDOWN_TIMEOUT=24h
```

You just need to specify LOST_TASK_COOLDOWN_TIMEOUT, recommended value is 24h. 

##### 4. Task-definitions.env

Example of ==task-definitions.env==.

```
IMAGE_REPOSITORIES=Zebrunner:chrome,firefox,edge,redroid,windows-chrome,windows-edge,cypress-chrome,cypress-chromium,cypress-edge,cypress-firefox
EXCLUDE_BROWSERS=
```

You need to specify by your self what images you needed for your tasks (copy from previous machine).
___
### (Optional) Database migration

In old machine run command to save users data.

```
docker exec -i postgres \
  pg_dump -U postgres -d postgres -a -t public.users > users_data.sql
```

On new machine after successful docker containers start run command to set users data.

```
docker exec -i postgres \
  psql -U postgres -d postgres < users_data.sql
```