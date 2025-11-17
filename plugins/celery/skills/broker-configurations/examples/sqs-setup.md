# Amazon SQS Broker Setup Example

Complete guide for configuring Amazon SQS as a Celery message broker with best practices for AWS integration.

## Overview

**Use when:**
- Running on AWS infrastructure (EC2, ECS, Lambda)
- Want fully managed message broker (no ops)
- Need unlimited scalability
- Prefer pay-per-use pricing model

**Benefits:**
- No infrastructure management
- Automatic scaling
- Built-in redundancy across AZs
- Pay only for what you use
- IAM-based security

**Limitations:**
- No worker remote control (celery inspect, control commands)
- No event monitoring (celery events)
- Eventual consistency (not immediate)
- FIFO queues have throughput limits (300 TPS)

## AWS Setup

### 1. IAM Policy

**celery-sqs-policy.json:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:CreateQueue",
        "sqs:DeleteQueue",
        "sqs:GetQueueUrl",
        "sqs:GetQueueAttributes",
        "sqs:SetQueueAttributes",
        "sqs:ListQueues",
        "sqs:ListQueueTags",
        "sqs:TagQueue",
        "sqs:UntagQueue"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:SendMessageBatch",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:DeleteMessageBatch",
        "sqs:ChangeMessageVisibility",
        "sqs:ChangeMessageVisibilityBatch",
        "sqs:PurgeQueue"
      ],
      "Resource": "arn:aws:sqs:*:*:celery-*"
    }
  ]
}
```

**Create IAM user and attach policy:**
```bash
# Create IAM user
aws iam create-user --user-name celery-worker

# Create policy
aws iam create-policy \
  --policy-name CelerySQSPolicy \
  --policy-document file://celery-sqs-policy.json

# Attach policy to user
aws iam attach-user-policy \
  --user-name celery-worker \
  --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/CelerySQSPolicy

# Create access key
aws iam create-access-key --user-name celery-worker
```

### 2. IAM Role for EC2/ECS (Recommended)

**celery-sqs-role.json:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Create and attach role:**
```bash
# Create role
aws iam create-role \
  --role-name CelerySQSRole \
  --assume-role-policy-document file://celery-sqs-role.json

# Attach policy to role
aws iam attach-role-policy \
  --role-name CelerySQSRole \
  --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/CelerySQSPolicy

# Create instance profile
aws iam create-instance-profile \
  --instance-profile-name CelerySQSInstanceProfile

# Add role to instance profile
aws iam add-role-to-instance-profile \
  --instance-profile-name CelerySQSInstanceProfile \
  --role-name CelerySQSRole
```

## Standard SQS Configuration

### 1. Celery Configuration (Standard Queues)

**celery_sqs.py:**
```python
import os
from celery import Celery
from kombu import Queue

# AWS Configuration
# Option 1: Use IAM role (recommended for EC2/ECS)
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')  # Leave empty for IAM role
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')

# SQS Configuration
QUEUE_PREFIX = os.getenv('SQS_QUEUE_PREFIX', 'celery-')

# Build broker URL
if AWS_ACCESS_KEY_ID:
    # Explicit credentials
    broker_url = f'sqs://{AWS_ACCESS_KEY_ID}:{AWS_SECRET_ACCESS_KEY}@'
else:
    # IAM role (recommended)
    broker_url = 'sqs://'

# Initialize Celery
app = Celery('myapp', broker=broker_url)

# SQS broker transport options
app.conf.broker_transport_options = {
    'region': AWS_REGION,
    'visibility_timeout': 3600,  # 1 hour (max time for task execution)
    'polling_interval': 1,  # Poll every 1 second (balance between latency and cost)
    'queue_name_prefix': QUEUE_PREFIX,

    # Long polling (reduces empty responses, saves costs)
    'wait_time_seconds': 10,  # Long polling wait (max 20)

    # Predefined queues (optional - auto-created if not exist)
    'predefined_queues': {
        f'{QUEUE_PREFIX}default': {
            'url': None,  # Will be auto-discovered
        },
        f'{QUEUE_PREFIX}high_priority': {
            'url': None,
        },
        f'{QUEUE_PREFIX}low_priority': {
            'url': None,
        },
    }
}

# Queue configuration
app.conf.task_queues = (
    Queue(f'{QUEUE_PREFIX}default'),
    Queue(f'{QUEUE_PREFIX}high_priority'),
    Queue(f'{QUEUE_PREFIX}low_priority'),
)

