# Security Validation Matrix

This document records the validation tests performed against the AWS Secure Cloud Storage environment.

## 1. IAM Least-Privilege Validation

| Test | Expected Result | Actual Result | Status |
|---|---|---|---|
| Developer: List bucket | Allowed | Allowed | PASS |
| Developer: Get object | Allowed | Allowed | PASS |
| Developer: Put object | Allowed | Allowed | PASS |
| Auditor: List bucket | Allowed | Allowed | PASS |
| Auditor: Get object | Allowed | Allowed | PASS |
| Auditor: Put object | Denied | AccessDenied | PASS |
| Unauthorized user: List bucket | Denied | AccessDenied | PASS |

## 2. S3 Security Validation

| Test | Expected Result | Actual Result | Status |
|---|---|---|---|
| Attempt to make bucket public using `PutBucketAcl` | Denied | AccessDenied | PASS |
| HTTP request to S3 bucket | Denied | HTTP 403 Forbidden | PASS |
| Uploaded object encryption | AES256 | AES256 confirmed | PASS |
| S3 versioning | Version retained | Version ID confirmed | PASS |

## 3. Detection & Alerting Validation

| Scenario | Detection | Expected Result | Actual Result | Status |
|---|---|---|---|---|
| Temporary bucket deletion | `DeleteBucketFilter` → `DeleteBucketAlarm` | Alarm triggered | ALARM | PASS |
| Public ACL modification attempt | `PutBucketAclFilter` → `PutBucketAclAlarm` | Alarm triggered | ALARM | PASS |
| Console login without MFA | `ConsoleLoginNoMFAFilter` → `ConsoleLoginNoMFAAlarm` | Alarm triggered | ALARM | PASS |

## 4. SNS Notification Validation

| Alarm | Expected Result | Actual Result | Status |
|---|---|---|---|
| `DeleteBucketAlarm` | SNS email received | Email received | PASS |
| `PutBucketAclAlarm` | SNS email received | Email received | PASS |
| `ConsoleLoginNoMFAAlarm` | SNS email received | Email received | PASS |

## 5. Python Analyzer Validation

| Test | Expected Result | Actual Result | Status |
|---|---|---|---|
| Sensitive API activity | `[HIGH]` finding generated | `DeleteObject`, `PutBucketAcl`, and `DeleteBucket` detected | PASS |
| High API-call volume from one IP | `[MEDIUM]` finding generated when threshold is exceeded | 27 events from one IP detected | PASS |

## Overall Result

All implemented security controls and detection scenarios were successfully validated in the lab environment.

The tests demonstrated:
- IAM least-privilege enforcement
- S3 public-access protection
- HTTPS-only access
- Server-side encryption
- S3 versioning
- CloudTrail monitoring
- CloudWatch detection
- SNS alerting
- Python-based log analysis