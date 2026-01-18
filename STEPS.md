# Verification Steps (AWS CLI) – Bonus-A

## 1. Prove the EC2 instance is private (has no public IPv4 address)

```bash
aws ec2 describe-instances \
    --instance-ids i-0450a37e4126d42ac \
    --query 'Reservations[*].Instances[*].PublicIpAddress' \
    --output text
```

**Expected result**: Empty output (or `None`) confirms the instance has no public IP.

---

## 2. Prove VPC Endpoints exist for private AWS service access

```bash
aws ec2 describe-vpc-endpoints \
    --query 'VpcEndpoints[*].ServiceName' \
    --output table
```

**Recommended alternative** (more informative – shows endpoint ID + service):

```bash
aws ec2 describe-vpc-endpoints \
    --query 'VpcEndpoints[*].[VpcEndpointId, ServiceName, VpcId, State]' \
    --output table
```

---

## 3. Prove the instance is managed by AWS Systems Manager (SSM) Session Manager

List all SSM-managed instance IDs in the current region:

```bash
aws ssm describe-instance-information \
    --query 'InstanceInformationList[*].InstanceId' \
    --output text
```

**Region-specific version** (if instance is in eu-west-2):

```bash
aws ssm describe-instance-information \
    --region eu-west-2 \
    --query 'InstanceInformationList[*].InstanceId' \
    --output text
```

**Expected result**: The target instance ID `i-0450a37e4126d42ac` should appear in the list.

---

## 4. Start an SSM Session Manager session (proves no SSH / bastion required)

```bash
aws ssm start-session \
    --target i-0450a37e4126d42ac \
    --region eu-west-2
```

---

## 5. Prove the instance can access both Parameter Store and Secrets Manager (via VPC endpoints)

**Run these commands inside the SSM session** (after step 4):

```bash
# Retrieve RDS endpoint from Parameter Store
aws ssm get-parameter \
    --name /lab/db/endpoint \
    --query Parameter.Value \
    --output text

# Retrieve RDS credentials from Secrets Manager
aws secretsmanager get-secret-value \
    --secret-id lab/rds/mysql_v5 \
    --query SecretString \
    --output text
```

**Expected result**: Both commands return valid values without network errors.

## 6. Prove CloudWatch Logs delivery path is available (via VPC endpoint)

```bash
aws logs describe-log-streams \
    --log-group-name /aws/ec2/lab-1c-rds-app \
    --query 'logStreams[*].logStreamName' \
    --output text
```

**Expected result**: A list of log stream names or information about the log group, confirming access to CloudWatch Logs.

---

## Summary Checklist

| # | Verification Goal                          | Command Status | Expected Outcome                     |
|---|--------------------------------------------|----------------|--------------------------------------|
| 1 | Instance has no public IP                  | Required       | Empty / None                         |
| 2 | VPC Endpoints exist                        | Required       | List includes relevant services      |
| 3 | Instance is SSM-managed                    | Required       | Instance ID appears in output        |
| 4 | Session Manager connection works           | Required       | Successful interactive session       |
| 5 | Can read Parameter Store + Secrets Manager | Required       | Valid parameter/secret values return |
| 6 | CloudWatch Logs endpoint path is available | Recommended    | Log streams or group information     |

All commands assume correct AWS CLI configuration, appropriate IAM permissions, and (where specified) the correct region (`eu-west-2`). If any command fails, please verify region, permissions, and network connectivity via VPC endpoints.
