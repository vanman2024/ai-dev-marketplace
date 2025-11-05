"""
Complete FastAPI Checkout Session Example
Demonstrates full checkout flow with webhook handling
"""
import os
from typing import Dict, Any
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
app = FastAPI(title="Stripe Checkout Example")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # Frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Models
class CreateCheckoutRequest(BaseModel):
    product_name: str
    amount: int  # in cents
    quantity: int = 1


class Product(BaseModel):
    id: str
    name: str
    price: int
    currency: str = "usd"


# Sample products
PRODUCTS = {
    "basic": Product(id="basic", name="Basic Plan", price=999),  # $9.99
    "pro": Product(id="pro", name="Pro Plan", price=2999),  # $29.99
    "enterprise": Product(id="enterprise", name="Enterprise Plan", price=9999),  # $99.99
}


@app.get("/")
async def root():
    """Health check endpoint"""
    return {"status": "ok", "message": "Stripe Checkout API"}


@app.get("/products")
async def list_products():
    """List available products"""
    return {"products": list(PRODUCTS.values())}


@app.post("/checkout/create-session")
async def create_checkout_session(request: CreateCheckoutRequest) -> Dict[str, Any]:
    """
    Create Stripe Checkout Session.

    Example request:
    {
        "product_name": "Pro Plan",
        "amount": 2999,
        "quantity": 1
    }
    """
    try:
        frontend_url = os.getenv("FRONTEND_URL", "http://localhost:3000")

        # Create Checkout Session
        session = stripe.checkout.Session.create(
            payment_method_types=["card"],
            line_items=[
                {
                    "price_data": {
                        "currency": "usd",
                        "product_data": {
                            "name": request.product_name,
                        },
                        "unit_amount": request.amount,
                    },
                    "quantity": request.quantity,
                }
            ],
            mode="payment",
            success_url=f"{frontend_url}/success?session_id={{CHECKOUT_SESSION_ID}}",
            cancel_url=f"{frontend_url}/cancel",
            # Optional: Add metadata for order tracking
            metadata={
                "product_name": request.product_name,
                "quantity": str(request.quantity),
            },
        )

        return {
            "session_id": session.id,
            "url": session.url,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/checkout/session/{session_id}")
async def get_session(session_id: str) -> Dict[str, Any]:
    """Retrieve checkout session details"""
    try:
        session = stripe.checkout.Session.retrieve(session_id)

        return {
            "id": session.id,
            "status": session.status,
            "payment_status": session.payment_status,
            "amount_total": session.amount_total,
            "currency": session.currency,
            "customer_email": session.customer_email,
            "metadata": session.metadata,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/webhook/stripe")
async def stripe_webhook(
    request: Request,
    stripe_signature: str = Header(None, alias="stripe-signature")
):
    """
    Handle Stripe webhook events.

    SECURITY: Verifies webhook signature to ensure events are from Stripe.

    Setup:
    1. Local testing: stripe listen --forward-to localhost:8000/webhook/stripe
    2. Production: Add webhook endpoint in Stripe Dashboard
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
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid signature")

    # Handle event types
    event_type = event["type"]
    event_data = event["data"]["object"]

    print(f"Received event: {event_type}")

    if event_type == "checkout.session.completed":
        # Payment successful - fulfill order
        session_id = event_data["id"]
        payment_status = event_data["payment_status"]
        customer_email = event_data.get("customer_email")
        amount_total = event_data["amount_total"]
        metadata = event_data.get("metadata", {})

        print(f"✅ Checkout completed: {session_id}")
        print(f"   Payment status: {payment_status}")
        print(f"   Customer: {customer_email}")
        print(f"   Amount: ${amount_total / 100:.2f}")
        print(f"   Metadata: {metadata}")

        # TODO: Implement order fulfillment
        # - Save order to database
        # - Send confirmation email
        # - Grant access to purchased product
        # - Update inventory

    elif event_type == "checkout.session.expired":
        # Checkout session expired
        session_id = event_data["id"]
        print(f"❌ Checkout expired: {session_id}")

        # TODO: Handle abandoned cart
        # - Send reminder email
        # - Update analytics

    elif event_type == "payment_intent.succeeded":
        # Payment succeeded
        payment_intent_id = event_data["id"]
        amount = event_data["amount"]
        print(f"✅ Payment succeeded: {payment_intent_id} (${amount / 100:.2f})")

    elif event_type == "payment_intent.payment_failed":
        # Payment failed
        payment_intent_id = event_data["id"]
        error_message = event_data.get("last_payment_error", {}).get("message")
        print(f"❌ Payment failed: {payment_intent_id} - {error_message}")

        # TODO: Notify customer of payment failure

    else:
        print(f"Unhandled event type: {event_type}")

    return {"status": "success"}


if __name__ == "__main__":
    import uvicorn

    print("=" * 60)
    print("Stripe Checkout API Server")
    print("=" * 60)
    print("API: http://localhost:8000")
    print("Docs: http://localhost:8000/docs")
    print()
    print("Test with Stripe CLI:")
    print("  stripe listen --forward-to localhost:8000/webhook/stripe")
    print()
    print("Test card: 4242 4242 4242 4242")
    print("=" * 60)

    uvicorn.run(app, host="0.0.0.0", port=8000)

"""
Setup Instructions:

1. Create .env file:
   STRIPE_SECRET_KEY=your_stripe_secret_key_here
   STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key_here
   STRIPE_WEBHOOK_SECRET=your_webhook_secret_here
   FRONTEND_URL=http://localhost:3000

2. Install dependencies:
   pip install fastapi uvicorn stripe python-dotenv

3. Run the server:
   python fastapi-checkout-example.py

4. Test webhook locally:
   stripe listen --forward-to localhost:8000/webhook/stripe

5. Create checkout session:
   curl -X POST http://localhost:8000/checkout/create-session \\
     -H "Content-Type: application/json" \\
     -d '{"product_name": "Pro Plan", "amount": 2999, "quantity": 1}'

6. Use the returned URL to complete checkout with test card:
   4242 4242 4242 4242 (any future date, any CVC)
"""
