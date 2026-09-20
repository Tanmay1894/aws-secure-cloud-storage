import boto3
import pandas as pd
from datetime import datetime, timedelta, timezone
import time

session = boto3.Session(
    profile_name="admin",
    region_name="ap-south-1"
)

logs = session.client("logs")


def fetch_recent_events(log_group, hours=2):
    query = """
    fields @timestamp, eventName, sourceIPAddress, userIdentity.arn, userIdentity.type
    | sort @timestamp desc
    """

    now = datetime.now(timezone.utc)

    start = int((now - timedelta(hours=hours)).timestamp())
    end = int(now.timestamp())

    query_id = logs.start_query(
        logGroupName=log_group,
        startTime=start,
        endTime=end,
        queryString=query
    )["queryId"]

    while True:
        result = logs.get_query_results(queryId=query_id)

        if result["status"] == "Complete":
            break

        if result["status"] in ("Failed", "Cancelled", "Timeout"):
            raise RuntimeError(
                f"CloudWatch Logs Insights query failed: {result['status']}"
            )

        time.sleep(1)

    rows = []

    for r in result["results"]:
        row = {field["field"]: field["value"] for field in r}
        rows.append(row)

    return pd.DataFrame(rows)


def flag_anomalies(df):
    findings = []

    if df.empty:
        return ["[INFO] No CloudTrail events found in the analysis window."]

    sensitive = df[
        df["eventName"].isin(
            ["DeleteBucket", "PutBucketAcl", "DeleteObject"]
        )
    ]

    for _, row in sensitive.iterrows():
        findings.append(
            f"[HIGH] Sensitive action "
            f"{row.get('eventName')} by "
            f"{row.get('userIdentity.arn')} from "
            f"{row.get('sourceIPAddress')}"
        )

    if "sourceIPAddress" in df.columns:
        ip_counts = df.groupby("sourceIPAddress").size()

        for ip, count in ip_counts.items():
            if count > 20:
                findings.append(
                    f"[MEDIUM] High call volume from "
                    f"{ip}: {count} events in window"
                )

    return findings


if __name__ == "__main__":
    df = fetch_recent_events("/cloudtrail/cloudsec-lab")

    for finding in flag_anomalies(df):
        print(finding)