---
name: add-responsive
description: Add responsive design patterns for mobile web
allowed-tools: Task, Bash, Read, Write, Edit, Glob, Grep, TodoWrite, AskUserQuestion
---

# /mobile:add-responsive

Add responsive design with Tailwind CSS and mobile-first patterns.

## Arguments

$ARGUMENTS - Optional: target framework

## Execution

### Phase 1: Detect Framework

Check for Next.js and Tailwind installation.

### Phase 2: Invoke Responsive Specialist

Task(description="Setup responsive design", subagent_type="responsive-design-specialist", prompt="Add responsive design utilities:

Create:
1. Tailwind config with:
   - Fluid typography (clamp-based)
   - Safe area spacing
   - Touch-friendly utilities
2. components/ResponsiveContainer.tsx
3. components/ResponsiveGrid.tsx
4. components/ResponsiveNav.tsx (hamburger on mobile)
5. components/ResponsiveImage.tsx (with Next/Image)
6. components/BreakpointIndicator.tsx (dev only)

Focus on mobile-first approach.
Include touch targets minimum 44x44px.")

### Phase 3: Summary

Display:
- Responsive utilities added
- Components: Container, Grid, Nav, Image
- Tailwind extended with fluid typography
- Next: Apply patterns to existing components
