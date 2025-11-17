/**
 * Organization Switcher Component
 *
 * Allows users to switch between organizations they belong to.
 * Integrates with Clerk's organization management system.
 *
 * Features:
 * - Display current organization
 * - List all user's organizations
 * - Switch organization context
 * - Create new organization option
 * - Keyboard navigation support
 */

'use client';

import { useOrganization, useOrganizationList, useUser } from '@clerk/nextjs';
import { OrganizationSwitcher as ClerkOrgSwitcher } from '@clerk/nextjs';
import { useState } from 'react';

/**
 * Simple Organization Switcher (uses Clerk's built-in component)
 *
 * This is the recommended approach - uses Clerk's pre-built UI
 */
export function SimpleOrganizationSwitcher() {
  return (
    <ClerkOrgSwitcher
      appearance={{
        elements: {
          rootBox: 'flex items-center',
          organizationSwitcherTrigger:
            'px-4 py-2 rounded-lg border border-gray-300 hover:bg-gray-50',
        },
      }}
      // Show organization profile option
      organizationProfileMode="modal"
      // Show create organization option
      createOrganizationMode="modal"
      // After switching, refresh the page
      afterSwitchOrganizationUrl="/"
    />
  );
}

/**
 * Custom Organization Switcher with Dropdown
 *
 * Use this for more control over the UI and behavior
 */
export function CustomOrganizationSwitcher() {
  const { organization, membership } = useOrganization();
  const { setActive, userMemberships, isLoaded } = useOrganizationList({
    userMemberships: {
      infinite: true,
    },
  });
  const { user } = useUser();
  const [isOpen, setIsOpen] = useState(false);

  if (!isLoaded) {
    return (
      <div className="w-48 h-10 bg-gray-200 animate-pulse rounded-lg" />
    );
  }

  const handleSwitch = async (orgId: string) => {
    if (!setActive) return;

    try {
      await setActive({ organization: orgId });
      setIsOpen(false);
      // Optionally refresh the page
      window.location.reload();
    } catch (error) {
      console.error('Failed to switch organization:', error);
    }
  };

  const handleCreateOrganization = () => {
    // Redirect to create organization page
    window.location.href = '/create-organization';
  };

  return (
    <div className="relative">
      {/* Trigger Button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-300 hover:bg-gray-50 transition-colors"
        aria-label="Switch organization"
      >
        {organization ? (
          <>
            {/* Organization Avatar */}
            <div className="w-6 h-6 rounded-full bg-blue-500 flex items-center justify-center text-white text-xs font-semibold">
              {organization.name.charAt(0).toUpperCase()}
            </div>
            {/* Organization Name */}
            <span className="font-medium text-sm">{organization.name}</span>
            {/* Role Badge */}
            {membership?.role && (
              <span className="text-xs px-2 py-0.5 rounded-full bg-gray-100 text-gray-600">
                {membership.role.replace('org:', '')}
              </span>
            )}
          </>
        ) : (
          <>
            {/* Personal Account */}
            <div className="w-6 h-6 rounded-full bg-gray-400 flex items-center justify-center text-white text-xs font-semibold">
              {user?.firstName?.charAt(0).toUpperCase() || 'P'}
            </div>
            <span className="font-medium text-sm">Personal</span>
          </>
        )}
        {/* Dropdown Icon */}
        <svg
          className={`w-4 h-4 transition-transform ${isOpen ? 'rotate-180' : ''}`}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {/* Dropdown Menu */}
      {isOpen && (
        <>
          {/* Backdrop */}
          <div
            className="fixed inset-0 z-10"
            onClick={() => setIsOpen(false)}
          />

          {/* Dropdown Content */}
          <div className="absolute top-full mt-2 w-64 bg-white rounded-lg shadow-lg border border-gray-200 z-20">
            {/* Personal Account Option */}
            <button
              onClick={() => handleSwitch('')}
              className="w-full px-4 py-3 text-left hover:bg-gray-50 flex items-center gap-2 border-b border-gray-100"
            >
              <div className="w-8 h-8 rounded-full bg-gray-400 flex items-center justify-center text-white text-sm font-semibold">
                {user?.firstName?.charAt(0).toUpperCase() || 'P'}
              </div>
              <div className="flex-1">
                <p className="font-medium text-sm">Personal Account</p>
                <p className="text-xs text-gray-500">{user?.primaryEmailAddress?.emailAddress}</p>
              </div>
              {!organization && (
                <svg className="w-5 h-5 text-blue-500" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fillRule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                    clipRule="evenodd"
                  />
                </svg>
              )}
            </button>

            {/* Organization List Header */}
            {userMemberships.data && userMemberships.data.length > 0 && (
              <div className="px-4 py-2 text-xs font-semibold text-gray-500 uppercase tracking-wide border-b border-gray-100">
                Organizations
              </div>
            )}

            {/* Organization List */}
            {userMemberships.data?.map((membership) => (
              <button
                key={membership.organization.id}
                onClick={() => handleSwitch(membership.organization.id)}
                className="w-full px-4 py-3 text-left hover:bg-gray-50 flex items-center gap-2"
              >
                <div className="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center text-white text-sm font-semibold">
                  {membership.organization.name.charAt(0).toUpperCase()}
                </div>
                <div className="flex-1">
                  <p className="font-medium text-sm">{membership.organization.name}</p>
                  <p className="text-xs text-gray-500">
                    {membership.role.replace('org:', '')}
                  </p>
                </div>
                {organization?.id === membership.organization.id && (
                  <svg className="w-5 h-5 text-blue-500" fill="currentColor" viewBox="0 0 20 20">
                    <path
                      fillRule="evenodd"
                      d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                      clipRule="evenodd"
                    />
                  </svg>
                )}
              </button>
            ))}

            {/* Create Organization Button */}
            <button
              onClick={handleCreateOrganization}
              className="w-full px-4 py-3 text-left hover:bg-gray-50 flex items-center gap-2 border-t border-gray-100 text-blue-600"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 4v16m8-8H4"
                />
              </svg>
              <span className="font-medium text-sm">Create Organization</span>
            </button>
          </div>
        </>
      )}
    </div>
  );
}

