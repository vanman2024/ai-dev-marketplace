#!/bin/bash
# Setup Stripe Payment Intents implementation
# Creates FastAPI endpoints for Payment Intent workflow with custom UI

set -e

echo "Setting up Stripe Payment Intents integration..."

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
        echo -e "\n# Environment files\n.env\n.env.local\n!.env.example" >> .gitignore
        echo "Updated .gitignore"
    fi
fi

# Create Payment Intent endpoint
cat > backend/routers/payment_intents.py << 'EOF'
"""Stripe Payment Intent endpoints for custom payment forms"""
import os
from typing import Dict, Any
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import stripe

router = APIRouter(prefix="/payment-intents", tags=["payment-intents"])

# Load Stripe API key from environment
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
if not stripe.api_key:
    raise ValueError("STRIPE_SECRET_KEY environment variable not set")


class CreatePaymentIntentRequest(BaseModel):
    """Request model for creating payment intent"""
    amount: int  # Amount in cents
    currency: str = "usd"
    customer_email: str | None = None
    description: str | None = None
    metadata: Dict[str, str] | None = None


class ConfirmPaymentIntentRequest(BaseModel):
    """Request model for confirming payment intent"""
    payment_intent_id: str
    payment_method_id: str


@router.post("/create")
async def create_payment_intent(
    request: CreatePaymentIntentRequest
) -> Dict[str, Any]:
    """
    Create a Payment Intent for collecting payment on the frontend.

    Returns client_secret for use with Stripe Elements.
    """
    try:
        # Create Payment Intent
        intent = stripe.PaymentIntent.create(
            amount=request.amount,
            currency=request.currency,
            description=request.description,
            metadata=request.metadata or {},
            # Automatically capture payment when confirmed
            capture_method="automatic",
            # Set up for future usage (optional)
            # setup_future_usage="off_session",
            # Receipt email (optional)
            receipt_email=request.customer_email,
        )

        return {
            "payment_intent_id": intent.id,
            "client_secret": intent.client_secret,
            "status": intent.status,
            "amount": intent.amount,
            "currency": intent.currency,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{payment_intent_id}")
async def get_payment_intent(payment_intent_id: str) -> Dict[str, Any]:
    """
    Retrieve Payment Intent status and details.

    Useful for checking payment status after page refresh.
    """
    try:
        intent = stripe.PaymentIntent.retrieve(payment_intent_id)

        return {
            "id": intent.id,
            "status": intent.status,
            "amount": intent.amount,
            "currency": intent.currency,
            "description": intent.description,
            "metadata": intent.metadata,
            # Payment method details (if available)
            "payment_method": intent.payment_method,
            # Latest charge (if available)
            "latest_charge": intent.latest_charge,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/update-amount")
async def update_payment_intent_amount(
    payment_intent_id: str,
    amount: int
) -> Dict[str, Any]:
    """
    Update Payment Intent amount before confirmation.

    Useful for cart updates or dynamic pricing.
    """
    try:
        intent = stripe.PaymentIntent.modify(
            payment_intent_id,
            amount=amount,
        )

        return {
            "id": intent.id,
            "status": intent.status,
            "amount": intent.amount,
            "currency": intent.currency,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/cancel")
async def cancel_payment_intent(payment_intent_id: str) -> Dict[str, Any]:
    """
    Cancel a Payment Intent.

    Only works if payment hasn't been confirmed yet.
    """
    try:
        intent = stripe.PaymentIntent.cancel(payment_intent_id)

        return {
            "id": intent.id,
            "status": intent.status,
            "cancellation_reason": intent.cancellation_reason,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/confirm")
async def confirm_payment_intent(
    request: ConfirmPaymentIntentRequest
) -> Dict[str, Any]:
    """
    Confirm Payment Intent with payment method.

    Note: Usually done on frontend with Stripe.js for PCI compliance.
    This endpoint is for server-side confirmation scenarios.
    """
    try:
        intent = stripe.PaymentIntent.confirm(
            request.payment_intent_id,
            payment_method=request.payment_method_id,
        )

        return {
            "id": intent.id,
            "status": intent.status,
            "amount": intent.amount,
            "currency": intent.currency,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))
EOF

echo ""
echo "Stripe Payment Intents setup complete!"
echo ""
echo "Next steps:"
echo "1. Copy .env.example to .env and add your Stripe keys"
echo "2. Import router in your main FastAPI app:"
echo "   from backend.routers import payment_intents"
echo "   app.include_router(payment_intents.router)"
echo "3. Use client_secret on frontend with Stripe Elements"
echo "4. Test with test card: 4242 4242 4242 4242"
echo ""
echo "Frontend integration:"
echo "- Install: npm install @stripe/stripe-js @stripe/react-stripe-js"
echo "- Use CardElement to collect payment details"
echo "- Call confirmCardPayment with client_secret"
