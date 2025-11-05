"""
Event processing example with idempotency and database transactions
Shows best practices for safe webhook event processing
"""

import os
from datetime import datetime
from typing import Optional

from sqlalchemy import create_engine, Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship


# Database configuration
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:pass@localhost/app_db")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()


# Database models
class User(Base):
    """User model"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    email = Column(String(255), unique=True, nullable=False)
    stripe_customer_id = Column(String(255), unique=True, index=True)
    subscription_status = Column(String(50), default="inactive")
    subscription_id = Column(String(255), nullable=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    payments = relationship("Payment", back_populates="user")


class Payment(Base):
    """Payment record"""
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    stripe_invoice_id = Column(String(255), unique=True, nullable=False, index=True)
    amount = Column(Integer, nullable=False)  # Amount in cents
    currency = Column(String(3), default="usd")
    status = Column(String(50), nullable=False)
    paid_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="payments")


class ProcessedEvent(Base):
    """Track processed webhook events for idempotency"""
    __tablename__ = "processed_events"

    id = Column(Integer, primary_key=True)
    event_id = Column(String(255), unique=True, nullable=False, index=True)
    event_type = Column(String(100), nullable=False)
    processed_at = Column(DateTime, default=datetime.utcnow)


# Create tables
Base.metadata.create_all(bind=engine)


class EventProcessor:
    """
    Idempotent event processor

    Key principles:
    1. Check if event already processed (idempotency)
    2. Use database transactions (atomic operations)
    3. Mark event as processed AFTER successful processing
    4. Handle errors gracefully
    """

    def __init__(self, db: Session):
        self.db = db

    def process_subscription_created(self, event_id: str, subscription_data: dict):
        """
        Process subscription creation event

        This is idempotent - safe to call multiple times with same event_id
        """
        # Check if already processed
        if self._is_processed(event_id):
            print(f"Event {event_id} already processed, skipping")
            return

        try:
            # Start transaction
            customer_id = subscription_data["customer"]
            subscription_id = subscription_data["id"]
            status = subscription_data["status"]

            # Find user by Stripe customer ID
            user = self.db.query(User).filter(
                User.stripe_customer_id == customer_id
            ).first()

            if not user:
                raise ValueError(f"User not found for customer {customer_id}")

            # Update user subscription (idempotent update)
            user.subscription_id = subscription_id
            user.subscription_status = status

            # Mark event as processed
            self._mark_processed(event_id, "customer.subscription.created")

            # Commit transaction (all or nothing)
            self.db.commit()

            print(f"Subscription created for user {user.email}: {subscription_id}")

            # Send welcome email (async task)
            self._send_welcome_email(user.email)

        except Exception as e:
            # Rollback on error
            self.db.rollback()
            raise

    def process_subscription_updated(self, event_id: str, subscription_data: dict):
        """Process subscription update event (idempotent)"""
        if self._is_processed(event_id):
            return

        try:
            subscription_id = subscription_data["id"]
            new_status = subscription_data["status"]

            # Find user by subscription ID
            user = self.db.query(User).filter(
                User.subscription_id == subscription_id
            ).first()

            if not user:
                raise ValueError(f"User not found for subscription {subscription_id}")

            # Store old status for comparison
            old_status = user.subscription_status

            # Update subscription status (idempotent)
            user.subscription_status = new_status

            # Mark as processed
            self._mark_processed(event_id, "customer.subscription.updated")

            self.db.commit()

            # Handle status changes
            if old_status != new_status:
                if new_status == "active":
                    self._handle_subscription_activated(user)
                elif new_status == "canceled":
                    self._handle_subscription_canceled(user)
                elif new_status == "past_due":
                    self._handle_payment_past_due(user)

            print(f"Subscription updated: {subscription_id}, status: {new_status}")

        except Exception as e:
            self.db.rollback()
            raise

    def process_subscription_deleted(self, event_id: str, subscription_data: dict):
        """Process subscription deletion event (idempotent)"""
        if self._is_processed(event_id):
            return

        try:
            subscription_id = subscription_data["id"]

            user = self.db.query(User).filter(
                User.subscription_id == subscription_id
            ).first()

            if not user:
                raise ValueError(f"User not found for subscription {subscription_id}")

            # Update user status (idempotent)
            user.subscription_status = "canceled"
            user.subscription_id = None  # Clear subscription

            # Mark as processed
            self._mark_processed(event_id, "customer.subscription.deleted")

            self.db.commit()

            print(f"Subscription deleted for user {user.email}")

            # Send cancellation email
            self._send_cancellation_email(user.email)

        except Exception as e:
            self.db.rollback()
            raise

    def process_payment_succeeded(self, event_id: str, invoice_data: dict):
        """Process successful payment (idempotent)"""
        if self._is_processed(event_id):
            return

        try:
            invoice_id = invoice_data["id"]
            customer_id = invoice_data["customer"]
            amount_paid = invoice_data["amount_paid"]
            currency = invoice_data["currency"]

            # Find user
            user = self.db.query(User).filter(
                User.stripe_customer_id == customer_id
            ).first()

            if not user:
                raise ValueError(f"User not found for customer {customer_id}")

            # Check if payment already recorded (additional idempotency check)
            existing_payment = self.db.query(Payment).filter(
                Payment.stripe_invoice_id == invoice_id
            ).first()

            if not existing_payment:
                # Create payment record
                payment = Payment(
                    user_id=user.id,
                    stripe_invoice_id=invoice_id,
                    amount=amount_paid,
                    currency=currency,
                    status="paid",
                    paid_at=datetime.utcnow()
                )
                self.db.add(payment)
            else:
                # Update existing payment (idempotent)
                existing_payment.status = "paid"
                existing_payment.paid_at = datetime.utcnow()

            # Mark event as processed
            self._mark_processed(event_id, "invoice.payment_succeeded")

            self.db.commit()

            print(f"Payment recorded: {invoice_id}, amount: {amount_paid} {currency}")

            # Send receipt email
            self._send_receipt_email(user.email, amount_paid, currency)

        except Exception as e:
            self.db.rollback()
            raise

    def process_payment_failed(self, event_id: str, invoice_data: dict):
        """Process failed payment (idempotent)"""
        if self._is_processed(event_id):
            return

        try:
            invoice_id = invoice_data["id"]
            customer_id = invoice_data["customer"]
            amount_due = invoice_data["amount_due"]

            user = self.db.query(User).filter(
                User.stripe_customer_id == customer_id
            ).first()

            if not user:
                raise ValueError(f"User not found for customer {customer_id}")

            # Record failed payment attempt
            payment = self.db.query(Payment).filter(
                Payment.stripe_invoice_id == invoice_id
            ).first()

            if not payment:
                payment = Payment(
                    user_id=user.id,
                    stripe_invoice_id=invoice_id,
                    amount=amount_due,
                    currency=invoice_data.get("currency", "usd"),
                    status="failed"
                )
                self.db.add(payment)
            else:
                # Update status (idempotent)
                payment.status = "failed"

            # Mark as processed
            self._mark_processed(event_id, "invoice.payment_failed")

            self.db.commit()

            print(f"Payment failed: {invoice_id}")

            # Send payment failure notification
            self._send_payment_failed_email(user.email, amount_due)

        except Exception as e:
            self.db.rollback()
            raise

    # Helper methods

    def _is_processed(self, event_id: str) -> bool:
        """Check if event already processed"""
        event = self.db.query(ProcessedEvent).filter(
            ProcessedEvent.event_id == event_id
        ).first()
        return event is not None

    def _mark_processed(self, event_id: str, event_type: str):
        """Mark event as processed"""
        # Use ON CONFLICT DO NOTHING equivalent
        existing = self.db.query(ProcessedEvent).filter(
            ProcessedEvent.event_id == event_id
        ).first()

        if not existing:
            event = ProcessedEvent(
                event_id=event_id,
                event_type=event_type
            )
            self.db.add(event)

    def _send_welcome_email(self, email: str):
        """Send welcome email (async task)"""
        # TODO: Implement with your email service
        print(f"Sending welcome email to {email}")

    def _send_cancellation_email(self, email: str):
        """Send cancellation email"""
        print(f"Sending cancellation email to {email}")

    def _send_receipt_email(self, email: str, amount: int, currency: str):
        """Send payment receipt"""
        print(f"Sending receipt to {email}: {amount/100:.2f} {currency.upper()}")

    def _send_payment_failed_email(self, email: str, amount: int):
        """Send payment failure notification"""
        print(f"Sending payment failed notice to {email}: {amount/100:.2f}")

    def _handle_subscription_activated(self, user: User):
        """Handle subscription activation"""
        print(f"Activating features for {user.email}")

    def _handle_subscription_canceled(self, user: User):
        """Handle subscription cancellation"""
        print(f"Revoking features for {user.email}")

    def _handle_payment_past_due(self, user: User):
        """Handle past due payment"""
        print(f"Sending past due notice to {user.email}")


# Example usage
if __name__ == "__main__":
    # Create database session
    db = SessionLocal()

    # Create processor
    processor = EventProcessor(db)

    # Example: Process subscription created event
    subscription_data = {
        "id": "sub_123",
        "customer": "cus_abc",
        "status": "active"
    }

    try:
        processor.process_subscription_created("evt_001", subscription_data)
        print("Event processed successfully")

        # Try processing same event again (idempotent)
        processor.process_subscription_created("evt_001", subscription_data)
        print("Duplicate event handled gracefully")

    finally:
        db.close()
