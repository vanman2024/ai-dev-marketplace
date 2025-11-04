"use client"

import * as React from "react"
import { Book, GraduationCap, LayoutDashboard, MessageSquare, Settings, Users } from "lucide-react"
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarRail,
} from "@/components/ui/sidebar"
import type { NavSection } from "../types/dashboard"

/**
 * Props for the DashboardSidebar component
 */
export interface DashboardSidebarProps extends React.ComponentProps<typeof Sidebar> {
  /** Navigation sections to display in the sidebar */
  navigation: NavSection[]
}

/**
 * DashboardSidebar Component
 *
 * Navigation sidebar for the RedAI education platform dashboard.
 * Displays grouped navigation items with icons and active states.
 *
 * @example
 * ```tsx
 * const navigation = [
 *   {
 *     title: "Main",
 *     items: [
 *       { title: "Dashboard", url: "/dashboard", icon: LayoutDashboard, isActive: true },
 *       { title: "Courses", url: "/courses", icon: Book }
 *     ]
 *   }
 * ]
 *
 * <DashboardSidebar navigation={navigation} />
 * ```
 */
export function DashboardSidebar({ navigation, ...props }: DashboardSidebarProps) {
  return (
    <Sidebar {...props}>
      <SidebarHeader>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton size="lg" className="data-[state=open]:bg-sidebar-accent">
              <div className="bg-primary text-primary-foreground flex aspect-square size-8 items-center justify-center rounded-lg">
                <GraduationCap className="size-4" />
              </div>
              <div className="flex flex-col gap-0.5 leading-none">
                <span className="font-semibold">RedAI</span>
                <span className="text-xs text-muted-foreground">Education Platform</span>
              </div>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>

      <SidebarContent>
        {navigation.map((section) => (
          <SidebarGroup key={section.title}>
            <SidebarGroupLabel>{section.title}</SidebarGroupLabel>
            <SidebarGroupContent>
              <SidebarMenu>
                {section.items.map((item) => (
                  <SidebarMenuItem key={item.title}>
                    <SidebarMenuButton asChild isActive={item.isActive}>
                      <a href={item.url}>
                        {item.icon && <item.icon className="size-4" />}
                        <span>{item.title}</span>
                        {item.badge !== undefined && item.badge > 0 && (
                          <span className="ml-auto flex h-5 min-w-5 items-center justify-center rounded-full bg-primary px-1.5 text-xs font-medium text-primary-foreground">
                            {item.badge}
                          </span>
                        )}
                      </a>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                ))}
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>
        ))}
      </SidebarContent>

      <SidebarRail />
    </Sidebar>
  )
}
