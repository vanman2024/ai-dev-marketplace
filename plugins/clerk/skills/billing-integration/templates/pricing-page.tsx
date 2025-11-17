import { PricingTable } from '@clerk/nextjs'
import { currentUser } from '@clerk/nextjs/server'
import Link from 'next/link'

export default async function PricingPage() {
  const user = await currentUser()

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-white dark:from-gray-900 dark:to-gray-800">
      {/* Header */}
      <div className="container mx-auto px-4 py-12">
        <div className="text-center mb-12">
          <h1 className="text-5xl font-bold text-gray-900 dark:text-white mb-4">
            Choose Your Plan
          </h1>
          <p className="text-xl text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
            Select the perfect plan for your needs. All plans include a 14-day free trial.
          </p>
        </div>

        {/* User Status Banner */}
        {user && (
          <div className="max-w-4xl mx-auto mb-8 p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
            <p className="text-center text-blue-900 dark:text-blue-100">
              Welcome back, <strong>{user.firstName || user.emailAddresses[0].emailAddress}</strong>!
              {' '}Choose a plan to unlock premium features.
            </p>
          </div>
        )}

        {/* Pricing Table */}
        <div className="max-w-6xl mx-auto">
          <PricingTable
            appearance={{
              elements: {
                rootBox: 'w-full',
                cardBox: 'shadow-lg hover:shadow-xl transition-shadow',
                planName: 'text-2xl font-bold',
                planPrice: 'text-3xl font-bold text-blue-600',
                planDescription: 'text-gray-600 dark:text-gray-400',
                featureList: 'space-y-3',
                subscribeButton: 'w-full py-3 px-6 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg transition-colors',
              },
              variables: {
                colorPrimary: '#3b82f6',
                colorBackground: '#ffffff',
                borderRadius: '0.75rem',
              },
            }}
          />
        </div>

        {/* Features Comparison */}
        <div className="max-w-6xl mx-auto mt-16">
          <h2 className="text-3xl font-bold text-center text-gray-900 dark:text-white mb-8">
            Compare All Features
          </h2>

          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg overflow-hidden">
            <table className="w-full">
              <thead className="bg-gray-50 dark:bg-gray-700">
                <tr>
                  <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900 dark:text-white">
                    Feature
                  </th>
                  <th className="px-6 py-4 text-center text-sm font-semibold text-gray-900 dark:text-white">
                    Free
                  </th>
                  <th className="px-6 py-4 text-center text-sm font-semibold text-gray-900 dark:text-white">
                    Pro
                  </th>
                  <th className="px-6 py-4 text-center text-sm font-semibold text-gray-900 dark:text-white">
                    Enterprise
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                <tr>
                  <td className="px-6 py-4 text-sm text-gray-900 dark:text-white">
                    API Calls per Month
                  </td>
                  <td className="px-6 py-4 text-center text-sm text-gray-600 dark:text-gray-400">
                    100
                  </td>
                  <td className="px-6 py-4 text-center text-sm text-gray-600 dark:text-gray-400">
                    10,000
                  </td>
                  <td className="px-6 py-4 text-center text-sm text-gray-600 dark:text-gray-400">
                    Unlimited
                  </td>
                </tr>
                <tr>
                  <td className="px-6 py-4 text-sm text-gray-900 dark:text-white">
                    Team Members
                  </td>
                  <td className="px-6 py-4 text-center text-sm text-gray-600 dark:text-gray-400">
                    1
                  </td>
                  <td className="px-6 py-4 text-center text-sm text-gray-600 dark:text-gray-400">
                    5
                  </td>
                  <td className="px-6 py-4 text-center text-sm text-gray-600 dark:text-gray-400">
                    Unlimited
                  </td>
                </tr>
                <tr>
                  <td className="px-6 py-4 text-sm text-gray-900 dark:text-white">
                    Priority Support
                  </td>
                  <td className="px-6 py-4 text-center text-sm">
                    <span className="text-red-500">✗</span>
                  </td>
                  <td className="px-6 py-4 text-center text-sm">
                    <span className="text-green-500">✓</span>
                  </td>
                  <td className="px-6 py-4 text-center text-sm">
                    <span className="text-green-500">✓</span>
                  </td>
                </tr>
                <tr>
                  <td className="px-6 py-4 text-sm text-gray-900 dark:text-white">
                    Advanced Analytics
                  </td>
                  <td className="px-6 py-4 text-center text-sm">
                    <span className="text-red-500">✗</span>
                  </td>
                  <td className="px-6 py-4 text-center text-sm">
                    <span className="text-green-500">✓</span>
                  </td>
                  <td className="px-6 py-4 text-center text-sm">
                    <span className="text-green-500">✓</span>
                  </td>
                </tr>
                <tr>
                  <td className="px-6 py-4 text-sm text-gray-900 dark:text-white">
                    Custom Integrations
                  </td>
                  <td className="px-6 py-4 text-center text-sm">
                    <span className="text-red-500">✗</span>
                  </td>
                  <td className="px-6 py-4 text-center text-sm">
                    <span className="text-red-500">✗</span>
                  </td>
                  <td className="px-6 py-4 text-center text-sm">
                    <span className="text-green-500">✓</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        {/* FAQ Section */}
        <div className="max-w-4xl mx-auto mt-16">
          <h2 className="text-3xl font-bold text-center text-gray-900 dark:text-white mb-8">
            Frequently Asked Questions
          </h2>

          <div className="space-y-6">
            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                Can I change plans later?
              </h3>
              <p className="text-gray-600 dark:text-gray-400">
                Yes! You can upgrade or downgrade your plan at any time. Changes take effect immediately,
                and we'll prorate any charges or credits.
              </p>
            </div>

            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                What payment methods do you accept?
              </h3>
              <p className="text-gray-600 dark:text-gray-400">
                We accept all major credit cards (Visa, Mastercard, American Express) and debit cards
                through our secure payment processor, Stripe.
              </p>
            </div>

            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                How does the 14-day free trial work?
              </h3>
              <p className="text-gray-600 dark:text-gray-400">
                Start with a 14-day free trial on any paid plan. Your card won't be charged until
                the trial ends. Cancel anytime during the trial with no charge.
              </p>
            </div>

            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                What happens if I cancel?
              </h3>
              <p className="text-gray-600 dark:text-gray-400">
                You can cancel your subscription at any time. You'll retain access until the end of
                your current billing period, then your account will revert to the free plan.
              </p>
            </div>
          </div>
        </div>

        {/* CTA Section */}
        <div className="max-w-4xl mx-auto mt-16 text-center">
          <div className="bg-gradient-to-r from-blue-600 to-purple-600 rounded-2xl p-12 shadow-2xl">
            <h2 className="text-3xl font-bold text-white mb-4">
              Ready to Get Started?
            </h2>
            <p className="text-xl text-blue-100 mb-8">
              Join thousands of satisfied customers using our platform
            </p>
            {!user && (
              <Link
                href="/sign-up"
                className="inline-block px-8 py-4 bg-white text-blue-600 font-semibold rounded-lg hover:bg-gray-100 transition-colors"
              >
                Sign Up Now
              </Link>
            )}
          </div>
        </div>

        {/* Trust Indicators */}
        <div className="max-w-4xl mx-auto mt-16 text-center">
          <p className="text-gray-600 dark:text-gray-400 mb-6">
            Trusted by teams at
          </p>
          <div className="flex justify-center items-center gap-12 flex-wrap opacity-60">
            {/* Add your company logos here */}
            <div className="text-2xl font-bold text-gray-400">Company 1</div>
            <div className="text-2xl font-bold text-gray-400">Company 2</div>
            <div className="text-2xl font-bold text-gray-400">Company 3</div>
            <div className="text-2xl font-bold text-gray-400">Company 4</div>
          </div>
        </div>
      </div>
    </div>
  )
}
