# Prerequisites

## AWS Marketplace subscriptions

### [Zebrunner Selenium Grid Agent](https://aws.amazon.com/marketplace/pp/prodview-qykvcpnstrlzi?sr=0-2&ref_=beagle&applicationId=AWSMPContessa)
Linux based ECS optimized instance with embedded Zebrunner tuning for scalable and reliable browser images usage

### [Zebrunner Selenium Grid Agent - Windows](https://aws.amazon.com/marketplace/pp/prodview-wmwdyq54i36jy?sr=0-4&ref_=beagle&applicationId=AWSMPContessa)
Windows based ECS optimized instance with embedded Zebrunner tuning for scalable and reliable browser images usage

## AWS Security groups

Security groups contain only inbound rules. 

### [Agent security group](cli-input/security-groups/e3s-agent-sg.json)

### [Load balancer and e3s server security group](cli-input/security-groups/e3s-sg.json)

## [Optional] E3S user policies
 
### [Monitor policy](cli-input/security-groups/e3s-monitor-policy.json)
To view current state of e3s infrastructure

### [Manage policy](cli-input/security-groups/e3s-manage-policy.json).
To update desired capacity/terminate instances in autoscaling group etc. In addition to user should be attached Monitor policy.

### [Deploy policy](cli-input/security-groups/e3s-deploy-policy.json).
Policy for elb and cluster deploy/cleanup. In addition to user should be attached Monitor and Manage policies.
