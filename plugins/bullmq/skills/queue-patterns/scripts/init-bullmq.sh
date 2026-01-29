#!/bin/bash
# Initialize BullMQ project
# Usage: ./init-bullmq.sh

echo "📦 Initializing BullMQ..."

npm install bullmq ioredis
npm install -D @types/node tsx

mkdir -p workers/lib workers/workers workers/jobs workers/dashboard

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/../templates/connection.ts" workers/lib/
cp "$SCRIPT_DIR/../templates/queue.ts" workers/lib/queues.ts

echo "✅ BullMQ initialized"
