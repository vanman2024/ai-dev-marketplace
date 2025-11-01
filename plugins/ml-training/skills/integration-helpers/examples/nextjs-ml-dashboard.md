# Complete Next.js ML Dashboard Example

This example demonstrates building a full-featured ML prediction dashboard with Next.js, TypeScript, and shadcn/ui.

## Project Structure

```
nextjs-frontend/
├── app/
│   ├── page.tsx
│   ├── layout.tsx
│   ├── api/
│   │   └── ml/
│   │       └── predict/
│   │           └── route.ts
│   └── dashboard/
│       └── page.tsx
├── components/
│   ├── ml/
│   │   ├── prediction-form.tsx
│   │   ├── prediction-history.tsx
│   │   └── model-stats.tsx
│   └── ui/
│       └── [shadcn components]
├── lib/
│   └── utils.ts
└── .env.local
```

## Step 1: Setup Next.js Project

```bash
npx create-next-app@latest ml-dashboard --typescript --tailwind --app
cd ml-dashboard
```

## Step 2: Install Dependencies

```bash
npm install react-hook-form @hookform/resolvers zod
npx shadcn@latest init
npx shadcn@latest add button card input textarea label alert
```

## Step 3: Generate Prediction Form Component

```bash
bash plugins/ml-training/skills/integration-helpers/scripts/add-nextjs-component.sh classification-form sentiment-form
```

This creates `components/ml/sentiment-form.tsx`.

## Step 4: Create API Route Handler

Create `app/api/ml/predict/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server'

const FASTAPI_URL = process.env.FASTAPI_URL || 'http://localhost:8000'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()

    // Validate request
    if (!body.text || typeof body.text !== 'string') {
      return NextResponse.json(
        { error: 'Invalid request: text is required' },
        { status: 400 }
      )
    }

    // Call FastAPI backend
    const response = await fetch(`${FASTAPI_URL}/ml/predict`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    })

    if (!response.ok) {
      const error = await response.json()
      return NextResponse.json(
        { error: error.detail || 'Prediction failed' },
        { status: response.status }
      )
    }

    const data = await response.json()

    // Log prediction to Supabase (optional)
    if (process.env.SUPABASE_URL) {
      await logPrediction(data, body)
    }

    return NextResponse.json(data)

  } catch (error) {
    console.error('Prediction error:', error)
    return NextResponse.json(
      { error: 'Failed to connect to ML service' },
      { status: 500 }
    )
  }
}

// Helper function to log predictions
async function logPrediction(prediction: any, input: any) {
  // Implement Supabase logging here
  // This is optional but useful for analytics
}
```

## Step 5: Create Prediction History Component

Create `components/ml/prediction-history.tsx`:

```typescript
'use client'

import { useEffect, useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'

interface Prediction {
  id: string
  text: string
  prediction: string
  confidence: number
  timestamp: string
}

export function PredictionHistory() {
  const [predictions, setPredictions] = useState<Prediction[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchPredictions()
  }, [])

  async function fetchPredictions() {
    try {
      const response = await fetch('/api/ml/history')
      const data = await response.json()
      setPredictions(data)
    } catch (error) {
      console.error('Failed to fetch predictions:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return <div>Loading history...</div>
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Recent Predictions</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {predictions.length === 0 ? (
            <p className="text-muted-foreground">No predictions yet</p>
          ) : (
            predictions.map((pred) => (
              <div
                key={pred.id}
                className="flex items-start justify-between border-b pb-3 last:border-0"
              >
                <div className="flex-1">
                  <p className="text-sm">{pred.text}</p>
                  <p className="text-xs text-muted-foreground mt-1">
                    {new Date(pred.timestamp).toLocaleString()}
                  </p>
                </div>
                <div className="flex items-center gap-2 ml-4">
                  <Badge
                    variant={
                      pred.prediction === 'positive' ? 'default' : 'destructive'
                    }
                  >
                    {pred.prediction}
                  </Badge>
                  <span className="text-sm text-muted-foreground">
                    {(pred.confidence * 100).toFixed(0)}%
                  </span>
                </div>
              </div>
            ))
          )}
        </div>
      </CardContent>
    </Card>
  )
}
```

## Step 6: Create Model Stats Component

Create `components/ml/model-stats.tsx`:

```typescript
'use client'

import { useEffect, useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { BarChart, TrendingUp, Activity } from 'lucide-react'

interface ModelStats {
  total_predictions: number
  avg_confidence: number
  avg_inference_time_ms: number
  model_version: string
}

export function ModelStats() {
  const [stats, setStats] = useState<ModelStats | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchStats()
  }, [])

  async function fetchStats() {
    try {
      const response = await fetch('/api/ml/stats')
      const data = await response.json()
      setStats(data)
    } catch (error) {
      console.error('Failed to fetch stats:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading || !stats) {
    return null
  }

  return (
    <div className="grid gap-4 md:grid-cols-3">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-sm font-medium">
            Total Predictions
          </CardTitle>
          <BarChart className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">
            {stats.total_predictions.toLocaleString()}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-sm font-medium">
            Avg Confidence
          </CardTitle>
          <TrendingUp className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">
            {(stats.avg_confidence * 100).toFixed(1)}%
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-sm font-medium">
            Avg Response Time
          </CardTitle>
          <Activity className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">
            {stats.avg_inference_time_ms.toFixed(0)}ms
          </div>
          <p className="text-xs text-muted-foreground mt-1">
            Model v{stats.model_version}
          </p>
        </CardContent>
      </Card>
    </div>
  )
}
```

