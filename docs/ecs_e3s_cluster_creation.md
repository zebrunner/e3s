# ECS E3S cluster creation

> Make sure to meet [prerequisites](prerequisites.md) before installation. 
> Replace all {Env}, {Account}, {Region}, {S3-bucket} vars in the next paragraph and corresponding json files

## Linux

### Encode user data

[Used data](cli-input/cluster/e3s-linux-userdata.txt) should be encoded to base64

### Create launch template

In [file://e3s-linux-launch-template.json](cli-input/cluster/e3s-linux-launch-template.json) file should be additionally specified Zebrunner Selenium Grid Agent Ami Id, Key Name, e3s-sg id and encoded userdata from previouse step

```
 aws ec2 create-launch-template --launch-template-name e3s-{Env}-launch-template --cli-input-json [file://e3s-linux-launch-template.json](cli-input/cluster/e3s-linux-launch-template.json)
```

```
aws ec2 describe-launch-template-versions --launch-template-name e3s-{Env}-launch-template
```

### Create auto scaling group

Additionly in [file://e3s-asg.json](cli-input/cluster/e3s-linux-asg.json) file should be specified Availability Zones, Subnets and compute optimized instance types (Recommended instance type is c5a.4xlarge)

```
aws autoscaling create-auto-scaling-group --auto-scaling-group-name e3s-{Env}-asg --cli-input-json [file://e3s-linux-asg.json](cli-input/cluster/e3s-linux-asg.json)
```

```
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names e3s-{Env}-asg
```

### Create capacity provider

Insert arn of newly created autoscaling group into [file://e3s-linux--capacityprovider.json](cli-input/cluster/e3s-linux-capacityprovider.json) file.

```
aws ecs create-capacity-provider --name e3s-{Env}-capacityprovider --cli-input-json [file://e3s-linux-capacityprovider.json](cli-input/cluster/e3s-linux-capacityprovider.json)
```

```
aws ecs describe-capacity-providers --capacity-providers e3s-{Env}-capacityprovider
```

## Windows

### Encode user data

[Used data](cli-input/cluster/e3s-windows-userdata.txt) should be encoded to base64. Make sure that {VpcCidrBlock} is specified for -AwsvpcAdditionalLocalRoutes flag in windows userdata

### Create launch template

 In [file://e3s-windows-launch-template.json](cli-input/cluster/e3s-windows-launch-template.json) file should be additionally specified Zebrunner Selenium Grid Windows Agent Ami Id, Key Name, e3s-sg id and encoded userdata from previouse step

 ```
aws ec2 create-launch-template --launch-template-name e3s-{Env}-win-launch-template --cli-input-json [file://e3s-windows-launch-template.json](cli-input/cluster/e3s-windows-launch-template.json)
```

```
aws ec2 describe-launch-template-versions --launch-template-name e3s-{Env}-win-launch-template
```

### Create auto scaling group

Additionly in [file://e3s-windows-asg.json](cli-input/cluster/e3s-windows-asg.json) file should be specified Availability Zones, Subnets and compute optimized instance types (Recommended min instance type is c5a.4xlarge)

```
aws autoscaling create-auto-scaling-group --auto-scaling-group-name e3s-{Env}-win-asg --cli-input-json [file://e3s-windows-asg.json](cli-input/cluster/e3s-windows-asg.json)
```

```
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names e3s-{Env}-win-asg
```

### Create capacity provider

Insert arn of newly created autoscaling group into [file://e3s-windows-capacityprovider.json](cli-input/cluster/e3s-windows-capacityprovider.json) file.

```
aws ecs create-capacity-provider --name e3s-{Env}-win-capacityprovider --cli-input-json [file://e3s-windows-capacityprovider.json](cli-input/cluster/e3s-windows-capacityprovider.json)
```

```
aws ecs describe-capacity-providers --capacity-providers e3s-{Env}-win-capacityprovider
```

## Cluster

### Create cluster

```
aws ecs create-cluster --cluster-name e3s-{Env} --capacity-providers e3s-{Env}-capacityprovider e3s-{Env}-win-capacityprovider --default-capacity-provider-strategy capacityProvider=e3s-{Env}-capacityprovider,weight=1
```

```
aws ecs describe-clusters --clusters e3s-{Env} --include ATTACHMENTS
```

### Disable scaling policy. Replace {Uuid} with actual policy value.

```
aws autoscaling put-scaling-policy --auto-scaling-group-name e3s-{Env}-asg --policy-name ECSManagedAutoScalingPolicy-{Uuid} --policy-type TargetTrackingScaling --target-tracking-configuration "{ \"CustomizedMetricSpecification\": { \"MetricName\": \"CapacityProviderReservation\", \"Namespace\": \"AWS/ECS/ManagedScaling\", \"Dimensions\": [{ \"Name\": \"CapacityProviderName\", \"Value\": \"e3s-{Env}-capacityprovider\" }, { \"Name\": \"ClusterName\", \"Value\": \"e3s-{Env}\"}], \"Statistic\": \"Average\"}, \"TargetValue\": 100.0, \"DisableScaleIn\": false }" --no-enabled
```

```
aws autoscaling put-scaling-policy --auto-scaling-group-name e3s-{Env}-win-asg --policy-name ECSManagedAutoScalingPolicy-{Uuid} --policy-type TargetTrackingScaling --target-tracking-configuration "{ \"CustomizedMetricSpecification\": { \"MetricName\": \"CapacityProviderReservation\", \"Namespace\": \"AWS/ECS/ManagedScaling\", \"Dimensions\": [{ \"Name\": \"CapacityProviderName\", \"Value\": \"e3s-{Env}-win-capacityprovider\" }, { \"Name\": \"ClusterName\", \"Value\": \"e3s-{Env}\"}], \"Statistic\": \"Average\"}, \"TargetValue\": 100.0, \"DisableScaleIn\": false }" --no-enabled
```

### [Optional] Enabling forecasts for autoscaling

#### Add scaling policy that creates forecasts but doesn't scale 

> [e3s-forecasts-configuration.json](cli-input/cluster/e3s-forecasts-configuration.json) - contains a complete policy configuration that uses CPU utilization metrics for predictive scaling with a target utilization of 40.

```
aws autoscaling put-scaling-policy --policy-name {prefix}-predictive-scaling-policy \
  --auto-scaling-group-name e3s-{Env}-asg --policy-type PredictiveScaling \
  --predictive-scaling-configuration file://e3s-forecasts-configuration.json
```

#### Add scaling policy that forecasts and scales

> [e3s-forecasts-scales-configuration.json](cli-input/cluster/e3s-forecasts-scales-configuration.json) - contains a policy configuration that uses Application Load Balancer request count metrics. The target utilization is 1000, and predictive scaling is set to ForecastAndScale mode. Should be added `ResourceLabel`.

```
aws autoscaling put-scaling-policy --policy-name {prefix}-predictive-scaling-policy \
  --auto-scaling-group-name e3s-{Env}-asg --policy-type PredictiveScaling \
  --predictive-scaling-configuration file://e3s-forecasts-scales-configuration.json
```

## Load balancer

### Create load balancer

In [file://e3s-load-balancer.json](cli-input/cluster/e3s-load-balancer.json) file should be specified subnets and e3s-sg id
    > Note: update ALB Scheme to `internal` inside [file://e3s-load-balancer.json](cli-input/cluster/e3s-load-balancer.json) to make environment publicly unavailable

```
aws elbv2 create-load-balancer --name e3s-{Env}-alb --cli-input-json [file://e3s-load-balancer.json](cli-input/cluster/e3s-load-balancer.json)
```

```
aws elbv2 describe-load-balancers --name e3s-{Env}-alb
```

### Increase deregistration_delay.timeout_seconds attribute value for load balancer

```
aws elbv2 modify-load-balancer-attributes --attributes Key=idle_timeout.timeout_seconds,Value=660 --load-balancer-arn {e3s-alb-arn}
```

```
aws elbv2 describe-load-balancer-attributes --load-balancer-arn {e3s-alb-arn}
```

### Create target group

In [file://e3s-target-group.json](cli-input/cluster/e3s-target-group.json) file should be specified {VpcId}

```
aws elbv2 create-target-group --name e3s-{Env}-tg --cli-input-json [file://e3s-target-group.json](cli-input/cluster/e3s-target-group.json)
```

```
aws elbv2 describe-target-groups --names e3s-{Env}-tg
```

### Increase deregistration_delay.timeout_seconds attribute value for target group

```
aws elbv2 modify-target-group-attributes --attributes Key=deregistration_delay.timeout_seconds,Value=660 --target-group-arn {e3s-tg-arn}
```

```
aws elbv2 describe-target-group-attributes --target-group-arn {e3s-tg-arn}
```

### Create listener

Update LoadBalancerArn and TargetGroupArn in [file://e3s-listener.json](cli-input/cluster/e3s-listener.json) file, specify certificate to use

```
aws elbv2 create-listener --cli-input-json [file://e3s-listener.json](cli-input/cluster/e3s-listener.json)
```

```
aws elbv2 describe-listeners --load-balancer-arn {e3s-alb-arn}
```

## Cleanup

### Autoscaling

```
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name e3s-{Env}-asg
```

```
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name e3s-{Env}-win-asg
```

### Launch templates

```
aws ec2 delete-launch-template --launch-template-name e3s-{Env}-launch-template
```

```
aws ec2 delete-launch-template --launch-template-name e3s-{Env}-win-launch-template
```

### Cluster

```
aws ecs delete-cluster --cluster e3s-{Env}
```

### Capacity provider

```
aws ecs delete-capacity-provider --capacity-provider e3s-{Env}-capacityprovider
```

```
aws ecs delete-capacity-provider --capacity-provider e3s-{Env}-win-capacityprovider
```

### Listener

```
aws elbv2 describe-load-balancers --names e3s-{Env}-alb
```

```
aws elbv2 describe-listeners --load-balancer-arn
```

```
aws elbv2 delete-listener --listener-arn
```

### Target group

```
aws elbv2 describe-target-groups --names e3s-{Env}-tg
```

```
aws elbv2 delete-target-group --target-group-arn
```

### Load balancer

```
aws elbv2 describe-load-balancers --names e3s-{Env}-alb
```

```
aws elbv2 delete-load-balancer --load-balancer-arn
```
