# AWS Deployment Guide for FastAPI

Complete walkthrough for deploying FastAPI applications on AWS using ECS (Elastic Container Service) and App Runner with production-grade infrastructure.

## Overview

This guide covers two AWS deployment options:

1. **AWS ECS (Fargate)** - Enterprise-grade container orchestration
2. **AWS App Runner** - Simplified container deployment

## Table of Contents

- [AWS ECS Deployment](#aws-ecs-deployment)
- [AWS App Runner Deployment](#aws-app-runner-deployment)
- [Comparison](#comparison)
- [Cost Optimization](#cost-optimization)

---

# AWS ECS Deployment

Enterprise container orchestration with load balancing, auto-scaling, and VPC networking.

## Prerequisites

- [ ] AWS account
- [ ] AWS CLI installed and configured
- [ ] Docker installed locally
- [ ] ECR repository for container images

## Architecture Overview

```
Internet → ALB → ECS Fargate Tasks → RDS PostgreSQL
                                    ↓
                                 ElastiCache Redis
                                    ↓
                                 CloudWatch Logs
```

## Step-by-Step Deployment

### 1. Install and Configure AWS CLI

```bash
# Install AWS CLI
# macOS
brew install awscli

# Linux/WSL
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure credentials
aws configure
# AWS Access Key ID: <your-access-key>
# AWS Secret Access Key: <your-secret-key>
# Default region: us-east-1
# Default output format: json
```

### 2. Create ECR Repository

```bash
# Create repository
aws ecr create-repository \
    --repository-name fastapi-app \
    --region us-east-1

# Get repository URI (save this)
ECR_URI=$(aws ecr describe-repositories \
    --repository-names fastapi-app \
    --query 'repositories[0].repositoryUri' \
    --output text)

echo "ECR URI: $ECR_URI"
```

### 3. Build and Push Docker Image

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin $ECR_URI

# Build image
docker build -t fastapi-app .

# Tag image
docker tag fastapi-app:latest $ECR_URI:latest

# Push to ECR
docker push $ECR_URI:latest
```

### 4. Create VPC and Networking

```bash
# Create VPC
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=fastapi-vpc}]' \
    --query 'Vpc.VpcId' \
    --output text)

# Create public subnets
SUBNET_1=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 \
    --availability-zone us-east-1a \
    --query 'Subnet.SubnetId' \
    --output text)

SUBNET_2=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.2.0/24 \
    --availability-zone us-east-1b \
    --query 'Subnet.SubnetId' \
    --output text)

# Create internet gateway
IGW_ID=$(aws ec2 create-internet-gateway \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

aws ec2 attach-internet-gateway \
    --vpc-id $VPC_ID \
    --internet-gateway-id $IGW_ID

# Create route table
ROUTE_TABLE=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --query 'RouteTable.RouteTableId' \
    --output text)

aws ec2 create-route \
    --route-table-id $ROUTE_TABLE \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID

# Associate subnets with route table
aws ec2 associate-route-table \
    --subnet-id $SUBNET_1 \
    --route-table-id $ROUTE_TABLE

aws ec2 associate-route-table \
    --subnet-id $SUBNET_2 \
    --route-table-id $ROUTE_TABLE
```

### 5. Create Security Groups

```bash
# ALB security group
ALB_SG=$(aws ec2 create-security-group \
    --group-name fastapi-alb-sg \
    --description "Security group for ALB" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text)

aws ec2 authorize-security-group-ingress \
    --group-id $ALB_SG \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id $ALB_SG \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

# ECS tasks security group
ECS_SG=$(aws ec2 create-security-group \
    --group-name fastapi-ecs-sg \
    --description "Security group for ECS tasks" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text)

aws ec2 authorize-security-group-ingress \
    --group-id $ECS_SG \
    --protocol tcp \
    --port 8000 \
    --source-group $ALB_SG
