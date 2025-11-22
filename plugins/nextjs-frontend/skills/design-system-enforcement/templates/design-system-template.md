# shadcn/ui with Tailwind v4 Design System Guidelines

**MANDATORY REFERENCE**: All agents MUST read and strictly adhere to these guidelines before creating any components, pages, or UI elements.

---

## Project Configuration

**Project Name**: {{PROJECT_NAME}}
**Primary Brand Color**: {{BRAND_COLOR}}
**Color Scheme**: {{COLOR_SCHEME}}
**Typography Scale**: 4 sizes, 2 weights (ENFORCED)
**Spacing Unit**: 8pt grid (ENFORCED)

---

## Core Design Principles

### 1. Typography System: 4 Sizes, 2 Weights

**STRICTLY ENFORCE**: Only 4 font sizes and 2 font weights allowed.

- **4 Font Sizes Only**:
  - Size 1: {{FONT_SIZE_1}} - Large headings
  - Size 2: {{FONT_SIZE_2}} - Subheadings/Important content
  - Size 3: {{FONT_SIZE_3}} - Body text
  - Size 4: {{FONT_SIZE_4}} - Small text/labels

- **2 Font Weights Only**:
  - Semibold (font-semibold): For headings and emphasis
  - Regular (font-normal): For body text and general content

**Tailwind Classes**:
- `text-3xl font-semibold` - Large headings
- `text-2xl font-semibold` - Subheadings
- `text-base font-normal` - Body text
- `text-sm font-normal` - Small text/labels

**FORBIDDEN**: Using more than 4 font sizes or additional font weights (text-xs, text-lg, text-xl, text-4xl, font-bold, font-light, etc.)

---

### 2. 8pt Grid System

**STRICTLY ENFORCE**: All spacing values MUST be divisible by 8 or 4.

**Allowed Values**:
- DO: Use 4, 8, 12, 16, 20, 24, 32, 40, 48, 56, 64px
- DON'T: Use 5, 7, 9, 11, 13, 15, 19, 25px

**Tailwind Utilities**:
- Padding: p-1 (4px), p-2 (8px), p-3 (12px), p-4 (16px), p-6 (24px), p-8 (32px)
- Margin: m-1 (4px), m-2 (8px), m-4 (16px), m-6 (24px), m-8 (32px)
- Gap: gap-1 (4px), gap-2 (8px), gap-4 (16px), gap-6 (24px), gap-8 (32px)
- Space: space-y-2 (8px), space-y-4 (16px), space-y-6 (24px)

**FORBIDDEN**: Any spacing value not divisible by 4 (p-5, m-7, gap-3, space-y-1.5, px-2.5, py-0.5)

---

### 3. 60/30/10 Color Rule

**STRICTLY ENFORCE**: Color distribution must follow this exact ratio.

- **60%: Neutral color** - `bg-background`
- **30%: Complementary color** - `text-foreground`
- **10%: Accent color** - `bg-primary` ({{BRAND_COLOR}})

**FORBIDDEN**: Overusing accent colors (exceeding 10%)

---

### 4. Clean Visual Structure

- **Logical Grouping**: Related elements must be visually connected
- **Deliberate Spacing**: Must follow 8pt grid system
- **Alignment**: Elements must be properly aligned
- **Simplicity Over Flashiness**: Clarity first

---

## Color Variables (globals.css)

```css
:root {
  /* 60% - Neutral Background */
  --background: {{BACKGROUND_OKLCH}};
  --foreground: {{FOREGROUND_OKLCH}};

  /* 30% - Complementary */
  --muted: {{MUTED_OKLCH}};
  --muted-foreground: {{MUTED_FOREGROUND_OKLCH}};

  /* 10% - Accent Brand */
  --primary: {{PRIMARY_OKLCH}};
  --primary-foreground: {{PRIMARY_FOREGROUND_OKLCH}};
}

.dark {
  --background: {{DARK_BACKGROUND_OKLCH}};
  --foreground: {{DARK_FOREGROUND_OKLCH}};
  --primary: {{DARK_PRIMARY_OKLCH}};
  --primary-foreground: {{DARK_PRIMARY_FOREGROUND_OKLCH}};
}

@theme {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
}
```

