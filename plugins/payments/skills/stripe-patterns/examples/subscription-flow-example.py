"""
Complete Subscription Flow Example
End-to-end subscription billing with customer management
"""
import os
from typing import Dict, Any, Optional
from fastapi import FastAPI, HTTPException, Request, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import stripe
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# SECURITY: Load API keys from environment variables
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
if not stripe.api_key:
    raise ValueError("STRIPE_SECRET_KEY environment variable not set")

webhook_secret = os.getenv("STRIPE_WEBHOOK_SECRET")

# Create FastAPI app
app = FastAPI(title="Stripe Subscription Example")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Models
class CreateCustomerRequest(BaseModel):
    email: str
    name: Optional[str] = None


class CreateSubscriptionRequest(BaseModel):
    customer_id: str
    price_id: str
    trial_days: Optional[int] = None


class UpdateSubscriptionRequest(BaseModel):
    subscription_id: str
    new_price_id: str


# Subscription Plans (create these in Stripe Dashboard first)
PLANS = {
    "basic": {
        "name": "Basic Plan",
        "price": 999,  # $9.99/month
        "price_id": "price_basic_monthly",  # Replace with real Price ID
        "features": ["10 GB Storage", "Email Support"],
    },
    "pro": {
        "name": "Pro Plan",
        "price": 2999,  # $29.99/month
        "price_id": "price_pro_monthly",  # Replace with real Price ID
        "features": ["100 GB Storage", "Priority Support", "Advanced Analytics"],
    },
    "enterprise": {
        "name": "Enterprise Plan",
        "price": 9999,  # $99.99/month
        "price_id": "price_enterprise_monthly",  # Replace with real Price ID
        "features": ["Unlimited Storage", "24/7 Support", "Custom Integrations"],
    },
}


@app.get("/")
async def root():
    """Health check"""
    return {"status": "ok", "message": "Stripe Subscription API"}


@app.get("/plans")
async def list_plans():
    """List available subscription plans"""
    return {"plans": PLANS}


