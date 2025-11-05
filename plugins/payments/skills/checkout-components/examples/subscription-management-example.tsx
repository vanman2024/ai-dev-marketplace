'use client';

/**
 * Subscription Management Example
 *
 * Demonstrates:
 * - Current subscription display
 * - Pricing comparison
 * - Upgrade/downgrade flow
 * - Cancellation handling
 * - Invoice history integration
 */

import { useState, useEffect } from 'react';
import { SubscriptionCard } from '@/components/payments/subscriptioncard';
import { PricingTable } from '@/components/payments/pricingtable';
import { PaymentHistory } from '@/components/payments/paymenthistory';

interface Subscription {
  id: string;
  status: 'active' | 'past_due' | 'canceled' | 'incomplete' | 'trialing';
  currentPeriodEnd: Date;
  cancelAtPeriodEnd?: boolean;
  plan: {
    name: string;
    amount: number;
    interval: 'month' | 'year';
  };
}

export default function SubscriptionManagement() {
  const [subscription, setSubscription] = useState<Subscription | null>(null);
  const [loading, setLoading] = useState(true);
  const [showUpgrade, setShowUpgrade] = useState(false);
  const [activeTab, setActiveTab] = useState<'overview' | 'billing'>('overview');

  // Pricing plans for upgrade/downgrade
  const pricingPlans = [
    {
      id: 'price_free',
      name: 'Free',
      description: 'Perfect for getting started',
      price: 0,
      interval: 'month' as const,
      features: [
        '10 API calls per month',
        'Basic support',
        'Community access',
        '1 project',
      ],
    },
    {
      id: 'price_pro',
      name: 'Pro',
      description: 'For growing businesses',
      price: 2999,
      interval: 'month' as const,
      features: [
        '1,000 API calls per month',
        'Priority support',
        'Advanced features',
        'Unlimited projects',
        'Team collaboration',
      ],
      recommended: true,
    },
    {
      id: 'price_enterprise',
      name: 'Enterprise',
      description: 'For large organizations',
      price: 9999,
      interval: 'month' as const,
      features: [
        'Unlimited API calls',
        'Dedicated support',
        'Custom integrations',
        'SLA guarantee',
        'Advanced security',
        'Custom contracts',
      ],
    },
  ];

  useEffect(() => {
    fetchSubscription();
  }, []);

  const fetchSubscription = async () => {
    try {
      const response = await fetch('/api/subscription');
      if (!response.ok) throw new Error('Failed to fetch subscription');

      const data = await response.json();
      setSubscription(data.subscription);
    } catch (error) {
      console.error('Error fetching subscription:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCancelSubscription = async () => {
    try {
      const response = await fetch('/api/subscription/cancel', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      });

      if (!response.ok) throw new Error('Failed to cancel subscription');

      // Refresh subscription data
      await fetchSubscription();
    } catch (error) {
      console.error('Error canceling subscription:', error);
      alert('Failed to cancel subscription. Please try again.');
    }
  };

  const handleReactivateSubscription = async () => {
    try {
      const response = await fetch('/api/subscription/reactivate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      });

      if (!response.ok) throw new Error('Failed to reactivate subscription');

      // Refresh subscription data
      await fetchSubscription();
    } catch (error) {
      console.error('Error reactivating subscription:', error);
      alert('Failed to reactivate subscription. Please try again.');
    }
  };

  const handleUpgradeSubscription = async (newPriceId: string) => {
    try {
      const response = await fetch('/api/subscription/update', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ priceId: newPriceId }),
      });

      if (!response.ok) throw new Error('Failed to update subscription');

      // Refresh subscription data
      await fetchSubscription();
      setShowUpgrade(false);
    } catch (error) {
      console.error('Error updating subscription:', error);
      alert('Failed to update subscription. Please try again.');
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Subscription Management</h1>
          <p className="mt-2 text-sm text-gray-600">
            Manage your subscription, billing, and payment methods
          </p>
        </div>

        {/* Tabs */}
        <div className="border-b border-gray-200 mb-8">
          <nav className="flex gap-8" aria-label="Tabs">
            <button
              onClick={() => setActiveTab('overview')}
              className={`py-4 px-1 border-b-2 font-medium text-sm transition-colors ${
                activeTab === 'overview'
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-600 hover:text-gray-900 hover:border-gray-300'
              }`}
              aria-current={activeTab === 'overview' ? 'page' : undefined}
            >
              Overview
            </button>
            <button
              onClick={() => setActiveTab('billing')}
              className={`py-4 px-1 border-b-2 font-medium text-sm transition-colors ${
                activeTab === 'billing'
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-600 hover:text-gray-900 hover:border-gray-300'
              }`}
              aria-current={activeTab === 'billing' ? 'page' : undefined}
            >
              Billing History
            </button>
          </nav>
        </div>

        {/* Overview Tab */}
        {activeTab === 'overview' && (
          <div className="space-y-8">
            {/* Current Subscription */}
            <div>
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-xl font-semibold text-gray-900">
                  Current Subscription
                </h2>
                {subscription && !showUpgrade && (
                  <button
                    onClick={() => setShowUpgrade(true)}
                    className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors"
                  >
                    Change Plan
                  </button>
                )}
              </div>

              {subscription ? (
                <SubscriptionCard
                  subscription={subscription}
                  onCancel={handleCancelSubscription}
                  onReactivate={handleReactivateSubscription}
                />
              ) : (
                <div className="bg-white border border-gray-200 rounded-lg p-8 text-center">
                  <h3 className="text-lg font-medium text-gray-900 mb-2">
                    No Active Subscription
                  </h3>
                  <p className="text-gray-600 mb-6">
                    Choose a plan to get started with premium features
                  </p>
                  <button
                    onClick={() => setShowUpgrade(true)}
                    className="px-6 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors"
                  >
                    View Plans
                  </button>
                </div>
              )}
            </div>

            {/* Upgrade/Downgrade Options */}
            {showUpgrade && (
              <div>
                <div className="flex items-center justify-between mb-4">
                  <h2 className="text-xl font-semibold text-gray-900">
                    {subscription ? 'Change Plan' : 'Choose a Plan'}
                  </h2>
                  <button
                    onClick={() => setShowUpgrade(false)}
                    className="text-sm text-gray-600 hover:text-gray-900"
                  >
                    Cancel
                  </button>
                </div>

                <PricingTable
                  plans={pricingPlans}
                  onSelectPlan={handleUpgradeSubscription}
                />
              </div>
            )}

            {/* Usage Statistics (Optional) */}
            {subscription && (
              <div className="bg-white border border-gray-200 rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">
                  Usage This Month
                </h3>

                <div className="grid md:grid-cols-3 gap-6">
                  <div>
                    <p className="text-sm text-gray-600">API Calls</p>
                    <p className="text-2xl font-semibold text-gray-900 mt-1">
                      450 / 1,000
                    </p>
                    <div className="mt-2 bg-gray-200 rounded-full h-2">
                      <div
                        className="bg-blue-600 h-2 rounded-full"
                        style={{ width: '45%' }}
                      />
                    </div>
                  </div>

                  <div>
                    <p className="text-sm text-gray-600">Projects</p>
                    <p className="text-2xl font-semibold text-gray-900 mt-1">
                      3 / Unlimited
                    </p>
                  </div>

                  <div>
                    <p className="text-sm text-gray-600">Team Members</p>
                    <p className="text-2xl font-semibold text-gray-900 mt-1">
                      5 / Unlimited
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Billing History Tab */}
        {activeTab === 'billing' && (
          <div>
            <h2 className="text-xl font-semibold text-gray-900 mb-6">Billing History</h2>
            <PaymentHistory customerId="cus_xxx" limit={10} />
          </div>
        )}
      </div>
    </div>
  );
}