# Celery configuration optimized for SQS
app.conf.update(
    # Task routing
    task_default_queue=f'{QUEUE_PREFIX}default',
    task_default_routing_key='default',

    # Serialization
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',

    # Result backend (SQS doesn't support results - use S3, DynamoDB, or Redis)
    result_backend=os.getenv('CELERY_RESULT_BACKEND'),  # e.g., 's3://bucket-name/'
    result_expires=3600,

    # Worker settings (important for SQS)
    worker_prefetch_multiplier=1,  # CRITICAL: Set to 1 to prevent visibility timeout
    worker_max_tasks_per_child=1000,

    # Task execution
    task_acks_late=True,
    task_reject_on_worker_lost=True,

    # Time limits (must be less than visibility_timeout)
    task_time_limit=3000,  # 50 minutes
    task_soft_time_limit=2700,  # 45 minutes

    # Disable events (not supported by SQS)
    worker_send_task_events=False,
    task_send_sent_event=False,

    # Timezone
    timezone='UTC',
    enable_utc=True,
)

# Task routing
app.conf.task_routes = {
    'myapp.tasks.critical_*': {
        'queue': f'{QUEUE_PREFIX}high_priority',
    },
    'myapp.tasks.background_*': {
        'queue': f'{QUEUE_PREFIX}low_priority',
    },
}

if __name__ == '__main__':
    # Verify SQS access
    import boto3

    try:
        sqs = boto3.client('sqs', region_name=AWS_REGION)
        queues = sqs.list_queues(QueueNamePrefix=QUEUE_PREFIX)
        print("✅ SQS access configured")
        print(f"Region: {AWS_REGION}")
        print(f"Queue Prefix: {QUEUE_PREFIX}")

        if 'QueueUrls' in queues:
            print("Existing queues:")
            for url in queues['QueueUrls']:
                print(f"  - {url}")
    except Exception as e:
        print(f"❌ SQS access error: {e}")
```

## FIFO Queue Configuration

### 1. FIFO Queue Setup

**celery_sqs_fifo.py:**
```python
import os
from celery import Celery
from kombu import Queue

AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')
QUEUE_PREFIX = os.getenv('SQS_QUEUE_PREFIX', 'celery-')

# FIFO queues
broker_url = 'sqs://'
app = Celery('myapp', broker=broker_url)

# FIFO queue configuration
app.conf.broker_transport_options = {
    'region': AWS_REGION,
    'visibility_timeout': 3600,
    'polling_interval': 1,
    'queue_name_prefix': QUEUE_PREFIX,
    'wait_time_seconds': 10,
}

# Define FIFO queues
app.conf.task_queues = (
    Queue(
        f'{QUEUE_PREFIX}default.fifo',
        queue_arguments={
            'FifoQueue': 'true',
            'ContentBasedDeduplication': 'true',
        }
    ),
    Queue(
        f'{QUEUE_PREFIX}high_priority.fifo',
        queue_arguments={
            'FifoQueue': 'true',
            'ContentBasedDeduplication': 'true',
        }
    ),
)

app.conf.update(
    task_default_queue=f'{QUEUE_PREFIX}default.fifo',
    worker_prefetch_multiplier=1,
    task_acks_late=True,
    worker_send_task_events=False,
)

# Helper function for FIFO queues
def send_task_fifo(task_name, args=None, kwargs=None, message_group_id='default', **options):
    """
    Send task to FIFO queue with required MessageGroupId.

    Args:
        task_name: Task function name
        args: Task arguments
        kwargs: Task keyword arguments
        message_group_id: FIFO message group ID (for ordering)
        **options: Additional apply_async options
    """
    # FIFO queues require MessageGroupId
    options['properties'] = {
        'MessageGroupId': message_group_id,
    }

    return app.send_task(
        task_name,
        args=args or [],
        kwargs=kwargs or {},
        **options
    )


# Example usage
@app.task
def process_user_action(user_id, action):
    return f"User {user_id} action {action} processed"


