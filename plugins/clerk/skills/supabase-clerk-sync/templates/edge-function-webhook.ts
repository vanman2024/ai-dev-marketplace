/**
 * Supabase Edge Function for Clerk Webhook Sync
 *
 * Deploy this as a Supabase Edge Function to handle Clerk webhooks
 * directly on Supabase infrastructure.
 *
 * Deploy:
 *   supabase functions deploy clerk-user-sync
 *
 * Set secrets:
 *   supabase secrets set CLERK_WEBHOOK_SECRET=whsec_xxx
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { Webhook } from 'https://esm.sh/svix@1.4.1'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, svix-id, svix-signature, svix-timestamp',
}

interface ClerkUser {
  id: string
  email_addresses: Array<{
    email_address: string
    id: string
  }>
  first_name: string | null
  last_name: string | null
  image_url: string
  username: string | null
  public_metadata: Record<string, any>
  created_at: number
  updated_at: number
}

interface WebhookEvent {
  type:
    | 'user.created'
    | 'user.updated'
    | 'user.deleted'
    | 'organization.created'
    | 'organization.updated'
    | 'organization.deleted'
  data: any
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify webhook signature
    const WEBHOOK_SECRET = Deno.env.get('CLERK_WEBHOOK_SECRET')
    if (!WEBHOOK_SECRET) {
      throw new Error('CLERK_WEBHOOK_SECRET not configured')
    }

    const svix_id = req.headers.get('svix-id')
    const svix_timestamp = req.headers.get('svix-timestamp')
    const svix_signature = req.headers.get('svix-signature')

    if (!svix_id || !svix_timestamp || !svix_signature) {
      return new Response('Missing svix headers', {
        status: 400,
        headers: corsHeaders,
      })
    }

    const body = await req.text()
    const webhook = new Webhook(WEBHOOK_SECRET)

    let event: WebhookEvent
    try {
      event = webhook.verify(body, {
        'svix-id': svix_id,
        'svix-timestamp': svix_timestamp,
        'svix-signature': svix_signature,
      }) as WebhookEvent
    } catch (err) {
      console.error('Webhook verification failed:', err)
      return new Response('Invalid signature', {
        status: 401,
        headers: corsHeaders,
      })
    }

    // Initialize Supabase client with service role
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    )

    // Handle different event types
    console.log('Processing event:', event.type)

    switch (event.type) {
      case 'user.created':
      case 'user.updated':
        await syncUser(supabase, event.data)
        break

      case 'user.deleted':
        await deleteUser(supabase, event.data.id)
        break

      case 'organization.created':
      case 'organization.updated':
        await syncOrganization(supabase, event.data)
        break

      case 'organization.deleted':
        await deleteOrganization(supabase, event.data.id)
        break

      default:
        console.log('Unhandled event type:', event.type)
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error: any) {
    console.error('Webhook error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})

async function syncUser(supabase: any, user: ClerkUser) {
  const userData = {
    clerk_id: user.id,
    email: user.email_addresses[0]?.email_address,
    first_name: user.first_name,
    last_name: user.last_name,
    avatar_url: user.image_url,
    username: user.username,
    metadata: user.public_metadata,
    updated_at: new Date(user.updated_at).toISOString(),
  }

  const { error } = await supabase.from('users').upsert(userData, {
    onConflict: 'clerk_id',
    ignoreDuplicates: false,
  })

  if (error) {
    console.error('Error syncing user:', error)
    throw error
  }

  console.log('User synced:', user.id)
}

async function deleteUser(supabase: any, clerkId: string) {
  const { error } = await supabase.from('users').delete().eq('clerk_id', clerkId)

  if (error) {
    console.error('Error deleting user:', error)
    throw error
  }

  console.log('User deleted:', clerkId)
}

async function syncOrganization(supabase: any, org: any) {
  const orgData = {
    clerk_org_id: org.id,
    name: org.name,
    slug: org.slug,
    image_url: org.image_url,
    settings: org.public_metadata,
    updated_at: new Date(org.updated_at).toISOString(),
  }

  const { error } = await supabase.from('organizations').upsert(orgData, {
    onConflict: 'clerk_org_id',
    ignoreDuplicates: false,
  })

  if (error) {
    console.error('Error syncing organization:', error)
    throw error
  }

  console.log('Organization synced:', org.id)
}

async function deleteOrganization(supabase: any, clerkOrgId: string) {
  const { error } = await supabase
    .from('organizations')
    .delete()
    .eq('clerk_org_id', clerkOrgId)

  if (error) {
    console.error('Error deleting organization:', error)
    throw error
  }

  console.log('Organization deleted:', clerkOrgId)
}