@app.post("/customers/create")
async def create_customer(request: CreateCustomerRequest) -> Dict[str, Any]:
    """
    Step 1: Create a Stripe Customer

    Example:
    {
        "email": "customer@example.com",
        "name": "John Doe"
    }
    """
    try:
        customer = stripe.Customer.create(
            email=request.email,
            name=request.name,
            metadata={
                "source": "api",
            },
        )

        return {
            "customer_id": customer.id,
            "email": customer.email,
            "name": customer.name,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/customers/{customer_id}/payment-method")
async def attach_payment_method(
    customer_id: str,
    payment_method_id: str
) -> Dict[str, Any]:
    """
    Step 2: Attach payment method to customer

    Note: Payment method must be created on frontend with Stripe.js
    This is just for attaching an existing payment method

    Example:
    POST /customers/cus_123/payment-method?payment_method_id=pm_card_visa
    """
    try:
        # Attach payment method to customer
        payment_method = stripe.PaymentMethod.attach(
            payment_method_id,
            customer=customer_id,
        )

        # Set as default payment method
        stripe.Customer.modify(
            customer_id,
            invoice_settings={
                "default_payment_method": payment_method_id,
            },
        )

        return {
            "customer_id": customer_id,
            "payment_method_id": payment_method.id,
            "type": payment_method.type,
            "card": {
                "brand": payment_method.card.brand,
                "last4": payment_method.card.last4,
                "exp_month": payment_method.card.exp_month,
                "exp_year": payment_method.card.exp_year,
            } if payment_method.type == "card" else None,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/subscriptions/create")
async def create_subscription(request: CreateSubscriptionRequest) -> Dict[str, Any]:
    """
    Step 3: Create subscription for customer

    Example:
    {
        "customer_id": "cus_123",
        "price_id": "price_pro_monthly",
        "trial_days": 14
    }
    """
    try:
        # Verify customer exists and has payment method
        customer = stripe.Customer.retrieve(request.customer_id)

        if not customer.invoice_settings.default_payment_method:
            raise HTTPException(
                status_code=400,
                detail="Customer must have a default payment method"
            )

        # Create subscription
        subscription = stripe.Subscription.create(
            customer=request.customer_id,
            items=[{"price": request.price_id}],
            trial_period_days=request.trial_days,
            payment_behavior="default_incomplete",
            expand=["latest_invoice.payment_intent"],
            metadata={
                "source": "api",
            },
        )

        # Extract payment intent if present
        payment_intent = None
        if subscription.latest_invoice and hasattr(subscription.latest_invoice, 'payment_intent'):
            pi = subscription.latest_invoice.payment_intent
            if pi:
                payment_intent = {
                    "id": pi.id,
                    "client_secret": pi.client_secret,
                    "status": pi.status,
                }

        return {
            "subscription_id": subscription.id,
            "status": subscription.status,
            "customer": subscription.customer,
            "current_period_start": subscription.current_period_start,
            "current_period_end": subscription.current_period_end,
            "trial_start": subscription.trial_start,
            "trial_end": subscription.trial_end,
            "payment_intent": payment_intent,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/subscriptions/{subscription_id}")
async def get_subscription(subscription_id: str) -> Dict[str, Any]:
    """Get subscription details"""
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
            "price_id": subscription.items.data[0].price.id,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/subscriptions/update")
async def update_subscription(request: UpdateSubscriptionRequest) -> Dict[str, Any]:
    """
    Update subscription (upgrade/downgrade)

    Example:
    {
        "subscription_id": "sub_123",
        "new_price_id": "price_enterprise_monthly"
    }
    """
    try:
        subscription = stripe.Subscription.retrieve(request.subscription_id)

        # Update to new price
        updated = stripe.Subscription.modify(
            request.subscription_id,
            items=[{
                "id": subscription.items.data[0].id,
                "price": request.new_price_id,
            }],
            proration_behavior="create_prorations",
        )

        return {
            "subscription_id": updated.id,
            "status": updated.status,
            "new_price_id": request.new_price_id,
            "message": "Subscription updated successfully",
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.delete("/subscriptions/{subscription_id}")
async def cancel_subscription(
    subscription_id: str,
    immediately: bool = False
) -> Dict[str, Any]:
    """
    Cancel subscription

    Query params:
    - immediately: Cancel now (true) or at period end (false, default)
    """
    try:
        if immediately:
            subscription = stripe.Subscription.delete(subscription_id)
        else:
            subscription = stripe.Subscription.modify(
                subscription_id,
                cancel_at_period_end=True,
            )

        return {
            "subscription_id": subscription.id,
            "status": subscription.status,
            "cancel_at_period_end": subscription.cancel_at_period_end,
            "current_period_end": subscription.current_period_end,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/webhook/subscription")
async def subscription_webhook(
    request: Request,
    stripe_signature: str = Header(None, alias="stripe-signature")
):
    """
    Handle subscription lifecycle events

    Important events:
    - customer.subscription.created
    - customer.subscription.updated
    - customer.subscription.deleted
    - customer.subscription.trial_will_end
    - invoice.payment_succeeded
    - invoice.payment_failed
    """
    if not webhook_secret:
        raise HTTPException(status_code=500, detail="Webhook secret not configured")

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

    print(f"📥 Received: {event_type}")

    if event_type == "customer.subscription.created":
        # New subscription created
        sub_id = event_data["id"]
        customer_id = event_data["customer"]
        status = event_data["status"]

        print(f"✅ Subscription created: {sub_id} for {customer_id}")
        print(f"   Status: {status}")

        # TODO: Grant access to subscription features in your database

    elif event_type == "customer.subscription.updated":
        # Subscription changed (upgrade, downgrade, etc.)
        sub_id = event_data["id"]
        status = event_data["status"]

        print(f"🔄 Subscription updated: {sub_id}")
        print(f"   Status: {status}")

        # TODO: Update customer access based on new plan

    elif event_type == "customer.subscription.deleted":
        # Subscription canceled
        sub_id = event_data["id"]
        customer_id = event_data["customer"]

        print(f"❌ Subscription deleted: {sub_id} for {customer_id}")

        # TODO: Revoke access to subscription features

    elif event_type == "customer.subscription.trial_will_end":
        # Trial ending soon (3 days before by default)
        sub_id = event_data["id"]
        trial_end = event_data["trial_end"]

        print(f"⏰ Trial ending soon: {sub_id} at {trial_end}")

        # TODO: Send reminder email to customer

    elif event_type == "invoice.payment_succeeded":
        # Successful payment
        invoice_id = event_data["id"]
        customer_id = event_data["customer"]
        amount_paid = event_data["amount_paid"]

        print(f"💰 Payment succeeded: {invoice_id}")
        print(f"   Customer: {customer_id}")
        print(f"   Amount: ${amount_paid / 100:.2f}")

        # TODO: Send receipt email, update billing history

    elif event_type == "invoice.payment_failed":
        # Failed payment
        invoice_id = event_data["id"]
        customer_id = event_data["customer"]

        print(f"💸 Payment failed: {invoice_id} for {customer_id}")

        # TODO: Notify customer, retry payment, or suspend account

    return {"status": "success"}


if __name__ == "__main__":
    import uvicorn

    print("=" * 60)
    print("Stripe Subscription API Server")
    print("=" * 60)
    print("API: http://localhost:8000")
    print("Docs: http://localhost:8000/docs")
    print()
    print("Setup webhook:")
    print("  stripe listen --forward-to localhost:8000/webhook/subscription")
    print()
    print("Subscription Flow:")
    print("  1. Create customer: POST /customers/create")
    print("  2. Attach payment method: POST /customers/{id}/payment-method")
    print("  3. Create subscription: POST /subscriptions/create")
    print("  4. Monitor webhooks for lifecycle events")
    print("=" * 60)

    uvicorn.run(app, host="0.0.0.0", port=8000)

"""
Complete Setup Guide:

1. Create .env file:
   STRIPE_SECRET_KEY=your_stripe_secret_key_here
   STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key_here
   STRIPE_WEBHOOK_SECRET=your_webhook_secret_here

2. Create Products and Prices in Stripe Dashboard:
   - Go to https://dashboard.stripe.com/test/products
   - Create 3 products: Basic, Pro, Enterprise
   - Create monthly prices for each
   - Copy Price IDs and update PLANS dict above

3. Install dependencies:
   pip install fastapi uvicorn stripe python-dotenv

4. Run server:
   python subscription-flow-example.py

5. Set up webhook forwarding:
   stripe listen --forward-to localhost:8000/webhook/subscription

6. Test subscription flow:

   # Create customer
   curl -X POST http://localhost:8000/customers/create \\
     -H "Content-Type: application/json" \\
     -d '{"email": "test@example.com", "name": "Test User"}'

   # Attach payment method (use Stripe.js on frontend to create pm_*)
   # For testing, use: pm_card_visa
   curl -X POST http://localhost:8000/customers/cus_123/payment-method?payment_method_id=pm_card_visa

   # Create subscription
   curl -X POST http://localhost:8000/subscriptions/create \\
     -H "Content-Type: application/json" \\
     -d '{"customer_id": "cus_123", "price_id": "price_pro_monthly", "trial_days": 14}'
"""