```

### 6. Create Application Load Balancer

```bash
# Create ALB
ALB_ARN=$(aws elbv2 create-load-balancer \
    --name fastapi-alb \
    --subnets $SUBNET_1 $SUBNET_2 \
    --security-groups $ALB_SG \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

# Create target group
TG_ARN=$(aws elbv2 create-target-group \
    --name fastapi-tg \
    --protocol HTTP \
    --port 8000 \
    --vpc-id $VPC_ID \
    --target-type ip \
    --health-check-path /health \
    --health-check-interval-seconds 30 \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

# Create listener
aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN
```

### 7. Create ECS Cluster

```bash
# Create cluster
aws ecs create-cluster \
    --cluster-name fastapi-cluster \
    --region us-east-1
```

### 8. Create Task Definition

Create `task-definition.json`:

```json
{
  "family": "fastapi-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::YOUR_ACCOUNT_ID:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "fastapi-container",
      "image": "YOUR_ECR_URI:latest",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "ENVIRONMENT",
          "value": "production"
        }
      ],
      "secrets": [
        {
          "name": "SECRET_KEY",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:YOUR_ACCOUNT_ID:secret:fastapi/secret-key"
        },
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:YOUR_ACCOUNT_ID:secret:fastapi/database-url"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/fastapi",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

Register task definition:

```bash
# Update YOUR_ACCOUNT_ID and YOUR_ECR_URI in the JSON file

# Register task
aws ecs register-task-definition \
    --cli-input-json file://task-definition.json
```

### 9. Create ECS Service

```bash
# Create service
aws ecs create-service \
    --cluster fastapi-cluster \
    --service-name fastapi-service \
    --task-definition fastapi-task \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$ECS_SG],assignPublicIp=ENABLED}" \
    --load-balancers "targetGroupArn=$TG_ARN,containerName=fastapi-container,containerPort=8000"
```

### 10. Configure Auto-Scaling

```bash
# Register scalable target
aws application-autoscaling register-scalable-target \
    --service-namespace ecs \
    --resource-id service/fastapi-cluster/fastapi-service \
    --scalable-dimension ecs:service:DesiredCount \
    --min-capacity 2 \
    --max-capacity 10

# Create scaling policy
aws application-autoscaling put-scaling-policy \
    --service-namespace ecs \
    --resource-id service/fastapi-cluster/fastapi-service \
    --scalable-dimension ecs:service:DesiredCount \
    --policy-name cpu-scaling-policy \
    --policy-type TargetTrackingScaling \
    --target-tracking-scaling-policy-configuration file://scaling-policy.json
```

Create `scaling-policy.json`:

```json
{
  "TargetValue": 75.0,
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
  },
  "ScaleInCooldown": 60,
  "ScaleOutCooldown": 60
}
```

### 11. Set Up RDS Database

```bash
# Create DB subnet group
aws rds create-db-subnet-group \
    --db-subnet-group-name fastapi-db-subnet \
    --db-subnet-group-description "Subnet group for FastAPI DB" \
    --subnet-ids $SUBNET_1 $SUBNET_2

# Create RDS instance
aws rds create-db-instance \
    --db-instance-identifier fastapi-db \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --master-username admin \
    --master-user-password <strong-password> \
    --allocated-storage 20 \
    --vpc-security-group-ids $ECS_SG \
    --db-subnet-group-name fastapi-db-subnet \
    --publicly-accessible false

# Get endpoint (after creation completes)
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier fastapi-db \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo "Database endpoint: $DB_ENDPOINT"
```

---

# AWS App Runner Deployment

Simplified container deployment with automatic scaling and load balancing.

## Prerequisites

- [ ] AWS account
- [ ] AWS CLI installed
- [ ] Docker image in ECR or public registry

## Step-by-Step Deployment

### 1. Prepare ECR Image

```bash
# Same as ECS steps 2-3 (Create ECR, build, push)
```

### 2. Create App Runner Service

Create `apprunner-config.json`:

```json
{
  "ServiceName": "fastapi-app",
  "SourceConfiguration": {
    "ImageRepository": {
      "ImageIdentifier": "YOUR_ECR_URI:latest",
      "ImageRepositoryType": "ECR",
      "ImageConfiguration": {
        "Port": "8000",
        "RuntimeEnvironmentVariables": {
          "ENVIRONMENT": "production",
          "LOG_LEVEL": "INFO"
        },
        "RuntimeEnvironmentSecrets": {
          "SECRET_KEY": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:fastapi/secret-key",
          "DATABASE_URL": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:fastapi/database-url"
        }
      }
    },
    "AutoDeploymentsEnabled": true,
    "AuthenticationConfiguration": {
      "AccessRoleArn": "arn:aws:iam::ACCOUNT_ID:role/AppRunnerECRAccessRole"
    }
  },
  "InstanceConfiguration": {
    "Cpu": "1 vCPU",
    "Memory": "2 GB",
    "InstanceRoleArn": "arn:aws:iam::ACCOUNT_ID:role/AppRunnerInstanceRole"
  },
  "HealthCheckConfiguration": {
    "Protocol": "HTTP",
    "Path": "/health",
    "Interval": 10,
    "Timeout": 5,
    "HealthyThreshold": 1,
    "UnhealthyThreshold": 5
  },
  "AutoScalingConfigurationArn": "arn:aws:apprunner:us-east-1:ACCOUNT_ID:autoscalingconfiguration/DefaultConfiguration/1/00000000000000000000000000000001"
}
```

Deploy:

```bash
# Create service
aws apprunner create-service \
    --cli-input-json file://apprunner-config.json \
    --region us-east-1

# Get service URL
aws apprunner describe-service \
    --service-arn <service-arn> \
    --query 'Service.ServiceUrl' \
    --output text
```

### 3. Configure Custom Domain

```bash
# Associate custom domain
aws apprunner associate-custom-domain \
    --service-arn <service-arn> \
    --domain-name api.yourdomain.com

# App Runner provides DNS validation records
# Add to your DNS provider
```

### 4. Configure Auto-Scaling

```bash
# Create auto-scaling config
aws apprunner create-auto-scaling-configuration \
    --auto-scaling-configuration-name fastapi-autoscaling \
    --max-concurrency 100 \
    --min-size 1 \
    --max-size 10

# Update service
aws apprunner update-service \
    --service-arn <service-arn> \
    --auto-scaling-configuration-arn <config-arn>
```

---

# Comparison

## AWS ECS vs App Runner

| Feature | ECS (Fargate) | App Runner |
|---------|--------------|------------|
| **Ease of Setup** | Complex (VPC, ALB, etc.) | Simple (managed) |
| **Control** | Full control | Limited control |
| **Networking** | Custom VPC required | Managed networking |
| **Load Balancing** | Separate ALB needed | Built-in |
| **Auto-Scaling** | Manual configuration | Automatic |
| **Cost** | $20-30/month base | $15-25/month base |
| **Best For** | Enterprise, complex apps | Simple APIs, startups |

## When to Use Each

### Use ECS When:
- Need custom VPC networking
- Require advanced load balancing
- Need service mesh (App Mesh)
- Require multi-AZ deployment control
- Need EC2 spot instances for cost savings

### Use App Runner When:
- Simple web application or API
- Want minimal operational overhead
- Don't need custom networking
- Fast deployment is priority
- Automatic scaling is sufficient

---

# Cost Optimization

## ECS Cost Breakdown

**Fargate pricing (us-east-1):**
- vCPU: $0.04048 per hour
- Memory: $0.004445 per GB per hour

**Example: 2 tasks (0.25 vCPU, 0.5 GB RAM each):**
- vCPU: 2 × 0.25 × $0.04048 × 730 hours = $14.78/month
- Memory: 2 × 0.5 × $0.004445 × 730 hours = $3.25/month
- ALB: $16.20/month (fixed)
- **Total: ~$34/month**

## App Runner Cost Breakdown

**Pricing:**
- $0.064 per GB per hour (memory)
- $0.043 per vCPU per hour (CPU)
- Additional: $0.064 per GB per hour when active

**Example: 1 vCPU, 2 GB RAM:**
- CPU: $0.043 × 730 hours = $31.39/month
- Memory: 2 × $0.064 × 730 hours = $93.44/month
- **Total: ~$125/month** (if always running)

**With auto-pause (no traffic):**
- Minimal cost when idle
- Good for development/staging

## Cost Optimization Tips

1. **Use Spot Instances (ECS):**
   ```bash
   # 70% cost savings for non-critical workloads
   --capacity-provider-strategy capacityProvider=FARGATE_SPOT,weight=1
   ```

2. **Right-size Resources:**
   - Start small (0.25 vCPU, 0.5 GB)
   - Monitor CloudWatch metrics
   - Scale as needed

3. **Use Reserved Capacity (RDS):**
   - Save up to 60% on database costs

4. **Enable Auto-Pause (App Runner):**
   - Pause when no traffic
   - Restart automatically on request

---

## Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS App Runner Documentation](https://docs.aws.amazon.com/apprunner/)
- [AWS Fargate Pricing](https://aws.amazon.com/fargate/pricing/)
- [AWS App Runner Pricing](https://aws.amazon.com/apprunner/pricing/)

---

**Deployment Time:**
- ECS: ~30-45 minutes
- App Runner: ~10-15 minutes

**Difficulty:**
- ECS: Advanced
- App Runner: Beginner-Intermediate
