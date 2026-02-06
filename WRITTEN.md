# Armageddon – Lab 2B (BAM II Honors)

## Written Explanation

### **Why origin-driven caching is safer for API's?**

Origin-driven caching is safer for APIs because it places full control of cache behavior in the hands of the application rather than the **CDN.** By requiring **CloudFront** to honor `Cache-Control` headers returned by the origin, the API explicitly declares which responses may be cached, for how long, and under what conditions. This prevents accidental caching of sensitive or user-specific data, avoids stale reads after writes, and eliminates cross-user data leakage. In this lab, `/api/public-feed` is intentionally marked as cacheable using `Cache-Control: public, s-maxage=30`, allowing **CloudFront** to cache responses safely for a short period while still ensuring correctness. If the origin omits or removes cache headers, **CloudFront** automatically defaults to not caching, which is the safest possible behavior for dynamic systems.

### **When caching should be disabled entirely?**

Caching should be disabled entirely for API's that return private, authenticated, or rapidly changing data. Endpoints such as user dashboards, account lists, inventory updates, or transactional responses must always reflect the current state at the origin. In these cases, headers like `Cache-Control: private, no-store` ensure that no intermediary — including **CloudFront** — stores or reuses responses. In this lab, `/api/list` demonstrates this pattern by disabling caching entirely, guaranteeing that every request reaches the origin. If **CloudFront** ever returned a cache hit for this endpoint, it would represent a serious security failure and potential data leak, which is why disabling caching is mandatory for such paths.
