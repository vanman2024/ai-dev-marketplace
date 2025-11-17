#!/bin/bash
# Create Clerk webhook infrastructure for user synchronization
# Usage: ./create-webhooks.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}Clerk Webhook Setup for User Sync${NC}"
echo "======================================"

# Check for required tools
if ! command -v supabase &> /dev/null; then
  echo -e "${RED}Error: Supabase CLI not found${NC}"
  echo "Install: npm install -g supabase"
  exit 1
fi

# Ask deployment target
echo "Where will the webhook handler run?"
echo "  1) Supabase Edge Function (recommended)"
echo "  2) External API (Vercel, Railway, etc.)"
echo "  3) Local development only"
echo ""
read -p "Choose deployment target (1-3): " DEPLOY_TARGET

case $DEPLOY_TARGET in
  1)
    echo -e "\n${GREEN}Creating Supabase Edge Function${NC}"

    # Create Edge Function directory
    FUNCTION_NAME="clerk-user-sync"
    FUNCTION_DIR="supabase/functions/$FUNCTION_NAME"

    mkdir -p "$FUNCTION_DIR"

    # Create Edge Function
    cat > "$FUNCTION_DIR/index.ts" <<'EOF'
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { Webhook } from "https://esm.sh/svix@1.4.1"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, svix-id, svix-signature, svix-timestamp',
}

interface ClerkUser {
  id: string
  email_addresses: Array<{ email_address: string, id: string }>
  first_name: string
  last_name: string
  image_url: string
  username: string
  public_metadata: Record<string, any>
  created_at: number
  updated_at: number
}

interface WebhookEvent {
  type: 'user.created' | 'user.updated' | 'user.deleted'
  data: ClerkUser
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
      return new Response('Missing svix headers', { status: 400 })
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
      return new Response('Invalid signature', { status: 401 })
    }

    // Initialize Supabase client with service role
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Handle different event types
    switch (event.type) {
      case 'user.created':
      case 'user.updated':
        await syncUser(supabase, event.data)
        break
      case 'user.deleted':
        await deleteUser(supabase, event.data.id)
        break
      default:
        console.log('Unhandled event type:', event.type)
    }

    return new Response(
      JSON.stringify({ success: true }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )
  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      }
    )
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

  const { error } = await supabase
    .from('users')
    .upsert(userData, {
      onConflict: 'clerk_id',
      ignoreDuplicates: false
    })

  if (error) {
    console.error('Error syncing user:', error)
    throw error
  }

  console.log('User synced:', user.id)
}

async function deleteUser(supabase: any, clerkId: string) {
  const { error } = await supabase
    .from('users')
    .delete()
    .eq('clerk_id', clerkId)

  if (error) {
    console.error('Error deleting user:', error)
    throw error
  }

  console.log('User deleted:', clerkId)
}
EOF

    echo -e "${GREEN}✓ Edge Function created${NC}"
    echo "Location: $FUNCTION_DIR/index.ts"

    # Deploy Edge Function
    echo -e "\n${BLUE}Deploying Edge Function...${NC}"
    read -p "Deploy now? (y/n): " DEPLOY_NOW

    if [ "$DEPLOY_NOW" = "y" ]; then
      supabase functions deploy "$FUNCTION_NAME" --no-verify-jwt

      echo -e "\n${GREEN}✓ Edge Function deployed${NC}"
      echo ""
      echo "Function URL:"
      echo "  https://YOUR_PROJECT_REF.supabase.co/functions/v1/$FUNCTION_NAME"
      echo ""
      echo "Set this as webhook URL in Clerk dashboard"
    fi

    # Create .env template for Edge Function
    cat > "$FUNCTION_DIR/.env.example" <<EOF
CLERK_WEBHOOK_SECRET=your_webhook_secret_here
SUPABASE_URL=https://your_project_ref.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
EOF

    echo ""
    echo "Configure secrets:"
    echo "  supabase secrets set CLERK_WEBHOOK_SECRET=your_secret"
    ;;

  2)
    echo -e "\n${GREEN}Creating external API webhook handler${NC}"

    mkdir -p api/webhooks

    cat > api/webhooks/clerk-sync.ts <<'EOF'
import { NextRequest, NextResponse } from 'next/server'
import { Webhook } from 'svix'
import { createClient } from '@supabase/supabase-js'

