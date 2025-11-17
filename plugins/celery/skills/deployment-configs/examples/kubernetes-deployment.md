# Production Kubernetes Deployment Example

Complete guide for deploying Celery to Kubernetes with autoscaling, monitoring, and high availability.

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                  Kubernetes Cluster              │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌────────────┐  ┌────────────┐  ┌───────────┐ │
│  │  Worker    │  │  Worker    │  │  Worker   │ │
│  │  Pod 1     │  │  Pod 2     │  │  Pod 3    │ │
│  └────────────┘  └────────────┘  └───────────┘ │
│        ▲              ▲               ▲          │
│        └──────────────┴───────────────┘          │
│                       │                          │
│                  ┌────▼─────┐                    │
│                  │  Redis   │                    │
│                  │ Sentinel │                    │
│                  └──────────┘                    │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │  Beat Scheduler (StatefulSet - 1 pod)    │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │  PostgreSQL (StatefulSet)                │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │  Horizontal Pod Autoscaler (2-50 pods)   │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

## Prerequisites

- Kubernetes cluster (1.24+)
- kubectl configured
- Helm 3+ (optional, for charts)
- Docker registry access
- Persistent storage (StorageClass)

## Step 1: Build and Push Worker Image

```bash
# Build worker image
docker build -f Dockerfile.worker -t your-registry/celery-worker:v1.0.0 .

# Test locally
docker run --rm your-registry/celery-worker:v1.0.0 celery --version

# Push to registry
docker push your-registry/celery-worker:v1.0.0

# Tag as latest
docker tag your-registry/celery-worker:v1.0.0 your-registry/celery-worker:latest
docker push your-registry/celery-worker:latest
```

## Step 2: Create Namespace

```bash
# Create production namespace
kubectl create namespace celery-prod

# Set as default (optional)
kubectl config set-context --current --namespace=celery-prod

# Verify
kubectl get namespace celery-prod
```

## Step 3: Configure Secrets

```bash
# Create secrets for sensitive data
kubectl create secret generic celery-secrets \
  --from-literal=broker-url='redis://redis-service:6379/0' \
  --from-literal=result-backend-url='db+postgresql://celery:your_password_here@postgres-service:5432/celery_results' \
  -n celery-prod

# Verify (values are base64 encoded)
kubectl get secret celery-secrets -n celery-prod -o yaml
```

## Step 4: Create ConfigMap

```bash
# Create configmap.yaml
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: celery-config
  namespace: celery-prod
data:
  app-env: "production"
  log-level: "info"
  worker-concurrency: "4"
  max-tasks-per-child: "1000"
EOF

# Verify
kubectl get configmap celery-config -n celery-prod -o yaml
```

## Step 5: Deploy Redis (Broker)

For production, use Redis Sentinel or managed service (AWS ElastiCache).

Simple deployment for testing:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: celery-prod
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: celery-prod
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
EOF
```

## Step 6: Deploy PostgreSQL (Result Backend)

For production, use managed service (RDS, Cloud SQL).

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: celery-prod
spec:
  serviceName: postgres-service
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_DB
          value: "celery_results"
        - name: POSTGRES_USER
          value: "celery"
        - name: POSTGRES_PASSWORD
          value: "your_password_here"  # Use Secret in production!
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: celery-prod
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  clusterIP: None
EOF
```

## Step 7: Deploy Celery Workers

```bash
# Generate and apply worker manifests
./scripts/deploy.sh kubernetes --namespace=celery-prod --replicas=3

# Or apply manually
kubectl apply -f templates/kubernetes/celery-worker.yaml -n celery-prod

# Verify deployment
kubectl get deployment celery-worker -n celery-prod

# Check pods
kubectl get pods -n celery-prod -l app=celery-worker

# View logs
kubectl logs -f deployment/celery-worker -n celery-prod
```

## Step 8: Deploy Beat Scheduler

```bash
# Apply beat manifest
kubectl apply -f templates/kubernetes/celery-beat.yaml -n celery-prod

# Verify StatefulSet
kubectl get statefulset celery-beat -n celery-prod

# Check pod
kubectl get pod celery-beat-0 -n celery-prod

# View logs
kubectl logs -f celery-beat-0 -n celery-prod
```

## Step 9: Configure Autoscaling

The HPA manifest is included in celery-worker.yaml. Verify:

```bash
# Check HPA status
kubectl get hpa celery-worker-hpa -n celery-prod

# Describe HPA
kubectl describe hpa celery-worker-hpa -n celery-prod

# Watch autoscaling in action
kubectl get hpa celery-worker-hpa -n celery-prod --watch
```

## Step 10: Test Deployment

