# Prerequisites

## AWS Marketplace subscriptions

### [Zebrunner Selenium Grid Agent](https://aws.amazon.com/marketplace/pp/prodview-qykvcpnstrlzi?sr=0-2&ref_=beagle&applicationId=AWSMPContessa)
Linux based ECS optimized instance with embedded Zebrunner tuning for scalable and reliable browser images usage

### [Zebrunner Selenium Grid Agent - Windows](https://aws.amazon.com/marketplace/pp/prodview-wmwdyq54i36jy?sr=0-4&ref_=beagle&applicationId=AWSMPContessa)
Windows based ECS optimized instance with embedded Zebrunner tuning for scalable and reliable browser images usage

## AWS Security groups

Security groups contain only inbound rules

### E3S server Load Balancer security group
Access to server and ssh connections

> [file://e3s-sg.json](cli-input/security-groups/e3s-sg.json)

```
aws ec2 create-security-group --group-name e3s-{Env}-sg --description "e3s {Env} sg"
```

```
aws ec2 authorize-security-group-ingress --group-name  e3s-{Env}-sg --cli-input-json file://e3s-sg.json
```

### Agent security group
Access to allocate tasks across the full range of Docker ports on agent instances.

> [file://e3s-agent-sg.json](cli-input/security-groups/e3s-agent-sg.json)

```
aws ec2 create-security-group --group-name e3s-{Env}-agent-sg --description "e3s {Env} agent sg"
```

```
aws ec2 authorize-security-group-ingress --group-name  e3s-{Env}-agent-sg --cli-input-json file://e3s-agent-sg.json
```

## Artifacts storage

### [S3 bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html)
Every video, session log, video log etc is stored in particular s3 bucket

```
aws s3 create-bucket --bucket {S3-bucket}
```

## E3S roles

> Replace all {Env}, {Account}, {Region}, {S3-bucket} vars in the next paragraph and corresponding json files

### e3s-{Env} role, policy and instance-profile 

> [file://e3s-ec2-assume-document.json](cli-input/roles/e3s-ec2-assume-document.json)

> [file://e3s-policy.json](cli-input/roles/e3s-policy.json)

```
aws iam create-role --role-name e3s-{Env}-role --assume-role-policy-document file://e3s-ec2-assume-document.json
```

```
aws iam create-policy --policy-name e3s-{Env}-policy --policy-document file://e3s-policy.json
```

```
aws iam attach-role-policy --role-name e3s-{Env}-role --policy-arn arn:aws:iam::{Account}:policy/e3s-{Env}-policy
```

```
aws iam create-instance-profile --instance-profile-name e3s-{Env}-role
```

```
aws iam add-role-to-instance-profile --instance-profile-name e3s-{Env}-role --role-name e3s-{Env}-role
```

### e3s-{Env}-agent role, policy and instance-profile 

> [file://e3s-ec2-assume-document.json](cli-input/roles/e3s-ec2-assume-document.json)

> [file://e3s-agent-policy.json](cli-input/roles/e3s-agent-policy.json)

```
aws iam create-role --role-name e3s-{Env}-agent-role --assume-role-policy-document file://e3s-ec2-assume-document.json
```

```
aws iam create-policy --policy-name e3s-{Env}-agent-policy --policy-document file://e3s-agent-policy.json
```

```
aws iam attach-role-policy --role-name e3s-{Env}-agent-role --policy-arn arn:aws:iam::{Account}:policy/e3s-{Env}-agent-policy
```

```
aws iam create-instance-profile --instance-profile-name e3s-{Env}-agent-role
```

```
aws iam add-role-to-instance-profile --instance-profile-name e3s-{Env}-agent-role --role-name e3s-{Env}-agent-role
```

### e3s-{Env}-task role and policy

> [file://e3s-ecs-assume-document.json](cli-input/roles/e3s-ecs-assume-document.json)

> [file://e3s-task-policy.json](cli-input/roles/e3s-task-policy.json)

```
aws iam create-role --role-name e3s-{Env}-task-role --assume-role-policy-document file://e3s-ecs-assume-document.json
```

```
aws iam create-policy --policy-name e3s-{Env}-task-policy --policy-document file://e3s-task-policy.json
```

```
aws iam attach-role-policy --role-name e3s-{Env}-task-role --policy-arn arn:aws:iam::{Account}:policy/e3s-{Env}-task-policy
```

## [Optional] E3S user policies

> Replace all {Account}, {Region} vars in the next paragraph and corresponding json files
 
### Monitor policy
To view current state of e3s infrastructure

> [file://e3s-monitor-policy.json](cli-input/roles/e3s-monitor-policy.json)

```
aws iam create-policy --policy-name e3s-monitor-policy --policy-document file://e3s-monitor-policy.json
```

### Manage policy
To update desired capacity/terminate instances in autoscaling group etc. The user should also have attached Monitor policy

>  [file://e3s-manage-policy.json](cli-input/roles/e3s-manage-policy.json)

```
aws iam create-policy --policy-name e3s-manage-policy --policy-document file://e3s-manage-policy.json
```

### Deploy policy
Policy for elb and cluster deploy/cleanup. The user should also have attached Monitor and Manage policies

> [file://e3s-deploy-policy.json](cli-input/roles/e3s-deploy-policy.json)

```
aws iam create-policy --policy-name e3s-deploy-policy --policy-document file://e3s-deploy-policy.json
```

## E3S server instance

### Hardware

* Network optimized instance m5n.large+
* Configured IMDSv2 (HttpPutResponseHopLimit=2). Replace {e3s-server-instance-id} with actual instance-id

    ```
    aws ec2 modify-instance-metadata-options --instance-id {e3s-server-instance-id} --http-tokens required --http-put-response-hop-limit 2 --http-endpoint enabled
    ```

* Attached [e3s-{Env}-role](cli-input/roles/e3s-policy.json) instance-role. Replace {e3s-server-instance-id} with actual instance-id

    ```
    aws ec2 associate-iam-instance-profile --iam-instance-profile Name=e3s-{Env}-role --instance-id {e3s-server-instance-id}
    ```

* Attached [e3s-{Env}-sg](cli-input/security-groups/e3s-sg.json) security group

### Software

* Installed Docker v19+
* Installed Docker compose plugin v2.20.3+
* [Optional] Installed jq and aws cli for ./scripts support
