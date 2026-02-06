# CloudFront Origin-Driven Caching Lab: Verification, Invalidation Procedures, and Best Practices

This document serves as a comprehensive, production-grade reference for the **honors verification lab** focused on demonstrating origin-driven caching with Amazon CloudFront, validating cache behavior, executing controlled invalidations, and establishing disciplined governance practices. All sections are designed to be clear, auditable, and aligned with AWS best practices, suitable for inclusion in a GitHub repository (e.g., as `DELIVERABLES.md` or `README.md` in the lab directory).

The lab emphasizes:

- Proving CloudFront respects origin `Cache-Control` headers
- Demonstrating safe invalidation for non-versioned entrypoints
- Reinforcing versioning as the primary cache freshness mechanism
- Enforcing strict governance to prevent misuse

---

## Part A — Add “Break Glass” Invalidation Procedure (CLI)

The procedures below define a controlled, auditable “break glass” process for invalidating CloudFront cache content during emergency scenarios (e.g., security remediation, critical content corruption, legal takedown, or severe misconfiguration). All commands must be executed only after obtaining required approval per the invalidation budget (Part E2).  

Prerequisites:

- AWS CLI v2 configured with credentials possessing `cloudfront:CreateInvalidation` and `cloudfront:GetInvalidation` permissions
- `DISTRIBUTION_ID` available from Terraform output (`cloudfront_distribution_id`)

### A1) Create an Invalidation for a Single Exact Path (Recommended Default)

```bash
# Retrieve the CloudFront distribution ID from Terraform
DISTRIBUTION_ID="$(terraform output -raw cloudfront_distribution_id)"

# Invalidate a single, precisely targeted path
aws cloudfront create-invalidation \
  --distribution-id "$DISTRIBUTION_ID" \
  --invalidation-batch '{
    "Paths": {
      "Quantity": 1,
      "Items": ["/static/index.html"]
    },
    "CallerReference": "manual-static-index-'$(date +%s)'"
  }'
```

**Key characteristics**:

- Returns an `Invalidation` object with `Id`, `Status` (“InProgress”), `CreateTime`, and `CallerReference`
- `CallerReference` uses a Unix timestamp for uniqueness and traceability
- Matches the official AWS CLI example for targeted invalidations

Retrieve status of any invalidation:

```bash
# Replace with actual ID from create-invalidation output
INVALIDATION_ID="IABCDEFGHIJKLMNOPQRSTUVW"

aws cloudfront get-invalidation \
  --distribution-id "$DISTRIBUTION_ID" \
  --id "$INVALIDATION_ID"
```

![lab-2b-bam-b-pt1.jpg](/Screenshots/lab-2b-bam-b-pt1.jpg)

**Post-invalidation verification** (confirm edge propagation):

```bash
curl -i -k "https://app.theinternationalquietstorm.com/static/index.html" | sed -n '1,30p'
curl -i -k "https://app.theinternationalquietstorm.com/static/index.html" | sed -n '1,30p'
```

![lab-2b-bam-b-pt2.jpg](/Screenshots/lab-2b-bam-b-pt2.jpg)
![lab-2b-bam-b-pt3.jpg](/Screenshots/lab-2b-bam-b-pt3.jpg)

**Expected behavior**:

- First request after completion: `x-cache: Miss from cloudfront`
- Subsequent requests: `x-cache: Hit from cloudfront` with updated content body

**Reference**:  
[Invalidation path rules](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/invalidation-specifying-objects.html) — Paths must begin with `/`; wildcards only at the end.

### A3) Track Invalidation Completion and Simulate Origin Update (Optional)

1. Monitor status until `Status` becomes `Completed` (via `get-invalidation` or CloudFront console).
2. (Optional) Simulate an origin content change via AWS Systems Manager (SSM):

```bash
aws ssm start-session \
  --target i-091287c6fbbd926a7 \
  --region us-east-2
```

Inside the SSM session:

```bash
sudo sh -c 'echo "<!-- deploy: '$(date -u +%FT%TZ)' -->" >> /var/www/html/static/index.html'
```

1. Immediately invalidate to force CloudFront to fetch the updated origin object:

```bash
aws cloudfront create-invalidation \
  --distribution-id "$DISTRIBUTION_ID" \
  --invalidation-batch '{
    "Paths": {
      "Quantity": 1,
      "Items": ["/static/index.html"]
    },
    "CallerReference": "manual-static-index-'$(date +%s)'"
  }'
```

![lab-2b-bam-b-pt4.jpg](/Screenshots/lab-2b-bam-b-pt4.jpg)

This sequence guarantees updated origin content is reflected at the edge.

---

## Part B — “Correctness Proof” Checklist (Required Submission)

Students must submit timestamped evidence (screenshots or pasted terminal output) demonstrating that invalidation correctly forces cache refresh.

### B1) Before Invalidation: Prove Object Is Cached

```bash
curl -i https://app.theinternationalquietstorm.com/static/index.html | sed -n '1,30p'
curl -i https://app.theinternationalquietstorm.com/static/index.html | sed -n '1,30p'
```

![lab-2b-bam-b-pt5.jpg](/Screenshots/lab-2b-bam-b-pt5.jpg)
![lab-2b-bam-b-pt6.jpg](/Screenshots/lab-2b-bam-b-pt6.jpg)

**Expected observations**:

- First request: `x-cache: Miss from cloudfront` (or absent `Age`)
- Second request: `x-cache: Hit from cloudfront`, `Age` present and incrementing (e.g., `Age: 3`, `Age: 5`)
- `Cache-Control` reflects origin directive (e.g., `public, max-age=86400, immutable`)

**Reference**: [Cache hit/miss statistics](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cache-statistics.html)

### B2) Deploy Change (Simulate)

Update `/static/index.html` at the origin to introduce a detectable change (e.g., append timestamp comment, modify text, or alter metadata) via:

- Direct file edit on the origin server (as shown in A3), or
- Re-deployment through the CI/CD pipeline.

Confirm the change is visible by requesting the origin directly (bypassing CloudFront) if network access permits.

### B3) After Invalidation: Prove Cache Refresh

1. Execute the single-path invalidation for `/static/index.html` (A1 command).
2. Wait for invalidation completion (poll with `get-invalidation` or monitor console).
3. Re-test:

```bash
curl -i https://app.theinternationalquietstorm.com/static/index.html | sed -n '1,30p'
```

**Expected observations**:

- Initial post-invalidation request: `x-cache: Miss from cloudfront` (or `RefreshHit` if conditional revalidation occurs)
- Subsequent requests: `x-cache: Hit from cloudfront`, `Age` starts near 0 and increments
- Response body matches the newly updated origin content (confirm via visual diff or added timestamp/comment)

**Reference**: [Standard logs reference – x-cache values](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/standard-logs-reference.html)  
Defines: `Hit from cloudfront`, `Miss from cloudfront`, `RefreshHit from cloudfront`.

---

## Part C — Terraform “Framework” for Invalidation Management (Two Options)

### Option 2 (Advanced / Optional): Terraform-Triggered Targeted Invalidation

**Rationale**  
In highly controlled environments (e.g., blue/green hotfix pipelines or non-versioned entrypoints), narrowly scoped invalidations may be triggered via Terraform using `terraform_data` and `local-exec`. This must remain opt-in, heavily gated, and restricted to exact paths.

#### **Terraform Apply and Set Variables**  

```bash
terraform apply \
  -var="break_glass_invalidate=true" \
  -var='break_glass_paths=["/static/index.html"]'
```

![lab-2b-bam-b-pt7.jpg](/Screenshots/lab-2b-bam-b-pt7.jpg)

#### **Expected Terraform Output**