## Step 7: Create Dashboard Page

Create `app/dashboard/page.tsx`:

```typescript
import { SentimentForm } from '@/components/ml/sentiment-form'
import { PredictionHistory } from '@/components/ml/prediction-history'
import { ModelStats } from '@/components/ml/model-stats'

export default function DashboardPage() {
  return (
    <div className="container mx-auto py-8 space-y-8">
      <div>
        <h1 className="text-3xl font-bold">ML Dashboard</h1>
        <p className="text-muted-foreground mt-2">
          Sentiment analysis powered by machine learning
        </p>
      </div>

      {/* Model Statistics */}
      <ModelStats />

      <div className="grid gap-8 lg:grid-cols-2">
        {/* Prediction Form */}
        <div>
          <SentimentForm />
        </div>

        {/* Prediction History */}
        <div>
          <PredictionHistory />
        </div>
      </div>
    </div>
  )
}
```

## Step 8: Setup Environment Variables

Create `.env.local`:

```env
FASTAPI_URL=http://localhost:8000
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

## Step 9: Add Supabase Integration (Optional)

Install Supabase client:

```bash
npm install @supabase/supabase-js
```

Create `lib/supabase.ts`:

```typescript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.SUPABASE_URL!
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

Update API route to log predictions:

```typescript
// In app/api/ml/predict/route.ts
import { supabase } from '@/lib/supabase'

async function logPrediction(prediction: any, input: any) {
  await supabase.from('predictions').insert({
    model_name: 'sentiment-analysis',
    model_version: prediction.model_version,
    input_data: { text: input.text },
    prediction: { label: prediction.prediction },
    confidence: prediction.confidence,
    inference_time_ms: prediction.inference_time_ms,
  })
}
```

## Step 10: Create History API Route

Create `app/api/ml/history/route.ts`:

```typescript
import { NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

export async function GET() {
  try {
    const { data, error } = await supabase
      .from('predictions')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(10)

    if (error) throw error

    const predictions = data.map((pred) => ({
      id: pred.id,
      text: pred.input_data.text,
      prediction: pred.prediction.label,
      confidence: pred.confidence,
      timestamp: pred.created_at,
    }))

    return NextResponse.json(predictions)
  } catch (error) {
    console.error('Failed to fetch history:', error)
    return NextResponse.json(
      { error: 'Failed to fetch prediction history' },
      { status: 500 }
    )
  }
}
```

## Step 11: Create Stats API Route

Create `app/api/ml/stats/route.ts`:

```typescript
import { NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

export async function GET() {
  try {
    const { data, error } = await supabase
      .from('predictions')
      .select('confidence, inference_time_ms, model_version')

    if (error) throw error

    const stats = {
      total_predictions: data.length,
      avg_confidence:
        data.reduce((sum, p) => sum + p.confidence, 0) / data.length || 0,
      avg_inference_time_ms:
        data.reduce((sum, p) => sum + p.inference_time_ms, 0) / data.length || 0,
      model_version: data[0]?.model_version || '1.0.0',
    }

    return NextResponse.json(stats)
  } catch (error) {
    console.error('Failed to fetch stats:', error)
    return NextResponse.json(
      { error: 'Failed to fetch statistics' },
      { status: 500 }
    )
  }
}
```

## Step 12: Run the Application

```bash
npm run dev
```

Visit http://localhost:3000/dashboard

## Advanced Features

### Real-time Updates with Supabase

Add real-time prediction updates:

```typescript
// In PredictionHistory component
useEffect(() => {
  const subscription = supabase
    .channel('predictions')
    .on(
      'postgres_changes',
      { event: 'INSERT', schema: 'public', table: 'predictions' },
      (payload) => {
        setPredictions((prev) => [payload.new, ...prev].slice(0, 10))
      }
    )
    .subscribe()

  return () => {
    subscription.unsubscribe()
  }
}, [])
```

### Dark Mode Support

Add theme toggle with next-themes:

```bash
npm install next-themes
```

### Error Boundaries

Create error boundary for graceful failure:

```typescript
// components/error-boundary.tsx
'use client'

import { Component, ReactNode } from 'react'

export class ErrorBoundary extends Component<
  { children: ReactNode },
  { hasError: boolean }
> {
  state = { hasError: false }

  static getDerivedStateFromError() {
    return { hasError: true }
  }

  render() {
    if (this.state.hasError) {
      return <div>Something went wrong</div>
    }
    return this.props.children
  }
}
```

### Loading States

Add skeleton loaders with shadcn/ui:

```bash
npx shadcn@latest add skeleton
```

## Performance Optimization

### Caching Predictions

Use React Query for data caching:

```bash
npm install @tanstack/react-query
```

### Debounced Input

Add debouncing for real-time predictions:

```typescript
import { useDebounce } from '@/hooks/use-debounce'

const debouncedText = useDebounce(text, 500)
```

## Deployment

### Vercel Deployment

```bash
npm install -g vercel
vercel
```

Set environment variables in Vercel dashboard.

## Next Steps

1. Add user authentication with Supabase Auth
2. Implement model comparison (A/B testing)
3. Add data visualization with Recharts
4. Create admin dashboard for model management
5. Add export functionality for predictions
6. Implement feedback collection for model improvement

## Additional Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [shadcn/ui Components](https://ui.shadcn.com/)
- [Supabase Client Library](https://supabase.com/docs/reference/javascript/introduction)
