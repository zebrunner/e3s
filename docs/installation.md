# Installation

1. Create launch template

* aws ec2 create-launch-template --launch-template-name e3s-{env}-launch-template --cli-input-json [file://launch-template.json](installation/launch-template.json)
* aws ec2 describe-launch-template-versions --launch-template-name e3s-{env}-launch-template

2. Create auto scaling group

* aws autoscaling create-auto-scaling-group --auto-scaling-group-name e3s-{env}-asg --cli-input-json [file://asg.json](installation/asg.json)
* aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names e3s-{env}-asg

3. Create capacity provider
* aws ecs create-capacity-provider --name e3s-{env}-capacityprovider --cli-input-json [file://capacityprovider.json](installation/capacityprovider.json)
* aws ecs describe-capacity-providers --capacity-providers e3s-{env}-capacityprovider

4. Create cluster
* aws ecs create-cluster --cluster-name e3s-{env} --capacity-providers e3s-{env}-capacityprovider --default-capacity-provider-strategy capacityProvider=e3s-{env}-capacityprovider,weight=1
* aws ecs describe-clusters --clusters e3s-{env} --include ATTACHMENTS --region us-east-1

5. Disable scaling policy

* aws autoscaling put-scaling-policy --auto-scaling-group-name e3s-{env}-asg --policy-name {ecs-policy-name} --policy-type TargetTrackingScaling --target-tracking-configuration "{ \"CustomizedMetricSpecification\": { \"MetricName\": \"CapacityProviderReservation\", \"Namespace\": \"AWS/ECS/ManagedScaling\", \"Dimensions\": [{ \"Name\": \"CapacityProviderName\", \"Value\": \"e3s-{env}-capacityprovider\" }, { \"Name\": \"ClusterName\", \"Value\": \"e3s-{env}\"}], \"Statistic\": \"Average\"}, \"TargetValue\": 100.0, \"DisableScaleIn\": false }" --no-enabled
                                                                                    
6. [Optional] Add crons for min/max capacity upgrade

* daily-mode, cron 0 6 * * 1-5
* * aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name e3s-{env}-asg --scheduled-action-name daily-mode --recurrence "0 6 * * 1-5" --min-size 1 --max-size 30 --time-zone Etc/UTC

*  nightly-mode, cron, 0 18 * * *
* * aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name e3s-{env}-asg --scheduled-action-name nightly-mode --recurrence "0 18 * * *" --min-size 0 --max-size 30 --time-zone Etc/UTC
