#!/bin/bash
# Setup Stripe Subscriptions implementation
# Creates FastAPI endpoints for subscription billing and customer management

set -e

echo "Setting up Stripe Subscriptions integration..."

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

# Create Subscriptions endpoint
cat > backend/routers/subscriptions.py << 'EOF'
"""Stripe Subscription endpoints for recurring billing"""
import os
from typing import Dict, Any, List
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import stripe

router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])

# Load Stripe API key from environment
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
if not stripe.api_key:
    raise ValueError("STRIPE_SECRET_KEY environment variable not set")


class CreateCustomerRequest(BaseModel):
    """Request model for creating customer"""
    email: str
    name: str | None = None
    metadata: Dict[str, str] | None = None


class CreateSubscriptionRequest(BaseModel):
    """Request model for creating subscription"""
    customer_id: str
    price_id: str
    trial_period_days: int | None = None
    metadata: Dict[str, str] | None = None


class UpdateSubscriptionRequest(BaseModel):
    """Request model for updating subscription"""
    price_id: str | None = None
    quantity: int | None = None


@router.post("/customers")
async def create_customer(request: CreateCustomerRequest) -> Dict[str, Any]:
    """
    Create a Stripe Customer for subscription management.

    Customers can have multiple subscriptions and payment methods.
    """
    try:
        customer = stripe.Customer.create(
            email=request.email,
            name=request.name,
            metadata=request.metadata or {},
        )

        return {
            "customer_id": customer.id,
            "email": customer.email,
            "name": customer.name,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/customers/{customer_id}")
async def get_customer(customer_id: str) -> Dict[str, Any]:
    """Retrieve customer details"""
    try:
        customer = stripe.Customer.retrieve(customer_id)

        return {
            "id": customer.id,
            "email": customer.email,
            "name": customer.name,
            "metadata": customer.metadata,
            "default_payment_method": customer.invoice_settings.default_payment_method,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/attach-payment-method")
async def attach_payment_method(
    customer_id: str,
    payment_method_id: str,
    set_default: bool = True
) -> Dict[str, Any]:
    """
    Attach payment method to customer and optionally set as default.

    Payment methods must be collected on frontend with Stripe Elements.
    """
    try:
        # Attach payment method to customer
        payment_method = stripe.PaymentMethod.attach(
            payment_method_id,
            customer=customer_id,
        )

        # Set as default payment method
        if set_default:
            stripe.Customer.modify(
                customer_id,
                invoice_settings={
                    "default_payment_method": payment_method_id,
                },
            )

        return {
            "payment_method_id": payment_method.id,
            "type": payment_method.type,
            "card": payment_method.card if payment_method.type == "card" else None,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/create")
async def create_subscription(
    request: CreateSubscriptionRequest
) -> Dict[str, Any]:
    """
    Create a subscription for a customer.

    Customer must have a default payment method attached.
    """
    try:
        subscription = stripe.Subscription.create(
            customer=request.customer_id,
            items=[{"price": request.price_id}],
            trial_period_days=request.trial_period_days,
            metadata=request.metadata or {},
            # Payment behavior: default_incomplete allows collecting payment separately
            payment_behavior="default_incomplete",
            # Expand latest invoice for payment intent details
            expand=["latest_invoice.payment_intent"],
        )

        # Get payment intent for frontend confirmation (if needed)
        payment_intent = None
        if subscription.latest_invoice:
            invoice = subscription.latest_invoice
            if hasattr(invoice, 'payment_intent'):
                payment_intent = {
                    "id": invoice.payment_intent.id,
                    "client_secret": invoice.payment_intent.client_secret,
                    "status": invoice.payment_intent.status,
                }

        return {
            "subscription_id": subscription.id,
            "status": subscription.status,
            "current_period_start": subscription.current_period_start,
            "current_period_end": subscription.current_period_end,
            "trial_end": subscription.trial_end,
            "payment_intent": payment_intent,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/{subscription_id}")
async def get_subscription(subscription_id: str) -> Dict[str, Any]:
    """Retrieve subscription details"""
    try:
        subscription = stripe.Subscription.retrieve(subscription_id)

        return {
            "id": subscription.id,
            "status": subscription.status,
            "customer": subscription.customer,
            "current_period_start": subscription.current_period_start,
            "current_period_end": subscription.current_period_end,
            "trial_end": subscription.trial_end,
            "cancel_at_period_end": subscription.cancel_at_period_end,
            "items": [
                {
                    "id": item.id,
                    "price": item.price.id,
                    "quantity": item.quantity,
                }
                for item in subscription.items.data
            ],
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.patch("/{subscription_id}")
async def update_subscription(
    subscription_id: str,
    request: UpdateSubscriptionRequest
) -> Dict[str, Any]:
    """
    Update subscription (change plan, quantity, etc.)

    Proration is handled automatically by Stripe.
    """
    try:
        subscription = stripe.Subscription.retrieve(subscription_id)

        update_params = {}

        if request.price_id:
            # Change to new price
            update_params["items"] = [{
                "id": subscription.items.data[0].id,
                "price": request.price_id,
            }]

        if request.quantity:
            # Update quantity
            update_params["items"] = [{
                "id": subscription.items.data[0].id,
                "quantity": request.quantity,
            }]

        updated_subscription = stripe.Subscription.modify(
            subscription_id,
            **update_params
        )

        return {
            "id": updated_subscription.id,
            "status": updated_subscription.status,
            "current_period_start": updated_subscription.current_period_start,
            "current_period_end": updated_subscription.current_period_end,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{subscription_id}")
async def cancel_subscription(
    subscription_id: str,
    immediately: bool = False
) -> Dict[str, Any]:
    """
    Cancel subscription.

    By default, cancels at end of billing period.
    Set immediately=True to cancel right away.
    """
    try:
        if immediately:
            # Cancel immediately
            subscription = stripe.Subscription.delete(subscription_id)
        else:
            # Cancel at period end
            subscription = stripe.Subscription.modify(
                subscription_id,
                cancel_at_period_end=True,
            )

        return {
            "id": subscription.id,
            "status": subscription.status,
            "cancel_at_period_end": subscription.cancel_at_period_end,
            "current_period_end": subscription.current_period_end,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/{subscription_id}/resume")
async def resume_subscription(subscription_id: str) -> Dict[str, Any]:
    """Resume a subscription that was set to cancel at period end"""
    try:
        subscription = stripe.Subscription.modify(
            subscription_id,
            cancel_at_period_end=False,
        )

        return {
            "id": subscription.id,
            "status": subscription.status,
            "cancel_at_period_end": subscription.cancel_at_period_end,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))
EOF

# Create subscription webhook handlers
cat > backend/webhooks/subscription_webhooks.py << 'EOF'
"""Webhook handlers for subscription lifecycle events"""
import os
from fastapi import APIRouter, Request, HTTPException, Header
import stripe

router = APIRouter(prefix="/webhook", tags=["webhooks"])

stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
webhook_secret = os.getenv("STRIPE_WEBHOOK_SECRET")


@router.post("/subscription")
async def subscription_webhook(
    request: Request,
    stripe_signature: str = Header(None, alias="stripe-signature")
):
    """Handle subscription lifecycle webhook events"""

    if not webhook_secret:
        raise HTTPException(
            status_code=500,
            detail="STRIPE_WEBHOOK_SECRET not configured"
        )

    payload = await request.body()

    try:
        event = stripe.Webhook.construct_event(
            payload, stripe_signature, webhook_secret
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid signature")

    event_type = event["type"]
    event_data = event["data"]["object"]

    # Subscription created
    if event_type == "customer.subscription.created":
        subscription_id = event_data["id"]
        customer_id = event_data["customer"]
        status = event_data["status"]

        print(f"Subscription created: {subscription_id} for {customer_id}")
        print(f"Status: {status}")

        # TODO: Grant access to subscription features

    # Subscription updated
    elif event_type == "customer.subscription.updated":
        subscription_id = event_data["id"]
        status = event_data["status"]
        cancel_at_period_end = event_data["cancel_at_period_end"]

        print(f"Subscription updated: {subscription_id}")
        print(f"Status: {status}, Cancel at end: {cancel_at_period_end}")

        # TODO: Update customer access based on status

    # Subscription deleted
    elif event_type == "customer.subscription.deleted":
        subscription_id = event_data["id"]
        customer_id = event_data["customer"]

        print(f"Subscription deleted: {subscription_id} for {customer_id}")

        # TODO: Revoke access to subscription features

    # Trial will end soon
    elif event_type == "customer.subscription.trial_will_end":
        subscription_id = event_data["id"]
        trial_end = event_data["trial_end"]

        print(f"Trial ending soon: {subscription_id} at {trial_end}")

        # TODO: Send reminder email to customer

    # Invoice payment succeeded
    elif event_type == "invoice.payment_succeeded":
        invoice_id = event_data["id"]
        customer_id = event_data["customer"]
        subscription_id = event_data["subscription"]
        amount_paid = event_data["amount_paid"]

        print(f"Invoice paid: {invoice_id} for subscription {subscription_id}")
        print(f"Amount: ${amount_paid / 100:.2f}")

        # TODO: Send receipt email, update billing history

    # Invoice payment failed
    elif event_type == "invoice.payment_failed":
        invoice_id = event_data["id"]
        customer_id = event_data["customer"]
        subscription_id = event_data["subscription"]

        print(f"Invoice payment failed: {invoice_id} for {subscription_id}")

        # TODO: Notify customer, possibly suspend access

    return {"status": "success"}
EOF

echo ""
echo "Stripe Subscriptions setup complete!"
echo ""
echo "Next steps:"
echo "1. Copy .env.example to .env and add your Stripe keys"
echo "2. Create Products and Prices in Stripe Dashboard"
echo "3. Import routers in your main FastAPI app:"
echo "   from backend.routers import subscriptions"
echo "   from backend.webhooks import subscription_webhooks"
echo "   app.include_router(subscriptions.router)"
echo "   app.include_router(subscription_webhooks.router)"
echo "4. Set up webhook endpoint in Stripe Dashboard"
echo ""
echo "Subscription workflow:"
echo "1. Create customer: POST /subscriptions/customers"
echo "2. Collect payment method on frontend"
echo "3. Attach payment method: POST /subscriptions/attach-payment-method"
echo "4. Create subscription: POST /subscriptions/create"
echo "5. Monitor webhooks for lifecycle events"
