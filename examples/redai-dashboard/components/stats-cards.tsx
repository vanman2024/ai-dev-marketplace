import * as React from "react"
import { ArrowDown, ArrowUp, Minus } from "lucide-react"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import type { StatsCardsProps, DashboardStat } from "../types/dashboard"
import { cn } from "@/lib/utils"

/**
 * StatsCards Component
 *
 * Displays a grid of statistical cards showing key metrics for the dashboard.
 * Each card can display a value, change indicator, icon, and description.
 *
 * This is a Server Component by default (no "use client" directive).
 *
 * @example
 * ```tsx
 * import { BookOpen, Users, CheckCircle } from "lucide-react"
 *
 * const stats = [
 *   {
 *     id: "courses",
 *     label: "Active Courses",
 *     value: 8,
 *     change: "+2",
 *     changeType: "positive",
 *     icon: BookOpen
 *   },
 *   {
 *     id: "students",
 *     label: "Total Students",
 *     value: "1,234",
 *     change: "+12%",
 *     changeType: "positive",
 *     icon: Users
 *   }
 * ]
 *
 * <StatsCards stats={stats} />
 * ```
 */
export function StatsCards({ stats, className }: StatsCardsProps) {
  return (
    <div className={cn("grid gap-4 md:grid-cols-2 lg:grid-cols-4", className)}>
      {stats.map((stat) => (
        <StatCard key={stat.id} stat={stat} />
      ))}
    </div>
  )
}

/**
 * Individual stat card component
 */
interface StatCardProps {
  stat: DashboardStat
}

function StatCard({ stat }: StatCardProps) {
  const Icon = stat.icon

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">{stat.label}</CardTitle>
        {Icon && (
          <Icon className="h-4 w-4 text-muted-foreground" />
        )}
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{stat.value}</div>
        {stat.change && (
          <div className="flex items-center gap-1 pt-1">
            {stat.changeType === "positive" && (
              <ArrowUp className="h-4 w-4 text-green-600" />
            )}
            {stat.changeType === "negative" && (
              <ArrowDown className="h-4 w-4 text-red-600" />
            )}
            {stat.changeType === "neutral" && (
              <Minus className="h-4 w-4 text-muted-foreground" />
            )}
            <p
              className={cn(
                "text-xs",
                stat.changeType === "positive" && "text-green-600",
                stat.changeType === "negative" && "text-red-600",
                stat.changeType === "neutral" && "text-muted-foreground"
              )}
            >
              {stat.change}
            </p>
            {stat.description && (
              <p className="text-xs text-muted-foreground ml-1">
                {stat.description}
              </p>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
