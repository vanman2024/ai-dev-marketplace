/**
 * Chart Generator Example - Complete Implementation
 *
 * This example demonstrates how to build a generative UI system
 * that creates data visualizations based on AI analysis.
 *
 * Use case: User provides data, AI analyzes it and chooses the
 * best chart type and configuration.
 */

'use server'

import { streamUI } from 'ai/rsc'
import { openai } from '@ai-sdk/openai'
import { z } from 'zod'
import { tool } from 'ai'

interface DataPoint {
  label: string
  value: number
}

export async function generateChartFromData(
  data: DataPoint[],
  userQuestion: string
) {
  const result = await streamUI({
    model: openai('gpt-4o'),
    messages: [
      {
        role: 'system',
        content: `You are a data visualization expert. Analyze the provided data and create appropriate visualizations.

Available chart types:
- bar: For comparing categories
- line: For trends over time
- pie: For showing proportions (max 6 slices)
- scatter: For correlation analysis

Choose the most appropriate visualization based on the data and user question.`
      },
      {
        role: 'user',
        content: `Data: ${JSON.stringify(data)}\n\nQuestion: ${userQuestion}`
      }
    ],

    text: ({ content }) => (
      <div className="analysis">
        <h4>Analysis:</h4>
        <p>{content}</p>
      </div>
    ),

    tools: {
      createBarChart: tool({
        description: 'Create a bar chart for categorical comparisons',
        parameters: z.object({
          title: z.string(),
          data: z.array(z.object({
            label: z.string(),
            value: z.number()
          })),
          yAxisLabel: z.string().optional(),
          color: z.string().optional()
        }),
        generate: async ({ title, data, yAxisLabel, color }) => {
          return (
            <BarChart
              title={title}
              data={data}
              yAxisLabel={yAxisLabel}
              color={color}
            />
          )
        }
      }),

      createLineChart: tool({
        description: 'Create a line chart for trends over time',
        parameters: z.object({
          title: z.string(),
          data: z.array(z.object({
            label: z.string(),
            value: z.number()
          })),
          showTrend: z.boolean().optional(),
          color: z.string().optional()
        }),
        generate: async ({ title, data, showTrend, color }) => {
          return (
            <LineChart
              title={title}
              data={data}
              showTrend={showTrend}
              color={color}
            />
          )
        }
      }),

      createPieChart: tool({
        description: 'Create a pie chart for proportions (max 6 categories)',
        parameters: z.object({
          title: z.string(),
          data: z.array(z.object({
            label: z.string(),
            value: z.number()
          })),
          showPercentages: z.boolean().optional()
        }),
        generate: async ({ title, data, showPercentages }) => {
          if (data.length > 6) {
            return (
              <div className="warning">
                <p>Too many categories for pie chart. Showing top 6.</p>
                <PieChart
                  title={title}
                  data={data.slice(0, 6)}
                  showPercentages={showPercentages}
                />
              </div>
            )
          }
          return (
            <PieChart
              title={title}
              data={data}
              showPercentages={showPercentages}
            />
          )
        }
      }),

      createMultiChart: tool({
        description: 'Create multiple charts for comprehensive analysis',
        parameters: z.object({
          title: z.string(),
          charts: z.array(z.object({
            type: z.enum(['bar', 'line', 'pie']),
            subtitle: z.string(),
            data: z.array(z.object({
              label: z.string(),
              value: z.number()
            }))
          }))
        }),
        generate: async ({ title, charts }) => {
          return (
            <div className="multi-chart-container">
              <h2>{title}</h2>
              <div className="charts-grid">
                {charts.map((chart, i) => (
                  <div key={i} className="chart-item">
                    <h3>{chart.subtitle}</h3>
                    {chart.type === 'bar' && <BarChart title="" data={chart.data} />}
                    {chart.type === 'line' && <LineChart title="" data={chart.data} />}
                    {chart.type === 'pie' && <PieChart title="" data={chart.data} />}
                  </div>
                ))}
              </div>
            </div>
          )
        }
      })
    }
  })

  return result.value
}

