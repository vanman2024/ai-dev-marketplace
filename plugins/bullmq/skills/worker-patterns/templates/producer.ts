// Job producer template
import { defaultQueue } from '../lib/queues';

export async function addJob(data: { message: string }) {
  const job = await defaultQueue.add('process', data);
  return job.id;
}
