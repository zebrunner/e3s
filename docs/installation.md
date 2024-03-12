# Prerequisites

## AWS Marketplace subscriptions

### [Zebrunner Selenium Grid Agent](https://aws.amazon.com/marketplace/pp/prodview-qykvcpnstrlzi?sr=0-2&ref_=beagle&applicationId=AWSMPContessa)

Linux based ECS optimized instance with embedded Zebrunner tuning for scalable and reliable browser images usage

### [Zebrunner Selenium Grid Agent - Windows](https://aws.amazon.com/marketplace/pp/prodview-wmwdyq54i36jy?sr=0-4&ref_=beagle&applicationId=AWSMPContessa)

Windows based ECS optimized instance with embedded Zebrunner tuning for scalable and reliable browser images usage


## AWS Infrastructure

> Replace all {Env}, {Account}, {Region} vars in the next paragraph and corresponding json files. 

### AWS IAM Roles

1. Create e3s role and policy

* aws iam create-role --role-name e3s-{Env}-role --assume-role-policy-document [file://e3s-ec2-assume-document.json](cli-input/roles/e3s-ec2-assume-document.json)
* aws iam create-policy --policy-name e3s-{Env}-policy --policy-document [file://e3s-policy.json](cli-input/roles/e3s-policy.json)
* aws iam attach-role-policy --role-name e3s-{Env}-role --policy-arn arn:aws:iam::{Account}:policy/e3s-{Env}-policy

2. Create e3s agent role and policy

* aws iam create-role --role-name e3s-{Env}-agent-role --assume-role-policy-document [file://e3s-ec2-assume-document.json](cli-input/roles/e3s-ec2-assume-document.json)
* aws iam create-policy --policy-name e3s-{Env}-agent-policy --policy-document [file://e3s-agent-policy.json](cli-input/roles/e3s-agent-policy.json)
* aws iam attach-role-policy --role-name e3s-{Env}-agent-role --policy-arn arn:aws:iam::{Account}:policy/e3s-{Env}-agent-policy

3. Create e3s task role and policy

* aws iam create-role --role-name e3s-{Env}-task-role --assume-role-policy-document [file://e3s-ecs-assume-document.json](cli-input/roles/e3s-ecs-assume-document.json)
* aws iam create-policy --policy-name e3s-{Env}-task-policy --policy-document [file://e3s-task-policy.json](cli-input/roles/e3s-task-policy.json)
* aws iam attach-role-policy --role-name e3s-{Env}-task-role --policy-arn arn:aws:iam::{Account}:policy/e3s-{Env}-task-policy 

### AWS Cluster

1. Encode user data ([linux](cli-input/cluster/e3s-linux-userdata.txt) or/and [windows](cli-input/cluster/e3s-windows-userdata.txt)) to base64. Make sure that {VpcCidrBlock} is specified for -AwsvpcAdditionalLocalRoutes flag in windows userdata.

2. Create launch template. In [file://e3s-launch-template.json](cli-input/cluster/e3s-launch-template.json) file should be additionally specified Zebrunner Selenium Grid Agent Ami Id, Key Name, Security Group Id and encoded userdata from previouse step.

* aws ec2 create-launch-template --launch-template-name e3s-{Env}-launch-template --cli-input-json [file://e3s-launch-template.json](cli-input/cluster/e3s-launch-template.json)
* aws ec2 describe-launch-template-versions --launch-template-name e3s-{Env}-launch-template

3. Create auto scaling group. Additionly in [file://e3s-asg.json](cli-input/cluster/e3s-asg.json) file should be specified Availability Zones, Subnets and compute optimized instance types (Recommended min instance type is c5a.2xlarge).

* aws autoscaling create-auto-scaling-group --auto-scaling-group-name e3s-{Env}-asg --cli-input-json [file://e3s-asg.json](cli-input/cluster/e3s-asg.json)
* aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names e3s-{Env}-asg

4. Create capacity provider. Insert arn of newly created autoscaling group into [file://e3s-capacityprovider.json](cli-input/cluster/e3s-capacityprovider.json) file.
* aws ecs create-capacity-provider --name e3s-{Env}-capacityprovider --cli-input-json [file://e3s-capacityprovider.json](cli-input/cluster/e3s-capacityprovider.json)
* aws ecs describe-capacity-providers --capacity-providers e3s-{Env}-capacityprovider

5. Create cluster
* aws ecs create-cluster --cluster-name e3s-{Env} --capacity-providers e3s-{Env}-capacityprovider --default-capacity-provider-strategy capacityProvider=e3s-{Env}-capacityprovider,weight=1
* aws ecs describe-clusters --clusters e3s-{Env} --include ATTACHMENTS

6. Disable scaling policy

* aws autoscaling put-scaling-policy --auto-scaling-group-name e3s-{Env}-asg --policy-name ECSManagedAutoScalingPolicy-{Uuid} --policy-type TargetTrackingScaling --target-tracking-configuration "{ \"CustomizedMetricSpecification\": { \"MetricName\": \"CapacityProviderReservation\", \"Namespace\": \"AWS/ECS/ManagedScaling\", \"Dimensions\": [{ \"Name\": \"CapacityProviderName\", \"Value\": \"e3s-{Env}-capacityprovider\" }, { \"Name\": \"ClusterName\", \"Value\": \"e3s-{Env}\"}], \"Statistic\": \"Average\"}, \"TargetValue\": 100.0, \"DisableScaleIn\": false }" --no-enabled

7. [Optional] Add crons for min/max capacity upgrade

* daily-mode, cron 0 6 * * 1-5
* * aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name e3s-{Env}-asg --scheduled-action-name daily-mode --recurrence "0 6 * * 1-5" --min-size 1 --max-size 30 --time-zone Etc/UTC

*  nightly-mode, cron, 0 18 * * *
* * aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name e3s-{Env}-asg --scheduled-action-name nightly-mode --recurrence "0 18 * * *" --min-size 0 --max-size 30 --time-zone Etc/UTC


# E3S configuration

## E3S server's instance requriements

### Hardware

* Network optimized instance m5n.large+
* Configured IMDSv2 (HttpPutResponseHopLimit=2)

### Software

* Installed Docker v19+
* Installed Docker compose plugin v2+
* [Optional] Installed jq and aws cli for ./scripts support

## Env files

> Supported env vars are differ from version to version for scaler and router images.

### Scaler.env

#### Required variables

* AWS_REGION={Region}
* AWS_CLUSTER=e3s-{Env}
* AWS_TASK_ROLE=e3s-{Env}-task-role
* ZEBRUNNER_ENV={Env}

#### Optional variables

* RESERVE_INSTANCES_PERCENT - Additional weight capacity reservation percent. Default value = 0.25.
* RESERVE_MAX_CAPACITY - Max number of additional weight capacity reservation. Default value = 5.
* INSTANCE_COOLDOWN_TIMEOUT - Time after instance start when shutdown is prohibited on scale down in time.Duration format. Default value = 4 min.
* EXCLUDE_BROWSERS - Excludes selected browser images from registering them as a task definition. Default value = empty.
* LOG_LEVEL - Desired log level. Valid levels: `panic`, `fatal`, `error`, `warning`, `info`, `debug`, `trace`. Default value = debug.
* MAX_MEMORY - Max amount of memory for a single task. Must not be higher then the smallest instance type memory value from all autoscaling groups. Default value = 28675
* MAX_CPU - Max amount of cpu for a single task. Must not be higher then the smallest instance type cpu value from all autoscaling groups. Default value = 16384
* IDLE_TIMEOUT - Session idle timeout in time.Duration format. Default value = 1 min
* MAX_TIMEOUT - Maximum valid task/session timeout in time.Duration format. Default value = 24 hours

### Router.env

#### Required variables

* AWS_REGION={Region}
* AWS_CLUSTER=e3s-{Env}
* USE_PUBLIC_IP=true/false. Default value = false
* AWS_TASK_ROLE=e3s-{Env}-task-role
* ZEBRUNNER_ENV={Env}
* AWS_LINUX_CAPACITY_PROVIDER=e3s-{Env}-capacityprovider - should be specified at least on of linux or windows values.
* AWS_WIN_CAPACITY_PROVIDER=e3s-{Env}-win-capacityprovider - should be specified at least on of linux or windows values.
* AWS_TARGET_GROUP=e3s-{Env}-tg - Target group name 
* S3_BUCKET=zebrunner.{Env}-engine
* S3_REGION={Region}


#### Optional variables

* EXCLUDE_BROWSERS - Excludes selected browser images from registering them as a task definition. Default value = empty.
* LOG_LEVEL - Desired log level. Valid levels: `panic`, `fatal`, `error`, `warning`, `info`, `debug`, `trace`. Default value = debug.
* MAX_MEMORY - Max amount of memory for a single task. Must not be higher then the smallest instance type memory value from all autoscaling groups. Default value = 28675
* MAX_CPU - Max amount of cpu for a single task. Must not be higher then the smallest instance type cpu value from all autoscaling groups. Default value = 16384
* IDLE_TIMEOUT - Session idle timeout in time.Duration format. Default value = 1 min
* MAX_TIMEOUT - Maximum valid task/session timeout in time.Duration format. Default value = 24 hours
* SERVICE_STARTUP_TIMEOUT - Task and session startup timeout in time.Duration format. Default value = 10 min
* SESSION_DELETE_TIMEOUT - Session delete timeout in time.Duration format. Default value = 30 sec

## E3S server process management

Recomended to use preinstalled ./zebrunner.sh script:

```
Usage: ./zebrunner.sh [option]
      Flags:
          --help | -h                       Print help
      Arguments:
      	  start     [data|service] <name>         Start containers for selected layers
      	  stop      [data|service] <name>         Stop containers for selected layers
      	  down      [data|service] <name>         Stop and remove containers for selected layers
      	  shutdown  [data|service] <name>         Stop, remove containers, clear volumes for selected layers
      	  restart   [data|service] <name>         Down and start containers for selected layers
      	  status                                  Show all containers statuses
          tasks     [list|stop]                   List all tasks or stop them
      	  describe  [cluster|instance|task]       Describe selected items
          instances [list]                        All cluster's container-instances list
```

### Examples
* Start e3s server: *./zebrunner.sh start*
* Restart only service layer:  *./zebrunner.sh restart service*
* Stop redis service: *./zebrunner.sh stop data redis*
