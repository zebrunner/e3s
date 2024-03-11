# Prerequisites

## AWS Marketplace subscriptions

### [Zebrunner Selenium Grid Agent](https://aws.amazon.com/marketplace/pp/prodview-qykvcpnstrlzi?sr=0-2&ref_=beagle&applicationId=AWSMPContessa)

Linux based ECS optimized instance with embedded Zebrunner tuning for scalable and reliable browser images usage

### [Zebrunner Selenium Grid Agent - Windows](https://aws.amazon.com/marketplace/pp/prodview-wmwdyq54i36jy?sr=0-4&ref_=beagle&applicationId=AWSMPContessa)

Windows based ECS optimized instance with embedded Zebrunner tuning for scalable and reliable browser images usage


## AWS Infrastructure

### AWS IAM Roles

1. Create e3s roles

* 

2. Create e3s agent role

* 

3. Create e3s task role

* 

### AWS Cluster

1. Create launch template

* aws ec2 create-launch-template --launch-template-name e3s-{Env}-launch-template --cli-input-json [file://e3s-launch-template.json](cli-input/e3s-launch-template.json)
* aws ec2 describe-launch-template-versions --launch-template-name e3s-{Env}-launch-template

2. Create auto scaling group

* aws autoscaling create-auto-scaling-group --auto-scaling-group-name e3s-{Env}-asg --cli-input-json [file://e3s-asg.json](cli-input/e3s-asg.json)
* aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names e3s-{Env}-asg

3. Create capacity provider
* aws ecs create-capacity-provider --name e3s-{Env}-capacityprovider --cli-input-json [file://e3s-capacityprovider.json](cli-input/e3s-capacityprovider.json)
* aws ecs describe-capacity-providers --capacity-providers e3s-{Env}-capacityprovider

4. Create cluster
* aws ecs create-cluster --cluster-name e3s-{Env} --capacity-providers e3s-{Env}-capacityprovider --default-capacity-provider-strategy capacityProvider=e3s-{Env}-capacityprovider,weight=1
* aws ecs describe-clusters --clusters e3s-{Env} --include ATTACHMENTS --region us-east-1

5. Disable scaling policy

* aws autoscaling put-scaling-policy --auto-scaling-group-name e3s-{Env}-asg --policy-name {ecs-policy-name} --policy-type TargetTrackingScaling --target-tracking-configuration "{ \"CustomizedMetricSpecification\": { \"MetricName\": \"CapacityProviderReservation\", \"Namespace\": \"AWS/ECS/ManagedScaling\", \"Dimensions\": [{ \"Name\": \"CapacityProviderName\", \"Value\": \"e3s-{Env}-capacityprovider\" }, { \"Name\": \"ClusterName\", \"Value\": \"e3s-{Env}\"}], \"Statistic\": \"Average\"}, \"TargetValue\": 100.0, \"DisableScaleIn\": false }" --no-enabled

6. [Optional] Add crons for min/max capacity upgrade

* daily-mode, cron 0 6 * * 1-5
* * aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name e3s-{Env}-asg --scheduled-action-name daily-mode --recurrence "0 6 * * 1-5" --min-size 1 --max-size 30 --time-zone Etc/UTC

*  nightly-mode, cron, 0 18 * * *
* * aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name e3s-{Env}-asg --scheduled-action-name nightly-mode --recurrence "0 18 * * *" --min-size 0 --max-size 30 --time-zone Etc/UTC


## E3S instance

### Hardware

* Network optimized instance m5n.large+
* Configured IMDSv2 (HttpPutResponseHopLimit=2)

### Software

* Installed Docker v19+
* Installed Docker compose plugin v2+
* [Optional] Installed jq and aws cli for ./scripts support

## Agent instance

### Hardware

* Compute optimized instance c5a.2xlarge +
* Configured IMDSv2 (HttpPutResponseHopLimit=1)