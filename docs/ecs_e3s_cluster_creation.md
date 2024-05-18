# ECS E3S cluster creation

> Make sure to meet [prerequisites](prerequisites.md) before installation. 
> Replace all {Env}, {Account}, {Region}, {S3-bucket} vars in the next paragraph and corresponding json files

## Linux

1. Encode [user data](cli-input/cluster/e3s-linux-userdata.txt) to base64

2. Create launch template. In [file://e3s-linux-launch-template.json](cli-input/cluster/e3s-linux-launch-template.json) file should be additionally specified Zebrunner Selenium Grid Agent Ami Id, Key Name, e3s-sg id and encoded userdata from previouse step
* aws ec2 create-launch-template --launch-template-name e3s-{Env}-launch-template --cli-input-json [file://e3s-linux-launch-template.json](cli-input/cluster/e3s-linux-launch-template.json)
* aws ec2 describe-launch-template-versions --launch-template-name e3s-{Env}-launch-template

3. Create auto scaling group. Additionly in [file://e3s-asg.json](cli-input/cluster/e3s-asg.json) file should be specified Availability Zones, Subnets and compute optimized instance types (Recommended min instance type is c5a.2xlarge)

* aws autoscaling create-auto-scaling-group --auto-scaling-group-name e3s-{Env}-asg --cli-input-json [file://e3s-linux-asg.json](cli-input/cluster/e3s-linux-asg.json)
* aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names e3s-{Env}-asg

4. Create capacity provider. Insert arn of newly created autoscaling group into [file://e3s-linux--capacityprovider.json](cli-input/cluster/e3s-linux-capacityprovider.json) file.
* aws ecs create-capacity-provider --name e3s-{Env}-capacityprovider --cli-input-json [file://e3s-linux-capacityprovider.json](cli-input/cluster/e3s-linux-capacityprovider.json)
* aws ecs describe-capacity-providers --capacity-providers e3s-{Env}-capacityprovider

## Windows

1. Encode [user data](cli-input/cluster/e3s-windows-userdata.txt) to base64. Make sure that {VpcCidrBlock} is specified for -AwsvpcAdditionalLocalRoutes flag in windows userdata

2. Create launch template. In [file://e3s-windows-launch-template.json](cli-input/cluster/e3s-windows-launch-template.json) file should be additionally specified Zebrunner Selenium Grid Windows Agent Ami Id, Key Name, e3s-sg id and encoded userdata from previouse step

* aws ec2 create-launch-template --launch-template-name e3s-{Env}-win-launch-template --cli-input-json [file://e3s-windows-launch-template.json](cli-input/cluster/e3s-windows-launch-template.json)
* aws ec2 describe-launch-template-versions --launch-template-name e3s-{Env}-win-launch-template

3. Create auto scaling group. Additionly in [file://e3s-windows-asg.json](cli-input/cluster/e3s-windows-asg.json) file should be specified Availability Zones, Subnets and compute optimized instance types (Recommended min instance type is c5a.2xlarge)

* aws autoscaling create-auto-scaling-group --auto-scaling-group-name e3s-{Env}-win-asg --cli-input-json [file://e3s-windows-asg.json](cli-input/cluster/e3s-windows-asg.json)
* aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names e3s-{Env}-win-asg

4. Create capacity provider. Insert arn of newly created autoscaling group into [file://e3s-windows-capacityprovider.json](cli-input/cluster/e3s-windows-capacityprovider.json) file.
* aws ecs create-capacity-provider --name e3s-{Env}-win-capacityprovider --cli-input-json [file://e3s-windows-capacityprovider.json](cli-input/cluster/e3s-windows-capacityprovider.json)
* aws ecs describe-capacity-providers --capacity-providers e3s-{Env}-win-capacityprovider

## Cluster

1. Create cluster
* aws ecs create-cluster --cluster-name e3s-{Env} --capacity-providers e3s-{Env}-capacityprovider e3s-{Env}-win-capacityprovider --default-capacity-provider-strategy capacityProvider=e3s-{Env}-capacityprovider,weight=1
* aws ecs describe-clusters --clusters e3s-{Env} --include ATTACHMENTS

2. Disable scaling policy. Replace {Uuid} with actual policy value.
* aws autoscaling put-scaling-policy --auto-scaling-group-name e3s-{Env}-asg --policy-name ECSManagedAutoScalingPolicy-{Uuid} --policy-type TargetTrackingScaling --target-tracking-configuration "{ \"CustomizedMetricSpecification\": { \"MetricName\": \"CapacityProviderReservation\", \"Namespace\": \"AWS/ECS/ManagedScaling\", \"Dimensions\": [{ \"Name\": \"CapacityProviderName\", \"Value\": \"e3s-{Env}-capacityprovider\" }, { \"Name\": \"ClusterName\", \"Value\": \"e3s-{Env}\"}], \"Statistic\": \"Average\"}, \"TargetValue\": 100.0, \"DisableScaleIn\": false }" --no-enabled
* aws autoscaling put-scaling-policy --auto-scaling-group-name e3s-{Env}-win-asg --policy-name ECSManagedAutoScalingPolicy-{Uuid} --policy-type TargetTrackingScaling --target-tracking-configuration "{ \"CustomizedMetricSpecification\": { \"MetricName\": \"CapacityProviderReservation\", \"Namespace\": \"AWS/ECS/ManagedScaling\", \"Dimensions\": [{ \"Name\": \"CapacityProviderName\", \"Value\": \"e3s-{Env}-win-capacityprovider\" }, { \"Name\": \"ClusterName\", \"Value\": \"e3s-{Env}\"}], \"Statistic\": \"Average\"}, \"TargetValue\": 100.0, \"DisableScaleIn\": false }" --no-enabled

3. [Optional] Add crons for min/max capacity upgrade

* daily-mode, cron 0 6 * * 1-5
* * aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name e3s-{Env}-asg --scheduled-action-name daily-mode --recurrence "0 6 * * 1-5" --min-size 1 --max-size 30 --time-zone Etc/UTC
* * aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name e3s-{Env}-win-asg --scheduled-action-name daily-mode --recurrence "0 6 * * 1-5" --min-size 1 --max-size 30 --time-zone Etc/UTC

*  nightly-mode, cron, 0 18 * * *
* * aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name e3s-{Env}-asg --scheduled-action-name nightly-mode --recurrence "0 18 * * *" --min-size 0 --max-size 30 --time-zone Etc/UTC
* * aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name e3s-{Env}-win-asg --scheduled-action-name nightly-mode --recurrence "0 18 * * *" --min-size 0 --max-size 30 --time-zone Etc/UTC

## Load balancer

1. Create load balancer. In [file://e3s-load-balancer.json](cli-input/cluster/e3s-load-balancer.json) file should be specified subnets and e3s-sg id
    > Note: update ALB Scheme to `internal` inside [file://e3s-load-balancer.json](cli-input/cluster/e3s-load-balancer.json) to make environment publicly unavailable
* aws elbv2 create-load-balancer --name e3s-{Env}-alb --cli-input-json [file://e3s-load-balancer.json](cli-input/cluster/e3s-load-balancer.json)
* aws elbv2 describe-load-balancers --name e3s-{Env}-alb

2. Create target group. In [file://e3s-target-group.json](cli-input/cluster/e3s-target-group.json) file should be specified {VpcId}
* aws elbv2 create-target-group --name e3s-{Env}-tg --cli-input-json [file://e3s-target-group.json](cli-input/cluster/e3s-target-group.json)
* aws elbv2 describe-target-groups --names e3s-{Env}-tg

3. Increase deregistration_delay.timeout_seconds attribute value
* aws elbv2 modify-target-group-attributes --attributes Key=deregistration_delay.timeout_seconds,Value=660 --target-group-arn {e3s-tg-arn}
* aws elbv2 describe-target-group-attributes --target-group-arn {e3s-tg-arn}

4. Create listener. Update LoadBalancerArn and TargetGroupArn in [file://e3s-listener.json](cli-input/cluster/e3s-listener.json) file, specify certificate to use
* aws elbv2 create-listener --cli-input-json [file://e3s-listener.json](cli-input/cluster/e3s-listener.json)
* aws elbv2 describe-listeners --load-balancer-arn {e3s-alb-arn}

## Cleanup

1. Autoscaling
* aws autoscaling delete-auto-scaling-group --auto-scaling-group-name e3s-{Env}-asg
* aws autoscaling delete-auto-scaling-group --auto-scaling-group-name e3s-{Env}-win-asg

2. Launch templates
* aws ec2 delete-launch-template --launch-template-name e3s-{Env}-launch-template
* aws ec2 delete-launch-template --launch-template-name e3s-{Env}-win-launch-template

3. Cluster
* aws ecs delete-cluster --cluster e3s-{Env}

4. Capacity provider
* aws ecs delete-capacity-provider --capacity-provider e3s-{Env}-capacityprovider
* aws ecs delete-capacity-provider --capacity-provider e3s-{Env}-win-capacityprovider

4. Listener
* aws elbv2 describe-load-balancers --names e3s-{Env}-alb
* aws elbv2 describe-listeners --load-balancer-arn
* aws elbv2 delete-listener --listener-arn

5. Target group
* aws elbv2 describe-target-groups --names e3s-{Env}-tg
* aws elbv2 delete-target-group --target-group-arn

5. Load balancer
* aws elbv2 describe-load-balancers --names e3s-{Env}-alb
* aws elbv2 delete-load-balancer --load-balancer-arn