# Send with message group ID (ensures ordering per user)
send_task_fifo(
    'myapp.tasks.process_user_action',
    args=[123, 'login'],
    message_group_id='user-123'
)
```

### 2. Create FIFO Queues with Terraform

**sqs-queues.tf:**
```hcl
# Standard queue
resource "aws_sqs_queue" "celery_default" {
  name                       = "celery-default"
  visibility_timeout_seconds = 3600
  message_retention_seconds  = 345600  # 4 days
  receive_wait_time_seconds  = 10      # Long polling

  tags = {
    Name        = "celery-default"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# FIFO queue
resource "aws_sqs_queue" "celery_fifo" {
  name                        = "celery-default.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = 3600
  message_retention_seconds   = 345600
  receive_wait_time_seconds   = 10

  tags = {
    Name        = "celery-default-fifo"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Dead letter queue (for failed tasks)
resource "aws_sqs_queue" "celery_dlq" {
  name                       = "celery-dlq"
  message_retention_seconds  = 1209600  # 14 days

  tags = {
    Name        = "celery-dead-letter-queue"
    Environment = "production"
  }
}

# Attach DLQ policy
resource "aws_sqs_queue_redrive_policy" "celery_default_redrive" {
  queue_url = aws_sqs_queue.celery_default.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.celery_dlq.arn
    maxReceiveCount     = 3
  })
}
```

## Environment Configuration

**.env:**
```bash
# AWS Credentials (leave empty to use IAM role)
AWS_ACCESS_KEY_ID=your_aws_access_key_here
AWS_SECRET_ACCESS_KEY=your_aws_secret_key_here
AWS_REGION=us-east-1

# SQS Configuration
SQS_QUEUE_PREFIX=celery-
USE_FIFO_QUEUES=false

# Result Backend (S3 or DynamoDB)
CELERY_RESULT_BACKEND=s3://my-celery-results/

# Or use DynamoDB
# CELERY_RESULT_BACKEND=dynamodb://
# AWS_DYNAMODB_TABLE=celery-results
```

## Result Backend Options

### Option 1: S3 Backend

```python
# Install: pip install celery[s3]
app.conf.result_backend = 's3://my-bucket-name/celery-results/'

# S3 backend options
app.conf.result_backend_transport_options = {
    'aws_access_key_id': AWS_ACCESS_KEY_ID,
    'aws_secret_access_key': AWS_SECRET_ACCESS_KEY,
    'region': AWS_REGION,
}
```

### Option 2: DynamoDB Backend

```python
# Install: pip install celery[dynamodb]
app.conf.result_backend = 'dynamodb://'

app.conf.result_backend_transport_options = {
    'table_name': 'celery-results',
    'region': AWS_REGION,
    'read_capacity_units': 5,
    'write_capacity_units': 5,
}
```

### Option 3: Redis Backend (Hybrid)

```python
# Use SQS for broker, Redis for results
app = Celery(
    'myapp',
    broker='sqs://',
    backend='redis://redis.example.com:6379/0'
)
```

## Cost Optimization

### 1. Reduce API Calls

```python
# Increase polling interval (less responsive, lower cost)
app.conf.broker_transport_options = {
    'polling_interval': 5,  # Poll every 5 seconds instead of 1
    'wait_time_seconds': 20,  # Max long polling
}
```

### 2. Batch Operations

```python
# Send multiple tasks at once
from celery import group

tasks = group(
    process_item.s(i) for i in range(100)
)
tasks.apply_async()
```

### 3. Queue Lifecycle Policies

```python
# Reduce message retention for temporary queues
app.conf.broker_transport_options = {
    'predefined_queues': {
        'celery-temporary': {
            'url': None,
            'message_retention_seconds': 3600,  # 1 hour only
        }
    }
}
```

## Monitoring

### CloudWatch Metrics

```python
import boto3

cloudwatch = boto3.client('cloudwatch', region_name='us-east-1')

# Get queue metrics
response = cloudwatch.get_metric_statistics(
    Namespace='AWS/SQS',
    MetricName='ApproximateNumberOfMessagesVisible',
    Dimensions=[
        {'Name': 'QueueName', 'Value': 'celery-default'},
    ],
    StartTime=datetime.utcnow() - timedelta(hours=1),
    EndTime=datetime.utcnow(),
    Period=300,
    Statistics=['Average', 'Maximum'],
)

print(response['Datapoints'])
```

### Key Metrics to Monitor

- `ApproximateNumberOfMessagesVisible`: Queue backlog
- `ApproximateNumberOfMessagesDelayed`: Delayed messages
- `ApproximateNumberOfMessagesNotVisible`: In-flight messages
- `NumberOfMessagesSent`: Task creation rate
- `NumberOfMessagesReceived`: Task consumption rate
- `NumberOfEmptyReceives`: Efficiency (should be low with long polling)

## Troubleshooting

### Tasks disappearing without processing

- Check `visibility_timeout` > task execution time
- Verify `worker_prefetch_multiplier=1`
- Check for worker crashes (enable error logging)

### High SQS costs

- Increase `polling_interval`
- Enable long polling (`wait_time_seconds`)
- Reduce unnecessary queue checks
- Use batch operations

### FIFO queue throughput limit

- FIFO queues limited to 300 TPS (or 3000 with batching)
- Use multiple message groups for parallelism
- Consider standard queues for high throughput

## Security Best Practices

- Use IAM roles instead of access keys (when on AWS)
- Enable encryption at rest (SSE-SQS)
- Use VPC endpoints to keep traffic private
- Implement least-privilege IAM policies
- Enable CloudTrail logging for audit
- Rotate access keys regularly
- Use separate queues per environment

## References

- Celery SQS: https://docs.celeryq.dev/en/stable/getting-started/backends-and-brokers/sqs.html
- AWS SQS: https://docs.aws.amazon.com/sqs/
- SQS FIFO: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html
- IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
