# Networking Configuration

## Create VPC

```bash
./scripts/create-vpc.sh my-vpc nyc3
```

## Setup Load Balancer

```bash
doctl compute load-balancer create \
    --name my-lb \
    --region nyc3 \
    --forwarding-rules "entry_protocol:https,entry_port:443,target_protocol:http,target_port:3000"
```