---

## Component Standards

### Button Component

**Location**: `components/ui/button.tsx`

#### Variants (When to Use)

| Variant | Use Case | Example |
|---------|----------|---------|
| `default` | Primary actions, CTAs | "Submit", "Save", "Continue" |
| `secondary` | Secondary actions | "Cancel", "Back", "Skip" |
| `destructive` | Dangerous actions | "Delete", "Remove", "Clear All" |
| `outline` | Tertiary actions, less emphasis | "Learn More", "View Details" |
| `ghost` | Minimal UI, toolbars, nav items | Icon buttons, menu items |
| `link` | Inline text actions | "Forgot password?", "Read more" |

#### Sizes (When to Use)

| Size | Height | Padding | Use Case |
|------|--------|---------|----------|
| `sm` | 36px (h-9) | px-3 | Compact UI, tables, inline actions |
| `default` | 40px (h-10) | px-4 | Standard forms, dialogs |
| `lg` | 44px (h-11) | px-8 | Hero sections, prominent CTAs |
| `icon` | 40px x 40px | - | Icon-only buttons |

#### Code Examples

```tsx
// Primary CTA
<Button>Get Started</Button>

// Secondary action
<Button variant="secondary">Cancel</Button>

// Destructive with confirmation
<Button variant="destructive">Delete Account</Button>

// Small button in table
<Button size="sm" variant="outline">Edit</Button>

// Icon button
<Button size="icon" variant="ghost">
  <Settings className="h-4 w-4" />
</Button>

// Large hero CTA
<Button size="lg">Start Free Trial</Button>
```

#### Button Groups

```tsx
// Standard button group - use gap-2 (8px)
<div className="flex gap-2">
  <Button variant="outline">Cancel</Button>
  <Button>Save</Button>
</div>

// Stacked buttons - use gap-2 (8px)
<div className="flex flex-col gap-2">
  <Button>Primary Action</Button>
  <Button variant="outline">Secondary Action</Button>
</div>
```

---

### Card Component

**Location**: `components/ui/card.tsx`

#### Standard Card Structure

```tsx
<Card>
  <CardHeader>
    <CardTitle>Card Title</CardTitle>
    <CardDescription>Optional description text</CardDescription>
  </CardHeader>
  <CardContent>
    {/* Main content */}
  </CardContent>
  <CardFooter>
    {/* Actions */}
  </CardFooter>
</Card>
```

#### Card Spacing Rules

- **CardHeader**: `p-6` (24px padding)
- **CardContent**: `p-6 pt-0` (24px padding, no top)
- **CardFooter**: `p-6 pt-0` (24px padding, no top)
- **Gap between cards**: `gap-4` (16px) or `gap-6` (24px)

#### Card Patterns

```tsx
// Simple info card
<Card>
  <CardHeader>
    <CardTitle className="text-2xl font-semibold">Statistics</CardTitle>
  </CardHeader>
  <CardContent>
    <p className="text-base">Your content here</p>
  </CardContent>
</Card>

// Card with actions
<Card>
  <CardHeader>
    <CardTitle>Settings</CardTitle>
    <CardDescription>Manage your preferences</CardDescription>
  </CardHeader>
  <CardContent>
    {/* Form fields */}
  </CardContent>
  <CardFooter className="flex justify-end gap-2">
    <Button variant="outline">Cancel</Button>
    <Button>Save</Button>
  </CardFooter>
</Card>

// Card grid layout
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <Card>...</Card>
  <Card>...</Card>
  <Card>...</Card>
</div>
```

---

### Form Elements

#### Input Component

**Location**: `components/ui/input.tsx`

```tsx
// Standard input with label
<div className="space-y-2">
  <Label htmlFor="email">Email</Label>
  <Input id="email" type="email" placeholder="you@example.com" />
</div>

// Input with error
<div className="space-y-2">
  <Label htmlFor="password">Password</Label>
  <Input id="password" type="password" className="border-destructive" />
  <p className="text-sm text-destructive">Password is required</p>
</div>
```

