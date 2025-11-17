# Systemd Deployment Example

Complete guide for deploying Celery workers and beat scheduler on traditional servers using systemd.

## Scenario

Deploy Celery to multiple Ubuntu 22.04 servers with:
- 4 worker instances per server
- 1 beat scheduler (single server)
- Systemd service management
- Automatic restart on failure
- Log management via journald

## Prerequisites

- Ubuntu 22.04 or similar systemd-based Linux
- Python 3.9+
- Redis server (local or remote)
- PostgreSQL (local or remote)
- Root/sudo access

## Architecture

```
Server 1 (app-server-01):
├── celery-worker@1.service
├── celery-worker@2.service
├── celery-worker@3.service
├── celery-worker@4.service
└── celery-beat.service (primary)

Server 2 (app-server-02):
├── celery-worker@1.service
├── celery-worker@2.service
├── celery-worker@3.service
└── celery-worker@4.service

Server 3 (app-server-03):
├── celery-worker@1.service
├── celery-worker@2.service
├── celery-worker@3.service
└── celery-worker@4.service
```

## Step 1: System Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y python3 python3-pip python3-venv \
    redis-tools postgresql-client build-essential \
    libpq-dev

# Create celery user
sudo useradd -m -s /bin/bash celery
sudo usermod -aG sudo celery  # Optional: if celery needs sudo
```

## Step 2: Application Setup

```bash
# Create application directory
sudo mkdir -p /opt/celery
sudo chown celery:celery /opt/celery

# Create log directory
sudo mkdir -p /var/log/celery
sudo chown celery:celery /var/log/celery

# Create pid directory
sudo mkdir -p /var/run/celery
sudo chown celery:celery /var/run/celery

# Create beat schedule directory
sudo mkdir -p /var/lib/celery
sudo chown celery:celery /var/lib/celery

# Switch to celery user
sudo su - celery

# Navigate to app directory
cd /opt/celery

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Celery and dependencies
pip install --upgrade pip
pip install celery[redis,postgresql] psycopg2-binary

# Copy your application code
# (using git, rsync, or other deployment method)
git clone https://github.com/your-org/your-celery-app.git .
pip install -r requirements.txt

# Test Celery can import
celery -A myapp worker --version
```

## Step 3: Configuration Files

Create `/etc/celery/celery.conf`:

```bash
sudo mkdir -p /etc/celery
sudo tee /etc/celery/celery.conf > /dev/null <<EOF
# Celery Configuration

# Application
CELERY_APP="myapp"

# Python path
PYTHONPATH="/opt/celery"

# Concurrency
CELERYD_CONCURRENCY=4
CELERYD_MAX_TASKS_PER_CHILD=1000

# Log level
CELERYD_LOG_LEVEL="INFO"

# Options
CELERYD_OPTS="--time-limit=300 --soft-time-limit=240"

# Beat options
CELERYBEAT_OPTS="--scheduler=django_celery_beat.schedulers:DatabaseScheduler"
EOF
```

Create `/etc/celery/secrets.env` (mode 0600):

```bash
sudo tee /etc/celery/secrets.env > /dev/null <<EOF
# Broker and Backend (NEVER commit these!)
CELERY_BROKER_URL=redis://your-redis-host:6379/0
CELERY_RESULT_BACKEND=db+postgresql://celery:your_password_here@your-postgres-host:5432/celery_results

# Application secrets
DATABASE_URL=postgresql://app:your_app_password_here@your-postgres-host:5432/appdb
API_KEY=your_api_key_here
EOF

# Secure secrets file
sudo chmod 600 /etc/celery/secrets.env
sudo chown celery:celery /etc/celery/secrets.env
```

## Step 4: Install Systemd Service Files

```bash
# Copy worker service template
sudo cp templates/systemd/celery-worker.service /etc/systemd/system/

# Copy beat service template
sudo cp templates/systemd/celery-beat.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Verify service files
systemctl cat celery-worker@1.service
systemctl cat celery-beat.service
```

## Step 5: Enable and Start Workers

```bash
# Enable workers (start on boot)
for i in {1..4}; do
    sudo systemctl enable celery-worker@${i}.service
done

# Start all workers
for i in {1..4}; do
    sudo systemctl start celery-worker@${i}.service
