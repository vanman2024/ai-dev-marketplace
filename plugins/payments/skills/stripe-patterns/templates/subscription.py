"""
Stripe Subscription Template
Complete implementation for recurring billing
"""
import os
from typing import Dict, Any, Optional, List
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import stripe

# Load Stripe API key from environment
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
if not stripe.api_key:
    raise ValueError("STRIPE_SECRET_KEY environment variable not set")

router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])


class CreateSubscriptionRequest(BaseModel):
    """Request to create subscription"""
    customer_id: str
    price_id: str
    trial_period_days: Optional[int] = None
    payment_behavior: str = "default_incomplete"
    proration_behavior: str = "create_prorations"
    metadata: Optional[Dict[str, str]] = None


class UpdateSubscriptionRequest(BaseModel):
    """Request to update subscription"""
    price_id: Optional[str] = None
    quantity: Optional[int] = None
    proration_behavior: str = "create_prorations"


@router.post("/create")
async def create_subscription(
    request: CreateSubscriptionRequest
) -> Dict[str, Any]:
    """
    Create a subscription for a customer.

    Customer must have a default payment method attached.

    Returns:
        - subscription_id: Subscription ID
        - status: Subscription status
        - client_secret: For frontend payment confirmation (if needed)

    Security:
        - Verify customer owns the subscription
        - Validate payment method before creating
        - Handle webhook events for status changes
    """
    try:
        # Verify customer exists
        try:
            stripe.Customer.retrieve(request.customer_id)
        except stripe.error.InvalidRequestError:
            raise HTTPException(
                status_code=404,
                detail=f"Customer {request.customer_id} not found"
            )

        # Create subscription
        subscription = stripe.Subscription.create(
            customer=request.customer_id,
            items=[{"price": request.price_id}],
            trial_period_days=request.trial_period_days,
            payment_behavior=request.payment_behavior,
            proration_behavior=request.proration_behavior,
            metadata=request.metadata or {},
            # Expand to get payment intent details
            expand=["latest_invoice.payment_intent"],
        )

        # Extract payment intent if available
        payment_intent = None
        if subscription.latest_invoice:
            invoice = subscription.latest_invoice
            if hasattr(invoice, 'payment_intent') and invoice.payment_intent:
                pi = invoice.payment_intent
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
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{subscription_id}")
async def get_subscription(subscription_id: str) -> Dict[str, Any]:
    """Retrieve subscription details"""
    try:
        subscription = stripe.Subscription.retrieve(
            subscription_id,
            expand=["default_payment_method"]
        )

        return {
            "id": subscription.id,
            "status": subscription.status,
            "customer": subscription.customer,
            "current_period_start": subscription.current_period_start,
            "current_period_end": subscription.current_period_end,
            "trial_start": subscription.trial_start,
            "trial_end": subscription.trial_end,
            "cancel_at": subscription.cancel_at,
            "cancel_at_period_end": subscription.cancel_at_period_end,
            "canceled_at": subscription.canceled_at,
            "items": [
                {
                    "id": item.id,
                    "price": {
                        "id": item.price.id,
                        "unit_amount": item.price.unit_amount,
                        "currency": item.price.currency,
                        "recurring": {
                            "interval": item.price.recurring.interval,
                            "interval_count": item.price.recurring.interval_count,
                        } if item.price.recurring else None,
                    },
                    "quantity": item.quantity,
                }
                for item in subscription.items.data
            ],
            "default_payment_method": subscription.default_payment_method,
            "metadata": subscription.metadata,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.patch("/{subscription_id}")
async def update_subscription(
    subscription_id: str,
    request: UpdateSubscriptionRequest
) -> Dict[str, Any]:
    """
    Update subscription (change plan, quantity).

    Proration is handled automatically.
    """
    try:
        subscription = stripe.Subscription.retrieve(subscription_id)

        update_params = {
            "proration_behavior": request.proration_behavior,
        }

        # Update price and/or quantity
        if request.price_id or request.quantity:
            item_params = {"id": subscription.items.data[0].id}

            if request.price_id:
                item_params["price"] = request.price_id

            if request.quantity:
                item_params["quantity"] = request.quantity

            update_params["items"] = [item_params]

        updated = stripe.Subscription.modify(
            subscription_id,
            **update_params
        )

        return {
            "id": updated.id,
            "status": updated.status,
            "current_period_start": updated.current_period_start,
            "current_period_end": updated.current_period_end,
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
            "canceled_at": subscription.canceled_at,
            "current_period_end": subscription.current_period_end,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/{subscription_id}/resume")
async def resume_subscription(subscription_id: str) -> Dict[str, Any]:
    """Resume a subscription scheduled for cancellation"""
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


@router.get("/customer/{customer_id}/subscriptions")
async def list_customer_subscriptions(
    customer_id: str,
    status: Optional[str] = None
) -> Dict[str, List[Dict[str, Any]]]:
    """List all subscriptions for a customer"""
    try:
        params = {"customer": customer_id}

        if status:
            params["status"] = status

        subscriptions = stripe.Subscription.list(**params)

        return {
            "subscriptions": [
                {
                    "id": sub.id,
                    "status": sub.status,
                    "current_period_start": sub.current_period_start,
                    "current_period_end": sub.current_period_end,
                    "trial_end": sub.trial_end,
                    "cancel_at_period_end": sub.cancel_at_period_end,
                }
                for sub in subscriptions.data
            ]
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


# Usage Example:
"""
# 1. Create customer (or retrieve existing)
customer = stripe.Customer.create(
    email="customer@example.com",
    name="Customer Name"
)

# 2. Attach payment method (collected on frontend)
stripe.PaymentMethod.attach(
    "pm_card_visa",
    customer=customer.id
)
stripe.Customer.modify(
    customer.id,
    invoice_settings={"default_payment_method": "pm_card_visa"}
)

# 3. Create subscription
response = await create_subscription(
    CreateSubscriptionRequest(
        customer_id=customer.id,
        price_id="price_1234567890",  # From Stripe Dashboard
        trial_period_days=14
    )
)

# 4. Handle webhook events
@app.post("/webhook/stripe")
async def handle_webhook(request: Request):
    event = stripe.Webhook.construct_event(
        await request.body(),
        request.headers["stripe-signature"],
        webhook_secret
    )

    if event.type == "customer.subscription.created":
        # Grant access to features
        pass
    elif event.type == "customer.subscription.deleted":
        # Revoke access
        pass
    elif event.type == "invoice.payment_failed":
        # Notify customer
        pass

    return {"status": "success"}
"""
