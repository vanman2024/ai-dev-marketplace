import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { ThemeToggle } from "@/components/theme-toggle"

export default function ThemeShowcase() {
  return (
    <div className="min-h-screen bg-background p-8">
      <div className="mx-auto max-w-4xl space-y-8">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-4xl font-bold tracking-tight">Theme Showcase</h1>
            <p className="text-muted-foreground mt-2">
              Demonstrating shadcn/ui components with Tailwind CSS
            </p>
          </div>
          <ThemeToggle />
        </div>

        {/* Button Variants */}
        <Card>
          <CardHeader>
            <CardTitle>Button Variants</CardTitle>
            <CardDescription>All available button styles</CardDescription>
          </CardHeader>
          <CardContent className="flex flex-wrap gap-4">
            <Button variant="default">Default</Button>
            <Button variant="secondary">Secondary</Button>
            <Button variant="destructive">Destructive</Button>
            <Button variant="outline">Outline</Button>
            <Button variant="ghost">Ghost</Button>
            <Button variant="link">Link</Button>
          </CardContent>
        </Card>

        {/* Button Sizes */}
        <Card>
          <CardHeader>
            <CardTitle>Button Sizes</CardTitle>
            <CardDescription>Different size options</CardDescription>
          </CardHeader>
          <CardContent className="flex flex-wrap items-center gap-4">
            <Button size="sm">Small</Button>
            <Button size="default">Default</Button>
            <Button size="lg">Large</Button>
            <Button size="icon">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M12 5v14M5 12h14" />
              </svg>
            </Button>
          </CardContent>
        </Card>

        {/* Form Components */}
        <Card>
          <CardHeader>
            <CardTitle>Form Components</CardTitle>
            <CardDescription>Input fields and labels</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input id="email" type="email" placeholder="Enter your email" />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input id="password" type="password" placeholder="Enter your password" />
            </div>
          </CardContent>
          <CardFooter>
            <Button className="w-full">Submit</Button>
          </CardFooter>
        </Card>

        {/* Color Palette */}
        <Card>
          <CardHeader>
            <CardTitle>Color Palette</CardTitle>
            <CardDescription>Theme colors using CSS variables</CardDescription>
          </CardHeader>
          <CardContent className="grid grid-cols-2 gap-4 md:grid-cols-4">
            <div className="space-y-2">
              <div className="h-20 rounded-md bg-primary" />
              <p className="text-sm font-medium">Primary</p>
            </div>
            <div className="space-y-2">
              <div className="h-20 rounded-md bg-secondary" />
              <p className="text-sm font-medium">Secondary</p>
            </div>
            <div className="space-y-2">
              <div className="h-20 rounded-md bg-muted" />
              <p className="text-sm font-medium">Muted</p>
            </div>
            <div className="space-y-2">
              <div className="h-20 rounded-md bg-accent" />
              <p className="text-sm font-medium">Accent</p>
            </div>
            <div className="space-y-2">
              <div className="h-20 rounded-md bg-destructive" />
              <p className="text-sm font-medium">Destructive</p>
            </div>
            <div className="space-y-2">
              <div className="h-20 rounded-md bg-card border" />
              <p className="text-sm font-medium">Card</p>
            </div>
            <div className="space-y-2">
              <div className="h-20 rounded-md bg-popover border" />
              <p className="text-sm font-medium">Popover</p>
            </div>
            <div className="space-y-2">
              <div className="h-20 rounded-md border-2 border-border" />
              <p className="text-sm font-medium">Border</p>
            </div>
          </CardContent>
        </Card>

        {/* Typography */}
        <Card>
          <CardHeader>
            <CardTitle>Typography</CardTitle>
            <CardDescription>Text styles and colors</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <h1 className="text-4xl font-bold">Heading 1</h1>
            <h2 className="text-3xl font-semibold">Heading 2</h2>
            <h3 className="text-2xl font-semibold">Heading 3</h3>
            <h4 className="text-xl font-semibold">Heading 4</h4>
            <p className="text-base">Regular paragraph text with base font size.</p>
            <p className="text-sm text-muted-foreground">
              Muted text for secondary information.
            </p>
            <p className="text-xs text-muted-foreground">
              Extra small text for captions or footnotes.
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
