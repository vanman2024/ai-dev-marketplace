'use server'

import { streamUI } from 'ai/rsc'
import { openai } from '@ai-sdk/openai'
import { z } from 'zod'
import { tool } from 'ai'

/**
 * Server Action Pattern for Generative UI
 *
 * This template demonstrates the core pattern for implementing
 * AI SDK RSC with streaming UI components.
 *
 * Usage:
 * 1. Import this in your Next.js App Router page/component
 * 2. Call from client component: const ui = await generateUI(prompt)
 * 3. Render result: {ui}
 */

interface Message {
  role: 'user' | 'assistant'
  content: string
}

export async function generateUI(
  messages: Message[],
  context?: Record<string, any>
) {
  'use server'

  try {
    const result = await streamUI({
      model: openai('gpt-4o'),
      messages,

      // Simple text streaming
      text: ({ content, done }) => {
        return (
          <div className="prose">
            <p>{content}</p>
            {done && <span className="text-green-500">✓</span>}
          </div>
        )
      },

      // Dynamic UI generation via tools
      tools: {
        showChart: tool({
          description: 'Display data visualization as a chart',
          parameters: z.object({
            title: z.string().describe('Chart title'),
            data: z.array(z.object({
              label: z.string(),
              value: z.number()
            })),
            type: z.enum(['bar', 'line', 'pie']).describe('Chart type')
          }),
          generate: async ({ title, data, type }) => {
            // Return React component based on chart type
            return (
              <div className="chart-container">
                <h3>{title}</h3>
                <ChartComponent data={data} type={type} />
              </div>
            )
          }
        }),

        showTable: tool({
          description: 'Display structured data as a table',
          parameters: z.object({
            title: z.string().describe('Table title'),
            headers: z.array(z.string()),
            rows: z.array(z.array(z.string()))
          }),
          generate: async ({ title, headers, rows }) => {
            return (
              <div className="table-container">
                <h3>{title}</h3>
                <table>
                  <thead>
                    <tr>
                      {headers.map((h, i) => <th key={i}>{h}</th>)}
                    </tr>
                  </thead>
                  <tbody>
                    {rows.map((row, i) => (
                      <tr key={i}>
                        {row.map((cell, j) => <td key={j}>{cell}</td>)}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )
          }
        }),

        showCard: tool({
          description: 'Display information as a card with optional actions',
          parameters: z.object({
            title: z.string(),
            description: z.string(),
            image: z.string().optional(),
            actions: z.array(z.object({
              label: z.string(),
              href: z.string()
            })).optional()
          }),
          generate: async ({ title, description, image, actions }) => {
            return (
              <div className="card">
                {image && <img src={image} alt={title} />}
                <h3>{title}</h3>
                <p>{description}</p>
                {actions && (
                  <div className="actions">
                    {actions.map((action, i) => (
                      <a key={i} href={action.href}>{action.label}</a>
                    ))}
                  </div>
                )}
              </div>
            )
          }
        })
      },

      // Error handling
      onError: (error) => {
        console.error('Generative UI error:', error)
        return (
          <div className="error-boundary">
            <p>Something went wrong. Please try again.</p>
          </div>
        )
      },

      // Loading fallback
      fallback: (
        <div className="loading">
          <div className="spinner" />
          <p>Generating UI...</p>
        </div>
      ),

      // Optional: Add context for personalization
      ...(context && { context })
    })

    return result.value
  } catch (error) {
    console.error('Failed to generate UI:', error)
    return (
      <div className="error">
        <p>Failed to generate UI. Please try again.</p>
      </div>
    )
  }
}

/**
 * Example Chart Component (replace with your preferred charting library)
 */
function ChartComponent({
  data,
  type
}: {
  data: Array<{ label: string; value: number }>
  type: 'bar' | 'line' | 'pie'
}) {
  // Replace with actual chart implementation (recharts, chart.js, etc.)
  return (
    <div className={`chart chart-${type}`}>
      {data.map((item, i) => (
        <div key={i} className="chart-item">
          <span>{item.label}</span>
          <span>{item.value}</span>
        </div>
      ))}
    </div>
  )
}

/**
 * Type exports for client components
 */
export type { Message }
