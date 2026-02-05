# Lab 2B – Be A Man Challenge C (Honors++)

---

## **Purpose (One-Sentence Learning Objective)**

This lab demonstrates that a CDN can **revalidate cached objects using conditional requests (ETag / Last-Modified)** instead of fully refetching them, producing `RefreshHit` behavior that saves bandwidth while preserving freshness.

---

## **Mental Model**

CloudFront cache outcomes:

| `x-cache` value              | Meaning                                                                                |
| ---------------------------- | -------------------------------------------------------------------------------------- |
| `Hit from cloudfront`        | Served entirely from edge cache                                                        |
| `Miss from cloudfront`       | Fetched fully from origin                                                              |
| `RefreshHit from cloudfront` | Cached object existed, TTL expired, CloudFront revalidated with origin and reused body |
| `Error from cloudfront`      | Edge or origin failure                                                                 |

**Key insight:**
`RefreshHit` means CloudFront **did contact the origin**, but used conditional headers (`If-None-Match`, `If-Modified-Since`). The origin returned **304 Not Modified**, so the cached body was reused instead of downloading the full object again.

**Tradeoff:**

* Lower bandwidth than a Miss
* Slightly higher latency than a Hit
* Correctness preserved

---

## **Architecture Context**

* **Viewer:** Browser / curl client
* **CDN:** AWS CloudFront
* **Origin:** ALB → EC2 Apache web server
* **Path under test:** `/static/index.html`

---

## **Challenge C Requirements**

### **Origin Requirements**

The `/static/index.html` endpoint must:

* Be cacheable
* Send validators:

  * `ETag`
  * `Last-Modified`
* Send cache headers:

  * `Cache-Control: public, max-age=5, s-maxage=5`

### **CloudFront Requirements**

* `/static/*` behavior configured
* CDN caching enabled
* Cache policy supports revalidation
* Distribution deployed and serving traffic

---

## **Final CloudFront Configuration**

### **Cache Behavior**

Path: `/static/*`

* Cache Policy: **Managed-CachingOptimized** *(used for deterministic demo behavior)*
* Origin Request Policy: static policy
* Methods: `GET`, `HEAD`
* Cached Methods: `GET`, `HEAD`

> Note: UseOriginCacheControlHeaders can also be used for strict origin-driven caching, but Managed-CachingOptimized provides more consistent revalidation behavior for demonstration and grading.

---

## **Origin Configuration**

### **File Location**

```bash
/var/www/html/static/index.html
```

### **Headers provided by Apache**

```plaintext
Cache-Control: public, max-age=5, s-maxage=5
ETag: "tiqs-v1"
Last-Modified: Sat, 24 Jan 2026 23:12:54 GMT
```

---

## **Verification Steps**

### Step 1 – Prime Cache (Cold Start)

```bash
curl -sS -D - -o /dev/null -k https://app.theinternationalquietstorm.com/static/index.html \
| egrep -i '^(x-cache:|age:|etag:|last-modified:|cache-control:|x-amz-cf-pop:)'
```

**Expected:**

```plaintext
X-Cache: Miss from cloudfront
```

![lab-2b-bam-c-pt1.jpg](/Screenshots/lab-2b-bam-c-pt1.jpg)

---

### Step 2 – Confirm Edge Cache Hit

```bash
curl -sS -D - -o /dev/null -k https://app.theinternationalquietstorm.com/static/index.html \
| egrep -i '^(x-cache:|age:|etag:|last-modified:|cache-control:|x-amz-cf-pop:)'
```

**Expected:**

```plaintext
X-Cache: Hit from cloudfront
Age: 8
```

![lab-2b-bam-c-pt2.jpg](/Screenshots/lab-2b-bam-c-pt2.jpg)

---

### Step 3 – TTL Expiry Revalidation

```bash
sleep 31
curl -sS -D - -o /dev/null -k https://app.theinternationalquietstorm.com/static/index.html \
| egrep -i '^(x-cache:|age:|etag:|last-modified:|cache-control:)'
```

**Expected:**

```plaintext
X-Cache: RefreshHit from cloudfront
```

![lab-2b-bam-c-pt3.jpg](/Screenshots/lab-2b-bam-c-pt3.jpg)

---

### Step 4 – Forced Conditional Revalidation

