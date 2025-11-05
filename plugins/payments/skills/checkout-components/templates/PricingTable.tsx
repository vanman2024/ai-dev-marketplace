'use client';

interface PricingPlan {
  id: string;
  name: string;
  description?: string;
  price: number;
  interval?: 'month' | 'year' | 'one-time';
  currency?: string;
  features: string[];
  recommended?: boolean;
  cta?: string;
}

interface PricingTableProps {
  plans: PricingPlan[];
  /** Callback when user selects a plan */
  onSelectPlan: (planId: string) => void;
  /** Show annual/monthly toggle (default: false) */
  showIntervalToggle?: boolean;
  /** Current billing interval (if toggle shown) */
  currentInterval?: 'month' | 'year';
  /** Callback when interval changes */
  onIntervalChange?: (interval: 'month' | 'year') => void;
  /** Custom CSS classes */
  className?: string;
}

/**
 * PricingTable - Compare pricing tiers with features
 *
 * Usage:
 * ```tsx
 * import { PricingTable } from '@/components/payments/pricingtable';
 *
 * const plans = [
 *   {
 *     id: 'price_free',
 *     name: 'Free',
 *     price: 0,
 *     interval: 'month',
 *     features: ['10 API calls/month', 'Basic support']
 *   },
 *   {
 *     id: 'price_pro',
 *     name: 'Pro',
 *     price: 2999,
 *     interval: 'month',
 *     features: ['1000 API calls/month', 'Priority support'],
 *     recommended: true
 *   }
 * ];
 *
 * export default function Pricing() {
 *   return (
 *     <PricingTable
 *       plans={plans}
 *       onSelectPlan={(planId) => handleCheckout(planId)}
 *     />
 *   );
 * }
 * ```
 */
export function PricingTable({
  plans,
  onSelectPlan,
  showIntervalToggle = false,
  currentInterval = 'month',
  onIntervalChange,
  className = '',
}: PricingTableProps) {
  const formatAmount = (cents: number, currency: string = 'usd') => {
    if (cents === 0) return 'Free';

    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency.toUpperCase(),
      minimumFractionDigits: 0,
      maximumFractionDigits: 2,
    }).format(cents / 100);
  };

  return (
    <div className={className}>
      {/* Interval Toggle */}
      {showIntervalToggle && (
        <div className="flex justify-center mb-8">
          <div className="inline-flex items-center bg-gray-100 rounded-lg p-1">
            <button
              onClick={() => onIntervalChange?.('month')}
              className={`px-6 py-2 rounded-md text-sm font-medium transition-colors ${
                currentInterval === 'month'
                  ? 'bg-white text-gray-900 shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
              aria-pressed={currentInterval === 'month'}
            >
              Monthly
            </button>
            <button
              onClick={() => onIntervalChange?.('year')}
              className={`px-6 py-2 rounded-md text-sm font-medium transition-colors ${
                currentInterval === 'year'
                  ? 'bg-white text-gray-900 shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
              aria-pressed={currentInterval === 'year'}
            >
              Yearly
              <span className="ml-2 text-xs text-green-600 font-semibold">Save 20%</span>
            </button>
          </div>
        </div>
      )}

      {/* Pricing Cards Grid */}
      <div
        className={`grid gap-6 ${
          plans.length === 2
            ? 'md:grid-cols-2 max-w-4xl mx-auto'
            : plans.length === 3
            ? 'md:grid-cols-3 max-w-6xl mx-auto'
            : 'md:grid-cols-2 lg:grid-cols-4 max-w-7xl mx-auto'
        }`}
      >
        {plans.map((plan) => (
          <div
            key={plan.id}
            className={`relative bg-white rounded-lg shadow-sm border-2 transition-all ${
              plan.recommended
                ? 'border-blue-600 shadow-lg scale-105'
                : 'border-gray-200 hover:border-gray-300'
            }`}
          >
            {/* Recommended Badge */}
            {plan.recommended && (
              <div className="absolute top-0 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
                <span className="inline-flex items-center px-4 py-1 rounded-full text-xs font-semibold bg-blue-600 text-white">
                  Recommended
                </span>
              </div>
            )}

            <div className="p-6">
              {/* Plan Name */}
              <h3 className="text-xl font-semibold text-gray-900">{plan.name}</h3>

              {/* Plan Description */}
              {plan.description && (
                <p className="mt-2 text-sm text-gray-600">{plan.description}</p>
              )}

              {/* Price */}
              <div className="mt-6">
                <span className="text-4xl font-bold text-gray-900">
                  {formatAmount(plan.price, plan.currency)}
                </span>
                {plan.price > 0 && plan.interval && (
                  <span className="text-gray-600 ml-2">/ {plan.interval}</span>
                )}
              </div>

              {/* Features List */}
              <ul className="mt-6 space-y-4" role="list">
                {plan.features.map((feature, index) => (
                  <li key={index} className="flex items-start">
                    <svg
                      className="h-5 w-5 text-green-500 mt-0.5 mr-3 flex-shrink-0"
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        fillRule="evenodd"
                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                        clipRule="evenodd"
                      />
                    </svg>
                    <span className="text-sm text-gray-700">{feature}</span>
                  </li>
                ))}
              </ul>

              {/* CTA Button */}
              <button
                onClick={() => onSelectPlan(plan.id)}
                className={`mt-8 w-full py-3 px-4 rounded-lg font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 ${
                  plan.recommended
                    ? 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500'
                    : 'bg-gray-900 text-white hover:bg-gray-800 focus:ring-gray-500'
                }`}
                aria-label={`Select ${plan.name} plan`}
              >
                {plan.cta || (plan.price === 0 ? 'Get Started' : 'Subscribe')}
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Additional Information */}
      <div className="mt-12 text-center">
        <p className="text-sm text-gray-600">
          All plans include a 14-day free trial. No credit card required.
        </p>
        <p className="text-sm text-gray-600 mt-2">
          Need a custom plan?{' '}
          <a href="/contact" className="text-blue-600 hover:text-blue-700 font-medium">
            Contact sales
          </a>
        </p>
      </div>
    </div>
  );
}
