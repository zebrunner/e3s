# ESG AWSVPC Migration Guide

### 1. Attach a Temporary Policy to the Node Role

> **Your Node role:** ``

1.  Open the **IAM** service in the AWS Management Console.
2.  Locate and select your node role.
3.  Attach the following **inline policy**:

``` json
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

> **Note:** This policy is **temporary** and can be safely removed after
> completing all migration steps.

------------------------------------------------------------------------

### 2. Enable AWSVPC Trunking for the Node Role

> **Your Node role:** ``

1.  Launch an **EC2 instance** with the AWS CLI installed and attach the
    node role to it.
2.  Run the following command, replacing `<region>` with your cluster's
    AWS region:

```sh
aws ecs put-account-setting \
  --name awsvpcTrunking \
  --value enabled \
  --region <region>
```

------------------------------------------------------------------------

### 3. Adjust the Auto Scaling Group

> **Your Auto Scaling group:** ``

1.  Open the **EC2** service in the AWS Management Console.
2.  Go to **Auto Scaling Groups**, and select your ESG auto scaling
    group.
3.  Navigate to the **Network** section and reduce the number of subnets
    to **1**.

> **Important:**\
> Choose a subnet large enough to support all ECS tasks and anticipated
> growth.
> Each task requires its own IP address, so smaller subnets (e.g.,
> `/24`) may run out of IPs quickly.
> A `/23` or larger subnet (≈ 507+ usable IPs) is recommended for stable
> production environments.

------------------------------------------------------------------------

### 4. Adjust the Security Group

> **Your Security group:** ``

1.  Open the **Security Groups** section in the EC2 console.
2.  Select the security group used for your worker nodes.
3.  Add the following **inbound rules** to enable container
    communication:

  -----------------------------------------------------------------------------------------
  Name      Rule ID        IP Version Type     Protocol   Port Range Source
  --------- -------------- ---------- -------- ---------- ---------- ----------------------
  rule-1    sgr-xxxxxx2    IPv4       All TCP  TCP        4444       `<ESG_SERVER_IP/32>`

  rule-2    sgr-xxxxxx3    IPv4       All TCP  TCP        4723       `<ESG_SERVER_IP/32>`

  rule-3    sgr-xxxxxx4    IPv4       All TCP  TCP        5900       `<ESG_SERVER_IP/32>`

  rule-4    sgr-xxxxxx5    IPv4       All TCP  TCP        7070       `<ESG_SERVER_IP/32>`

  rule-5    sgr-xxxxxx6    IPv4       All TCP  TCP        8060       `<ESG_SERVER_IP/32>`

  rule-6    sgr-xxxxxx7    IPv4       All TCP  TCP        8080       `<ESG_SERVER_IP/32>`

  rule-7    sgr-xxxxxx8    IPv4       All TCP  TCP        8081       `<ESG_SERVER_IP/32>`

  rule-8    sgr-xxxxxx9    IPv4       All TCP  TCP        8082       `<ESG_SERVER_IP/32>`

  rule-9    sgr-xxxxxx10   IPv4       All TCP  TCP        9080       `<ESG_SERVER_IP/32>`

  rule-10   sgr-xxxxxx11   IPv4       All TCP  TCP        9090       `<ESG_SERVER_IP/32>`

  -----------------------------------------------------------------------------------------

> **Important:**\
> Replace `<ESG_SERVER_IP/32>` with your actual ESG server IP address
> (e.g., `10.0.0.5/32`), an appropriate subnet CIDR (e.g.,
> `10.0.0.0/16`), or a reference to another security group --- depending
> on your network configuration.\
> The key requirement is that your ESG server (or its network range)
> must be able to reach these ports.

------------------------------------------------------------------------

### 5. Update Configuration Files

1.  SSH into your **ESG server EC2 instance**.

2.  Navigate to the following directory:

    ``` bash
    cd e3s/properties/
    ```

3.  Open the **router.env** file and add the following AWSVPC settings:

    ```bash
    # AWSVPC settings
    # SUBNET AND SECURITY_GROUPS formating example: SECURITY_GROUPS=sg-1,sg-2 and SUBNET=subnet-1
    SECURITY_GROUPS=sg-1,sg-2
    SUBNET=subnet-1
    ```

    -   Set `SECURITY_GROUPS` to the security group IDs used in your
        Auto Scaling Group's launch template.
    -   Set `SUBNET` to the subnet you selected in the **Adjust Auto
        Scaling Group** step.

4.  Return to the parent directory:

    ``` bash
    cd ..
    ```

5.  Open the **docker-compose.yaml** file and update all image versions
    to `3.1.5-awsvpc`.

------------------------------------------------------------------------

### 6. Restart ESG Services

1.  Run the following commands:

    ``` bash
    docker compose pull && ./zebrunner.sh restart
    ```

2.  Wait approximately **10 minutes** for the new AWSVPC task
    definitions to be created.\
    You can monitor progress with:

    ``` bash
    docker logs -f task-definitions
    ```

3.  Once the process completes, your ESG environment will be running the
    new AWSVPC-enabled version.
