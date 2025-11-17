'use client'

import { UserButton } from '@clerk/nextjs'
import { useRouter } from 'next/navigation'
import { LayoutDashboard, Settings, CreditCard, HelpCircle } from 'lucide-react'

export function CustomUserButton() {
  const router = useRouter()

  return (
    <UserButton
      appearance={{
        elements: {
          userButtonAvatarBox: "w-10 h-10",
          userButtonPopoverCard: "shadow-xl border border-gray-200",
          userButtonPopoverActionButton: "hover:bg-gray-100",
          userButtonPopoverActionButtonText: "text-gray-700",
          userButtonPopoverActionButtonIcon: "text-gray-500"
        }
      }}
    >
      {/* Custom menu items */}
      <UserButton.MenuItems>
        <UserButton.Link
          label="Dashboard"
          labelIcon={<LayoutDashboard size={16} />}
          href="/dashboard"
        />
        <UserButton.Action
          label="Settings"
          labelIcon={<Settings size={16} />}
          onClick={() => router.push('/settings')}
        />
        <UserButton.Action
          label="Billing"
          labelIcon={<CreditCard size={16} />}
          onClick={() => router.push('/billing')}
        />
        <UserButton.Link
          label="Help"
          labelIcon={<HelpCircle size={16} />}
          href="/help"
        />
      </UserButton.MenuItems>

      {/* User profile customization */}
      <UserButton.UserProfilePage
        label="Custom Page"
        url="custom"
      >
        <div className="p-4">
          <h2 className="text-lg font-semibold mb-2">Custom Profile Section</h2>
          <p className="text-gray-600">Add custom content here</p>
        </div>
      </UserButton.UserProfilePage>
    </UserButton>
  )
}

// Simplified version without custom items
export function SimpleUserButton() {
  return (
    <UserButton
      appearance={{
        elements: {
          userButtonAvatarBox: "w-9 h-9 border-2 border-gray-200",
          userButtonPopoverCard: "shadow-lg"
        }
      }}
      afterSignOutUrl="/"
    />
  )
}

// User button with custom avatar size
export function LargeUserButton() {
  return (
    <UserButton
      appearance={{
        elements: {
          userButtonAvatarBox: "w-12 h-12",
        }
      }}
    />
  )
}
