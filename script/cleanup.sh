#!/bin/bash

# AWS Secure Cloud Storage Lab Cleanup
# Run only after all evidence and documentation have been saved.

PROFILE="admin"
REGION="ap-south-1"

DATA_BUCKET="cloudsec-lab-bucket-tanmay-01"
TRAIL_BUCKET="cloudsec-lab-trail-logs-tanmay"
TRAIL_NAME="cloudsec-lab-trail"
LOG_GROUP="/cloudtrail/cloudsec-lab"
SNS_TOPIC_ARN="arn:aws:sns:${REGION}:YOUR_ACCOUNT_ID:cloudsec-lab-alerts"

# --------------------------------------------------
# 1. Delete CloudWatch alarms
# --------------------------------------------------

aws cloudwatch delete-alarms \
  --alarm-names \
  DeleteBucketAlarm \
  PutBucketAclAlarm \
  ConsoleLoginNoMFAAlarm \
  --profile "$PROFILE"

# --------------------------------------------------
# 2. Delete CloudWatch metric filters
# --------------------------------------------------

aws logs delete-metric-filter \
  --log-group-name "$LOG_GROUP" \
  --filter-name DeleteBucketFilter \
  --profile "$PROFILE"

aws logs delete-metric-filter \
  --log-group-name "$LOG_GROUP" \
  --filter-name PutBucketAclFilter \
  --profile "$PROFILE"

aws logs delete-metric-filter \
  --log-group-name "$LOG_GROUP" \
  --filter-name ConsoleLoginNoMFAFilter \
  --profile "$PROFILE"

# --------------------------------------------------
# 3. Delete CloudWatch log group
# --------------------------------------------------

aws logs delete-log-group \
  --log-group-name "$LOG_GROUP" \
  --profile "$PROFILE"

# --------------------------------------------------
# 4. Delete SNS topic
# --------------------------------------------------

aws sns delete-topic \
  --topic-arn "$SNS_TOPIC_ARN" \
  --profile "$PROFILE"

# --------------------------------------------------
# 5. Stop and delete CloudTrail
# --------------------------------------------------

aws cloudtrail stop-logging \
  --name "$TRAIL_NAME" \
  --profile "$PROFILE"

aws cloudtrail delete-trail \
  --name "$TRAIL_NAME" \
  --profile "$PROFILE"

# --------------------------------------------------
# 6. Delete all object versions from the data bucket
# --------------------------------------------------

aws s3api delete-objects \
  --bucket "$DATA_BUCKET" \
  --delete "$(aws s3api list-object-versions \
    --bucket "$DATA_BUCKET" \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
    --profile "$PROFILE")" \
  --profile "$PROFILE"

# --------------------------------------------------
# 7. Delete the main data bucket
# --------------------------------------------------

aws s3api delete-bucket \
  --bucket "$DATA_BUCKET" \
  --profile "$PROFILE"

# --------------------------------------------------
# 8. Delete the CloudTrail log bucket
# --------------------------------------------------

aws s3 rm \
  "s3://$TRAIL_BUCKET" \
  --recursive \
  --profile "$PROFILE"

aws s3api delete-bucket \
  --bucket "$TRAIL_BUCKET" \
  --profile "$PROFILE"

# --------------------------------------------------
# 9. Delete test-user access keys and users
# --------------------------------------------------

for user in test-developer test-auditor test-unauthorized; do

    for key in $(aws iam list-access-keys \
        --user-name "$user" \
        --query 'AccessKeyMetadata[].AccessKeyId' \
        --output text \
        --profile "$PROFILE"); do

        aws iam delete-access-key \
          --user-name "$user" \
          --access-key-id "$key" \
          --profile "$PROFILE"

    done

    aws iam remove-user-from-group \
      --user-name "$user" \
      --group-name Developers \
      --profile "$PROFILE" 2>/dev/null || true

    aws iam remove-user-from-group \
      --user-name "$user" \
      --group-name Auditors \
      --profile "$PROFILE" 2>/dev/null || true

    aws iam delete-user \
      --user-name "$user" \
      --profile "$PROFILE"

done

# --------------------------------------------------
# 10. Delete IAM group policies
# --------------------------------------------------

aws iam delete-group-policy \
  --group-name Developers \
  --policy-name DevelopersS3Access \
  --profile "$PROFILE"

aws iam delete-group-policy \
  --group-name Auditors \
  --policy-name AuditorsS3ReadOnly \
  --profile "$PROFILE"

# --------------------------------------------------
# 11. Delete IAM groups
# --------------------------------------------------

aws iam delete-group \
  --group-name Developers \
  --profile "$PROFILE"

aws iam delete-group \
  --group-name Auditors \
  --profile "$PROFILE"

echo "AWS Secure Cloud Storage lab cleanup completed."