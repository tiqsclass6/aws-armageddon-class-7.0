# Lab 3A: Multi-Region Application with TGW Connectivity

- **Infrastructure Setup**: RDS is deployed only in Shinjuku (Tokyo `ap-northeast-1` region). The app (EC2 via ASG, ALB, CloudFront) is deployed only in Liberdade (Sao Paulo `sa-east-1` region). VPCs, subnets, NAT, IGW, and route tables are configured in both regions as per the "Lab 2 minus DB" pattern for Liberdade.
- **TGW and Peering**: Separate TGWs in each region, with peering initiated from Shinjuku and accepted in Liberdade. VPC attachments to local TGWs, and explicit routes in TGW route tables for cross-region CIDRs (e.g., Liberdade to Shinjuku CIDR via peering).
- **Routing and Connectivity**: Private subnet route tables in each region route internet traffic via NAT/IGW and cross-region traffic via local TGW. No direct cross-region VPC attachments.
- **Security**: Shinjuku RDS SG allows MySQL ingress from both local (Shinjuku) VPC CIDR and Liberdade (Liberdade) VPC CIDR. Liberdade app SG allows outbound anywhere (including to RDS). ALB listener uses custom header for origin verification with CloudFront.
- **Data Access**: Authoritative DB credentials stored in Shinjuku Secrets Manager; Liberdade EC2 role allows read access. App user data/script fetches creds from Shinjuku and connects to RDS endpoint.
- **Compliance/Engineering**: Storage (RDS) remains in Shinjuku; compute (app) in Liberdade is stateless. Single CloudFront URL for app access. No PHI handling specified or implemented.
- **Naming**: Uses shinjuku for Shinjuku and liberdade for Liberdade consistently; no Chewie/Chewbacca references.
- **Other**: Multi-region providers, backend S3 state, random passwords, no-cache CloudFront policy, ASG with launch template, and outputs for verification.

The setup adheres to the "controlled corridor" via TGW, with all elements deployable via Terraform.

To ensure you meet the Lab 3A objective (deploying the infrastructure, verifying connectivity, and confirming app functionality across regions), follow these steps in sequence. Assume you have AWS credentials configured (e.g., via `aws configure`) with permissions for the required services in both regions (ap-northeast-1 and sa-east-1). Use a terminal with Terraform >=1.9 installed.

---

## 1. **Prepare Your Environment**

- Review and customize variables in `4-variables.tf` if needed (e.g., VPC CIDRs, ASG sizes, instance type). Defaults should work for lab purposes.
- Initialize Terraform:

     ```bash
     terraform init -upgrade
     ```

---

## 2. **Deploy the Infrastructure**

- Validate the configuration with a plan:

     ```bash
     terraform validate
     ```

     Ensure no syntax errors.

- Format the code (optional but recommended):

     ```bash
     terraform fmt -recursive
     ```

- Run a plan to validate:

     ```bash
     terraform plan
     ```

     Review for errors or unexpected changes.
- Apply the configuration:

     ```bash
     terraform apply
     ```

     This deploys everything: VPCs, TGWs, peering, RDS (Shinjuku only), app (Liberdade only), Secrets Manager, CloudFront, etc. It may take 10-15 minutes.
- Fetch outputs for verification (save to a file for reference):

     ```bash
     terraform output > outputs.txt
     ```

     Key outputs include `liberdade_cloudfront_domain`, `shinjuku_rds_endpoint`, `liberdade_application_urls`, TGW IDs, and VPC CIDRs.

---

## 3. **Verify Network Connectivity**

- Confirm TGW peering status (should be "active"):

     ```bash
     # Describe peering attachments from Shinjuku side
     aws ec2 describe-transit-gateway-peering-attachments \ 
       --region ap-northeast-1 \ 
       --filters "Name=transit-gateway-id,Values=$(terraform output -raw shinjuku_tgw_id)"
    ```

    ```bash
     # Describe peering attachments from Liberdade side
     aws ec2 describe-transit-gateway-peering-attachments \ 
       --region sa-east-1 \ 
       --filters "Name=transit-gateway-id,Values=$(terraform output -raw liberdade_tgw_id)"
     ```

