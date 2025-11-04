/**
 * Dashboard Component Types for RedAI Education Platform
 *
 * This file contains all TypeScript type definitions for the dashboard components.
 */

/**
 * Statistical metric displayed on the dashboard
 */
export interface DashboardStat {
  /** Unique identifier for the stat */
  id: string
  /** Display label for the stat */
  label: string
  /** The numeric or string value to display */
  value: string | number
  /** Optional change indicator (e.g., "+12%", "-3%") */
  change?: string
  /** Whether the change is positive or negative (affects styling) */
  changeType?: 'positive' | 'negative' | 'neutral'
  /** Icon component to display (from lucide-react) */
  icon?: React.ComponentType<{ className?: string }>
  /** Optional description or tooltip */
  description?: string
}

/**
 * Activity item displayed in the recent activity section
 */
export interface ActivityItem {
  /** Unique identifier for the activity */
  id: string
  /** Type of activity (affects icon and styling) */
  type: 'course' | 'assignment' | 'achievement' | 'message' | 'notification'
  /** Activity title */
  title: string
  /** Activity description or details */
  description: string
  /** Timestamp of the activity */
  timestamp: Date
  /** URL to navigate to when clicked */
  href?: string
  /** Whether the activity has been read/viewed */
  isRead?: boolean
}

/**
 * Navigation item for the sidebar
 */
export interface NavItem {
  /** Display title for the nav item */
  title: string
  /** Navigation URL */
  url: string
  /** Icon component from lucide-react */
  icon?: React.ComponentType<{ className?: string }>
  /** Whether this nav item is currently active */
  isActive?: boolean
  /** Optional badge count (e.g., unread messages) */
  badge?: number
}

/**
 * Navigation section grouping multiple nav items
 */
export interface NavSection {
  /** Section title */
  title: string
  /** Array of navigation items in this section */
  items: NavItem[]
}

/**
 * User profile information
 */
export interface UserProfile {
  /** User's full name */
  name: string
  /** User's email address */
  email: string
  /** URL to user's avatar image */
  avatarUrl?: string
  /** User's role in the platform */
  role: 'student' | 'teacher' | 'admin'
  /** Optional initials for avatar fallback */
  initials?: string
}

/**
 * Props for the DashboardLayout component
 */
export interface DashboardLayoutProps {
  /** Child components to render in the main content area */
  children: React.ReactNode
  /** User profile information for the header */
  user: UserProfile
  /** Navigation sections for the sidebar */
  navigation: NavSection[]
}

/**
 * Props for the StatsCards component
 */
export interface StatsCardsProps {
  /** Array of statistics to display */
  stats: DashboardStat[]
  /** Optional className for custom styling */
  className?: string
}

/**
 * Props for the RecentActivity component
 */
export interface RecentActivityProps {
  /** Array of activity items to display */
  activities: ActivityItem[]
  /** Maximum number of activities to show */
  limit?: number
  /** Optional className for custom styling */
  className?: string
}

/**
 * Props for the UserProfileHeader component
 */
export interface UserProfileHeaderProps {
  /** User profile information */
  user: UserProfile
  /** Optional className for custom styling */
  className?: string
  /** Callback when profile is clicked */
  onProfileClick?: () => void
}
