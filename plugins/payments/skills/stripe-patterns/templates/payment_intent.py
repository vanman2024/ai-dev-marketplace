"""
Stripe Payment Intent Template
For custom payment forms with Stripe Elements
"""
import os
from typing import Dict, Any, Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import stripe

# Load Stripe API key from environment
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
if not stripe.api_key:
    raise ValueError("STRIPE_SECRET_KEY environment variable not set")

router = APIRouter(prefix="/payment-intents", tags=["payment-intents"])


class CreatePaymentIntentRequest(BaseModel):
    """Request to create payment intent"""
    amount: int  # Amount in cents
    currency: str = "usd"
    description: Optional[str] = None
    customer_id: Optional[str] = None
    payment_method_types: list[str] = ["card"]
    metadata: Optional[Dict[str, str]] = None
    setup_future_usage: Optional[str] = None  # "off_session" or "on_session"


@router.post("/create")
async def create_payment_intent(
    request: CreatePaymentIntentRequest
) -> Dict[str, Any]:
    """
    Create a Payment Intent for collecting payment.

    Returns client_secret for frontend confirmation.

    Security:
        - NEVER send secret key to frontend
        - Only send client_secret (safe to use client-side)
        - Validate on backend before creating intent
    """
    try:
        # Validate amount (must be positive)
        if request.amount <= 0:
            raise HTTPException(
                status_code=400,
                detail="Amount must be positive"
            )

        # Create Payment Intent
        intent_params = {
            "amount": request.amount,
            "currency": request.currency,
            "payment_method_types": request.payment_method_types,
            "description": request.description,
            "metadata": request.metadata or {},
        }

        # Attach to customer if provided
        if request.customer_id:
            intent_params["customer"] = request.customer_id

        # Set up for future usage if requested
        if request.setup_future_usage:
            intent_params["setup_future_usage"] = request.setup_future_usage

        intent = stripe.PaymentIntent.create(**intent_params)

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
    Retrieve Payment Intent status.

    Use after page refresh to check payment completion.
    """
    try:
        intent = stripe.PaymentIntent.retrieve(payment_intent_id)

        return {
            "id": intent.id,
            "status": intent.status,
            "amount": intent.amount,
            "amount_received": intent.amount_received,
            "currency": intent.currency,
            "description": intent.description,
            "metadata": intent.metadata,
            "payment_method": intent.payment_method,
            "charges": [
                {
                    "id": charge.id,
                    "amount": charge.amount,
                    "status": charge.status,
                    "receipt_url": charge.receipt_url,
                }
                for charge in intent.charges.data
            ] if intent.charges else [],
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/{payment_intent_id}/update")
async def update_payment_intent(
    payment_intent_id: str,
    amount: Optional[int] = None,
    description: Optional[str] = None,
    metadata: Optional[Dict[str, str]] = None
) -> Dict[str, Any]:
    """
    Update Payment Intent before confirmation.

    Useful for cart updates or dynamic pricing.
    """
    try:
        update_params = {}

        if amount is not None:
            if amount <= 0:
                raise HTTPException(
                    status_code=400,
                    detail="Amount must be positive"
                )
            update_params["amount"] = amount

        if description is not None:
            update_params["description"] = description

        if metadata is not None:
            update_params["metadata"] = metadata

        intent = stripe.PaymentIntent.modify(
            payment_intent_id,
            **update_params
        )

        return {
            "id": intent.id,
            "status": intent.status,
            "amount": intent.amount,
            "currency": intent.currency,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/{payment_intent_id}/cancel")
async def cancel_payment_intent(payment_intent_id: str) -> Dict[str, Any]:
    """
    Cancel a Payment Intent.

    Only works if payment hasn't been captured yet.
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


@router.post("/{payment_intent_id}/capture")
async def capture_payment_intent(
    payment_intent_id: str,
    amount_to_capture: Optional[int] = None
) -> Dict[str, Any]:
    """
    Manually capture a Payment Intent.

    Only needed if using manual capture method.
    """
    try:
        capture_params = {}

        if amount_to_capture is not None:
            capture_params["amount_to_capture"] = amount_to_capture

        intent = stripe.PaymentIntent.capture(
            payment_intent_id,
            **capture_params
        )

        return {
            "id": intent.id,
            "status": intent.status,
            "amount": intent.amount,
            "amount_received": intent.amount_received,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


# Usage Example:
"""
# Backend: Create Payment Intent
@app.post("/create-payment")
async def create_payment(amount: int):
    return await create_payment_intent(
        CreatePaymentIntentRequest(
            amount=amount,
            currency="usd",
            description="Product purchase"
        )
    )

# Frontend: Confirm Payment
import { loadStripe } from '@stripe/stripe-js';

const stripe = await loadStripe('your_stripe_publishable_key_here');

const { client_secret } = await fetch('/payment-intents/create', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ amount: 2999 })  // $29.99
}).then(r => r.json());

const { error } = await stripe.confirmCardPayment(client_secret, {
  payment_method: {
    card: cardElement,
    billing_details: {
      name: 'Customer Name',
      email: 'customer@example.com'
    }
  }
});

if (error) {
  console.error(error.message);
} else {
  // Payment succeeded!
}
"""
