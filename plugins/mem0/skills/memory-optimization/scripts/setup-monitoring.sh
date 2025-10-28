#!/bin/bash
# Set up monitoring for Mem0 performance
PROJECT="${1:-mem0-app}"
echo "Setting up monitoring for $PROJECT..."
echo ""
cat > prometheus-mem0.yaml << 'PROM'
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'mem0'
    static_configs:
      - targets: ['localhost:9090']
PROM
echo "✓ Created prometheus-mem0.yaml"
echo ""
echo "Next steps:"
echo "1. Install Prometheus and Grafana"
echo "2. Configure application to expose metrics"
echo "3. Import dashboard from templates/monitoring/grafana-dashboard.json"
echo "4. Set up alerts from templates/monitoring/alert-rules.yaml"
