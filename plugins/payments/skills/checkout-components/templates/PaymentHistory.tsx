'use client';

import { useState, useEffect } from 'react';

interface PaymentRecord {
  id: string;
  amount: number;
  currency: string;
  status: 'succeeded' | 'pending' | 'failed' | 'refunded';
  created: Date;
  description?: string;
  invoiceUrl?: string;
  receiptUrl?: string;
}

interface PaymentHistoryProps {
  /** Stripe customer ID */
  customerId: string;
  /** Number of records per page (default: 10) */
  limit?: number;
  /** Show filters (default: true) */
  showFilters?: boolean;
  /** Callback when loading more payments */
  onLoadMore?: () => void;
  /** Custom CSS classes */
  className?: string;
}

/**
 * PaymentHistory - Display transaction history with pagination
 *
 * Usage:
 * ```tsx
 * import { PaymentHistory } from '@/components/payments/paymenthistory';
 *
 * export default function BillingPage() {
 *   return (
 *     <div className="max-w-4xl mx-auto p-6">
 *       <h1 className="text-2xl font-semibold mb-6">Billing History</h1>
 *       <PaymentHistory
 *         customerId="cus_xxx"
 *         limit={10}
 *       />
 *     </div>
 *   );
 * }
 * ```
 */
export function PaymentHistory({
  customerId,
  limit = 10,
  showFilters = true,
  onLoadMore,
  className = '',
}: PaymentHistoryProps) {
  const [payments, setPayments] = useState<PaymentRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [statusFilter, setStatusFilter] = useState<string>('all');

  useEffect(() => {
    fetchPayments();
  }, [customerId, statusFilter]);

  const fetchPayments = async () => {
    setLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams({
        customerId,
        limit: limit.toString(),
        ...(statusFilter !== 'all' && { status: statusFilter }),
      });

      const response = await fetch(`/api/payment-history?${params}`);

      if (!response.ok) {
        throw new Error('Failed to fetch payment history');
      }

      const data = await response.json();
      setPayments(data.payments);
      setHasMore(data.hasMore);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load payments');
    } finally {
      setLoading(false);
    }
  };

  const formatAmount = (cents: number, currency: string) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency.toUpperCase(),
    }).format(cents / 100);
  };

  const formatDate = (date: Date) => {
    return new Intl.DateFormat('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    }).format(new Date(date));
  };

  const getStatusBadge = (status: PaymentRecord['status']) => {
    const badges = {
      succeeded: {
        color: 'bg-green-100 text-green-800',
        label: 'Paid',
      },
      pending: {
        color: 'bg-yellow-100 text-yellow-800',
        label: 'Pending',
      },
      failed: {
        color: 'bg-red-100 text-red-800',
        label: 'Failed',
      },
      refunded: {
        color: 'bg-gray-100 text-gray-800',
        label: 'Refunded',
      },
    };

    const badge = badges[status];

    return (
      <span className={`inline-flex px-2 py-1 rounded-full text-xs font-medium ${badge.color}`}>
        {badge.label}
      </span>
    );
  };

  if (loading && payments.length === 0) {
    return (
      <div className="flex justify-center items-center py-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-4 bg-red-50 border border-red-200 rounded-lg" role="alert">
        <p className="text-sm text-red-800">{error}</p>
      </div>
    );
  }

  return (
    <div className={className}>
      {/* Filters */}
      {showFilters && (
        <div className="mb-6 flex items-center gap-4">
          <label htmlFor="status-filter" className="text-sm font-medium text-gray-700">
            Filter by status:
          </label>
          <select
            id="status-filter"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="all">All</option>
            <option value="succeeded">Paid</option>
            <option value="pending">Pending</option>
            <option value="failed">Failed</option>
            <option value="refunded">Refunded</option>
          </select>
        </div>
      )}

      {/* Payment List */}
      {payments.length === 0 ? (
        <div className="text-center py-12 bg-gray-50 rounded-lg">
          <svg
            className="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            aria-hidden="true"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
            />
          </svg>
          <h3 className="mt-2 text-sm font-medium text-gray-900">No payments found</h3>
          <p className="mt-1 text-sm text-gray-500">
            {statusFilter !== 'all'
              ? 'Try adjusting your filters'
              : "You haven't made any payments yet"}
          </p>
        </div>
      ) : (
        <div className="bg-white border border-gray-200 rounded-lg overflow-hidden">
          <ul className="divide-y divide-gray-200" role="list">
            {payments.map((payment) => (
              <li key={payment.id} className="p-4 hover:bg-gray-50 transition-colors">
                <div className="flex items-center justify-between">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-3 mb-1">
                      <p className="text-sm font-medium text-gray-900 truncate">
                        {payment.description || 'Payment'}
                      </p>
                      {getStatusBadge(payment.status)}
                    </div>
                    <p className="text-sm text-gray-600">{formatDate(payment.created)}</p>
                  </div>

                  <div className="flex items-center gap-4">
                    <span className="text-lg font-semibold text-gray-900">
                      {formatAmount(payment.amount, payment.currency)}
                    </span>

                    {/* Action Buttons */}
                    <div className="flex gap-2">
                      {payment.invoiceUrl && (
                        <a
                          href={payment.invoiceUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-sm text-blue-600 hover:text-blue-700 font-medium"
                          aria-label="View invoice"
                        >
                          Invoice
                        </a>
                      )}
                      {payment.receiptUrl && (
                        <a
                          href={payment.receiptUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-sm text-blue-600 hover:text-blue-700 font-medium"
                          aria-label="View receipt"
                        >
                          Receipt
                        </a>
                      )}
                    </div>
                  </div>
                </div>
              </li>
            ))}
          </ul>
        </div>
      )}

      {/* Load More Button */}
      {hasMore && (
        <div className="mt-6 text-center">
          <button
            onClick={() => {
              onLoadMore?.();
              fetchPayments();
            }}
            className="px-6 py-2 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500"
            disabled={loading}
          >
            {loading ? 'Loading...' : 'Load More'}
          </button>
        </div>
      )}

      {/* Summary */}
      {payments.length > 0 && (
        <div className="mt-6 pt-6 border-t border-gray-200">
          <p className="text-sm text-gray-600 text-center">
            Showing {payments.length} payment{payments.length !== 1 ? 's' : ''}
          </p>
        </div>
      )}
    </div>
  );
}
