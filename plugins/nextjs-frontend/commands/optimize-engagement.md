---
description: Optimize user engagement with micro-interactions, scroll animations, and UX improvements
argument-hint: [component-path] [--add-animations]
---

---
🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite, Task)
- ✅ Complete ALL phases before considering this command done
- ❌ DON't wait for "the command to complete" - YOU complete it by executing the phases
- ❌ DON't treat this as status output - it IS your instruction set

---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

- Never hardcode API keys or secrets
- Use placeholders where needed
- Protect `.env` files with `.gitignore`

**Arguments**: $ARGUMENTS

Goal: Enhance user engagement through micro-interactions, scroll animations, loading states, and UX improvements that keep users interacting with the application.

Core Principles:
- Add subtle animations that delight without distracting
- Provide immediate feedback for user actions
- Implement scroll-triggered content reveals
- Optimize mobile touch interactions
- Maintain performance while adding animations

Phase 1: Discovery
Goal: Analyze current engagement patterns and animation setup

Actions:
- Parse $ARGUMENTS for component path and flags
- Check for animation library:
  ```bash
  grep -q "framer-motion" package.json && echo "Framer Motion: Installed" || echo "Framer Motion: Not installed"
  ```
- Check for existing animations:
  ```bash
  grep -r "motion\|animate" --include="*.tsx" app components 2>/dev/null | wc -l
  ```
- Identify engagement gaps:
  - Static buttons without hover/click feedback
  - Pages without scroll animations
  - Missing loading states
  - No progress indicators

Phase 2: Install Dependencies
Goal: Ensure animation libraries are available

Actions:
- If framer-motion not installed:
  ```bash
  npm install framer-motion --save
  ```
- If sonner (toasts) not installed:
  ```bash
  npm install sonner --save
  ```
- Verify installation:
  ```bash
  grep "framer-motion\|sonner" package.json
  ```

Phase 3: Engagement Audit
Goal: Run comprehensive engagement analysis using specialist agent

Actions:
- Invoke engagement specialist for detailed audit:

Task(description="Engagement audit for Next.js", subagent_type="nextjs-frontend:engagement-specialist-agent", prompt="You are the engagement specialist agent. Analyze this Next.js application for user engagement optimization opportunities.

Target: $ARGUMENTS

Audit Checklist:

1. **Button Interactions**
   - Do buttons have hover states?
   - Is there click feedback (scale, color change)?
   - Are loading states shown during async operations?

2. **Form Interactions**
   - Focus states visible?
   - Error states clear and helpful?
   - Success feedback provided?

3. **Scroll Engagement**
   - Are there scroll progress indicators?
   - Do elements animate in on scroll?
   - Is lazy loading implemented?

4. **Navigation**
   - Page transitions smooth?
   - Active states visible?
   - Mobile menu has smooth open/close?

5. **Loading States**
   - Skeleton loaders for content?
   - Spinners for async operations?
   - Progress bars for uploads?

6. **Social Proof**
   - Testimonials animated?
   - Stats have count-up animations?
   - Trust badges visible?

Deliverable: Prioritized list of engagement improvements with implementation difficulty (Easy/Medium/Hard)")

Phase 4: Implement Micro-Interactions
Goal: Add button, card, and form interactions

Actions:
- Create engaging button component if needed:
  - Hover scale effect (1.02)
  - Click scale effect (0.98)
  - Loading state with spinner
  - Success state with checkmark

- Create card hover effects:
  - Subtle lift on hover (y: -4)
  - Shadow increase
  - Optional image zoom

- Enhance form interactions:
  - Focus ring animations
  - Error shake animation
  - Success checkmark animation

Phase 5: Add Scroll Animations
Goal: Implement scroll-triggered reveals

Actions:
- Create ScrollReveal component:
  - Fade up on viewport entry
  - Configurable delay and duration
  - useInView hook integration

- Add scroll progress indicator (for long pages):
  - Fixed top bar
  - Shows reading progress
  - Smooth animation

- Implement lazy loading:
  - Images fade in on load
  - Content sections reveal on scroll

Phase 6: Optimize Loading States
Goal: Ensure all async operations have feedback

Actions:
- Check for async operations without loading states:
  ```bash
  grep -r "async\|await\|fetch\|useSWR\|useQuery" --include="*.tsx" app components | head -20
  ```
- Add skeleton loaders for data-dependent components
- Implement progress indicators for multi-step processes
- Add toast notifications for background operations

Phase 7: Mobile Touch Optimization
Goal: Enhance mobile interaction experience

Actions:
- Verify touch targets are 44x44px minimum
- Add touch feedback (active states)
- Implement swipe gestures where appropriate
- Test pull-to-refresh if applicable

Phase 8: Generate Engagement Report
Goal: Document all improvements

Actions:
- Generate markdown report with:
  - Engagement score improvement
  - Components enhanced
  - Animations added
  - Performance impact notes

Display final summary:
```
Engagement Optimization Complete
================================
✅ Framer Motion installed and configured
✅ Button interactions enhanced
✅ Scroll animations implemented
✅ Loading states added
✅ Mobile touch optimized

Components Enhanced:
- Button: hover/click/loading states
- Card: lift and shadow animations
- Forms: focus/error/success feedback
- Sections: scroll reveal animations

Performance Notes:
- Animations use GPU acceleration
- Reduced motion respected
- Lazy loading prevents layout shift

Next Steps:
1. Test on various devices
2. Monitor engagement metrics
3. A/B test animation intensity
```
