import json
import boto3
import os
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setlevel(logging.INFO)

ec2 = boto3.client("ec2")
sns = boto3.client("sns")

INSTANCE_ID = os.environ.get("INSTANCE_ID")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")

def lambda_handler(event, context):
    logger.info("received event: %s", json.dumps(event))
    if not INSTANCE_ID or not SNS_TOPIC_ARN:
        raise Exception("Missing INSTANCE_ID or SNS_TOPIC_ARN environment variables")

    ec2.reboor_instances(InstanceIds=[INSTANCE_ID])

    message = {
        "action": "EC2 reboot triggered",
        "instance_id": INSTANCE_ID,
        "time": datetime.utcnow().isoformat() + "Z",
        "reason": "Sumo logic alert  slow /api/data response time > 3s"
    }
    logger.info("reboot initiated for %s", INSTANCE_ID)

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject="Ec2 restart triggered by sumo alert",
        Message= json.dumps(message, indent=2)
    )

    return {
        "StatusCode": 200,
        "body": json.dumps({"message": "reboot is triggered and sns notification sent"})
    }