# Honors Verification: Origin-Driven Caching w/ AWS CloudFront

This document outlines the required proofs and submissions for honors verification of origin-driven caching behavior in **Amazon CloudFront.** Students must demonstrate that CloudFront respects origin-provided HTTP headers (particularly `Cache-Control`) rather than applying permissive defaults, ensuring safe and controlled caching for APIs.

## **1. Prove CloudFront Honors Origin `Cache-Control` Headers**

Use the following endpoints for verification (replace with your distribution URL as needed):

- Cacheable endpoint: `https://app.theinternationalquietstorm.com/api/public-feed`  
  Expected origin headers: `Cache-Control: public, s-maxage=30, max-age=0`

- Non-cacheable endpoint: `https://app.theinternationalquietstorm.com/api/list`  
  Expected origin headers: `Cache-Control: private, no-store`

### Verification Steps for Cacheable Endpoint (`/api/public-feed`)

**A. First request – Expect cache MISS**  

```bash
curl -i -k https://app.theinternationalquietstorm.com/api/public-feed | sed -n '1,30p'
```

**Expected observations**:

- `x-cache: Miss from cloudfront` (or `Miss` variant)
- `Cache-Control: public, s-maxage=30, max-age=0` (or similar origin directive)
- `Age` header absent or `0`

**B. Second request (within 30 seconds) – Expect cache HIT**  

```bash
curl -i -k https://app.theinternationalquietstorm.com/api/public-feed | sed -n '1,30p'
```

**Expected observations**:

- `x-cache: Hit from cloudfront`
- `Age` header present and incrementing (indicates caching)
- Response body identical to first request

**C. After TTL expiration (wait ~35 seconds) – Expect cache MISS or RefreshHit**  

```bash
sleep 35
curl -i -k https://app.theinternationalquietstorm.com/api/public-feed | sed -n '1,30p'
```

**Expected observations**:

- `x-cache` reverts to `Miss from cloudfront` (or `RefreshHit`)
- Response body may update (reflecting origin freshness)
- `Age` resets or absent

**Reference**: **AWS CloudFront** documentation on `x-cache` header values and caching behavior is available in the [Amazon CloudFront Developer Guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/RequestAndResponseBehaviorCustomOrigin.html) and related sections.

### Verification Steps for Non-Cacheable Endpoint (`/api/list`)

```bash
curl -i -k https://app.theinternationalquietstorm.com/api/list | sed -n '1,30p'
curl -i -k https://app.theinternationalquietstorm.com/api/list | sed -n '1,30p'
```

**Expected observations**:

- `Cache-Control: private, no-store` (or equivalent directive)
- `x-cache: Miss from cloudfront` on all requests
- No `Age` header growth or cache `Hit`
- Response body reflects current origin state on every request

**Safety implication**: Any `Hit` observed here constitutes a failure (risk of data leakage or stale sensitive data).

**Reference**: **CloudFront** respects `no-store` and `no-cache` directives when Minimum TTL is 0; see [Manage how long content stays in the cache (expiration)](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Expiration.html).

## **2. Failure Injection Challenges (“Make Them Sweat”)**

### A. Origin Forgets `Cache-Control` Header

- Temporarily remove `Cache-Control` from responses on `/api/public-feed`.
- With a managed origin-driven cache policy (e.g., `UseOriginCacheControlHeaders`), **CloudFront** should **not cache** by default (Default TTL applies only when headers are present and TTL settings allow; Minimum TTL=0 prevents unintended caching).

**Observations**:

- Persistent `Miss from cloudfront`
- Increased origin load (visible via metrics or logs)
- No `Hit` or `Age` growth

**Fix**: Restore proper `Cache-Control` headers.

**Reference**: [Understand cache policies](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cache-key-understand-cache-policy.html) and [Use managed cache policies](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html) — `UseOriginCacheControlHeaders` sets TTLs to allow origin control.

### B. Cache Fragmentation (Poor Configuration)

- Configure policy to forward unnecessary headers (e.g., `User-Agent`) into the cache key.
- Observe hit ratio drop significantly (due to fragmentation).

**Fix**: Use header whitelisting or minimal cache key; **CloudFront** provides warnings about low hit ratios when forwarding excessive headers.

