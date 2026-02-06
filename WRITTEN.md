# **Lab 2B — Class Questions**

## **Incident-Style Failure Analysis**

### **Failure A — User A sees User B’s data**

- **Cause**: API caching enabled without Authorization/session token in cache key.
- **Risk**: Cross-user data leakage.
- **Fix**:
  - Disable caching for personalized endpoints (`CachingDisabled` policy).
- **Alternative**: include Authorization header in cache key (low hit ratio, higher risk).

---

### **Failure B — Random 403 after forwarding all headers**

- **Cause**: Origin receives unexpected **CloudFront**/system headers.
- **Risk**: **WAF, CSRF**, or app validation blocks requests.
- **Fix**:
  - Whitelist only required headers.
  - Separate cache policies from origin request policies.

---

### **Failure C — Cache hit ratio collapse**

- **Cause**: High-cardinality elements in cache key (headers, cookies, query strings).
- **Risk**: Cache fragmentation.
- **Fix**:
  - Minimal cache key design.
  - Forward values via origin request policy instead.
  - Monitor **CloudFront** `CacheHitRate` metrics.
  - Minimal cache key design.
  - Forward values via origin request policy instead.
  - Monitor **CloudFront** `CacheHitRate` metrics.

---

## **References**

- [**Understand the cache key**](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/understanding-the-cache-key.html)
- [**Controlling the cache key with a policy**](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/controlling-the-cache-key.html)
- [**Using managed cache policies**](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html)
- [**Controlling origin requests with a policy**](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/controlling-origin-requests.html)
- [**Understand origin request policies**](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/origin-request-understand-origin-request-policy.html)
- [**How origin request policies and cache policies work together**](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/understanding-how-origin-request-policies-and-cache-policies-work-together.html)

---