```bash
curl -sS -D - -o /dev/null -k \
  -H "Cache-Control: no-cache" \
  https://app.theinternationalquietstorm.com/static/index.html \
| egrep -i '^(x-cache:|age:|etag:|last-modified:|cache-control:)'
```

**Expected:**

```plaintext
X-Cache: RefreshHit from cloudfront
```

---

## Evidence Collected

| Proof Type         | Evidence                                    |
| ------------------ | ------------------------------------------- |
| Validator presence | `ETag`, `Last-Modified` headers             |
| Edge caching       | `Hit from cloudfront` with `Age`            |
| Revalidation       | `RefreshHit from cloudfront`                |
| Conditional flow   | TTL expiry + no-cache triggers revalidation |

---

## **Failure Injection Analysis**

### Injection A – Short TTL

```plaintext
Cache-Control: public, max-age=5
ETag: "tiqs-v1"
```

**Observed:**

* Frequent revalidation
* `RefreshHit` after TTL expiry

---

### Injection B – Stale Validator Scenario

Condition:

* Content changes
* Validator unchanged (`ETag` not updated)

**Observed behavior:**

* CloudFront continues receiving `304`
* Cached stale content persists
* `RefreshHit` continues

---

## **Fix Strategies**

| Fix                    | Use Case                     |
| ---------------------- | ---------------------------- |
| Update `ETag`          | Correct fix                  |
| Update `Last-Modified` | Acceptable                   |
| Invalidate object      | Emergency only               |
| Increase TTL           | Only if content truly static |

---

## **Controlled Invalidation**

```bash
aws cloudfront create-invalidation \
  --distribution-id E3NWFUTJ8T6OVO \
  --invalidation-batch "{\
    \"Paths\": {\"Quantity\": 1, \"Items\": [\"/static/index.html\"]},\
    \"CallerReference\": \"manual-$(date +%s)\"\
  }"
```

**Explanation:**

* Invalidation forces cache purge
* Works immediately
* Not preferred for normal updates
* Proper validator updates are the correct long-term fix

---

## **Log Interpretation**

### CloudFront

* `x-cache: RefreshHit from cloudfront`

### Origin

* Conditional requests
* `304 Not Modified`

---

## **Engineering Interpretation**

**`RefreshHit` is not a bug.**
It is correct CDN behavior:

* Cache exists
* TTL expired
* CDN validates freshness
* Origin confirms unchanged
* Cached body reused

This pattern:

* Reduces bandwidth
* Reduces origin load
* Preserves data correctness
* Improves scalability

---

## Final Takeaway (Deliverable)

`RefreshHit` in Amazon CloudFront indicates that a requested object was present in the edge cache but its time-to-live (TTL) had expired, prompting CloudFront to issue a conditional GET request to the origin server using validators such as ETag (via If-None-Match) or Last-Modified (via If-Modified-Since). When the origin responds with a 304 Not Modified status, CloudFront reuses the existing cached object body without transferring the full content again. This outcome is frequently superior to a cache Miss because it maintains the same level of freshness and correctness as a complete origin fetch while significantly reducing bandwidth consumption and origin server load by avoiding the transfer of the full payload; the primary tradeoff is a modest increase in latency due to the revalidation round-trip, which remains substantially faster and less resource-intensive than retrieving and transmitting the entire object in a Miss scenario.

### **Documentation**

* [**Amazon CloudFront Developer Guide, “Standard logging reference”**](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/standard-logs-reference.html)  
  Defines `RefreshHit` as: “The server found the object in the cache but the object had expired, so the server fetched the object from the origin using a conditional GET request. The origin returned a 304 status code (Not Modified), so CloudFront served the object to the viewer from the cache.”

* [**Amazon CloudFront Developer Guide, “View CloudFront cache statistics reports”**](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cache-statistics.html)  
  (Describes refresh hits in the context of cache performance metrics and associates them with the x-edge-response-result-type field value of `RefreshHit` in access logs.)

---

## **References**

* [AWS CloudFront Cache Behavior Documentation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/CacheBehaviors.html)
* [AWS CloudFront Caching Optimized Policy](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/ConfiguringCaching.html)
* [HTTP Caching - MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching)
* [AWS CloudFront Invalidation API](https://docs.aws.amazon.com/cli/latest/reference/cloudfront/create-invalidation.html)

---