done

# Check status
sudo systemctl status celery-worker@{1..4}.service

# Should see "active (running)" for all
```

## Step 6: Enable and Start Beat (Primary Server Only)

```bash
# Enable beat scheduler
sudo systemctl enable celery-beat.service

# Start beat
sudo systemctl start celery-beat.service

# Check status
sudo systemctl status celery-beat.service

# Should see "active (running)"
```

## Step 7: Verify Deployment

```bash
# Check all services
systemctl list-units "celery-*" --all

# Test worker connectivity
sudo -u celery /opt/celery/venv/bin/celery -A myapp inspect ping

# Expected output:
# -> worker1@app-server-01: OK
# -> worker2@app-server-01: OK
# -> worker3@app-server-01: OK
# -> worker4@app-server-01: OK

# Check worker stats
sudo -u celery /opt/celery/venv/bin/celery -A myapp inspect stats

# View logs
sudo journalctl -u celery-worker@1.service -f
```

## Step 8: Submit Test Task

```bash
# As celery user
sudo su - celery
cd /opt/celery
source venv/bin/activate

# Python shell
python <<EOF
from celery import Celery
app = Celery('myapp')
app.config_from_object('celeryconfig')

# Submit test task
result = app.send_task('myapp.tasks.add', args=[5, 10])
print(f"Task ID: {result.id}")
print(f"Result: {result.get(timeout=10)}")
EOF
```

## Monitoring

### View Logs

```bash
# Real-time logs for specific worker
sudo journalctl -u celery-worker@1.service -f

# All workers
sudo journalctl -u "celery-worker@*" -f

# Beat scheduler
sudo journalctl -u celery-beat.service -f

# Last 100 lines
sudo journalctl -u celery-worker@1.service -n 100

# Since specific time
sudo journalctl -u celery-worker@1.service --since "1 hour ago"

# With timestamps
sudo journalctl -u celery-worker@1.service -f -o short-iso
```

### Check Service Status

```bash
# All celery services
systemctl list-units "celery-*"

# Detailed status
systemctl status celery-worker@1.service

# Check if enabled
systemctl is-enabled celery-worker@1.service

# Check if active
systemctl is-active celery-worker@1.service
```

### Resource Usage

```bash
# CPU and memory usage
systemctl status celery-worker@1.service | grep -A 5 "Memory\|CPU"

# Detailed cgroup stats
systemctl show celery-worker@1.service --property=CPUUsageNSec --property=MemoryCurrent

# All worker processes
ps aux | grep celery
```

## Service Management

### Restart Services

```bash
# Restart single worker
sudo systemctl restart celery-worker@1.service

# Restart all workers
for i in {1..4}; do
    sudo systemctl restart celery-worker@${i}.service
done

# Restart beat
sudo systemctl restart celery-beat.service

# Reload configuration
sudo systemctl reload celery-worker@1.service
```

### Stop Services

```bash
# Stop single worker
sudo systemctl stop celery-worker@1.service

# Stop all workers
for i in {1..4}; do
    sudo systemctl stop celery-worker@${i}.service
done

# Stop beat
sudo systemctl stop celery-beat.service
```

### Disable Services

```bash
# Disable worker (won't start on boot)
sudo systemctl disable celery-worker@1.service

# Disable all
for i in {1..4}; do
    sudo systemctl disable celery-worker@${i}.service
done
```

## Rolling Restart (Zero Downtime)

```bash
# Restart workers one by one
for i in {1..4}; do
    echo "Restarting worker $i..."
    sudo systemctl restart celery-worker@${i}.service

    # Wait for worker to be ready
    sleep 30

    # Verify worker is healthy
    sudo -u celery /opt/celery/venv/bin/celery -A myapp inspect ping | grep "worker${i}"

    if [ $? -eq 0 ]; then
        echo "Worker $i restarted successfully"
    else
        echo "ERROR: Worker $i failed to restart"
        exit 1
    fi
done

echo "Rolling restart completed successfully"
```

## Application Updates

```bash
# Stop all workers
for i in {1..4}; do sudo systemctl stop celery-worker@${i}.service; done
sudo systemctl stop celery-beat.service

