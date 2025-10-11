# ESG awsvpc migration guide

### Attach temporary policy to node-role
1. Navigate to AIM service, select node-role
2. Attach inline-policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:PutAccountSetting",
        "ecs:PutAccountSettingDefault"
      ],
      "Resource": "*"
    }
  ]
}
```

>Note: this policy is temporary and can be deleted after all steps completed.

### Enable awsvpc trunking for node-role
1. Create a EC2 instance with aws-cli and node-role attached
2. Run command provided below, replace <region> with your cluster region 

```sh
aws ecs put-account-setting \
  --name awsvpcTrunking \
  --value enabled \
  --region <region>
```

### Adjust Auto scaling group
1. Navigate to EC2 service, auto scaling groups, select your esg auto scaling group
2. Navigate to Network, change amount of subnets to 1.

> Important: Choose a subnet that’s big enough for all your ECS tasks and future growth.
Because each task needs its own IP address, smaller subnets (like /24) often run out of space quickly.
Use /23 or larger for stable production use. (Usable IPs ~507+)

### Adjust configuration files
1. SSH to your esg-server EC2 instance
2. Nagivate to e3s/properties/
3. Add to router.env - new awsvpc settings

```
# AWSVPC settings
# SUBNETS AND SECURITY_GROUPS formating example: SECURITY_GROUPS=sg-1;sg-2 and SUBNETS=subnet-1;subnet-2;subnet-3
SECURITY_GROUPS=sg-1;sg-1
SUBNETS=subnet-1
```

Fill "SECURITY_GROUPS" with security groups that you use in Auto scaling group launch template.
Fill "SUBNETS" with that one subnet from step "Adjust Auto scaling group"

4. Navigate to previous folder (e3s, cd ..)
5. Adjust docker-compose.yaml file, change every image version to 3.1.5-awsvpc

### Restart ESG services
1. Run command: "docker compose pull && ./zebrunner.sh restart"
2. Wait around 10 minutes for new awsvpc tasks-definitions to be created
    You can monitor status by running: "docker logs -f task-definitions"
3. After that you can use new ESG version      