export async function POST(req: NextRequest) {
  const WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET

  if (!WEBHOOK_SECRET) {
    return NextResponse.json(
      { error: 'Webhook secret not configured' },
      { status: 500 }
    )
  }

  // Get headers
  const svix_id = req.headers.get('svix-id')
  const svix_timestamp = req.headers.get('svix-timestamp')
  const svix_signature = req.headers.get('svix-signature')

  if (!svix_id || !svix_timestamp || !svix_signature) {
    return NextResponse.json(
      { error: 'Missing svix headers' },
      { status: 400 }
    )
  }

  // Verify webhook
  const body = await req.text()
  const webhook = new Webhook(WEBHOOK_SECRET)

  let event: any
  try {
    event = webhook.verify(body, {
      'svix-id': svix_id,
      'svix-timestamp': svix_timestamp,
      'svix-signature': svix_signature,
    })
  } catch (err) {
    console.error('Verification failed:', err)
    return NextResponse.json(
      { error: 'Invalid signature' },
      { status: 401 }
    )
  }

  // Initialize Supabase
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  )

  // Handle event
  try {
    switch (event.type) {
      case 'user.created':
      case 'user.updated':
        await syncUser(supabase, event.data)
        break
      case 'user.deleted':
        await deleteUser(supabase, event.data.id)
        break
    }

    return NextResponse.json({ success: true })
  } catch (error: any) {
    console.error('Sync error:', error)
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    )
  }
}

async function syncUser(supabase: any, user: any) {
  const { error } = await supabase
    .from('users')
    .upsert({
      clerk_id: user.id,
      email: user.email_addresses[0]?.email_address,
      first_name: user.first_name,
      last_name: user.last_name,
      avatar_url: user.image_url,
      username: user.username,
      metadata: user.public_metadata,
      updated_at: new Date(user.updated_at).toISOString(),
    }, { onConflict: 'clerk_id' })

  if (error) throw error
}

async function deleteUser(supabase: any, clerkId: string) {
  const { error } = await supabase
    .from('users')
    .delete()
    .eq('clerk_id', clerkId)

  if (error) throw error
}
EOF

    echo -e "${GREEN}✓ API route created${NC}"
    echo "Location: api/webhooks/clerk-sync.ts"
    echo ""
    echo "Webhook URL (after deployment):"
    echo "  https://your-domain.com/api/webhooks/clerk-sync"
    ;;

  3)
    echo -e "\n${GREEN}Creating local development webhook${NC}"
    echo "For local testing, use ngrok or similar tunneling service"
    echo ""
    echo "Install ngrok: npm install -g ngrok"
    echo "Run: ngrok http 3000"
    echo "Use the HTTPS URL as webhook endpoint in Clerk"
    ;;
esac

# Generate Clerk dashboard instructions
echo -e "\n${GREEN}Clerk Dashboard Setup${NC}"
echo "======================================"
cat > clerk-webhook-setup.md <<'EOF'
# Clerk Webhook Configuration

## Step 1: Create Webhook Endpoint

1. Go to: https://dashboard.clerk.com/last-active?path=webhooks
2. Click "Add Endpoint"
3. Enter your endpoint URL:
   - Supabase: `https://YOUR_PROJECT.supabase.co/functions/v1/clerk-user-sync`
   - External: `https://your-domain.com/api/webhooks/clerk-sync`
4. Click "Create"

## Step 2: Subscribe to Events

Select these events:
- ✓ user.created
- ✓ user.updated
- ✓ user.deleted

## Step 3: Get Signing Secret

1. Click on the webhook endpoint
2. Copy the "Signing Secret"
3. Add to environment variables:
   - `CLERK_WEBHOOK_SECRET=whsec_...`

## Step 4: Test Webhook

1. Click "Testing" tab in Clerk dashboard
2. Send test event
3. Check logs:
   - Supabase: Function logs in dashboard
   - External: Application logs

## Troubleshooting

**Webhook fails:**
- Check endpoint URL is accessible
- Verify signing secret is correct
- Check application logs for errors
- Ensure Supabase service role key is set

**User not syncing:**
- Verify user table schema matches webhook payload
- Check RLS policies allow service role writes
- Review function/API logs for errors
- Test with curl and manual payload
EOF

echo "Webhook setup guide: clerk-webhook-setup.md"
echo ""

echo -e "${GREEN}Setup Complete!${NC}"
echo "======================================"
echo ""
echo "Next steps:"
echo "  1. Review clerk-webhook-setup.md"
echo "  2. Configure webhook in Clerk dashboard"
echo "  3. Test with a new user signup"
echo "  4. Monitor logs for successful sync"
echo ""
echo -e "${YELLOW}Don't forget to:${NC}"
echo "  - Set CLERK_WEBHOOK_SECRET environment variable"
echo "  - Ensure users table exists in Supabase"
echo "  - Run ./setup-sync.sh if you haven't already"
echo "  - Run ./configure-rls.sh to set up policies"