# Update application code
sudo su - celery
cd /opt/celery
git pull origin main

# Update dependencies
source venv/bin/activate
pip install -r requirements.txt

# Run migrations (if applicable)
python manage.py migrate

# Start services
exit  # Back to sudo user
for i in {1..4}; do sudo systemctl start celery-worker@${i}.service; done
sudo systemctl start celery-beat.service

# Verify
systemctl status celery-worker@{1..4}.service
systemctl status celery-beat.service
```

## Troubleshooting

### Service Won't Start

```bash
# Check detailed logs
sudo journalctl -u celery-worker@1.service -xe

# Check service file syntax
systemctl cat celery-worker@1.service

# Test command manually
sudo -u celery /opt/celery/venv/bin/celery -A myapp worker --loglevel=debug

# Common issues:
# - Wrong user/group
# - Missing environment variables
# - Import errors
# - Permission issues
```

### Workers Not Registering

```bash
# Check broker connectivity
redis-cli -h your-redis-host ping

# Test from celery user
sudo -u celery /opt/celery/venv/bin/celery -A myapp inspect ping

# Check logs for connection errors
sudo journalctl -u celery-worker@1.service | grep -i "error\|connection"
```

### High Memory Usage

```bash
# Check current usage
systemctl status celery-worker@1.service | grep Memory

# Reduce concurrency
sudo vi /etc/celery/celery.conf
# Change: CELERYD_CONCURRENCY=2

# Add max-tasks-per-child
# Add to CELERYD_OPTS: --max-tasks-per-child=100

# Restart
sudo systemctl restart celery-worker@1.service
```

### Service Crashes

```bash
# View crash logs
sudo journalctl -u celery-worker@1.service --since today | grep -i "killed\|segfault\|error"

# Check for OOM kills
sudo dmesg | grep -i "out of memory"

# Check system resources
free -h
df -h

# Adjust resource limits in service file
sudo systemctl edit celery-worker@1.service

# Add:
[Service]
MemoryLimit=2G
CPUQuota=150%

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart celery-worker@1.service
```

## Multi-Server Management with Ansible

Create `inventory.ini`:

```ini
[celery_workers]
app-server-01 ansible_host=10.0.1.10
app-server-02 ansible_host=10.0.1.11
app-server-03 ansible_host=10.0.1.12

[celery_beat]
app-server-01 ansible_host=10.0.1.10
```

Create `restart-workers.yml`:

```yaml
---
- name: Restart Celery workers
  hosts: celery_workers
  become: yes
  tasks:
    - name: Restart worker services
      systemd:
        name: "celery-worker@{{ item }}.service"
        state: restarted
      loop: [1, 2, 3, 4]

    - name: Wait for workers to be ready
      wait_for:
        timeout: 30

    - name: Verify workers
      command: /opt/celery/venv/bin/celery -A myapp inspect ping
      become_user: celery
```

Execute:

```bash
# Restart all workers across all servers
ansible-playbook -i inventory.ini restart-workers.yml

# Check status
ansible celery_workers -i inventory.ini -a "systemctl status celery-worker@1.service"
```

## Production Best Practices

1. **Use configuration management** (Ansible, Puppet, Chef)
2. **Implement monitoring** (Prometheus, Datadog)
3. **Set up log rotation** via journald configuration
4. **Regular backups** of beat schedule database
5. **Security hardening** (firewall, SELinux, AppArmor)
6. **Use managed services** for Redis and PostgreSQL when possible
7. **Implement health checks** with external monitoring
8. **Document runbooks** for common operations

## Cleanup

```bash
# Stop and disable all services
for i in {1..4}; do
    sudo systemctl stop celery-worker@${i}.service
    sudo systemctl disable celery-worker@${i}.service
done
sudo systemctl stop celery-beat.service
sudo systemctl disable celery-beat.service

# Remove service files
sudo rm /etc/systemd/system/celery-worker.service
sudo rm /etc/systemd/system/celery-beat.service
sudo systemctl daemon-reload

# Remove application (WARNING: destructive)
sudo rm -rf /opt/celery
sudo rm -rf /var/log/celery
sudo rm -rf /var/run/celery
sudo rm -rf /var/lib/celery
sudo rm -rf /etc/celery
```