#### Form Layout Patterns

```tsx
// Vertical form (default)
<form className="space-y-4">
  <div className="space-y-2">
    <Label>Field 1</Label>
    <Input />
  </div>
  <div className="space-y-2">
    <Label>Field 2</Label>
    <Input />
  </div>
  <Button type="submit">Submit</Button>
</form>

// Two-column form
<form className="space-y-4">
  <div className="grid grid-cols-2 gap-4">
    <div className="space-y-2">
      <Label>First Name</Label>
      <Input />
    </div>
    <div className="space-y-2">
      <Label>Last Name</Label>
      <Input />
    </div>
  </div>
</form>
```

#### Select Component

```tsx
<div className="space-y-2">
  <Label>Category</Label>
  <Select>
    <SelectTrigger>
      <SelectValue placeholder="Select a category" />
    </SelectTrigger>
    <SelectContent>
      <SelectItem value="option1">Option 1</SelectItem>
      <SelectItem value="option2">Option 2</SelectItem>
    </SelectContent>
  </Select>
</div>
```

#### Checkbox & Switch

```tsx
// Checkbox with label
<div className="flex items-center gap-2">
  <Checkbox id="terms" />
  <Label htmlFor="terms" className="text-sm">
    Accept terms and conditions
  </Label>
</div>

// Switch with label
<div className="flex items-center justify-between">
  <Label htmlFor="notifications">Enable notifications</Label>
  <Switch id="notifications" />
</div>
```

---

### Badge Component

**Location**: `components/ui/badge.tsx`

#### Variants

| Variant | Use Case |
|---------|----------|
| `default` | Status indicators (primary color) |
| `secondary` | Neutral tags, categories |
| `destructive` | Errors, warnings, alerts |
| `outline` | Subtle indicators |

```tsx
// Status badge
<Badge>Active</Badge>

// Category tag
<Badge variant="secondary">Documentation</Badge>

// Error indicator
<Badge variant="destructive">Failed</Badge>

// Subtle label
<Badge variant="outline">Beta</Badge>
```

---

### Dialog/Modal Component

**Location**: `components/ui/dialog.tsx`

#### Standard Dialog Structure

```tsx
<Dialog>
  <DialogTrigger asChild>
    <Button>Open Dialog</Button>
  </DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Dialog Title</DialogTitle>
      <DialogDescription>
        Brief description of the dialog purpose.
      </DialogDescription>
    </DialogHeader>
    <div className="py-4">
      {/* Dialog content */}
    </div>
    <DialogFooter>
      <Button variant="outline">Cancel</Button>
      <Button>Confirm</Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

#### Dialog Sizing

- Default width: `max-w-lg` (512px)
- Small dialogs: `max-w-sm` (384px)
- Large dialogs: `max-w-2xl` (672px)

---

### Layout Patterns

#### Page Container

```tsx
// Standard page container
<div className="container mx-auto px-4 py-8">
  {/* Page content */}
</div>

// With max-width constraint
<div className="container mx-auto px-4 py-8 max-w-4xl">
  {/* Centered content */}
</div>
```

#### Section Spacing

```tsx
// Between major sections - use py-8 or py-16
<section className="py-8">
  <h2 className="text-2xl font-semibold mb-4">Section Title</h2>
  {/* Section content */}
</section>

// Content grouping - use space-y-4 or space-y-6
<div className="space-y-4">
  <Component1 />
  <Component2 />
  <Component3 />
</div>
```

#### Grid Layouts

```tsx
// Responsive grid
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  {items.map(item => <Card key={item.id}>...</Card>)}
</div>

// Sidebar layout
<div className="flex gap-6">
  <aside className="w-64 shrink-0">
    {/* Sidebar */}
  </aside>
  <main className="flex-1">
    {/* Main content */}
  </main>
