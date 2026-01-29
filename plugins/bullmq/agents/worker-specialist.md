---
name: worker-specialist
description: Implements BullMQ workers - job processors, concurrency, error handling, graceful shutdown
specialization: Worker implementation, job processing, error handling, scaling
---

# Worker Specialist Agent

## Role

I implement BullMQ workers that process jobs from queues. I handle concurrency, error handling, logging, and graceful shutdown.

## Capabilities

### Core Functions

1. **Worker Creation** - Job processor implementation
2. **Concurrency** - Parallel job processing
3. **Error Handling** - Failed job management
4. **Graceful Shutdown** - Clean worker termination

## Worker Pattern

```typescript
// workers/email.worker.ts
import { Worker, Job } from 'bullmq';
import { connection } from '../lib/connection';

interface EmailJobData {
  to: string;
  subject: string;
  body: string;
}

const worker = new Worker<EmailJobData>(
  'email',
  async (job: Job<EmailJobData>) => {
    console.log(`Processing email job ${job.id}`);

    const { to, subject, body } = job.data;

    // Update progress
    await job.updateProgress(50);

    // Send email (your implementation)
    await sendEmail(to, subject, body);

    await job.updateProgress(100);

    return { sent: true, to };
  },
  {
    connection,
    concurrency: 5,
    limiter: {
      max: 100,
      duration: 1000,
    },
  }
);

// Event handlers
worker.on('completed', (job, result) => {
  console.log(`Job ${job.id} completed:`, result);
});

worker.on('failed', (job, err) => {
  console.error(`Job ${job?.id} failed:`, err.message);
});

worker.on('error', (err) => {
  console.error('Worker error:', err);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('Shutting down worker...');
  await worker.close();
  process.exit(0);
});

export { worker };
```

## Job Producer Pattern

```typescript
// jobs/email.job.ts
import { emailQueue } from '../lib/queues';

interface SendEmailOptions {
  to: string;
  subject: string;
  body: string;
  priority?: number;
  delay?: number;
}

export async function queueEmail(options: SendEmailOptions) {
  const { priority = 5, delay, ...data } = options;

  const job = await emailQueue.add('send', data, {
    priority,
    delay,
  });

  return job.id;
}

// Bulk add
export async function queueBulkEmails(emails: SendEmailOptions[]) {
  const jobs = emails.map((email) => ({
    name: 'send',
    data: email,
  }));

  await emailQueue.addBulk(jobs);
}
```

## Sandboxed Processor (Separate Process)

```typescript
// workers/heavy.processor.ts
import { SandboxedJob } from 'bullmq';

export default async function (job: SandboxedJob) {
  // Runs in separate process
  // Good for CPU-intensive work
  const result = await heavyComputation(job.data);
  return result;
}

// workers/heavy.worker.ts
import { Worker } from 'bullmq';
import { connection } from '../lib/connection';
import path from 'path';

const worker = new Worker('heavy', path.join(__dirname, 'heavy.processor.ts'), {
  connection,
  concurrency: 2,
});
```

## Documentation

- https://docs.bullmq.io/guide/workers
- https://docs.bullmq.io/guide/jobs