```bash
# Run test suite
./scripts/test-deployment.sh kubernetes --namespace=celery-prod

# Manual verification
kubectl exec -n celery-prod deployment/celery-worker -- celery -A myapp inspect ping

# Submit test task
kubectl exec -n celery-prod deployment/celery-worker -- python -c "
from celery import Celery
app = Celery('myapp')
app.config_from_object('celeryconfig')
result = app.send_task('test_task', args=[1, 2])
print(f'Task ID: {result.id}')
print(f'Result: {result.get(timeout=10)}')
"
```

## Monitoring

### View Logs

```bash
# Stream worker logs
kubectl logs -f deployment/celery-worker -n celery-prod

# Stream beat logs
kubectl logs -f celery-beat-0 -n celery-prod

# All celery pods
kubectl logs -l app=celery-worker -n celery-prod --tail=100

# Previous pod logs (after crash)
kubectl logs celery-worker-abc123-xyz --previous -n celery-prod
```

### Check Resource Usage

```bash
# Top pods
kubectl top pods -n celery-prod

# Top nodes
kubectl top nodes

# Detailed metrics
kubectl describe pod celery-worker-abc123-xyz -n celery-prod
```

### View Events

```bash
# Recent events
kubectl get events -n celery-prod --sort-by='.lastTimestamp'

# Watch events
kubectl get events -n celery-prod --watch
```

## Scaling Operations

### Manual Scaling

```bash
# Scale to 10 workers
kubectl scale deployment celery-worker --replicas=10 -n celery-prod

# Verify scaling
kubectl get pods -n celery-prod -l app=celery-worker --watch
```

### Adjust HPA

```bash
# Edit HPA
kubectl edit hpa celery-worker-hpa -n celery-prod

# Or patch
kubectl patch hpa celery-worker-hpa -n celery-prod -p '{"spec":{"maxReplicas":100}}'
```

## Rolling Updates

```bash
# Update worker image
kubectl set image deployment/celery-worker \
  celery-worker=your-registry/celery-worker:v1.1.0 \
  -n celery-prod

# Watch rollout
kubectl rollout status deployment/celery-worker -n celery-prod

# View rollout history
kubectl rollout history deployment/celery-worker -n celery-prod

# Rollback if needed
kubectl rollout undo deployment/celery-worker -n celery-prod
```

## High Availability Configuration

### Pod Disruption Budget

Ensure minimum availability during maintenance:

```bash
kubectl apply -f - <<EOF
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: celery-worker-pdb
  namespace: celery-prod
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: celery-worker
EOF
```

### Node Affinity

Distribute workers across availability zones:

```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - celery-worker
      topologyKey: topology.kubernetes.io/zone
```

## Troubleshooting

### Pods Not Starting

```bash
# Describe pod
kubectl describe pod celery-worker-abc123-xyz -n celery-prod

# Common issues:
# - ImagePullBackOff: Check registry credentials
# - CrashLoopBackOff: Check application logs
# - Pending: Check resource constraints
```

### Worker Not Connecting

```bash
# Check secrets
kubectl get secret celery-secrets -n celery-prod -o jsonpath='{.data.broker-url}' | base64 -d

# Test broker connectivity
kubectl run -it --rm debug --image=redis:alpine --restart=Never -n celery-prod -- redis-cli -h redis-service ping

# Check logs
kubectl logs -f deployment/celery-worker -n celery-prod | grep -i "error\|connection"
```

### High CPU/Memory

```bash
# Check resource usage
kubectl top pods -n celery-prod

# Adjust resource limits
kubectl edit deployment celery-worker -n celery-prod

# Reduce concurrency
kubectl set env deployment/celery-worker CELERY_WORKER_CONCURRENCY=2 -n celery-prod
```

## Production Checklist

- [ ] Use managed Redis (ElastiCache, MemoryStore)
- [ ] Use managed PostgreSQL (RDS, Cloud SQL)
- [ ] Configure proper resource limits
- [ ] Set up HPA with custom metrics (queue depth)
- [ ] Implement Pod Disruption Budgets
- [ ] Configure node affinity for HA
- [ ] Set up monitoring (Prometheus, Grafana)
- [ ] Configure log aggregation (ELK, Loki)
- [ ] Implement network policies
- [ ] Use RBAC for security
- [ ] Regular backup of result backend
- [ ] Test disaster recovery procedures

## Cleanup

```bash
# Delete deployment
kubectl delete deployment celery-worker -n celery-prod
kubectl delete statefulset celery-beat -n celery-prod

# Delete services
kubectl delete service celery-worker-service redis-service postgres-service -n celery-prod

# Delete entire namespace (WARNING: deletes everything)
kubectl delete namespace celery-prod
```
