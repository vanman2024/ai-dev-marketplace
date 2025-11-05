#!/bin/bash
# Setup Stripe Checkout Session implementation
# Creates FastAPI endpoints, webhook handlers, and configuration files

set -e

echo "Setting up Stripe Checkout integration..."

# Check if we're in a project directory
if [ ! -f "pyproject.toml" ] && [ ! -f "requirements.txt" ] && [ ! -f "package.json" ]; then
    echo "Warning: No project configuration file found. Are you in a project directory?"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create backend directory structure
mkdir -p backend/routers
mkdir -p backend/webhooks

# Create .env.example if it doesn't exist
if [ ! -f ".env.example" ]; then
    cat > .env.example << 'EOF'
# Stripe API Keys (get from https://dashboard.stripe.com/test/apikeys)
STRIPE_SECRET_KEY=your_stripe_secret_key_here
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key_here
STRIPE_WEBHOOK_SECRET=your_webhook_secret_here

# Application URLs
FRONTEND_URL=http://localhost:3000
BACKEND_URL=http://localhost:8000
EOF
    echo "Created .env.example"
fi

# Update .gitignore
if [ -f ".gitignore" ]; then
    if ! grep -q "^.env$" .gitignore; then
        echo -e "\n# Environment files\n.env\n.env.local\n.env.development\n.env.production\n!.env.example" >> .gitignore
        echo "Updated .gitignore"
    fi
else
    cat > .gitignore << 'EOF'
# Environment files
.env
.env.local
.env.development
.env.production
!.env.example

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
ENV/

# Node
node_modules/
.next/
EOF
    echo "Created .gitignore"
fi

# Create Checkout Session endpoint
cat > backend/routers/checkout.py << 'EOF'
"""Stripe Checkout Session endpoints"""
import os
from typing import Dict, Any
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import stripe

router = APIRouter(prefix="/checkout", tags=["checkout"])

# Load Stripe API key from environment
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
if not stripe.api_key:
    raise ValueError("STRIPE_SECRET_KEY environment variable not set")


class CreateCheckoutSessionRequest(BaseModel):
    """Request model for creating checkout session"""
    price_id: str | None = None
    amount: int | None = None
    currency: str = "usd"
    product_name: str = "Product"
    quantity: int = 1


@router.post("/create-session")
async def create_checkout_session(
    request: CreateCheckoutSessionRequest
) -> Dict[str, Any]:
    """
    Create a Stripe Checkout Session for payment processing.

    Returns session ID and URL for redirect.
    """
    try:
        frontend_url = os.getenv("FRONTEND_URL", "http://localhost:3000")

        # Build line items
        line_items = []

        if request.price_id:
            # Use existing Price ID
            line_items.append({
                "price": request.price_id,
                "quantity": request.quantity,
            })
        elif request.amount:
            # Create one-time payment with amount
            line_items.append({
                "price_data": {
                    "currency": request.currency,
                    "product_data": {
                        "name": request.product_name,
                    },
                    "unit_amount": request.amount,  # Amount in cents
                },
                "quantity": request.quantity,
            })
        else:
            raise HTTPException(
                status_code=400,
                detail="Either price_id or amount must be provided"
            )

        # Create Checkout Session
        session = stripe.checkout.Session.create(
            payment_method_types=["card"],
            line_items=line_items,
            mode="payment",
            success_url=f"{frontend_url}/success?session_id={{CHECKOUT_SESSION_ID}}",
            cancel_url=f"{frontend_url}/cancel",
            # Optionally collect customer email
            customer_email=None,
            # Enable automatic tax calculation
            automatic_tax={"enabled": False},
        )

        return {
            "session_id": session.id,
            "url": session.url,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/session/{session_id}")
async def get_session(session_id: str) -> Dict[str, Any]:
    """
    Retrieve Checkout Session details.

    Useful for displaying order confirmation.
    """
    try:
        session = stripe.checkout.Session.retrieve(session_id)

        return {
            "id": session.id,
            "status": session.status,
            "payment_status": session.payment_status,
            "amount_total": session.amount_total,
            "currency": session.currency,
            "customer_email": session.customer_email,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))
EOF

# Create webhook handler
cat > backend/webhooks/stripe_webhooks.py << 'EOF'
"""Stripe webhook event handlers"""
import os
from fastapi import APIRouter, Request, HTTPException, Header
import stripe

router = APIRouter(prefix="/webhook", tags=["webhooks"])

stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
webhook_secret = os.getenv("STRIPE_WEBHOOK_SECRET")


@router.post("/stripe")
async def stripe_webhook(
    request: Request,
    stripe_signature: str = Header(None, alias="stripe-signature")
):
    """
    Handle Stripe webhook events.

    SECURITY: Verifies webhook signature to ensure events are from Stripe.
    """
    if not webhook_secret:
        raise HTTPException(
            status_code=500,
            detail="STRIPE_WEBHOOK_SECRET not configured"
        )

    # Get raw request body
    payload = await request.body()

    try:
        # Verify webhook signature
        event = stripe.Webhook.construct_event(
            payload, stripe_signature, webhook_secret
        )
    except ValueError:
        # Invalid payload
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError:
        # Invalid signature
        raise HTTPException(status_code=400, detail="Invalid signature")

    # Handle specific event types
    event_type = event["type"]
    event_data = event["data"]["object"]

    if event_type == "checkout.session.completed":
        # Payment successful - fulfill order
        session_id = event_data["id"]
        payment_status = event_data["payment_status"]
        customer_email = event_data.get("customer_email")
        amount_total = event_data["amount_total"]

        print(f"Checkout completed: {session_id}")
        print(f"Payment status: {payment_status}")
        print(f"Customer: {customer_email}")
        print(f"Amount: ${amount_total / 100:.2f}")

        # TODO: Implement order fulfillment logic
        # - Update database with order details
        # - Send confirmation email
        # - Trigger delivery process

    elif event_type == "checkout.session.expired":
        # Checkout session expired
        session_id = event_data["id"]
        print(f"Checkout expired: {session_id}")

        # TODO: Handle abandoned cart
        # - Send reminder email
        # - Update analytics

    elif event_type == "payment_intent.succeeded":
        # Payment succeeded
        payment_intent_id = event_data["id"]
        amount = event_data["amount"]
        print(f"Payment succeeded: {payment_intent_id} (${amount / 100:.2f})")

    elif event_type == "payment_intent.payment_failed":
        # Payment failed
        payment_intent_id = event_data["id"]
        error_message = event_data.get("last_payment_error", {}).get("message")
        print(f"Payment failed: {payment_intent_id} - {error_message}")

        # TODO: Notify customer of payment failure

    return {"status": "success"}
EOF

echo ""
echo "Stripe Checkout setup complete!"
echo ""
echo "Next steps:"
echo "1. Copy .env.example to .env and add your Stripe keys"
echo "2. Get test keys from: https://dashboard.stripe.com/test/apikeys"
echo "3. Import routers in your main FastAPI app:"
echo "   from backend.routers import checkout"
echo "   from backend.webhooks import stripe_webhooks"
echo "   app.include_router(checkout.router)"
echo "   app.include_router(stripe_webhooks.router)"
echo "4. Test with Stripe CLI: stripe listen --forward-to localhost:8000/webhook/stripe"
echo ""
echo "Test card: 4242 4242 4242 4242 (any future date, any CVC)"