**Reference**: [Cache content based on request headers](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/header-caching.html).

## **3. Student Submission Checklist (Honors)**

Submit the following artifacts:

1. **Terraform diff or configuration excerpt** showing use of the managed cache policy `UseOriginCacheControlHeaders` (or equivalent origin-driven policy) attached to the relevant cache behavior.

    - ![cloudfront-cache-policy-disabled-01.jpg](/Screenshots/cloudfront-cache-policy-disabled-01.jpg)
    - ![cloudfront-cache-policy-static-01.jpg](/Screenshots/cloudfront-cache-policy-static-01.jpg)
    - ![cloudfront-origin-rqst-policy-api-01.jpg](/Screenshots/cloudfront-origin-rqst-policy-api-01.jpg)
    - ![cloudfront-response-static-01.jpg](/Screenshots/cloudfront-response-static-01.jpg)

2. **curl evidence** (screenshots or pasted output with timestamps) demonstrating:
   - Presence of appropriate `Cache-Control` headers from origin
   - `x-cache` transitions: `Miss` → `Hit` → `Miss` (or `RefreshHit`) on the cacheable endpoint
   - Consistent `Miss` behavior on the non-cacheable (`no-store`) endpoint

   ![lab-2b-bam-a-pt1.jpg](/Screenshots/lab-2b-bam-a-pt1.jpg)
   ![lab-2b-bam-a-pt2.jpg](/Screenshots/lab-2b-bam-a-pt2.jpg)
   ![lab-2b-bam-a-pt3.jpg](/Screenshots/lab-2b-bam-a-pt3.jpg)
   ![lab-2b-bam-a-pt4.jpg](/Screenshots/lab-2b-bam-a-pt4.jpg)

3. **One-paragraph explanations** (submit exactly as follows or adapted):

   ### Why is origin-driven caching safer for APIs?

   Origin-driven caching is safer for APIs because it allows the origin server to maintain explicit and authoritative control over cache behavior through standard HTTP response headers, such as `Cache-Control`, `ETag`, and `Vary`. This ensures that only responses explicitly identified as safe, idempotent, and non-sensitive are cached at intermediate layers, such as **content delivery networks (CDNs)** or reverse proxies, while dynamic, user-specific, or authenticated content remains uncached by default. By preventing edge infrastructure from applying permissive or incorrect caching assumptions—which could lead to serving stale data, violating authorization boundaries, or exposing tenant-isolated information—this approach preserves data integrity, security, and compliance. In AWS environments, such as with **Amazon CloudFront**, cache policies and behaviors respect origin headers (e.g., `Cache-Control` directives) to determine caching eligibility, reducing risks compared to edge-driven defaults that might cache inappropriately.

   ### **References for Origin-Driven Caching**

    - [Configuring Caching](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/ConfiguringCaching.html)
    - [Cache content based on request headers](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/header-caching.html)
    - [Understand cache policies](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cache-key-understand-cache-policy.html)

   ### **When would you still disable caching entirely?**

   Caching should be disabled entirely for API endpoints involving authentication, authorization, financial transactions, identity data, personalization, session state, or compliance-regulated information (e.g., PII under GDPR, HIPAA, or PCI DSS), as even brief caching could result in data leakage, stale state propagation, or regulatory violations. This is essential for endpoints requiring strict real-time freshness, strong consistency, or per-request context dependency, where responses must bypass any shared or edge cache. In AWS, disable caching by setting appropriate origin headers (e.g., `Cache-Control: no-store, no-cache, must-revalidate`) or configuring zero TTL in services like **API Gateway** (TTL=0) and **CloudFront** (e.g., using the `CachingDisabled` managed policy or Minimum TTL=0 with no caching enabled). Such measures prevent risks in dynamic or sensitive operations, including those protected by authorizers or handling protected health/financial data.

   ### **References for Disabling Caching**

    - [Cache settings for REST APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-caching.html) **(API Gateway TTL=0)**
    - [Using managed cache policies](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html) (`CachingDisabled`)
    - [Manage how long content stays in the cache (expiration)](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Expiration.html) (`no-store`/`no-cache` handling)

---
