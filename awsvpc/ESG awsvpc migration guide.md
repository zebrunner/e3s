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

## Adjust Security group
1. Navigate to security group that you use for worker-node
2. Adjust the security group to include the following inbound rules, which are required to enable communication with all containers:

| Name    | Security group rule ID | IP version | Type    | Protocol | Port range | Source             | Description |
| ------- | ---------------------- | ---------- | ------- | -------- | ---------- | ------------------ | ----------- |
| rule-1  | sgr-xxxxxx2            | IPv4       | All TCP | TCP      | 4444       | <ESG_SERVER_IP/32> |             |
| rule-2  | sgr-xxxxxx3            | IPv4       | All TCP | TCP      | 4723       | <ESG_SERVER_IP/32> |             |
| rule-3  | sgr-xxxxxx4            | IPv4       | All TCP | TCP      | 5900       | <ESG_SERVER_IP/32> |             |
| rule-4  | sgr-xxxxxx5            | IPv4       | All TCP | TCP      | 7070       | <ESG_SERVER_IP/32> |             |
| rule-5  | sgr-xxxxxx6            | IPv4       | All TCP | TCP      | 8060       | <ESG_SERVER_IP/32> |             |
| rule-6  | sgr-xxxxxx7            | IPv4       | All TCP | TCP      | 8080       | <ESG_SERVER_IP/32> |             |
| rule-7  | sgr-xxxxxx8            | IPv4       | All TCP | TCP      | 8081       | <ESG_SERVER_IP/32> |             |
| rule-8  | sgr-xxxxxx9            | IPv4       | All TCP | TCP      | 8082       | <ESG_SERVER_IP/32> |             |
| rule-9  | sgr-xxxxxx10           | IPv4       | All TCP | TCP      | 9080       | <ESG_SERVER_IP/32> |             |
| rule-10 | sgr-xxxxxx11           | IPv4       | All TCP | TCP      | 9090       | <ESG_SERVER_IP/32> |             |

>Important:
Replace <ESG_SERVER_IP/32> with your actual ESG server instance IP (e.g., 10.0.0.5/32), a whole subnet CIDR (e.g., 10.0.0.0/16), or another security group — depending on your preferred configuration and network design.
The essential requirement is that your ESG server instance (or its network range) must be able to reach these ports.

### Adjust configuration files
1. SSH to your esg-server EC2 instance
2. Nagivate to e3s/properties/
3. Add to router.env - new awsvpc settings

```
# AWSVPC settings
# SUBNET AND SECURITY_GROUPS formating example: SECURITY_GROUPS=sg-1,sg-2 and SUBNET=subnet-1
SECURITY_GROUPS=sg-1,sg-2
SUBNET=subnet-1
```

Fill "SECURITY_GROUPS" with security groups that you use in Auto scaling group launch template.
Fill "SUBNET" with that one subnet from step "Adjust Auto scaling group"

4. Navigate to previous folder (e3s, cd ..)
5. Adjust docker-compose.yaml file, change every image version to 3.1.5-awsvpc

### Restart ESG services
1. Run command: "docker compose pull && ./zebrunner.sh restart"
2. Wait around 10 minutes for new awsvpc tasks-definitions to be created
    You can monitor status by running: "docker logs -f task-definitions"
3. After that you can use new ESG version      