</div>
```

---

### Tabs Component

**Location**: `components/ui/tabs.tsx`

```tsx
<Tabs defaultValue="tab1">
  <TabsList>
    <TabsTrigger value="tab1">Tab 1</TabsTrigger>
    <TabsTrigger value="tab2">Tab 2</TabsTrigger>
  </TabsList>
  <TabsContent value="tab1" className="mt-4">
    {/* Tab 1 content */}
  </TabsContent>
  <TabsContent value="tab2" className="mt-4">
    {/* Tab 2 content */}
  </TabsContent>
</Tabs>
```

---

### Table Patterns

```tsx
<div className="rounded-md border">
  <Table>
    <TableHeader>
      <TableRow>
        <TableHead>Name</TableHead>
        <TableHead>Status</TableHead>
        <TableHead className="text-right">Actions</TableHead>
      </TableRow>
    </TableHeader>
    <TableBody>
      <TableRow>
        <TableCell className="font-medium">Item 1</TableCell>
        <TableCell>
          <Badge>Active</Badge>
        </TableCell>
        <TableCell className="text-right">
          <Button size="sm" variant="ghost">Edit</Button>
        </TableCell>
      </TableRow>
    </TableBody>
  </Table>
</div>
```

---

## Common Anti-Patterns to Avoid

**NEVER DO THIS:**

```tsx
// Wrong: Custom colors instead of semantic tokens
<Button className="bg-red-500">Delete</Button>
// Correct:
<Button variant="destructive">Delete</Button>

// Wrong: Arbitrary spacing
<div className="p-5 m-7 gap-3">
// Correct: Use 8pt grid values
<div className="p-4 m-8 gap-4">

// Wrong: Inconsistent button sizes
<Button className="h-12 px-10">
// Correct: Use predefined sizes
<Button size="lg">

// Wrong: Multiple font sizes beyond 4
<p className="text-xs">Tiny</p>
<p className="text-lg">Large</p>
<p className="text-xl">Larger</p>
<p className="text-4xl">Huge</p>
// Correct: Only 4 sizes allowed
<p className="text-sm">Small (14px)</p>
<p className="text-base">Body (16px)</p>
<p className="text-2xl">Subheading (24px)</p>
<p className="text-3xl">Heading (32px)</p>

// Wrong: Custom shadows and borders
<Card className="shadow-2xl border-4">
// Correct: Use component defaults
<Card>

// Wrong: Non-grid spacing
<div className="space-y-1.5">
<Badge className="px-2.5 py-0.5">
// Correct: Use grid-aligned spacing
<div className="space-y-2">
<Badge className="px-2 py-1">

// Wrong: Extra font weights
<p className="font-bold">Bold</p>
<p className="font-light">Light</p>
<p className="font-medium">Medium</p>
// Correct: Only 2 weights
<p className="font-semibold">Emphasis</p>
<p className="font-normal">Normal</p>
```

---

## Code Review Checklist

**MANDATORY VALIDATION**: Every component/page must pass these checks.

- [ ] Typography: Uses only 4 font sizes (text-sm, text-base, text-2xl, text-3xl)
- [ ] Typography: Uses only 2 font weights (font-normal, font-semibold)
- [ ] Spacing: All values divisible by 4 (p-1, p-2, p-4, p-6, p-8, etc.)
- [ ] Colors: Uses semantic tokens (bg-primary, text-foreground, etc.)
- [ ] Colors: Follows 60/30/10 distribution
- [ ] Buttons: Uses variant and size props, not custom classes
- [ ] Cards: Uses standard Card subcomponents with default spacing
- [ ] Forms: Uses space-y-2 for label/input, space-y-4 between fields
- [ ] Grids: Uses gap-4 or gap-6 between elements
- [ ] shadcn/ui components only (no custom implementations)
- [ ] Dark mode support included
- [ ] Accessibility: Labels, aria attributes, focus states

**REJECT IF ANY VIOLATIONS EXIST**

---

## Resources

- **shadcn/ui Documentation**: https://ui.shadcn.com
- **Tailwind CSS v4 Documentation**: https://tailwindcss.com/docs
- **Project Figma**: {{FIGMA_URL}}

---

**Last Updated**: {{LAST_UPDATED}}
**Version**: 1.0.0
