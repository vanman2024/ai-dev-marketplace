"""
Stripe Checkout Session Template
Complete implementation for one-time and recurring payments
"""
import os
from typing import Dict, Any, List, Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import stripe

# Load Stripe API key from environment
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
if not stripe.api_key:
    raise ValueError("STRIPE_SECRET_KEY environment variable not set")

router = APIRouter(prefix="/checkout", tags=["checkout"])


class LineItem(BaseModel):
    """Line item for checkout"""
    price_id: Optional[str] = None  # Use existing Price ID
    name: Optional[str] = None  # For one-time products
    amount: Optional[int] = None  # Amount in cents
    currency: str = "usd"
    quantity: int = 1


class CreateCheckoutSessionRequest(BaseModel):
    """Request to create checkout session"""
    line_items: List[LineItem]
    mode: str = "payment"  # "payment" or "subscription"
    success_url: Optional[str] = None
    cancel_url: Optional[str] = None
    customer_email: Optional[str] = None
    allow_promotion_codes: bool = False
    metadata: Optional[Dict[str, str]] = None


@router.post("/create-session")
async def create_checkout_session(
    request: CreateCheckoutSessionRequest
) -> Dict[str, Any]:
    """
    Create a Stripe Checkout Session.

    Returns:
        - session_id: Checkout Session ID
        - url: Redirect URL for Stripe-hosted checkout

    Security:
        - NEVER hardcode API keys
        - Always use environment variables
        - Validate webhook signatures
    """
    try:
        # Get frontend URL from environment
        frontend_url = os.getenv("FRONTEND_URL", "http://localhost:3000")

        # Build success and cancel URLs
        success_url = request.success_url or f"{frontend_url}/success?session_id={{CHECKOUT_SESSION_ID}}"
        cancel_url = request.cancel_url or f"{frontend_url}/cancel"

        # Build line items
        line_items_data = []
        for item in request.line_items:
            if item.price_id:
                # Use existing Price ID
                line_items_data.append({
                    "price": item.price_id,
                    "quantity": item.quantity,
                })
            elif item.amount and item.name:
                # Create one-time price
                line_items_data.append({
                    "price_data": {
                        "currency": item.currency,
                        "product_data": {
                            "name": item.name,
                        },
                        "unit_amount": item.amount,
                    },
                    "quantity": item.quantity,
                })
            else:
                raise HTTPException(
                    status_code=400,
                    detail="Each line item must have either price_id or (amount + name)"
                )

        # Create Checkout Session
        session = stripe.checkout.Session.create(
            payment_method_types=["card"],
            line_items=line_items_data,
            mode=request.mode,
            success_url=success_url,
            cancel_url=cancel_url,
            customer_email=request.customer_email,
            allow_promotion_codes=request.allow_promotion_codes,
            metadata=request.metadata or {},
            # Optional: Enable automatic tax calculation
            automatic_tax={"enabled": False},
            # Optional: Collect shipping address
            # shipping_address_collection={
            #     "allowed_countries": ["US", "CA"],
            # },
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
async def get_checkout_session(session_id: str) -> Dict[str, Any]:
    """
    Retrieve Checkout Session details.

    Useful for displaying order confirmation after payment.
    """
    try:
        session = stripe.checkout.Session.retrieve(
            session_id,
            expand=["line_items"]
        )

        return {
            "id": session.id,
            "status": session.status,
            "payment_status": session.payment_status,
            "amount_total": session.amount_total,
            "amount_subtotal": session.amount_subtotal,
            "currency": session.currency,
            "customer_email": session.customer_email,
            "customer": session.customer,
            "payment_intent": session.payment_intent,
            "subscription": session.subscription,
            "line_items": [
                {
                    "description": item.description,
                    "amount_total": item.amount_total,
                    "quantity": item.quantity,
                }
                for item in session.line_items.data
            ] if session.line_items else [],
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/session/{session_id}/line-items")
async def get_session_line_items(session_id: str) -> Dict[str, Any]:
    """Retrieve line items for a Checkout Session"""
    try:
        line_items = stripe.checkout.Session.list_line_items(session_id)

        return {
            "session_id": session_id,
            "line_items": [
                {
                    "id": item.id,
                    "description": item.description,
                    "amount_total": item.amount_total,
                    "amount_subtotal": item.amount_subtotal,
                    "amount_discount": item.amount_discount,
                    "amount_tax": item.amount_tax,
                    "currency": item.currency,
                    "quantity": item.quantity,
                    "price": {
                        "id": item.price.id,
                        "unit_amount": item.price.unit_amount,
                        "recurring": item.price.recurring,
                    } if item.price else None,
                }
                for item in line_items.data
            ],
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


# Usage Example:
"""
# In your main FastAPI app:
from fastapi import FastAPI
from .templates import checkout_session

app = FastAPI()
app.include_router(checkout_session.router)

# Frontend redirect:
const response = await fetch('/checkout/create-session', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    line_items: [{
      name: 'Premium Plan',
      amount: 2999,  // $29.99
      currency: 'usd',
      quantity: 1
    }],
    mode: 'payment'
  })
});

const { url } = await response.json();
window.location.href = url;  // Redirect to Stripe Checkout
"""
