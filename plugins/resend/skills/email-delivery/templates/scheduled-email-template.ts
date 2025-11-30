/**
 * Scheduled Email Template
 * Pattern for scheduling emails to be sent at specific times
 */

import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

interface ScheduledEmailConfig {
  from: string;
  to: string;
  subject: string;
  html: string;
  text?: string;
  scheduledAt: Date;
}

/**
 * Schedule a single email for future delivery
 */
export async function scheduleEmail(config: ScheduledEmailConfig) {
  try {
    const { data, error } = await resend.emails.send({
      from: config.from,
      to: config.to,
      subject: config.subject,
      html: config.html,
      text: config.text,
      scheduled_at: config.scheduledAt.toISOString(),
    });

    if (error) {
      console.error('Schedule email failed:', error);
      return { success: false, error: error.message };
    }

    console.log(`Email scheduled for ${config.scheduledAt.toISOString()}`);
    return {
      success: true,
      messageId: data.id,
      scheduledAt: config.scheduledAt.toISOString(),
    };
  } catch (err) {
    console.error('Schedule email exception:', err);
    return {
      success: false,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

/**
 * Calculate delay in minutes
 */
export function calculateScheduleTime(delayMinutes: number): Date {
  const scheduledDate = new Date();
  scheduledDate.setMinutes(scheduledDate.getMinutes() + delayMinutes);
  return scheduledDate;
}

/**
 * Calculate schedule time in hours
 */
export function calculateScheduleTimeHours(delayHours: number): Date {
  const scheduledDate = new Date();
  scheduledDate.setHours(scheduledDate.getHours() + delayHours);
  return scheduledDate;
}

/**
 * Calculate schedule time for specific hour/minute in user's timezone
 */
export function scheduleForTimeZone(
  targetHour: number,
  targetMinute: number,
  userTimeZone: string
): Date {
  const formatter = new Intl.DateTimeFormat('en-US', {
    timeZone: userTimeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  });

  const now = new Date();
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: userTimeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  }).formatToParts(now);

  const userTime = new Date();

  for (const part of parts) {
    if (part.type === 'year') userTime.setFullYear(parseInt(part.value));
    if (part.type === 'month') userTime.setMonth(parseInt(part.value) - 1);
    if (part.type === 'day') userTime.setDate(parseInt(part.value));
    if (part.type === 'hour') userTime.setHours(parseInt(part.value));
    if (part.type === 'minute') userTime.setMinutes(parseInt(part.value));
  }

  const targetTime = new Date(userTime);
  targetTime.setHours(targetHour, targetMinute, 0, 0);

  // If time has passed, schedule for tomorrow
  if (targetTime < now) {
    targetTime.setDate(targetTime.getDate() + 1);
  }

  return targetTime;
}

/**
 * Onboarding sequence template
 */
interface OnboardingStep {
  delayHours: number;
  subject: string;
  html: string;
}

export async function scheduleOnboardingSequence(
  userEmail: string,
  firstName: string,
  steps: OnboardingStep[]
) {
  const results = [];

  for (const step of steps) {
    const scheduledDate = new Date();
    scheduledDate.setHours(scheduledDate.getHours() + step.delayHours);

    const { data, error } = await resend.emails.send({
      from: 'onboarding@example.com',
      to: userEmail,
      subject: step.subject,
      html: `<h2>${step.subject}</h2>${step.html}<p>Welcome, ${firstName}!</p>`,
      scheduled_at: scheduledDate.toISOString(),
    });

    results.push({
      step: steps.indexOf(step) + 1,
      success: !error,
      scheduledAt: scheduledDate.toISOString(),
      messageId: data?.id,
      error: error?.message,
    });

    // Avoid rate limiting
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  return results;
}

/**
 * Default onboarding sequence
 */
export const defaultOnboardingSequence: OnboardingStep[] = [
  {
    delayHours: 0,
    subject: 'Welcome to Example!',
    html: '<p>Your account is ready. Get started now.</p>',
  },
  {
    delayHours: 24,
    subject: 'Pro Tip: How to Optimize Your Setup',
    html: '<p>Here are some best practices to get more out of the app...</p>',
  },
  {
    delayHours: 72,
    subject: 'Explore Advanced Features',
    html: '<p>You unlocked access to premium features...</p>',
  },
  {
    delayHours: 168, // 1 week
    subject: 'We Want Your Feedback',
    html: '<p>How is your experience so far? Share your thoughts...</p>',
  },
];

/**
 * Birthday email scheduler
 */
export function calculateBirthdaySchedule(
  birthDate: string, // YYYY-MM-DD
  targetHour: number = 8,
  targetMinute: number = 0
): Date {
  const [year, month, day] = birthDate.split('-').map(Number);

  let birthdayDate = new Date(new Date().getFullYear(), month - 1, day);
  birthdayDate.setHours(targetHour, targetMinute, 0, 0);

  // If birthday has passed, schedule for next year
  if (birthdayDate < new Date()) {
    birthdayDate.setFullYear(birthdayDate.getFullYear() + 1);
  }

  return birthdayDate;
}

/**
 * Recurring reminder scheduler
 */
export interface RecurringReminder {
  email: string;
  subject: string;
  html: string;
  hour: number;
  minute: number;
  daysOfWeek: number[]; // 0-6, Sunday-Saturday
}

export function calculateNextOccurrence(
  hour: number,
  minute: number,
  daysOfWeek: number[]
): Date {
  const now = new Date();
  const nextOccurrence = new Date(now);

  // Find next occurrence
  let daysToAdd = 0;
  let found = false;

  for (let i = 0; i < 7; i++) {
    const checkDate = new Date(now);
    checkDate.setDate(checkDate.getDate() + i);

    if (daysOfWeek.includes(checkDate.getDay())) {
      nextOccurrence.setDate(checkDate.getDate());
      nextOccurrence.setMonth(checkDate.getMonth());
      nextOccurrence.setFullYear(checkDate.getFullYear());
      found = true;
      break;
    }
  }

  nextOccurrence.setHours(hour, minute, 0, 0);

  // If time has passed today, move to next occurrence
  if (nextOccurrence <= now) {
    nextOccurrence.setDate(nextOccurrence.getDate() + 1);
  }

  return nextOccurrence;
}

/**
 * Staggered campaign scheduler
 */
export async function scheduleStaggeredCampaign(
  recipients: string[],
  subject: string,
  htmlContent: string,
  staggerMinutes: number = 5
) {
  const results = [];

  for (let i = 0; i < recipients.length; i++) {
    const scheduledDate = new Date();
    scheduledDate.setMinutes(scheduledDate.getMinutes() + i * staggerMinutes);

    const { data, error } = await resend.emails.send({
      from: 'campaigns@example.com',
      to: recipients[i],
      subject,
      html: htmlContent,
      scheduled_at: scheduledDate.toISOString(),
    });

    results.push({
      recipient: recipients[i],
      success: !error,
      scheduledAt: scheduledDate.toISOString(),
      messageId: data?.id,
    });

    // Rate limiting
    await new Promise(resolve => setTimeout(resolve, 50));
  }

  return results;
}

/**
 * Validate schedule time
 */
export function validateScheduleTime(scheduledAt: Date): { valid: boolean; error?: string } {
  const now = new Date();

  // Minimum 5 minutes in future
  const minDate = new Date(now.getTime() + 5 * 60 * 1000);
  if (scheduledAt < minDate) {
    return {
      valid: false,
      error: 'Email must be scheduled at least 5 minutes in advance',
    };
  }

  // Maximum 365 days in future
  const maxDate = new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000);
  if (scheduledAt > maxDate) {
    return {
      valid: false,
      error: 'Email cannot be scheduled more than 365 days in advance',
    };
  }

  return { valid: true };
}