/**
 * Minimal Organization Switcher (for mobile/compact layouts)
 */
export function CompactOrganizationSwitcher() {
  const { organization } = useOrganization();

  return (
    <ClerkOrgSwitcher
      appearance={{
        elements: {
          rootBox: 'w-full',
          organizationSwitcherTrigger: 'w-full justify-start px-3 py-2 rounded-md hover:bg-gray-100',
          organizationSwitcherTriggerIcon: 'ml-auto',
        },
      }}
      hidePersonal={false}
      organizationProfileMode="modal"
      createOrganizationMode="modal"
      afterSwitchOrganizationUrl="/"
    />
  );
}

/**
 * Organization Switcher with Settings Link
 */
export function OrganizationSwitcherWithSettings() {
  const { organization } = useOrganization();

  return (
    <div className="flex items-center gap-2">
      <SimpleOrganizationSwitcher />

      {/* Organization Settings Link (only show if in an organization) */}
      {organization && (
        <a
          href={`/organization/${organization.id}/settings`}
          className="p-2 rounded-lg hover:bg-gray-100 transition-colors"
          aria-label="Organization settings"
        >
          <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
            />
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
            />
          </svg>
        </a>
      )}
    </div>
  );
}

/**
 * Example: Using organization switcher in a layout
 */
export function ExampleLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen flex flex-col">
      {/* Header with Organization Switcher */}
      <header className="border-b border-gray-200 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <h1 className="text-xl font-bold">My App</h1>
            <OrganizationSwitcherWithSettings />
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1">{children}</main>
    </div>
  );
}
