# ESG Deploy step by step guide.

**Precondition: Prepare a VPC and an EC2 instance.**
**Recommended to use suggested names for infrastructure elements.**
___
### List of required infrastructure elements and suggested names

1. **ECS cluster** (esg-qa-newest-cluster)
2. **Security group** *for worker node* (esg-qa-newest-node-sg)
3. **IAM role** *for worker node* (esg-qa-newest-node-role)
4. **Launch template** (esg-qa-newest-lt)
5. **Auto Scaling group** (esg-qa-newest-asg)
6. **Capacity provider** (esg-qa-newest-capacity-provider)
7. **s3 bucket** (esg-qa-newest-bucket)
8. **Security group** *for main esg vm* (esg-qa-newest-main-sg)
9. **Target group** (esg-qa-newest-tg)
10. **Load balancer** (esg-qa-newest-lb)
11. **IAM role** *for worker ECS task*  (esg-qa-newest-task-role)
12. **IAM role** *for main EC2 vm* (esg-qa-newest-main-role)

ZEBRUNNER_ENV = esg-qa-newest

### infrastructure elements creation and configuration

##### 1. Create a ECS cluster

The only way to create a working cluster - using AWS CLI tool.
Use command to create a cluster, replace `<region>` with your region.

```
aws ecs create-cluster \
  --cluster-name esg-qa-newest-cluster \
  --region <region>
```

##### 2. Create/check a security group for worker node
Note before you begin:
*In case of you already have security group, ensure that it contains rules provided below* 

Recommended:
1. Navigate to EC2 service. Go to Security Groups. 
   Create security group (name: ==esg-qa-newest-node-sg==).
2. While creating security group, select your VPC and add required rules provided below:

Required **Inbound** rules:

| Name | Security group rule ID | IP version | Type       | Protocol | Port range    | Source      | Description                                 |
| ---- | ---------------------- | ---------- | ---------- | -------- | ------------- | ----------- | ------------------------------------------- |
| esg  | -                      | IPv4       | Custom TCP | TCP      | 32768 - 64536 | 10.0.0.5/32 | docker port range to access from esg server |

> **Important note**: Source is your main, esg - EC2 virtual machine ip address (ip/32).

**Outbound** rules: default, allow all traffic. 

**P.S.** This rules are required to allow our main, esg - EC2 virtual machine to communicate with worker nodes.

##### 3. Create worker node IAM role.
1. Navigate to IAM service.
2. Create a new role (name: ==esg-qa-newest-node-role==)
3. Attach policy from template provided in file: ==`esg-node-role-policy.json`==.
   Replace `<REGION_>` with your region and `<ACCOUNT_ID>` with account id.

**P.S.**  This *Role/Policy* is required for worker node. It gives basic access needed to run ECS tasks.
**P.S.S.**  Template file already contains preconfigured cluster name, if you used not suggested cluster name, you should change ==esg-qa-newest-cluster== in template to your cluster name. 

##### 4. Create/modify launch template
1. Navigate to EC2 service, launch templates.
2. Create new launch template (name: ==esg-qa-newest-lt==).
   * Use AMI: ==Zebrunner-ESG-Agent-v2.8.0== (browse for it)
   * Instance type: Dont include in launch template.
   * Key pair: Add yours if u want ssh access to worker nodes.
   * Subnet and Availability Zone: Dont include in launch template.
   * Security groups: ==esg-qa-newest-node-sg==
   * Advanced details - IAM instance profile: ==esg-qa-newest-node-role==
   * Advanced details - User Data: copy from file ==`node-launch-template-user-data.bash`==.

##### 5. Create Auto Scaling group
1. Navigate to EC2 service, Auto Scaling groups.
2. Create new Auto Scaling group (name: ==esg-qa-newest-asg==)
   * Launch template: esg-qa-newest-node-lt
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

##### 6. Create Capacity provider
1. Navigate to ECS service, ==esg-qa-newest-cluster== Cluster, Infrastructure.
2. Create new Capacity Provider (name: ==esg-qa-newest-capacity-provider==):
   * Auto Scaling group: ==esg-qa-newest-asg==
   * Other options leave default.

##### 7. Modify Auto Scaling group
1. Navigate to EC2 service, Auto Scaling groups.
2. Open auto scaling group (name: ==esg-qa-newest-asg==)
3. Navigate to Automatic scaling
4. Change Dynamic scaling policies
   Change field ***Instances need**** with value - 10 seconds to warm up before including in metric.
5. Create Predictive scaling policies:
   Turn on scaling - on.
   Metrics and target utilization - cpu 100%.
   Other options leave default.

##### 8. Create s3 bucket
1. Navigate to s3 service, create s3 bucket (name: ==esg-qa-newest-bucket==)

