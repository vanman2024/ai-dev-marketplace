import * as React from "react"
import {
  Award,
  BookOpen,
  CheckCircle,
  FileText,
  MessageCircle,
} from "lucide-react"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { cn } from "@/lib/utils"
import type { RecentActivityProps, ActivityItem } from "../types/dashboard"

/**
 * Icon mapping for different activity types
 */
const ACTIVITY_ICONS = {
  course: BookOpen,
  assignment: FileText,
  achievement: Award,
  message: MessageCircle,
  notification: CheckCircle,
} as const

/**
 * RecentActivity Component
 *
 * Displays a list of recent user activities on the dashboard.
 * Activities are displayed in reverse chronological order with icons and timestamps.
 *
 * This is a Server Component by default (no "use client" directive).
 *
 * @example
 * ```tsx
 * const activities = [
 *   {
 *     id: "1",
 *     type: "course",
 *     title: "Completed Module 3",
 *     description: "Introduction to Machine Learning",
 *     timestamp: new Date(),
 *     href: "/courses/ml/module-3",
 *     isRead: true
 *   },
 *   {
 *     id: "2",
 *     type: "assignment",
 *     title: "New Assignment Available",
 *     description: "Python Programming Exercise",
 *     timestamp: new Date(Date.now() - 3600000),
 *     isRead: false
 *   }
 * ]
 *
 * <RecentActivity activities={activities} limit={5} />
 * ```
 */
export function RecentActivity({
  activities,
  limit,
  className,
}: RecentActivityProps) {
  const displayedActivities = limit ? activities.slice(0, limit) : activities

  return (
    <Card className={className}>
      <CardHeader>
        <CardTitle>Recent Activity</CardTitle>
        <CardDescription>
          Your latest activities and updates
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {displayedActivities.length === 0 ? (
            <p className="text-sm text-muted-foreground text-center py-8">
              No recent activities to display
            </p>
          ) : (
            displayedActivities.map((activity) => (
              <ActivityListItem key={activity.id} activity={activity} />
            ))
          )}
        </div>
      </CardContent>
    </Card>
  )
}

/**
 * Individual activity list item component
 */
interface ActivityListItemProps {
  activity: ActivityItem
}

function ActivityListItem({ activity }: ActivityListItemProps) {
  const Icon = ACTIVITY_ICONS[activity.type]
  const formattedTime = formatRelativeTime(activity.timestamp)

  const content = (
    <div
      className={cn(
        "flex items-start gap-4 rounded-lg p-3 transition-colors",
        activity.href && "cursor-pointer hover:bg-accent",
        !activity.isRead && "bg-muted/50"
      )}
    >
      <div
        className={cn(
          "flex h-10 w-10 shrink-0 items-center justify-center rounded-full",
          activity.type === "course" && "bg-blue-100 text-blue-600",
          activity.type === "assignment" && "bg-purple-100 text-purple-600",
          activity.type === "achievement" && "bg-yellow-100 text-yellow-600",
          activity.type === "message" && "bg-green-100 text-green-600",
          activity.type === "notification" && "bg-gray-100 text-gray-600"
        )}
      >
        <Icon className="h-5 w-5" />
      </div>
      <div className="flex-1 space-y-1">
        <div className="flex items-center justify-between">
          <p className="text-sm font-medium leading-none">{activity.title}</p>
          {!activity.isRead && (
            <span className="h-2 w-2 rounded-full bg-blue-600" aria-label="Unread" />
          )}
        </div>
        <p className="text-sm text-muted-foreground">
          {activity.description}
        </p>
        <p className="text-xs text-muted-foreground">{formattedTime}</p>
      </div>
    </div>
  )

  if (activity.href) {
    return (
      <a href={activity.href} className="block">
        {content}
      </a>
    )
  }

  return content
}

/**
 * Format a timestamp into a relative time string (e.g., "2 hours ago")
 */
function formatRelativeTime(date: Date): string {
  const now = new Date()
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000)

  if (diffInSeconds < 60) {
    return "Just now"
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60)
  if (diffInMinutes < 60) {
    return `${diffInMinutes} ${diffInMinutes === 1 ? "minute" : "minutes"} ago`
  }

  const diffInHours = Math.floor(diffInMinutes / 60)
  if (diffInHours < 24) {
    return `${diffInHours} ${diffInHours === 1 ? "hour" : "hours"} ago`
  }

  const diffInDays = Math.floor(diffInHours / 24)
  if (diffInDays < 7) {
    return `${diffInDays} ${diffInDays === 1 ? "day" : "days"} ago`
  }

  const diffInWeeks = Math.floor(diffInDays / 7)
  if (diffInWeeks < 4) {
    return `${diffInWeeks} ${diffInWeeks === 1 ? "week" : "weeks"} ago`
  }

  return date.toLocaleDateString()
}
