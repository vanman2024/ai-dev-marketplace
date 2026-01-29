# BullMQ Setup

## Initialize

```bash
./scripts/init-bullmq.sh
```

## Create Queue

See `templates/queue.ts` for queue definition pattern.

## Start Worker

```bash
npx tsx workers/workers/example.worker.ts
```
