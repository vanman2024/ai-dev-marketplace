---
description: Customize Clerk UI appearance and branding - themes, localization, email templates
argument-hint: none
allowed-tools: Task, AskUserQuestion, Read
---

**Arguments**: $ARGUMENTS

Goal: Customize Clerk UI components, themes, localization, and email templates

Core Principles:
- Understand customization goals before implementing
- Ask when requirements are unclear
- Follow Clerk's theming and localization best practices
- Validate customizations with proper testing

Phase 1: Discovery
Goal: Understand customization requirements

Actions:
- If $ARGUMENTS is unclear or empty, use AskUserQuestion to gather:
  - What aspects need customization? (themes, localization, email templates, components)
  - Are you using Clerk Components or custom components?
  - What branding requirements do you have?
  - Do you need dark mode support?
  - Which languages need to be supported?
- Load Clerk configuration files for context
- Example: @src/app/layout.tsx or @app/ClerkProvider

Phase 2: Analysis
Goal: Understand current Clerk setup

Actions:
- Read Clerk provider configuration to understand current setup
- Check for existing theme customizations
- Identify Clerk components in use (SignIn, SignUp, UserButton, etc.)
- Look for existing localization configuration
- Example: !{bash find src -name "*clerk*" -o -name "*sign-in*" -o -name "*sign-up*" | head -10}

Phase 3: Planning
Goal: Design customization approach

Actions:
- Determine which customization areas to focus on:
  - Theme variables (colors, fonts, borders, radii)
  - Component appearance (buttons, inputs, layouts)
  - Localization strings
  - Email templates
- Identify files that need to be created or modified
- Confirm approach with user if significant changes required

Phase 4: Implementation
Goal: Apply customizations with clerk-ui-customizer agent

Actions:

Task(description="Customize Clerk UI", subagent_type="clerk:clerk-ui-customizer", prompt="You are the clerk-ui-customizer agent. Customize Clerk UI for $ARGUMENTS.

Context: User wants to customize Clerk's appearance and branding

Customization Requirements:
- Theme customization (colors, fonts, spacing)
- Component styling (buttons, inputs, cards)
- Localization setup (if multi-language support needed)
- Email template customization (if needed)
- Dark mode support (if required)

Current Setup:
- Clerk provider configuration detected in project
- Existing Clerk components identified

Expected Output:
- Appearance prop configuration in ClerkProvider
- Theme variables defined
- Localization configuration (if needed)
- Custom CSS or styling (if needed)
- Email template customizations (if applicable)
- Dark mode implementation (if required)
- Documentation of customization approach")

Phase 5: Verification
Goal: Verify customizations work correctly

Actions:
- Review implemented customizations
- Check that theme variables are properly applied
- Verify localization files are correctly configured
- Ensure email templates follow Clerk's requirements
- Validate dark mode toggle works (if implemented)
- Example: !{bash npm run typecheck || echo "No typecheck available"}

Phase 6: Summary
Goal: Document customizations and next steps

Actions:
- Summarize customizations applied:
  - Theme variables configured
  - Components styled
  - Localization languages added
  - Email templates customized
- Highlight customization decisions:
  - Color scheme choices
  - Font selections
  - Localization strategy
- Suggest next steps:
  - Test in different browsers
  - Verify email templates in Clerk Dashboard
  - Add additional language translations
  - Test dark mode across all components
