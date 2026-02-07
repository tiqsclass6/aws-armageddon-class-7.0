# 🛡️ Lab 1C – Bonus B (Public ALB + Private EC2 + TLS + WAF + Monitoring)

[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![MySQL](https://img.shields.io/badge/mysql-4479A1.svg?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](https://www.python.org/)
[![Flask](https://img.shields.io/badge/flask-%23000.svg?style=for-the-badge&logo=flask&logoColor=white)](https://flask.palletsprojects.com/)
[![Secrets Manager](https://img.shields.io/badge/Secrets_Manager-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/secrets-manager/)

---

## 📌 Task Overview

This lab implements a **foundational AWS two-tier application architecture**: an Amazon EC2 compute layer securely integrated with an Amazon RDS MySQL database.  
The solution emphasizes **network isolation**, **least-privilege security**, and **secure credential management** using AWS Secrets Manager.

An enhanced Flask-based **“Passport Bro Notes”** application runs on EC2 and provides:

- Read-only database access
- Dynamic UI rendering
- Dark / Light mode toggle
- Embedded background music playback

This mirrors a real-world cloud pattern used for internal tools, dashboards, and lightweight service frontends.

**Reference:**  
📄 <https://github.com/BalericaAI/armageddon/blob/main/SEIR_Foundations/LAB1/1a_laba.md?plain=1>

---

## 🏗️ Network Architecture

The deployment uses a **custom VPC** with segmented networking for security and scalability:

### Networking

- **Public Subnets**
  - Host the EC2 application server
  - Assigned a public IP for HTTP access
- **Private Subnets**
  - Host the RDS MySQL instance
  - No direct internet exposure

### Connectivity & Access

- **Internet Gateway**
  - Enables inbound/outbound internet traffic for public subnets
- **Security Groups**
  - **EC2 SG**
    - Inbound: HTTP (80), SSH (22)
    - Outbound: unrestricted
  - **RDS SG**
    - Inbound: MySQL (3306) **only from EC2 SG**
- **Secrets Management**
  - EC2 IAM role retrieves DB credentials from AWS Secrets Manager
  - No credentials stored in plaintext or source code

This architecture follows AWS Well-Architected Framework best practices for **security**, **operational excellence**, and **cost awareness**.

---

## 🧰 Resources Needed to Build

- AWS account with access to:
  - EC2
  - RDS
  - VPC
  - IAM
  - Secrets Manager
- Terraform **≥ 1.0**
  - AWS Provider **v6.27.0**
- AWS CLI configured locally (optional, for validation)
- `user_data.sh` present in project root

---

## 📂 Project Structure

```plaintext
lab-1/
├── Screenshots/             # Verification screenshots
│   ├── bonus-b-pt1.jpg
│   ├── bonus-b-pt2.jpg
|   ├── bonus-b-pt3.jpg
│   ├── bonus-b-pt4.jpg
│   ├── terraform-apply.jpg
│   ├── terraform-destroy.jpg
|   ├── terraform-init-fmt-validate.jpg
│   └── terraform-plan.jpg
|
├── scripts/                 # Additional scripts (if needed)
│   └── user_data.sh         # EC2 bootstrap script with enhanced Flask app
|
├── .gitignore               # Git ignore file
├── 1-versions.tf            # Terraform provider and version constraints
├── 2-providers.tf           # AWS provider configuration
├── 3-locals.tf              # Local variables for resource naming
├── 4-main.tf                # Main Terraform configuration for VPC, EC2, RDS, etc.
├── 5-variables.tf           # Input variables for configuration parameters
├── 6-outputs.tf             # Output values for resource information
└── README.md                # Project documentation
````

---

## 🚀 Deployment Steps

1. Clone the repository and navigate to the project directory
2. Initialize Terraform:

   ```bash
   terraform init
   terraform fmt
   terraform validate
   ```

   ![terraform-init-fmt-validate.jpg](Screenshots/terraform-init-fmt-validate.jpg)

3. Review the execution plan:

   ```bash
   terraform plan
   ```

   ![terraform-plan.jpg](Screenshots/terraform-plan.jpg)

4. Deploy infrastructure:

   ```bash
   terraform apply
   ```

   ![terraform-apply.jpg](Screenshots/terraform-apply.jpg)
   Type `yes` when prompted

5. Wait for provisioning to complete
   *(RDS may take 10–15 minutes)*

6. Capture Terraform outputs:

   - EC2 public IP
   - Application URL

7. Open the application `(Route53 DNS)` in a web browser:

   ```plaintext
   https://theinternationalquietstorm.com/init
   https://theinternationalquietstorm.com/list
   ```

   ![route53-init.jpg](Screenshots/route53-init.jpg)
   ![route53-list.jpg](Screenshots/route53-list.jpg)

8. Open the application `(SSM Session Manager)` in a web browser:

   ```plaintext
   https://localhost/init
   https://localhost/list
   ```

   ![ssm-init.jpg](Screenshots/ssm-init.jpg)
   ![ssm-list.jpg](Screenshots/ssm-list.jpg)

---

## 📸 Screenshots

| Deliverable       | Description                                                    | Screenshot                                      |
| ----------------- | -------------------------------------------------------------- | ----------------------------------------------- |
| `bonus-b-pt1.jpg` | EC2 instance with IAM role attached for Secrets Manager access | ![bonus-b-pt1.jpg](Screenshots/bonus-b-pt1.jpg) |
| `bonus-b-pt2.jpg` | EC2 security group inbound rule allowing MySQL connections     | ![bonus-b-pt2.jpg](Screenshots/bonus-b-pt2.jpg) |
| `bonus-b-pt3.jpg` | CloudWatch Logs showing application logs from EC2              | ![bonus-b-pt3.jpg](Screenshots/bonus-b-pt3.jpg) |
| `bonus-b-pt4.jpg` | CloudWatch Dashboard list                                      | ![bonus-b-pt4.jpg](Screenshots/bonus-b-pt4.jpg) |

---

## 🧹 Teardown Steps

To prevent ongoing AWS charges, destroy all resources:

1. Save and delete all the logs in the S3 bucket created for CloudWatch Logs (if applicable)
2. Run the following command in the project directory:

    ```bash
    terraform destroy
    ```

    ![terraform-destroy.jpg](Screenshots/terraform-destroy.jpg)

---

## 🛠️ Troubleshooting Steps

- **500 Internal Server Error**
  - Run: `journalctl -u rdsapp`

- **Secrets Retrieval Failure**
  - Validate IAM role permissions and secret ARN

---

## 📚 References

- AWS RDS Security Best Practices
  [https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.Security.html](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.Security.html)
- RDS Security Groups
  [https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.RDSSecurityGroups.html](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.RDSSecurityGroups.html)
- MySQL Default Port
  [https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ConnectToInstance.html](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ConnectToInstance.html)
- AWS Secrets Manager
  [https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)
- Terraform AWS Provider
  [https://registry.terraform.io/providers/hashicorp/aws/latest/docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## ✍️ Author

- **Author:** T.I.Q.S.
- **Group Leader:** John Sweeney
