# Cleanup

> Replace {Env} var in the next paragraph.

1. Autoscaling
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name e3s-{Env}-asg
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name e3s-{Env}-win-asg

2. Launch templates
aws ec2 delete-launch-template --launch-template-name e3s-{Env}-launch-template
aws ec2 describe-launch-templates --launch-template-names e3s-{Env}-launch-template

aws ec2 delete-launch-template --launch-template-name e3s-{Env}-win-launch-template
aws ec2 describe-launch-templates --launch-template-names e3s-{Env}-win-launch-template

3. Cluster
aws ecs delete-cluster --cluster e3s-{Env}
aws ecs describe-clusters --clusters e3s-{Env} --include ATTACHMENTS

4. Capacity provider
aws ecs delete-capacity-provider --capacity-provider e3s-{Env}-capacityprovider
aws ecs describe-capacity-providers --capacity-providers e3s-{Env}-capacityprovider

aws ecs delete-capacity-provider --capacity-provider e3s-{Env}-win-capacityprovider
aws ecs describe-capacity-providers --capacity-providers e3s-{Env}-win-capacityprovider

4. Listener
aws elbv2 describe-load-balancers --names e3s-{Env}-alb
aws elbv2 describe-listeners --load-balancer-arn
aws elbv2 delete-listener --listener-arn

5. Target group
aws elbv2 describe-target-groups --names e3s-{Env}-tg
aws elbv2 delete-target-group --target-group-arn

5. Load balancer
aws elbv2 describe-load-balancers --names e3s-{Env}-alb
aws elbv2 delete-load-balancer --load-balancer-arn
