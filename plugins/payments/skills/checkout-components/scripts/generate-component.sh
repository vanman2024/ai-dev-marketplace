#!/bin/bash

# Generate payment component from template
# Usage: bash generate-component.sh <component-name>
# Examples:
#   bash generate-component.sh checkout-form
#   bash generate-component.sh subscription-card
#   bash generate-component.sh pricing-table

set -e

COMPONENT_NAME=$1

if [ -z "$COMPONENT_NAME" ]; then
  echo "Usage: bash generate-component.sh <component-name>"
  echo ""
  echo "Available components:"
  echo "  - checkout-form          Complete checkout form with card input"
  echo "  - payment-method-form    Standalone payment method collection"
  echo "  - subscription-card      Subscription display and management"
  echo "  - pricing-table          Pricing tier comparison"
  echo "  - payment-history        Transaction history display"
  exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/../templates"

# Determine template file
case "$COMPONENT_NAME" in
  checkout-form)
    TEMPLATE_FILE="CheckoutForm.tsx"
    OUTPUT_DIR="components/payments"
    ;;
  payment-method-form)
    TEMPLATE_FILE="PaymentMethodForm.tsx"
    OUTPUT_DIR="components/payments"
    ;;
  subscription-card)
    TEMPLATE_FILE="SubscriptionCard.tsx"
    OUTPUT_DIR="components/payments"
    ;;
  pricing-table)
    TEMPLATE_FILE="PricingTable.tsx"
    OUTPUT_DIR="components/payments"
    ;;
  payment-history)
    TEMPLATE_FILE="PaymentHistory.tsx"
    OUTPUT_DIR="components/payments"
    ;;
  *)
    echo "Error: Unknown component '$COMPONENT_NAME'"
    echo ""
    echo "Available components:"
    echo "  - checkout-form"
    echo "  - payment-method-form"
    echo "  - subscription-card"
    echo "  - pricing-table"
    echo "  - payment-history"
    exit 1
    ;;
esac

# Check if template exists
if [ ! -f "$TEMPLATES_DIR/$TEMPLATE_FILE" ]; then
  echo "Error: Template file not found: $TEMPLATES_DIR/$TEMPLATE_FILE"
  exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Copy template to output directory
OUTPUT_FILE="$OUTPUT_DIR/$(echo $COMPONENT_NAME | sed 's/-//')".tsx
cp "$TEMPLATES_DIR/$TEMPLATE_FILE" "$OUTPUT_FILE"

echo "✅ Generated component: $OUTPUT_FILE"
echo ""
echo "Component details:"
case "$COMPONENT_NAME" in
  checkout-form)
    echo "  - Complete checkout form with Stripe CardElement"
    echo "  - Handles payment processing and errors"
    echo "  - Loading states and success callbacks"
    echo ""
    echo "Usage example:"
    echo "  import { CheckoutForm } from '@/components/payments/checkoutform';"
    echo ""
    echo "  <CheckoutForm"
    echo "    amount={4999}"
    echo "    onSuccess={() => router.push('/success')}"
    echo "    onError={(error) => console.error(error)}"
    echo "  />"
    ;;
  payment-method-form)
    echo "  - Collect and save payment methods"
    echo "  - Reusable payment method component"
    echo "  - Customer payment method management"
    echo ""
    echo "Usage example:"
    echo "  import { PaymentMethodForm } from '@/components/payments/paymentmethodform';"
    echo ""
    echo "  <PaymentMethodForm"
    echo "    customerId=\"cus_xxx\""
    echo "    onComplete={(pmId) => console.log(pmId)}"
    echo "  />"
    ;;
  subscription-card)
    echo "  - Display subscription details"
    echo "  - Cancel/upgrade actions"
    echo "  - Status and renewal information"
    echo ""
    echo "Usage example:"
    echo "  import { SubscriptionCard } from '@/components/payments/subscriptioncard';"
    echo ""
    echo "  <SubscriptionCard"
    echo "    subscription={subscriptionData}"
    echo "    onCancel={() => handleCancel()}"
    echo "  />"
    ;;
  pricing-table)
    echo "  - Compare pricing tiers"
    echo "  - Feature comparison"
    echo "  - Call-to-action buttons"
    echo ""
    echo "Usage example:"
    echo "  import { PricingTable } from '@/components/payments/pricingtable';"
    echo ""
    echo "  <PricingTable"
    echo "    plans={pricingPlans}"
    echo "    onSelectPlan={(id) => handleCheckout(id)}"
    echo "  />"
    ;;
  payment-history)
    echo "  - Display transaction history"
    echo "  - Invoice downloads"
    echo "  - Pagination support"
    echo ""
    echo "Usage example:"
    echo "  import { PaymentHistory } from '@/components/payments/paymenthistory';"
    echo ""
    echo "  <PaymentHistory"
    echo "    customerId=\"cus_xxx\""
    echo "    limit={10}"
    echo "  />"
    ;;
esac
echo ""