/**
 * Bar Chart Component
 * Replace with your preferred charting library (recharts, chart.js, etc.)
 */
function BarChart({
  title,
  data,
  yAxisLabel,
  color = '#3498db'
}: {
  title: string
  data: DataPoint[]
  yAxisLabel?: string
  color?: string
}) {
  const maxValue = Math.max(...data.map(d => d.value))

  return (
    <div className="chart bar-chart">
      {title && <h3>{title}</h3>}
      <div className="chart-body">
        {data.map((point, i) => (
          <div key={i} className="bar-item">
            <div
              className="bar"
              style={{
                height: `${(point.value / maxValue) * 200}px`,
                backgroundColor: color
              }}
            >
              <span className="value">{point.value}</span>
            </div>
            <span className="label">{point.label}</span>
          </div>
        ))}
      </div>
      {yAxisLabel && <div className="y-axis-label">{yAxisLabel}</div>}
    </div>
  )
}

/**
 * Line Chart Component
 */
function LineChart({
  title,
  data,
  showTrend,
  color = '#2ecc71'
}: {
  title: string
  data: DataPoint[]
  showTrend?: boolean
  color?: string
}) {
  const maxValue = Math.max(...data.map(d => d.value))
  const points = data.map((d, i) => ({
    x: (i / (data.length - 1)) * 100,
    y: 100 - ((d.value / maxValue) * 100)
  }))

  const pathData = points.map((p, i) =>
    i === 0 ? `M ${p.x} ${p.y}` : `L ${p.x} ${p.y}`
  ).join(' ')

  return (
    <div className="chart line-chart">
      {title && <h3>{title}</h3>}
      <svg viewBox="0 0 100 100" className="line-svg">
        <path
          d={pathData}
          stroke={color}
          strokeWidth="2"
          fill="none"
        />
        {points.map((p, i) => (
          <circle
            key={i}
            cx={p.x}
            cy={p.y}
            r="2"
            fill={color}
          />
        ))}
      </svg>
      <div className="labels">
        {data.map((point, i) => (
          <span key={i}>{point.label}</span>
        ))}
      </div>
    </div>
  )
}

/**
 * Pie Chart Component
 */
function PieChart({
  title,
  data,
  showPercentages
}: {
  title: string
  data: DataPoint[]
  showPercentages?: boolean
}) {
  const total = data.reduce((sum, d) => sum + d.value, 0)
  const colors = ['#3498db', '#2ecc71', '#e74c3c', '#f39c12', '#9b59b6', '#1abc9c']

  let currentAngle = 0
  const slices = data.map((d, i) => {
    const percentage = (d.value / total) * 100
    const angle = (percentage / 100) * 360
    const slice = {
      ...d,
      percentage,
      startAngle: currentAngle,
      endAngle: currentAngle + angle,
      color: colors[i % colors.length]
    }
    currentAngle += angle
    return slice
  })

  return (
    <div className="chart pie-chart">
      {title && <h3>{title}</h3>}
      <svg viewBox="0 0 100 100" className="pie-svg">
        {slices.map((slice, i) => {
          const startRad = (slice.startAngle * Math.PI) / 180
          const endRad = (slice.endAngle * Math.PI) / 180
          const x1 = 50 + 40 * Math.cos(startRad)
          const y1 = 50 + 40 * Math.sin(startRad)
          const x2 = 50 + 40 * Math.cos(endRad)
          const y2 = 50 + 40 * Math.sin(endRad)
          const largeArc = slice.endAngle - slice.startAngle > 180 ? 1 : 0

          return (
            <path
              key={i}
              d={`M 50 50 L ${x1} ${y1} A 40 40 0 ${largeArc} 1 ${x2} ${y2} Z`}
              fill={slice.color}
            />
          )
        })}
      </svg>
      <div className="legend">
        {slices.map((slice, i) => (
          <div key={i} className="legend-item">
            <span
              className="color-box"
              style={{ backgroundColor: slice.color }}
            />
            <span>
              {slice.label}
              {showPercentages && ` (${slice.percentage.toFixed(1)}%)`}
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}
