'use client'

/**
 * ML Prediction Form Component
 * Component Type: {{FORM_TYPE}}
 * Component Name: {{COMPONENT_NAME}}
 */

import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Label } from '@/components/ui/label'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Loader2, CheckCircle2, XCircle } from 'lucide-react'

// ============================================================================
// Form Schema
// ============================================================================

const formSchema = z.object({
  text: z.string()
    .min(1, { message: 'Input is required' })
    .max(10000, { message: 'Input is too long (max 10,000 characters)' }),
  returnProbabilities: z.boolean().default(true),
})

type FormValues = z.infer<typeof formSchema>

// ============================================================================
// Response Types
// ============================================================================

interface PredictionResponse {
  prediction: string
  confidence: number
  probabilities?: Record<string, number>
  model_version: string
  inference_time_ms: number
}

interface ErrorResponse {
  error?: string
  detail?: string
  message?: string
}

// ============================================================================
// Main Component
// ============================================================================

export function {{COMPONENT_NAME}}() {
  const [result, setResult] = useState<PredictionResponse | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      text: '',
      returnProbabilities: true,
    },
  })

  async function onSubmit(values: FormValues) {
    setLoading(true)
    setError(null)
    setResult(null)

    try {
      const response = await fetch('/api/ml/predict', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text: values.text,
          return_probabilities: values.returnProbabilities,
        }),
      })

      const data = await response.json()

      if (!response.ok) {
        const errorData = data as ErrorResponse
        throw new Error(errorData.detail || errorData.error || errorData.message || 'Prediction failed')
      }

      setResult(data as PredictionResponse)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unexpected error occurred')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="w-full max-w-3xl mx-auto space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>ML Prediction</CardTitle>
          <CardDescription>
            Enter your input below to get a prediction from the ML model
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="text">Input Text</Label>
              <Textarea
                id="text"
                placeholder="Enter text for prediction..."
                rows={6}
                {...form.register('text')}
                disabled={loading}
              />
              {form.formState.errors.text && (
                <p className="text-sm text-destructive">
                  {form.formState.errors.text.message}
                </p>
              )}
            </div>

            <div className="flex items-center space-x-2">
              <input
                type="checkbox"
                id="returnProbabilities"
                {...form.register('returnProbabilities')}
                disabled={loading}
                className="h-4 w-4 rounded border-gray-300"
              />
              <Label htmlFor="returnProbabilities" className="cursor-pointer">
                Show prediction probabilities
              </Label>
            </div>

            <Button type="submit" disabled={loading} className="w-full">
              {loading ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Analyzing...
                </>
              ) : (
                'Analyze'
              )}
            </Button>
          </form>
        </CardContent>
      </Card>

      {/* Error Display */}
      {error && (
        <Alert variant="destructive">
          <XCircle className="h-4 w-4" />
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      {/* Success Result Display */}
      {result && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <CheckCircle2 className="h-5 w-5 text-green-500" />
              Prediction Result
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Main Prediction */}
            <div className="space-y-2">
              <h3 className="text-sm font-medium text-muted-foreground">
                Prediction
              </h3>
              <p className="text-2xl font-bold">{result.prediction}</p>
            </div>

            {/* Confidence */}
            <div className="space-y-2">
              <h3 className="text-sm font-medium text-muted-foreground">
                Confidence
              </h3>
              <div className="flex items-center gap-4">
                <div className="flex-1 bg-secondary rounded-full h-3">
                  <div
                    className="bg-primary h-3 rounded-full transition-all duration-500"
                    style={{ width: `${result.confidence * 100}%` }}
                  />
                </div>
                <span className="text-lg font-semibold min-w-[4rem] text-right">
                  {(result.confidence * 100).toFixed(1)}%
                </span>
              </div>
            </div>

            {/* Probabilities */}
            {result.probabilities && (
              <div className="space-y-2">
                <h3 className="text-sm font-medium text-muted-foreground">
                  Class Probabilities
                </h3>
                <div className="space-y-2">
                  {Object.entries(result.probabilities)
                    .sort(([, a], [, b]) => b - a)
                    .map(([label, prob]) => (
                      <div key={label} className="space-y-1">
                        <div className="flex items-center justify-between text-sm">
                          <span className="font-medium capitalize">{label}</span>
                          <span className="text-muted-foreground">
                            {(prob * 100).toFixed(1)}%
                          </span>
                        </div>
                        <div className="w-full bg-secondary rounded-full h-2">
                          <div
                            className="bg-primary/60 h-2 rounded-full transition-all duration-500"
                            style={{ width: `${prob * 100}%` }}
                          />
                        </div>
                      </div>
                    ))}
                </div>
              </div>
            )}

            {/* Metadata */}
            <div className="pt-4 border-t">
              <div className="flex justify-between text-sm text-muted-foreground">
                <span>Model Version: {result.model_version}</span>
                <span>Inference Time: {result.inference_time_ms.toFixed(1)}ms</span>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
