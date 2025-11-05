'use client';

import { useState } from 'react';

interface Plan {
  name: string;
  amount: number;
  interval: 'month' | 'year';
  currency?: string;
}

interface Subscription {
  id: string;
  status: 'active' | 'past_due' | 'canceled' | 'incomplete' | 'trialing';
  currentPeriodEnd: Date;
  cancelAtPeriodEnd?: boolean;
  plan: Plan;
}

interface SubscriptionCardProps {
  subscription: Subscription;
  /** Callback when user cancels subscription */
  onCancel?: () => void;
  /** Callback when user updates subscription */
  onUpdate?: () => void;
  /** Callback when user reactivates subscription */
  onReactivate?: () => void;
  /** Show manage button (default: true) */
  showManage?: boolean;
  /** Custom CSS classes */
  className?: string;
}

/**
 * SubscriptionCard - Display and manage subscription details
 *
 * Usage:
 * ```tsx
 * import { SubscriptionCard } from '@/components/payments/subscriptioncard';
 *
 * export default function SubscriptionPage() {
 *   return (
 *     <SubscriptionCard
 *       subscription={{
 *         id: 'sub_xxx',
 *         status: 'active',
 *         currentPeriodEnd: new Date('2025-12-01'),
 *         plan: {
 *           name: 'Pro Plan',
 *           amount: 2999,
 *           interval: 'month'
 *         }
 *       }}
 *       onCancel={() => handleCancellation()}
 *       onUpdate={() => handleUpdate()}
 *     />
 *   );
 * }
 * ```
 */
export function SubscriptionCard({
  subscription,
  onCancel,
  onUpdate,
  onReactivate,
  showManage = true,
  className = '',
}: SubscriptionCardProps) {
  const [showCancelConfirm, setShowCancelConfirm] = useState(false);
  const [canceling, setCanceling] = useState(false);

  const formatAmount = (cents: number, currency: string = 'usd') => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency.toUpperCase(),
    }).format(cents / 100);
  };

  const formatDate = (date: Date) => {
    return new Intl.DateFormat('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    }).format(new Date(date));
  };

  const getStatusBadge = (status: Subscription['status']) => {
    const badges = {
      active: {
        color: 'bg-green-100 text-green-800 border-green-200',
        label: 'Active',
      },
      trialing: {
        color: 'bg-blue-100 text-blue-800 border-blue-200',
        label: 'Trial',
      },
      past_due: {
        color: 'bg-yellow-100 text-yellow-800 border-yellow-200',
        label: 'Past Due',
      },
      canceled: {
        color: 'bg-red-100 text-red-800 border-red-200',
        label: 'Canceled',
      },
      incomplete: {
        color: 'bg-gray-100 text-gray-800 border-gray-200',
        label: 'Incomplete',
      },
    };

    const badge = badges[status];

    return (
      <span
        className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium border ${badge.color}`}
      >
        {badge.label}
      </span>
    );
  };

  const handleCancelClick = async () => {
    setCanceling(true);
    try {
      await onCancel?.();
    } finally {
      setCanceling(false);
      setShowCancelConfirm(false);
    }
  };

  return (
    <div className={`bg-white border border-gray-200 rounded-lg p-6 ${className}`}>
      {/* Header */}
      <div className="flex items-start justify-between mb-6">
        <div>
          <h3 className="text-xl font-semibold text-gray-900">
            {subscription.plan.name}
          </h3>
          <p className="text-gray-600 mt-1">
            {formatAmount(subscription.plan.amount, subscription.plan.currency)} /{' '}
            {subscription.plan.interval}
          </p>
        </div>
        <div>{getStatusBadge(subscription.status)}</div>
      </div>

      {/* Subscription Details */}
      <div className="space-y-4 mb-6">
        {/* Renewal Date */}
        <div className="flex justify-between items-center">
          <span className="text-sm text-gray-600">
            {subscription.cancelAtPeriodEnd ? 'Ends on' : 'Renews on'}
          </span>
          <span className="text-sm font-medium text-gray-900">
            {formatDate(subscription.currentPeriodEnd)}
          </span>
        </div>

        {/* Cancellation Notice */}
        {subscription.cancelAtPeriodEnd && (
          <div
            className="p-3 bg-yellow-50 border border-yellow-200 rounded-lg"
            role="status"
          >
            <p className="text-sm text-yellow-800">
              Your subscription will be canceled at the end of the current billing period.
            </p>
          </div>
        )}

        {/* Past Due Notice */}
        {subscription.status === 'past_due' && (
          <div
            className="p-3 bg-red-50 border border-red-200 rounded-lg"
            role="alert"
          >
            <p className="text-sm text-red-800 font-medium">Payment Failed</p>
            <p className="text-sm text-red-700 mt-1">
              Please update your payment method to keep your subscription active.
            </p>
          </div>
        )}
      </div>

      {/* Actions */}
      {showManage && (
        <div className="space-y-3">
          {/* Update Plan Button */}
          {subscription.status === 'active' && !subscription.cancelAtPeriodEnd && (
            <button
              onClick={onUpdate}
              className="w-full py-2 px-4 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500"
              aria-label="Update subscription plan"
            >
              Update Plan
            </button>
          )}

          {/* Cancel/Reactivate Buttons */}
          {subscription.cancelAtPeriodEnd ? (
            <button
              onClick={onReactivate}
              className="w-full py-2 px-4 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500"
              aria-label="Reactivate subscription"
            >
              Reactivate Subscription
            </button>
          ) : (
            subscription.status !== 'canceled' && (
              <>
                {!showCancelConfirm ? (
                  <button
                    onClick={() => setShowCancelConfirm(true)}
                    className="w-full py-2 px-4 border border-red-300 text-red-600 rounded-lg text-sm font-medium hover:bg-red-50 transition-colors focus:outline-none focus:ring-2 focus:ring-red-500"
                    aria-label="Cancel subscription"
                  >
                    Cancel Subscription
                  </button>
                ) : (
                  <div className="space-y-2">
                    <p className="text-sm text-gray-700 text-center">
                      Are you sure you want to cancel?
                    </p>
                    <div className="flex gap-2">
                      <button
                        onClick={() => setShowCancelConfirm(false)}
                        className="flex-1 py-2 px-4 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
                        disabled={canceling}
                      >
                        Keep Subscription
                      </button>
                      <button
                        onClick={handleCancelClick}
                        className="flex-1 py-2 px-4 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700 transition-colors disabled:opacity-50"
                        disabled={canceling}
                      >
                        {canceling ? 'Canceling...' : 'Yes, Cancel'}
                      </button>
                    </div>
                  </div>
                )}
              </>
            )
          )}
        </div>
      )}

      {/* Billing History Link */}
      <div className="mt-6 pt-6 border-t border-gray-200">
        <a
          href="/billing/history"
          className="text-sm text-blue-600 hover:text-blue-700 font-medium"
        >
          View Billing History →
        </a>
      </div>
    </div>
  );
}