##### 9. Create/check a security group for worker node
Note before you begin:
*In case of you already have security group, ensure that it contains rules provided below* 

Recommended:
1. Navigate to EC2 service. Go to Security Groups. 
   Create security group (name: ==esg-qa-newest-main-sg==).
2. While creating security group, select your VPC and add required rules provided below:

Required **Inbound** rules:

| Name | Security group rule ID | IP version | Type       | Protocol | Port range  | Source    | Description  |
| ---- | ---------------------- | ---------- | ---------- | -------- | ----------- | --------- | ------------ |
| e3s  | -                      | IPv4       | SSH        | TCP      | 22          | 0.0.0.0/0 | ssh          |
| e3s  | -                      | IPv4       | Custom TCP | TCP      | 4444 - 4445 | 0.0.0.0/0 | router_ports |
| e3s  | -                      | IPv6       | SSH        | TCP      | 22          | ::/0      | ssh          |
| e3s  | -                      | IPv4       | HTTPS      | TCP      | 443         | 0.0.0.0/0 | –            |
>You can use different source for shh.

**Outbound** rules: default, allow all traffic. 

##### 10. Attach security group
1. Navigate to EC2 service, find your main instance.
2. Attach security group (name: ==esg-qa-newest-main-sg==) to your main vm.

##### 11. Create target group
1. Navigate to EC2 service, target groups.
2. Create target group (name: ==esg-qa-newest-tg==):
   * Target type - Instances
   * Protocol - HTTP, Port 4444
   * Ip adress iPv4
   * VPC - your VPC
   * Protocol version - HTTP1
   * Health-check - default
   * Target - select your main ec2 vm.

##### 12. Create Load Balancer
1. Navigate to EC2 service, Load balancers.
2. Create new Load balancer (name: ==esg-qa-newest-lb==):
   * Type: application.
   * Scheme: Internet Facing 
   * Network: select your VPC and subnet where main ec2 vm located, and minimum one additional subnet.
   * Security group ==esg-qa-newest-main-sg==
   * Listeners and routing: protocol HTTPS, port 443, Default action - select ==esg-qa-newest-tg==
   * Certificate source from ACM, select *.zebrunner...
   * Other options left default

##### 13. Create ECS task IAM role.
1. Navigate to IAM service.
2. Create a new role (name: ==esg-qa-newest-task-role==)
3. Attach policy from template provided in file: ==`esg-task-role-policy.json`==.
   Bucket name is already specified, if you followed instruction.

**P.S.**  This *Role/Policy* is required for ECS tasks. It gives basic access needed to send artifacts to s3 bucket. 
**P.S.S.**  Template file already contains preconfigured bucket name, if you used not suggested bucket name, you should change ==esg-qa-newest-bucket== in template to your bucket name. 

##### 14. Create main IAM role.
1. Navigate to IAM service.
2. Create a new role (name: ==esg-qa-newest-main-role==)
3. Attach policy from template provided in file: ==`esg-main-role-policy.json`==.
   Replace `<REGION_>` with your region and `<ACCOUNT_ID>` with account id.

**P.S.**  This *Role/Policy* is required for ECS tasks. It gives basic access needed to send artifacts to s3 bucket. 
**P.S.S.**  Template file already contains preconfigured infrastructure elements names, if you used not suggested names for infrastructure elements, you should change their names in template to your names. 

##### 15. Attach main IAM role.
1. Navigate to EC2 service, find your main instance.
2. Attach IAM (name: ==esg-qa-newest-main-role==) to your main vm.

### How to fill config (.env) files on main EC2 machine

##### 1. Config.env

Example how ==config.env== will look, if you used suggested infrastructure elements names

```env
IDLE_TIMEOUT=
MAX_TIMEOUT=
RECORDING_SHUTDOWN_GRACE_PERIOD=0s

# AWS settings
AWS_REGION=<YOUR_REGION>
AWS_RETRY=10
AWS_CLUSTER=esg-qa-newest-cluster
AWS_ACESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_TASK_ROLE=esg-qa-newest-task-role

# S3 settings
S3_BUCKET=esg-qa-newest-bucket
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

ZEBRUNNER_ENV=esg-qa-newest
```

You just need to replace <YOUR_REGION> and <YOUR_REGION_BUCKET_REGION> placeholders with your AWS region, for example: AWS_REGION=us-east-1 and 
S3_REGION=us-east-1.

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
AWS_LINUX_CAPACITY_PROVIDER=esg-qa-newest-capacity-provider
#AWS_WIN_CAPACITY_PROVIDER=
AWS_TARGET_GROUP=esg-qa-newest-tg

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