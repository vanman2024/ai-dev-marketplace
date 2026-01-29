// Queue definitions
import { Queue } from 'bullmq';
import { connection } from './connection';

export const defaultQueue = new Queue('default', {
  connection,
  defaultJobOptions: {
    attempts: 3,
    backoff: { type: 'exponential', delay: 1000 },
    removeOnComplete: 1000,
    removeOnFail: 5000,
  },
});
