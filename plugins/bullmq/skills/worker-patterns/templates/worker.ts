// Worker template
import { Job, Worker } from 'bullmq';
import { connection } from '../lib/connection';

interface JobData {
  // Define your job data type
  message: string;
}

const worker = new Worker<JobData>(
  'default',
  async (job: Job<JobData>) => {
    console.log(`Processing job ${job.id}:`, job.data);
    // Your processing logic here
    return { success: true };
  },
  { connection, concurrency: 5 }
);

worker.on('completed', (job, result) => {
  console.log(`Job ${job.id} completed`);
});

worker.on('failed', (job, err) => {
  console.error(`Job ${job?.id} failed:`, err.message);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  await worker.close();
  process.exit(0);
});

export { worker };
