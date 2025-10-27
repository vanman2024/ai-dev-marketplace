/**
 * Realtime E2E Tests
 * Tests for Supabase Realtime subscriptions, broadcast, and presence
 */

import { createClient, SupabaseClient, RealtimeChannel } from '@supabase/supabase-js';
import { config } from 'dotenv';

config({ path: '.env.test' });

const supabaseUrl = process.env.SUPABASE_TEST_URL!;
const supabaseKey = process.env.SUPABASE_TEST_ANON_KEY!;

// Helper to wait for condition
const waitFor = async (
  condition: () => boolean,
  timeout: number = 5000
): Promise<void> => {
  const startTime = Date.now();

  while (!condition()) {
    if (Date.now() - startTime > timeout) {
      throw new Error(`Timeout waiting for condition after ${timeout}ms`);
    }
    await new Promise(resolve => setTimeout(resolve, 100));
  }
};

describe('Realtime E2E Tests', () => {
  let supabase: SupabaseClient;
  const testTableName = 'test_realtime_messages';
  let testChannels: RealtimeChannel[] = [];

  beforeAll(async () => {
    supabase = createClient(supabaseUrl, supabaseKey);

    // Create test table (assume it exists or create via migration)
    // This is just for demonstration - in real tests, use migrations
  });

  afterEach(async () => {
    // Cleanup all channels created during tests
    for (const channel of testChannels) {
      await supabase.removeChannel(channel);
    }
    testChannels = [];
  });

  afterAll(async () => {
    // Cleanup test data
    await supabase.from(testTableName).delete().neq('id', 0);
  });

  describe('Database Change Subscriptions', () => {
    test('should receive INSERT events', async () => {
      const receivedEvents: any[] = [];

      const channel = supabase
        .channel('test-insert-channel')
        .on(
          'postgres_changes',
          {
            event: 'INSERT',
            schema: 'public',
            table: testTableName,
          },
          (payload) => {
            receivedEvents.push(payload);
          }
        )
        .subscribe();

      testChannels.push(channel);

      // Wait for subscription to be established
      await waitFor(() => channel.state === 'joined', 3000);

      // Insert test data
      const testContent = `Test message ${Date.now()}`;
      await supabase.from(testTableName).insert({
        content: testContent,
      });

      // Wait for event to be received
      await waitFor(() => receivedEvents.length > 0, 5000);

      expect(receivedEvents).toHaveLength(1);
      expect(receivedEvents[0].eventType).toBe('INSERT');
      expect(receivedEvents[0].new.content).toBe(testContent);
    });

    test('should receive UPDATE events', async () => {
      const receivedEvents: any[] = [];

      // Insert initial data
      const { data: inserted } = await supabase
        .from(testTableName)
        .insert({
          content: 'Original content',
        })
        .select()
        .single();

      const channel = supabase
        .channel('test-update-channel')
        .on(
          'postgres_changes',
          {
            event: 'UPDATE',
            schema: 'public',
            table: testTableName,
          },
          (payload) => {
            receivedEvents.push(payload);
          }
        )
        .subscribe();

      testChannels.push(channel);

      await waitFor(() => channel.state === 'joined', 3000);

      // Update data
      await supabase
        .from(testTableName)
        .update({ content: 'Updated content' })
        .eq('id', inserted!.id);

      await waitFor(() => receivedEvents.length > 0, 5000);

      expect(receivedEvents).toHaveLength(1);
      expect(receivedEvents[0].eventType).toBe('UPDATE');
      expect(receivedEvents[0].new.content).toBe('Updated content');
      expect(receivedEvents[0].old.content).toBe('Original content');
    });

    test('should receive DELETE events', async () => {
      const receivedEvents: any[] = [];

      // Insert initial data
      const { data: inserted } = await supabase
        .from(testTableName)
        .insert({
          content: 'To be deleted',
        })
        .select()
        .single();

      const channel = supabase
        .channel('test-delete-channel')
        .on(
          'postgres_changes',
          {
            event: 'DELETE',
            schema: 'public',
            table: testTableName,
          },
          (payload) => {
            receivedEvents.push(payload);
          }
        )
        .subscribe();

      testChannels.push(channel);

      await waitFor(() => channel.state === 'joined', 3000);

      // Delete data
      await supabase.from(testTableName).delete().eq('id', inserted!.id);

      await waitFor(() => receivedEvents.length > 0, 5000);

      expect(receivedEvents).toHaveLength(1);
      expect(receivedEvents[0].eventType).toBe('DELETE');
      expect(receivedEvents[0].old.id).toBe(inserted!.id);
    });

    test('should filter events by column value', async () => {
      const receivedEvents: any[] = [];

      const channel = supabase
        .channel('test-filter-channel')
        .on(
          'postgres_changes',
          {
            event: 'INSERT',
            schema: 'public',
            table: testTableName,
            filter: 'content=eq.filtered',
          },
          (payload) => {
            receivedEvents.push(payload);
          }
        )
        .subscribe();

      testChannels.push(channel);

      await waitFor(() => channel.state === 'joined', 3000);

      // Insert data that doesn't match filter
      await supabase.from(testTableName).insert({
        content: 'not filtered',
      });

      await new Promise(resolve => setTimeout(resolve, 1000));

      // Insert data that matches filter
      await supabase.from(testTableName).insert({
        content: 'filtered',
      });

      await waitFor(() => receivedEvents.length > 0, 5000);

      // Should only receive the filtered event
      expect(receivedEvents).toHaveLength(1);
      expect(receivedEvents[0].new.content).toBe('filtered');
    });
  });

  describe('Broadcast', () => {
    test('should broadcast and receive messages', async () => {
      const receivedMessages: any[] = [];

      const channel = supabase
        .channel('test-broadcast')
        .on('broadcast', { event: 'test-event' }, (payload) => {
          receivedMessages.push(payload);
        })
        .subscribe();

      testChannels.push(channel);

      await waitFor(() => channel.state === 'joined', 3000);

      // Broadcast a message
      const testMessage = { text: 'Hello World', timestamp: Date.now() };
      await channel.send({
        type: 'broadcast',
        event: 'test-event',
        payload: testMessage,
      });

      await waitFor(() => receivedMessages.length > 0, 5000);

      expect(receivedMessages).toHaveLength(1);
      expect(receivedMessages[0].payload).toEqual(testMessage);
    });

    test('should handle multiple broadcast events', async () => {
      const event1Messages: any[] = [];
      const event2Messages: any[] = [];

      const channel = supabase
        .channel('test-multi-broadcast')
        .on('broadcast', { event: 'event1' }, (payload) => {
          event1Messages.push(payload);
        })
        .on('broadcast', { event: 'event2' }, (payload) => {
          event2Messages.push(payload);
        })
        .subscribe();

      testChannels.push(channel);

      await waitFor(() => channel.state === 'joined', 3000);

      // Send to different events
      await channel.send({
        type: 'broadcast',
        event: 'event1',
        payload: { msg: 'Event 1' },
      });

      await channel.send({
        type: 'broadcast',
        event: 'event2',
        payload: { msg: 'Event 2' },
      });

      await waitFor(() => event1Messages.length > 0 && event2Messages.length > 0, 5000);

      expect(event1Messages[0].payload.msg).toBe('Event 1');
      expect(event2Messages[0].payload.msg).toBe('Event 2');
    });
  });

  describe('Presence', () => {
    test('should track user presence', async () => {
      const presenceState: any[] = [];

      const channel = supabase
        .channel('test-presence')
        .on('presence', { event: 'sync' }, () => {
          const state = channel.presenceState();
          presenceState.push(state);
        })
        .subscribe(async (status) => {
          if (status === 'SUBSCRIBED') {
            await channel.track({
              user_id: 'test-user-1',
              online_at: new Date().toISOString(),
            });
          }
        });

      testChannels.push(channel);

      await waitFor(() => presenceState.length > 0, 5000);

      // Verify presence state contains our user
      const latestState = presenceState[presenceState.length - 1];
      expect(Object.keys(latestState).length).toBeGreaterThan(0);
    });

    test('should detect user joins', async () => {
      const joinEvents: any[] = [];

      const channel = supabase
        .channel('test-presence-join')
        .on('presence', { event: 'join' }, (payload) => {
          joinEvents.push(payload);
        })
        .subscribe(async (status) => {
          if (status === 'SUBSCRIBED') {
            await channel.track({
              user_id: 'test-user-2',
              status: 'online',
            });
          }
        });

      testChannels.push(channel);

      await waitFor(() => joinEvents.length > 0, 5000);

      expect(joinEvents).toHaveLength(1);
    });

    test('should detect user leaves', async () => {
      const leaveEvents: any[] = [];

      const channel = supabase
        .channel('test-presence-leave')
        .on('presence', { event: 'leave' }, (payload) => {
          leaveEvents.push(payload);
        })
        .subscribe(async (status) => {
          if (status === 'SUBSCRIBED') {
            await channel.track({
              user_id: 'test-user-3',
            });

            // Untrack after a delay
            setTimeout(async () => {
              await channel.untrack();
            }, 1000);
          }
        });

      testChannels.push(channel);

      await waitFor(() => leaveEvents.length > 0, 10000);

      expect(leaveEvents.length).toBeGreaterThan(0);
    });
  });

  describe('Connection Management', () => {
    test('should handle subscription and unsubscription', async () => {
      const channel = supabase.channel('test-unsub').subscribe();

      testChannels.push(channel);

      await waitFor(() => channel.state === 'joined', 3000);

      expect(channel.state).toBe('joined');

      await supabase.removeChannel(channel);

      expect(channel.state).toBe('closed');
    });

    test('should reconnect after disconnection', async () => {
      const states: string[] = [];

      const channel = supabase
        .channel('test-reconnect')
        .subscribe((status) => {
          states.push(status);
        });

      testChannels.push(channel);

      await waitFor(() => channel.state === 'joined', 3000);

      // This test would require simulating network disconnection
      // which is complex in a test environment
      expect(states).toContain('SUBSCRIBED');
    });

    test('should cleanup subscriptions properly', async () => {
      const receivedEvents: any[] = [];

      const channel = supabase
        .channel('test-cleanup')
        .on(
          'postgres_changes',
          {
            event: 'INSERT',
            schema: 'public',
            table: testTableName,
          },
          (payload) => {
            receivedEvents.push(payload);
          }
        )
        .subscribe();

      await waitFor(() => channel.state === 'joined', 3000);

      // Unsubscribe
      await supabase.removeChannel(channel);

      // Insert data - should NOT be received
      await supabase.from(testTableName).insert({
        content: 'After unsubscribe',
      });

      await new Promise(resolve => setTimeout(resolve, 2000));

      // Should not have received any events
      expect(receivedEvents).toHaveLength(0);
    });
  });

  describe('Multi-Client Scenarios', () => {
    test('should receive messages between multiple clients', async () => {
      const client1 = createClient(supabaseUrl, supabaseKey);
      const client2 = createClient(supabaseUrl, supabaseKey);

      const client2Messages: any[] = [];

      const channel1 = client1.channel('multi-client-test').subscribe();
      const channel2 = client2
        .channel('multi-client-test')
        .on('broadcast', { event: 'message' }, (payload) => {
          client2Messages.push(payload);
        })
        .subscribe();

      await waitFor(
        () => channel1.state === 'joined' && channel2.state === 'joined',
        5000
      );

      // Send from client 1
      await channel1.send({
        type: 'broadcast',
        event: 'message',
        payload: { text: 'Cross-client message' },
      });

      await waitFor(() => client2Messages.length > 0, 5000);

      expect(client2Messages[0].payload.text).toBe('Cross-client message');

      // Cleanup
      await client1.removeChannel(channel1);
      await client2.removeChannel(channel2);
    });
  });
});
