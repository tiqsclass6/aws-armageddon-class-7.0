# 🛡️ **AWS Lab 1A EC2 → RDS Integration Lab**

[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![AWS Certified](https://img.shields.io/badge/AWS%20Certified-Solutions%20Architect%20-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/certification/certified-solutions-architect-associate/)
[![Secrets Manager](https://img.shields.io/badge/Secrets_Manager-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/secrets-manager/)
[![VPC](https://img.shields.io/badge/VPC-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/vpc/)
[![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)](https://flask.palletsprojects.com/)
[![GitHub Repo](https://img.shields.io/badge/GitHub-Repo-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/yourusername/aws-armageddon-class-7.0)

---

## **Task Overview**

This laboratory exercise establishes a foundational AWS cloud application pattern by deploying an **Amazon EC2 instance** as the compute layer and an **Amazon RDS MySQL instance** as the managed database layer, connected securely within a custom VPC. The implementation emphasizes network isolation through security groups, dynamic credential retrieval using **AWS Secrets Manager**, and a minimal **Python Flask application** for persistent note storage and retrieval.

Detailed explanations of the architectural principles and design decisions are provided in the companion documentation at [`1a_explanation.md`](https://github.com/BalericaAI/armageddon/blob/main/SEIR_Foundations/LAB1/1a_explanation.md). A step-by-step walkthrough for provisioning the resources, configuring security, and testing the application is available at [`1a_lab_a_walkthru.md`](https://github.com/BalericaAI/armageddon/blob/main/SEIR_Foundations/LAB1/1a_lab_a_walkthru.md).

---

## **Planning Documentation**

```plaintext
Region:                        sa-east-1 (São Paulo)
VPC Name:                      lab-1a-vpc
VPC CIDR:                      10.240.0.0/16

Public Subnets:
  - sa-east-1a:                10.240.1.0/24
  - sa-east-1b:                10.240.2.0/24
  - sa-east-1c:                10.240.3.0/24

Private Subnets:
  - sa-east-1a:                10.240.11.0/24
  - sa-east-1b:                10.240.12.0/24
  - sa-east-1c:                10.240.13.0/24

RDS Instance Identifier:       lab-mysql
DB Username:                   admin
DB Password:                   <PASSWORD_HERE>

Secrets Manager Secret Name:   lab1a-rds-mysql
Secret ID for Application:     lab1a-rds-mysql
```

---

## Project Structure

```plaintext
lab-1a/
├── Screenshots/
│   ├── final-check-pt1.jpg
│   ├── final-check-pt2.jpg
│   ├── init.jpg
│   ├── lab-1a-ec2-iam-role.jpg
│   ├── lab-1a-ec2-rds-sg-inbound-rule.jpg
│   ├── list.jpg
│   ├── note1.jpg
│   ├── note2.jpg
│   ├── note3.jpg
│   ├── note4.jpg
│   ├── note5.jpg
│   └── verification.mp4
├── scripts-results/
│   ├── gate_result_secrets_and_role.json
│   ├── gate_network_db.json
│   ├── run_all_gates_1.json
│   └── run_all_gates_2.json
├── .gitignore
├── gate_secrets_and_role.sh
├── gate_network_db.sh
├── run_all_gates.sh
├── README.md
└── user_data.sh
```

---

## **Part I: Create Custom VPC w/ Subnets, IGW, NAT GW, and EIP**

1. Navigate to the AWS Management Console and sign in.
2. Select the **sa-east-1 (São Paulo)** region from the top-right dropdown.
3. Search for "VPC" and open the VPC Dashboard.
4. Click **Create VPC** → select **VPC and more**.
5. Set **Name tag auto-generation** or name the VPC **lab-1a-vpc**.
6. Set IPv4 CIDR block to **10.240.0.0/16**.
7. Select **three Availability Zones**.
8. Configure subnets:
   - **Public subnets**:
     - **Availability Zone 1** → **sa-east-1a**: `10.240.1.0/24`
     - **Availability Zone 2** → **sa-east-1b**: `10.240.2.0/24`
     - **Availability Zone 3** → **sa-east-1c**: `10.240.3.0/24`
   - **Private subnets**:
     - **Availability Zone 1** → **sa-east-1a**: `10.240.11.0/24`
     - **Availability Zone 2** → **sa-east-1b**: `10.240.12.0/24`
     - **Availability Zone 3** → **sa-east-1c**: `10.240.13.0/24`
9. Enable **one NAT Gateway** (it will be placed in a public subnet and allocate an Elastic IP automatically).
10. Enable **one Internet Gateway**.
11. Review and click **Create VPC**.

---

## **Part II: Create Security Groups**

1. In the VPC Dashboard, select **Security Groups** from the left menu.
2. Click **Create security group**.

### **EC2 Security Group**

- **Name:** `ec2-lab-sg`
- **Description:** `Security group for lab EC2 instance`
- **VPC:** `lab-1a-vpc`
- **Inbound rules:**
  - **Type:** `HTTP`, **Port:** `80`, **Source:** `Anywhere IPv4`, **Source:** `0.0.0.0/0`
  - **Type:** `SSH`, **Port:** `22`, **Source:** `My IP` (auto-detects your current IP)
- **Outbound rules:** **Default (allow all)**
- Create security group.

### **RDS Security Group**

- **Name:** `rds-lab-sg`
- **Description:** `Security group for lab RDS instance`
- **VPC:** `lab-1a-vpc`
- **Inbound rule:**
  - **Type:** `MySQL/Aurora`, **Port:** `3306`, **Source:** `Custom`, **Source:** `ec2-lab-sg`
- **Outbound rules:** **Default (allow all)**
- Create security group.

---

## **Part III: Create RDS MySQL DB Subnet Group and DB Instance**

### Creating a MySQL RDS Instance – Step-by-Step Guide

1. In the AWS Management Console, search for **RDS** and open the **RDS Dashboard**  
   > NOTE: Ensure you are in the **sa-east-1** region.

2. In the left navigation pane, click **Subnet groups**.
3. Click **Create subnet group**.

4. Fill in the details:
   - **Name:** `lab-mysql-subnet-group`
   - **Description:** `Subnet group for lab RDS MySQL instance`
   - **VPC:** `lab-1a-vpc`

5. Under **Subnets**, select **only the three private subnets**  
   (leave all public subnets unchecked).

6. Click **Create**.

7. Return to the **RDS Dashboard** and click **Create database**.

8. Choose **Full Configuration**.

9. Configure the following settings:

   **Engine options**  
   - Engine type: **MySQL 8.4.7**

   **Templates**  
   - Select **Free tier** (or **Dev/Test** if preferred)

   **Settings**  
   - **DB instance identifier:** `lab-mysql`  
   - **Master username:** `admin`  
   - **Master password:** `<PASSWORD_HERE>` (must enter it two times)

   **Connectivity**  
   - **VPC:** `lab-1a-vpc`  
   - **Public access:** **No**  
   - **DB subnet group:** `lab-mysql-subnet-group`  
   - **VPC security groups:** `rds-lab-sg`

   **Additional configuration**  
   - **Port:** `3306` (*default to confirm)*

10. Leave all remaining settings at their default values.

11. Click **Create database**.

12. Wait until the database status changes to **Available**.

  > NOTE: This may take several minutes.

---

## **Part IV: Store Database Credentials in Secrets Manager**

1. Search for "Secrets Manager" (sa-east-1 region).
2. Click **Store a new secret**.
3. Secret type: **Credentials for RDS database**.
4. **Username:** `admin`
5. **Password:** `<PASSWORD_HERE>`
6. **Select RDS instance:** `lab-mysql` (auto-populates host, port, and endpoint.)
7. **Secret name:** `lab-rds-mysql`
8. **Description:** `Credentials for RDS database`
9. Accept defaults and create the secret.

---

## **Part V: Create Custom IAM Role**

1. Search for "IAM" and open the IAM Dashboard.
2. Navigate to **Roles** → **Create role**.
3. Trusted entity: **AWS service** → **EC2**.
4. Name the role: **lab-ec2-role**.
5. Description: `Role for EC2 to access Secrets Manager`.
6. Click **Create role**
7. After creation, attach an inline policy:
   - Go to the role → **Add permissions** → **Create inline policy** → **JSON**.

     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Sid": "ReadSpecificSecret",
           "Effect": "Allow",
           "Action": [
             "secretsmanager:GetSecretValue"
           ],
           "Resource": "arn:aws:secretsmanager:<REGION_HERE>:<ACCOUNT_ID>:secret:lab-rds-mysql*"
         },
         {
           "Sid": "EC2ReadAccess",
           "Effect": "Allow",
           "Action": [
             "ec2:DescribeInstances",
             "ec2:DescribeTags"
           ],
           "Resource": "*"
         }
       ]
     }
     ```

     > NOTE: Replace **<REGION_HERE>** with your actual AWS region and **<ACCOUNT_ID>** with your actual AWS account ID.

8. Name the policy (e.g., `secrets-access`) and create policy.

---

## **Part VI: Launch EC2 Instance with Bootstrap User Data**

1. Search for "EC2" (sa-east-1 region).
2. Click Launch instance.
3. **Name:** `lab-ec2-app`
4. **AMI:** **Amazon Linux 2023**
5. **Instance type:** **t3.micro** (or **t2.micro**)
6. **Key pair:** Select `ec2-key-pair` or create one for SSH
7. **Network settings:**
   - **VPC:** `lab-1a-vpc`
   - **Subnet:** One **public subnet** (e.g., **10.240.1.0/24** in sa-east-1a)
   - **Auto-assign public IP:** **Enable**
   - **Security group:** Existing → `ec2-lab-sg`
8. **Advanced details** → **IAM instance profile:** `lab-ec2-role`
9. **User data:** Add the **`user_data.sh`** file:

    Python code defaults:

    ```bash
    #!/bin/bash
    dnf update -y
    dnf install -y python3-pip
    pip3 install flask pymysql boto3

    mkdir -p /opt/rdsapp
    chown ec2-user:ec2-user /opt/rdsapp
    cd /opt/rdsapp

    cat > app.py <<'PYTHON'
    import json
    import os
    import boto3
    import pymysql
    from flask import Flask, request

    REGION = os.environ.get("AWS_REGION", "sa-east-1")
    SECRET_ID = os.environ.get("SECRET_ID", "lab-rds-mysql")

    secrets = boto3.client("secretsmanager", region_name=REGION)

    def get_db_creds():
        resp = secrets.get_secret_value(SecretId=SECRET_ID)
        s = json.loads(resp["SecretString"])
        return s

    def get_conn():
        c = get_db_creds()
        host = c["host"]
        user = c["username"]
        password = c["password"]
        port = int(c.get("port", 3306))
        db = c.get("dbname", "labdb")
        return pymysql.connect(host=host, user=user, password=password, port=port, database=db, autocommit=True)

    app = Flask(__name__)

    @app.route("/")
    def home():
        return """
        <h2>EC2 → RDS Notes App</h2>
        <p>POST /add?note=hello</p>
        <p>GET /list</p>
        """

    @app.route("/init")
    def init_db():
        c = get_db_creds()
        host = c["host"]
        user = c["username"]
        password = c["password"]
        port = int(c.get("port", 3306))

        # connect without specifying a DB first
        conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)
        cur = conn.cursor()
        cur.execute("CREATE DATABASE IF NOT EXISTS labdb;")
        cur.execute("USE labdb;")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS notes (
                id INT AUTO_INCREMENT PRIMARY KEY,
                note VARCHAR(255) NOT NULL
            );
        """)
        cur.close()
        conn.close()
        return "Initialized labdb + notes table."

    @app.route("/add", methods=["POST", "GET"])
    def add_note():
        note = request.args.get("note", "").strip()
        if not note:
            return "Missing note param. Try: /add?note=hello", 400
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("INSERT INTO notes(note) VALUES(%s);", (note,))
        cur.close()
        conn.close()
        return f"Inserted note: {note}"

    @app.route("/list")
    def list_notes():
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT id, note FROM notes ORDER BY id DESC;")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        out = "<h3>Notes</h3><ul>"
        for r in rows:
            out += f"<li>{r[0]}: {r[1]}</li>"
        out += "</ul>"
        return out

    if __name__ == "__main__":
        app.run(host="0.0.0.0", port=80)
    PYTHON

    # Create systemd service file (runs as root to allow binding to port 80)
    cat > /etc/systemd/system/rdsapp.service <<'SERVICE'
    [Unit]
    Description=EC2 to RDS Notes App
    After=network.target

    [Service]
    WorkingDirectory=/opt/rdsapp
    Environment=AWS_REGION=sa-east-1
    Environment=SECRET_ID=lab-rds-mysql
    ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
    Restart=always

    [Install]
    WantedBy=multi-user.target
    SERVICE

    # Reload systemd, enable and start the service
    systemctl daemon-reload
    systemctl enable rdsapp
    systemctl start rdsapp
    ```

10. Launch the instance.

---

## **Part VII: Test the Deployment and Collect Deliverables**

1. Note the public IPv4 address of the instance.

2. In a browser:

    ```plaintext
    http://<PUBLIC_IP>/init                                    → Initializes database and table
    http://<PUBLIC_IP>/add?note=first_note                     → (repeat for multiple notes)
    http://<PUBLIC_IP>/add?note=blue_book_gentlemen            → (repeat for multiple notes)
    http://<PUBLIC_IP>/add?note=brazil_colombia_capeverde      → (repeat for multiple notes)
    http://<PUBLIC_IP>/add?note=this_is_200k_work              → (repeat for multiple notes) 
    http://<PUBLIC_IP>/add?note=lab_1b_is_a_success            → (repeat for multiple notes)
    http://<PUBLIC_IP>/list                                    → Verify at least three notes displayed
    ```

3. **For deliverables:**

    - **Screenshot RDS SG inbound rule** (`3306` from `ec2-lab-sg`)
    ![lab-1a-ec2-rds-sg-inbound-rule.jpg](/Screenshots/lab-1a-ec2-rds-sg-inbound-rule.jpg)

    - **Screenshot EC2 instance with attached IAM role**
    ![lab-1a-ec2-iam-role.jpg](/Screenshots/lab-1a-ec2-iam-role.jpg)

    - Screenshot of `http://<PUBLIC_IP>/list` output with ≥ **three notes**

      - **RDS + EC2 Notes App Initialized**
        - ![init.jpg](/Screenshots/init.jpg)

      - 1: **first_note**
        - ![note1.jpg](/Screenshots/note1.jpg)

      - 2: **blue_book_gentlemen**
        - ![note2.jpg](/Screenshots/note2.jpg)

      - 3: **brazil_colombia_capeverde**
        - ![note3.jpg](/Screenshots/note3.jpg)

      - 4: **this_is_200k_work**
        - ![note4.jpg](/Screenshots/note4.jpg)

      - 5: **lab_1a_is_a_successful**
        - ![note5.jpg](/Screenshots/note5.jpg)

      - 6: **Full list view:**
        - ![list.jpg](/Screenshots/list.jpg)

4. **Short Answers:**

- **Why is DB inbound source restricted to the EC2 security group?**
  - `To limit database access only to the EC2 instance, enhancing security by preventing unauthorized access from other sources.`

- **What port does MySQL use?**
  - `3306`

- **Why is Secrets Manager better than storing creds in code/user-data?**
  - `It provides secure, centralized management of credentials with automatic rotation and fine-grained access control, reducing the risk of exposure.`

---

## **Part VIII: Verification Checklist**

- **Verification Commands:**

    ```bash
    # Verify EC2 Instance ID (Part 6.1)
    aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=<EC2_INSTANCE_NAME>" \
    --query "Reservations[].Instances[].InstanceId"

    # Verify EC2 IAM Role Attached to EC2 Instance (Part 6.2)
    aws ec2 describe-instances \
    --instance-ids <INSTANCE_ID> \
    --query "Reservations[].Instances[].IamInstanceProfile.Arn"

    # Verify RDS Instance Details (Part 6.3)
    aws rds describe-db-instances \
    --db-instance-identifier <DB_INSTANCE_IDENTIFIER> \
    --query "DBInstances[].DBInstanceArn"

    # Verify RDS Instance Status (Bonus)
    aws rds describe-db-instances \
    --db-instance-identifier <DB_INSTANCE_IDENTIFIER> \
    --query "DBInstances[].DBInstanceStatus"

    # Verify RDS Endpoint (Connectivity Target - Part 6.4)
    aws rds describe-db-instances \
    --db-instance-identifier <DB_INSTANCE_IDENTIFIER> \
    --query "DBInstances[].Endpoint"

    # Verify RDS Security Group Critical Inbound Rule (Part 6.5)
    aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=<VPC_ID>" "Name=group-name,Values=<RDS_SECURITY_GROUP>" \
    --query "SecurityGroups[].IpPermissions"

    # Verify Secrets Manager Access (From EC2 - Part 6.6)
    aws secretsmanager get-secret-value \
    --secret-id <SECRET_ID>

    # Commands to Install MySQL Client on EC2 Instance (Required before Part 6.7)
    sudo dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-5.noarch.rpm
    sudo dnf module disable mariadb -y
    sudo dnf makecache
    sudo dnf install -y mysql-community-client

    # Verify MySQL Version (After MySQL Client Installation)
    mysql --version

    # Connect to RDS MySQL Instance from EC2 Instance (Part 6.7)
    mysql -h <RDS_ENDPOINT> -u admin -p
    
    # Enter the password when prompted
    # Verification is successful if you reach the MySQL prompt
    ```

  - **Verification Demonstration:**

  <https://github.com/user-attachments/assets/d5f0c48c-1678-4c14-a8f8-148dba0ba53f>

---

## **Part IX: Final Audit Checks**
  
- **SEIR Gate - 1 of 2 Output:**
[`gate_secrets_and_role.sh`](/gate_secrets_and_role.sh)
  - **Gate Secrets and Role JSON Output:**
  [`gate_result_secrets_and_role.json`](/scripts-results/gate_result_secrets_and_role.json)

- **SEIR Gate - 2 of 2 Output:**
[`gate_network_db.sh`](/gate_network_db.sh)
  - **Gate Network Database JSON Output:**
  [`gate_network_db.json`](/scripts-results/gate_network_db.json)

- **SEIR Run All Gates Output:**
[`run_all_gates.sh`](/run_all_gates.sh)
  - **Run All Gates JSON Output (Part I):**
  [`run_all_gates_1.json`](/scripts-results/run_all_gates_1.json)
  - **Run All Gates JSON Output (Part II):**
  [`run_all_gates_2.json`](/scripts-results/run_all_gates_2.json)

- **Final Audit Check**

  ![final-check-pt1.jpg](/Screenshots/final-check-pt1.jpg)
  ![final-check-pt2.jpg](/Screenshots/final-check-pt2.jpg)

---

## **Part X: References**

- **AWS Documentation on Security Best Practices for Amazon RDS:** <https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.Security.html>  
- **Controlling Access with Security Groups in Amazon RDS:** <https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.RDSSecurityGroups.html>  
- **Connecting to a MySQL DB Instance in Amazon RDS:** <https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ConnectToInstance.html>  
- **AWS Secrets Manager Introduction and Best Practices:** <https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html>  
- **Moving Hardcoded Credentials to AWS Secrets Manager:** <https://docs.aws.amazon.com/secretsmanager/latest/userguide/hardcoded-db-creds.html>  
- **Amazon EC2 User Guide:** <https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html>  
- **AWS IAM Best Practices:** <https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html>

## **Troubleshooting**

### Common Issues and Solutions

- **Application returns 500 errors:**
  - Check EC2 system logs: `sudo journalctl -u rdsapp`
  - Common causes: IAM role not attached, incorrect secret name, security group blocking 3306.

- **"Can't connect to MySQL server" from EC2:**
  - Verify RDS security group allows inbound 3306 from EC2 security group.
  - Confirm RDS is in "Available" state.

- **Secrets Manager AccessDenied:**
  - Ensure IAM role has `secretsmanager:GetSecretValue` on the correct secret ARN.
  - Instance profile must be attached to EC2.

- **No notes displayed:**
  - Run `/init` first to create database/table.
  - Check application logs for DB connection errors.

- **MySQL client not found:**
  - Use `sudo dnf install -y mariadb` (**Amazon Linux 2023 uses MariaDB client**).

---

## **Authors**

- **Author:** T.I.Q.S.
- **Group Leader:** John Sweeney

---