- Verify cross-region routes in TGW route tables (e.g., Shinjuku CIDR points to peering attachment in Liberdade):

     ```bash
     # Check Shinjuku TGW route table
     aws ec2 describe-transit-gateway-route-tables \ 
       --region ap-northeast-1 \ 
       --filters "Name=transit-gateway-id,Values=$(terraform output -raw shinjuku_tgw_id)" \
       --query "TransitGatewayRouteTables[].TransitGatewayRouteTableId" \
       --output text | xargs -I {} aws ec2 search-transit-gateway-routes --region ap-northeast-1 --transit-gateway-route-table-id {}
     ```

     ```bash
     # Check Liberdade TGW route table
     aws ec2 describe-transit-gateway-route-tables \
       --region sa-east-1 \
       --filters "Name=transit-gateway-id,Values=$(terraform output -raw liberdade_tgw_id)" \
       --query "TransitGatewayRouteTables[].TransitGatewayRouteTableId" \
       --output text | xargs -I {} aws ec2 search-transit-gateway-routes --region sa-east-1 --transit-gateway-route-table-id {}
     ```

- From a Liberdade EC2 instance (use SSM to connect; find instance ID via AWS Console or `aws ec2 describe-instances --region sa-east-1 --filters "Name=tag:Name,Values=liberdade-app"`):

     ```bash
     # Start SSM session to Liberdade EC2
     aws ssm start-session \
       --target <instance-id> \
       --region sa-east-1
     ```

     Inside the session, test RDS reachability:

     ```bash
     # Test connectivity to Shinjuku RDS from Liberdade EC2 (via SSM session)
     nc -vz $(terraform output -raw shinjuku_rds_endpoint) 3306
     ```

     Expected: "Connection succeeded" (port open via TGW and SG rules).

---

## 4. **Verify Application Functionality**

- Use the CloudFront URLs from `terraform output liberdade_application_urls` (or directly from outputs.txt).
- Initialize the DB (run in browser or curl):

     ```bash
     # Initialize the database
     curl "https://$(terraform output -raw liberdade_cloudfront_domain)/init"
     ```

     Expected: "Initialized labdb + notes table."
- Add notes (repeat for each note in the output block):

     ```bash
     # Add notes via CloudFront URL
     curl "https://$(terraform output -raw liberdade_cloudfront_domain)/add?note=first_note"
     curl "https://$(terraform output -raw liberdade_cloudfront_domain)/add?note=blue_book_gentlemen"
     curl "https://$(terraform output -raw liberdade_cloudfront_domain)/add?note=TIQS_loves_big_booty_latinas"
     curl "https://$(terraform output -raw liberdade_cloudfront_domain)/add?note=brazil_colombia_capeverde"
     curl "https://$(terraform output -raw liberdade_cloudfront_domain)/add?note=this_is_300k_work"
     curl "https://$(terraform output -raw liberdade_cloudfront_domain)/add?note=lab_3a_is_complete"
     ```

     Expected: "Inserted note: \<note\>" for each.
- List notes:

     ```bash
     # List notes via CloudFront URL
     curl "https://$(terraform output -raw liberdade_cloudfront_domain)/list"
     ```

     Expected: HTML list showing all inserted notes (confirms Liberdade app writes/reads from Shinjuku RDS via TGW).
- Check app logs on Liberdade EC2 (via SSM session):

     ```bash
     # View user-data log on Liberdade EC2 (via SSM session)
     tail -f /var/log/user-data.log
     ```

     Look for successful DB connections and note insertions (via Watchtower to CloudWatch).

---

## 5. **Verify Security and Compliance Aspects**

- Confirm RDS SG rules allow Liberdade CIDR:

     ```bash
     # EC2 describe SG rules in Shinjuku
     aws ec2 describe-security-groups \
       --region ap-northeast-1 \
       --filters "Name=tag:Name,Values=shinjuku-rds-sg" \
       --query "SecurityGroups[].IpPermissions[]"
     ```

     Expected: Ingress rule for 3306 from Liberdade VPC CIDR (10.245.0.0/16).
- Confirm Secrets Manager access: On Liberdade EC2 (SSM session), test fetching secret:

     ```bash
     # AWS Secrets Manager value fetch command
     aws secretsmanager get-secret-value \
       --secret-id lab-3a/shinjuku/rds/mysql_v6 \
       --region ap-northeast-1
     ```

     Expected: JSON with DB creds (role allows cross-region read).
- Attempt direct ALB access (should fail without custom header):

     ```bash
     # Attempt direct ALB access (should fail without custom header)
     curl "http://$(terraform output -raw liberdade_alb_dns_name)/list"
     ```

     Expected: 403 Forbidden (enforces CloudFront origin security).

---

## 6. **Cleanup (Optional, After Verification)**

- Destroy resources to avoid costs:

     ```bash
     terraform destroy
     ```

     Confirm all resources (RDS, TGWs, VPCs, etc.) are deleted via AWS Console.

---