```json
{
    "Location": "https://cloudfront.amazonaws.com/2020-05-31/distribution/E103ZUUVKAUOOL/invalidation/I4ZGG5UKUDVEXPLDM6JTVKDP2P",
    "Invalidation": {
        "Id": "I4ZGG5UKUDVEXPLDM6JTVKDP2P",
        "Status": "InProgress",
        "CreateTime": "2026-01-24T05:48:55.098000+00:00",
        "InvalidationBatch": {
            "Paths": {
                "Quantity": 1,
                "Items": [
                    "/static/index.html"
                ]
            },
            "CallerReference": "tf-break-glass-2026-01-24T05:48:53Z"
        }
    }
}
```

![lab-2b-bam-b-pt8.jpg](/Screenshots/lab-2b-bam-b-pt8.jpg)

**Recommendation**  

- Adopt **Option 2 (Preferred)** only with strict governance, narrow path scopes, comprehensive logging/auditing, and thorough knowledge of HashiCorp Terraform best practices.

**References**  

- [Invalidate files to remove content](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html)  
- [Terraform `terraform_data` resource](https://developer.hashicorp.com/terraform/language/resources/terraform-data)  
- [AWS CLI: create-invalidation](https://docs.aws.amazon.com/cli/latest/reference/cloudfront/create-invalidation.html)

---

## Part D — Analysis of Caching Behavior and Invalidation Evidence

The provided curl outputs and CloudFront console screenshot confirm correct **origin-driven caching** behavior for the static asset `/static/index.html`.

### Observed Headers and Behavior

- **Cache-Control: public, max-age=86400, immutable**  
  Origin directs CloudFront and shared caches to store the object for 86,400 seconds (24 hours) without revalidation, even with conditional headers present.
- **ETag** and **Last-Modified** headers present, enabling efficient conditional validation upon TTL expiration.
- **x-cache: Miss from cloudfront** → Origin fetch when no valid cached copy exists (initial or post-invalidation).
- **x-cache: Hit from cloudfront** with **Age: 2** → Edge cache hit; `Age` indicates seconds since caching.

This demonstrates CloudFront’s strict adherence to origin-provided `Cache-Control` directives under an origin-driven cache policy (e.g., `UseOriginCacheControlHeaders` with low Minimum TTL), preventing permissive edge defaults.

### Why Versioning Is Preferred, and Why Entrypoints Sometimes Require Invalidation

**Versioning** (e.g., `/static/index.<content-hash>.html`, `/static/app.v123.js`) is AWS’s recommended best practice for most assets. Unique URLs per change create distinct cache objects; new versions are fetched on first request, old versions remain cached for existing clients. Benefits include:

- Elimination of manual invalidations
- No propagation delays or extra costs
- Safe rollbacks via URL reversion
- Higher long-term cache hit ratios
- Simplified debugging through version-specific logs

**Entrypoint files** (e.g., root `index.html` in SPAs, HTML shells, manifests) are often non-versionable without breaking routing or client expectations. In these cases, invalidation is required for urgent updates (security patches, corruption, legal takedown). Always scope narrowly (e.g., `/static/index.html` only). Broad wildcards (`/*`, `/static/*`) must be avoided—they flush excessive cache, increase costs beyond the free tier (1,000 paths/month), consume limits, amplify blast radius, and encourage unsafe habits.

### Recommended Invalidation Action

- Use exact path invalidation (e.g., `/static/index.html`)
- Avoid `/*` or directory wildcards unless multiple files are affected
- After completion (monitor console), verify:
  - Initial request: `x-cache: Miss from cloudfront`
  - Subsequent: `x-cache: Hit from cloudfront`, updated content body

This targeted approach minimizes disruption and follows AWS best practices.

![lab-2b-bam-b-pt9.jpg](/Screenshots/lab-2b-bam-b-pt9.jpg)
![lab-2b-bam-b-pt10.jpg](/Screenshots/lab-2b-bam-b-pt10.jpg)

### Short Incident Note (Post-Mortem / Ticket)

On January 24, 2026, a deployment error required immediate cache refresh of `/static/index.html`. A scoped CloudFront invalidation was executed for the exact path `/static/index.html` (Invalidation ID: I4ZG5UKDVEXPLDM6JTVKDP2P, completed 5:48:55 AM UTC), ensuring minimal impact. No broad wildcards were used, preserving unrelated asset hit ratios. Future updates to this non-versioned entrypoint will follow precise invalidation protocol, with strong preference for build-time hashing to enable immutable versioning and eliminate manual invalidations where feasible.

**References**  

- [Invalidate files to remove content](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html)  
- [Manage how long content stays in the cache (expiration)](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Expiration.html)  
- [What you need to know when invalidating files](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/invalidation-specifying-objects.html)

---

## Part E — “Smart” Upgrade (Extra Credit)

### E1) Explain When Not to Invalidate

Invalidation should be avoided entirely when only **versioned static assets** are modified, such as:

- `/static/app.9f3c1c7.js`
- `/static/styles.abcd1234.css`
- `/static/images/logo-v2.56789ef.png`

Each deployment generates a unique filename (via content hash or version identifier). CloudFront treats each as a distinct object: new versions are fetched and cached on first request; prior versions continue serving existing clients safely. This eliminates invalidation needs, avoids costs beyond the free tier (1,000 paths/month), prevents cache purges that reduce hit ratios, and avoids propagation delays.

AWS recommends versioning for frequently changing assets, providing deterministic freshness, safe rollbacks, and optimal cache efficiency without operational overhead.

**Contrast: When Invalidation Is Necessary**  
Non-versioned entrypoints (e.g., `/index.html`, `/manifest.json`, SPA HTML shells) require invalidation because clients always request the same URL. Use narrowly scoped invalidations (e.g., `/index.html` only) for break-glass scenarios (security fixes, legal takedown, severe corruption).

**Reference**  
[Invalidate files to remove content](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html)  
“A best practice is to version your files… Versioning eliminates the need to invalidate files and provides better performance…”

Adopting versioning for non-critical assets reserves invalidation for exceptional cases, reducing risk, cost, and cache churn.

### E2) Create “Invalidation Budget”

To enforce disciplined, cost-effective cache management, implement the following **CloudFront invalidation budget** and governance framework.

**Monthly Invalidation Path Budget**  

- Allocated: **200 paths per month**  
- Conservative buffer below AWS free tier (1,000 paths/month)  
- Tracked via CloudFront usage reports, CloudWatch (`InvalidationCount`), billing alerts  
- At 80% consumption (160 paths), automated notifications trigger review/escalation

**Allowed Wildcard Usage Conditions**  
Wildcard invalidations (`/*`, `/static/*`, etc.) are **prohibited by default** and allowed only for:  

1. Catastrophic security incident (widespread malicious content)  
2. Widespread content corruption (non-versionable directory)  
3. Legal/regulatory takedown order requiring broad removal  
4. Critical misconfiguration rollback where targeted invalidations fail  

All other changes must use exact paths or versioning. Wildcard requests require documented justification and prior approval.

**Approval Workflow for `/*` (or Broad Wildcard) Invalidations**  

1. Initiator submits request (ticket) with paths, root cause, impact assessment, alternatives  
2. First-level review (on-call/SRE): 15 min (business) / 60 min (off-hours); denied if narrower viable  
3. Second-level approval (manager/security officer): confirms eligibility, cost, remediation plan  
4. Execution only after dual approval; logged with ticket ID  
5. Post-event 5-Why retrospective within 72 hours, with preventive actions

This framework ensures invalidations remain exceptional, auditable, and tightly controlled, aligning with AWS guidance favoring versioning.

**References**  

- [Invalidate files to remove content](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html)  
- AWS Pricing: First 1,000 paths/month free; excess incur charges

---
