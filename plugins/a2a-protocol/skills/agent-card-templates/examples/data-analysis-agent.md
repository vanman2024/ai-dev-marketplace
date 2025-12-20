# Data Analysis Agent Example

This example demonstrates a complex data analysis agent with streaming capabilities, multiple analytical skills, and webhook notifications.

## Agent Card

```json
{
  "id": "urn:example:agent:data-analyzer",
  "name": "Advanced Data Analysis Agent",
  "description": "Comprehensive data analysis platform with statistical analysis, machine learning, data visualization, and real-time streaming analytics.",
  "logo": "https://analytics.example.com/logo.png",
  "version": "4.2.1",
  "protocolVersion": "0.3",
  "serviceEndpoint": "https://api.analytics.example.com/agent",
  "provider": {
    "name": "DataTech Analytics",
    "contactEmail": "analytics@datatech.example.com",
    "url": "https://datatech.example.com"
  },
  "capabilities": {
    "streaming": true,
    "pushNotifications": true
  },
  "securitySchemes": {
    "api_key": {
      "type": "apiKey",
      "name": "X-API-Key",
      "in": "header"
    },
    "bearer_auth": {
      "type": "http",
      "scheme": "bearer"
    },
    "oauth2_auth": {
      "type": "oauth2",
      "flows": {
        "authorizationCode": {
          "authorizationUrl": "https://auth.analytics.example.com/oauth/authorize",
          "tokenUrl": "https://auth.analytics.example.com/oauth/token",
          "scopes": {
            "read": "Read access to analytics data",
            "analyze": "Execute analysis operations",
            "export": "Export analysis results"
          }
        }
      }
    }
  },
  "security": [
    {
      "oauth2_auth": ["read", "analyze"]
    },
    {
      "bearer_auth": []
    }
  ],
  "skills": [
    {
      "name": "statistical-analysis",
      "description": "Perform statistical analysis including descriptive stats, hypothesis testing, and correlation analysis",
      "inputSchema": {
        "type": "object",
        "properties": {
          "dataset": {
            "type": "object",
            "properties": {
              "sourceUrl": {
                "type": "string",
                "format": "uri",
                "description": "URL to CSV or JSON dataset"
              },
              "columns": {
                "type": "array",
                "items": { "type": "string" },
                "description": "Columns to analyze"
              }
            }
          },
          "analyses": {
            "type": "array",
            "items": {
              "type": "string",
              "enum": [
                "descriptive",
                "correlation",
                "regression",
                "hypothesis_test",
                "anova",
                "time_series"
              ]
            }
          },
          "options": {
            "type": "object",
            "properties": {
              "confidenceLevel": {
                "type": "number",
                "minimum": 0,
                "maximum": 1,
                "default": 0.95
              },
              "removeOutliers": {
                "type": "boolean"
              }
            }
          }
        },
        "required": ["dataset", "analyses"]
      },
      "outputSchema": {
        "type": "object",
        "properties": {
          "analysisId": {
            "type": "string"
          },
          "results": {
            "type": "object",
            "properties": {
              "descriptive": {
                "type": "object",
                "properties": {
                  "mean": { "type": "number" },
                  "median": { "type": "number" },
                  "stdDev": { "type": "number" },
                  "variance": { "type": "number" }
                }
              },
              "correlation": {
                "type": "object",
                "additionalProperties": { "type": "number" }
              }
            }
          },
          "visualizations": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "type": { "type": "string" },
                "url": { "type": "string", "format": "uri" }
              }
            }
          }
        }
      },
      "tags": ["statistics", "analysis", "data-science"],
      "examples": [
        {
          "input": {
            "dataset": {
              "sourceUrl": "https://data.example.com/sales.csv",
              "columns": ["revenue", "units_sold", "region"]
            },
            "analyses": ["descriptive", "correlation"]
          },
          "output": {
            "analysisId": "analysis_abc123",
            "results": {
              "descriptive": {
                "mean": 45632.5,
                "median": 42000,
                "stdDev": 12450.3,
                "variance": 155010002.25
              },
              "correlation": {
                "revenue_units_sold": 0.87
              }
            }
          }
        }
      ]
    },
    {
      "name": "machine-learning-model",
      "description": "Train and apply machine learning models for prediction and classification",
      "inputSchema": {
        "type": "object",
        "properties": {
          "modelType": {
            "type": "string",
            "enum": [
              "linear_regression",
              "logistic_regression",
              "random_forest",
              "neural_network",
              "clustering"
            ]
          },
          "trainingData": {
            "type": "object",
            "properties": {
              "sourceUrl": { "type": "string", "format": "uri" },
              "features": { "type": "array", "items": { "type": "string" } },
              "target": { "type": "string" }
            }
          },
          "hyperparameters": {
            "type": "object",
            "additionalProperties": true
          },
          "validationSplit": {
            "type": "number",
            "minimum": 0,
            "maximum": 1,
            "default": 0.2
          }
        },
        "required": ["modelType", "trainingData"]
      },
      "outputSchema": {
        "type": "object",
        "properties": {
          "modelId": {
            "type": "string",
            "description": "Unique identifier for trained model"
          },
          "metrics": {
            "type": "object",
            "properties": {
              "accuracy": { "type": "number" },
              "precision": { "type": "number" },
              "recall": { "type": "number" },
              "f1Score": { "type": "number" }
            }
          },
          "featureImportance": {
            "type": "object",
            "additionalProperties": { "type": "number" }
          },
          "status": {
            "type": "string",
            "enum": ["training", "completed", "failed"]
          }
        }
      },
      "tags": ["machine-learning", "prediction", "classification"]
    },
    {
      "name": "streaming-analytics",
      "description": "Real-time analytics on streaming data with SSE output",
      "inputSchema": {
        "type": "object",
        "properties": {
          "streamSource": {
            "type": "string",
            "format": "uri",
            "description": "Real-time data source endpoint"
          },
          "metrics": {
            "type": "array",
            "items": {
              "type": "string",
              "enum": ["count", "sum", "average", "min", "max", "percentile"]
            }
          },
          "windowSize": {
            "type": "integer",
            "description": "Time window in seconds",
            "minimum": 1
          },
          "webhookUrl": {
            "type": "string",
            "format": "uri",
            "description": "Optional webhook for notifications"
          }
        },
        "required": ["streamSource", "metrics", "windowSize"]
      },
      "outputSchema": {
        "type": "object",
        "properties": {
          "streamId": {
            "type": "string"
          },
          "sseEndpoint": {
            "type": "string",
            "format": "uri",
            "description": "Server-Sent Events endpoint for results"
          },
          "status": {
            "type": "string",
            "enum": ["active", "paused", "stopped"]
          }
        }
      },
      "outputModes": ["text/event-stream", "application/json"],
      "tags": ["streaming", "realtime", "sse"]
    },
    {
      "name": "data-visualization",
      "description": "Generate interactive visualizations and dashboards",
      "inputSchema": {
        "type": "object",
        "properties": {
          "dataset": {
            "type": "object",
            "properties": {
              "sourceUrl": { "type": "string", "format": "uri" }
            }
          },
          "visualizations": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "type": {
                  "type": "string",
                  "enum": ["bar", "line", "scatter", "pie", "heatmap", "boxplot"]
                },
                "xAxis": { "type": "string" },
                "yAxis": { "type": "string" },
                "groupBy": { "type": "string" }
              }
            }
          },
          "theme": {
            "type": "string",
            "enum": ["light", "dark", "custom"]
          }
        },
        "required": ["dataset", "visualizations"]
      },
      "outputSchema": {
        "type": "object",
        "properties": {
          "dashboardUrl": {
            "type": "string",
            "format": "uri",
            "description": "URL to interactive dashboard"
          },
          "charts": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "chartId": { "type": "string" },
                "imageUrl": { "type": "string", "format": "uri" },
                "embedCode": { "type": "string" }
              }
            }
          }
        }
      },
      "tags": ["visualization", "charts", "dashboard"]
    }
  ],
  "extensions": [
    {
      "name": "sse-keepalive",
      "version": "1.0"
    },
    {
      "name": "webhook-retry",
      "version": "1.0"
    },
    {
      "name": "batch-processing",
      "version": "2.0"
    }
  ],
  "supportsExtendedAgentCard": true,
  "metadata": {
    "supportedFormats": ["CSV", "JSON", "Parquet", "Excel"],
    "maxDatasetSize": "10GB",
    "mlFrameworks": ["scikit-learn", "TensorFlow", "PyTorch"],
    "streamingProtocols": ["SSE", "WebSocket"],
    "rateLimit": "100 analyses/hour",
    "webhookRetryPolicy": "exponential-backoff"
  }
}
```

## Authentication Setup

The data analysis agent supports OAuth 2.0 for secure access:

### Step 1: Register Application

1. Visit https://analytics.example.com/developers
2. Create a new application
3. Note your Client ID and Client Secret (store securely)
4. Configure redirect URIs

### Step 2: Obtain Authorization

```bash
# Redirect user to authorization URL
https://auth.analytics.example.com/oauth/authorize?
  response_type=code&
  client_id=your_client_id_here&
  redirect_uri=https://your-app.com/callback&
  scope=read+analyze
```

### Step 3: Exchange Code for Token

```bash
curl -X POST https://auth.analytics.example.com/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=AUTHORIZATION_CODE" \
  -d "client_id=your_client_id_here" \
  -d "client_secret=your_client_secret_here" \
  -d "redirect_uri=https://your-app.com/callback"
```

Response:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "refresh_token_value",
  "scope": "read analyze"
}
```

### Step 4: Make API Requests

```bash
curl -X POST https://api.analytics.example.com/agent/task \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..." \
  -H "Content-Type: application/json" \
  -d '{
    "skillName": "statistical-analysis",
    "input": {...}
  }'
```

## Usage Scenarios

### Scenario 1: Statistical Analysis

Perform comprehensive statistical analysis on sales data.

**Request:**
```json
{
  "skillName": "statistical-analysis",
  "input": {
    "dataset": {
      "sourceUrl": "https://storage.example.com/data/q4-sales.csv",
      "columns": ["revenue", "profit", "region", "product_category"]
    },
    "analyses": ["descriptive", "correlation", "anova"],
    "options": {
      "confidenceLevel": 0.95,
      "removeOutliers": true
    }
  }
}
```

**Response:**
```json
{
  "analysisId": "analysis_xyz789",
  "results": {
    "descriptive": {
      "revenue": {
        "mean": 125432.50,
        "median": 118000,
        "stdDev": 34521.22,
        "min": 45000,
        "max": 285000
      }
    },
    "correlation": {
      "revenue_profit": 0.92,
      "revenue_region": 0.15
    },
    "anova": {
      "f_statistic": 12.45,
      "p_value": 0.001,
      "significant": true
    }
  },
  "visualizations": [
    {
      "type": "histogram",
      "url": "https://viz.example.com/charts/revenue_dist.png"
    },
    {
      "type": "correlation_matrix",
      "url": "https://viz.example.com/charts/correlation.png"
    }
  ]
}
```

### Scenario 2: Machine Learning Model Training

Train a random forest model for sales prediction.

**Request:**
```json
{
  "skillName": "machine-learning-model",
  "input": {
    "modelType": "random_forest",
    "trainingData": {
      "sourceUrl": "https://storage.example.com/data/historical-sales.csv",
      "features": ["month", "marketing_spend", "season", "region"],
      "target": "revenue"
    },
    "hyperparameters": {
      "n_estimators": 100,
      "max_depth": 10,
      "min_samples_split": 5
    },
    "validationSplit": 0.2
  }
}
```

**Response:**
```json
{
  "modelId": "model_rf_abc123",
  "metrics": {
    "r2Score": 0.87,
    "meanAbsoluteError": 5234.12,
    "rootMeanSquaredError": 7845.33
  },
  "featureImportance": {
    "marketing_spend": 0.45,
    "month": 0.28,
    "season": 0.18,
    "region": 0.09
  },
  "status": "completed"
}
```

### Scenario 3: Real-time Streaming Analytics

Monitor real-time metrics from a data stream.

**Request:**
```json
{
  "skillName": "streaming-analytics",
  "input": {
    "streamSource": "https://stream.example.com/live/metrics",
    "metrics": ["count", "average", "percentile"],
    "windowSize": 60,
    "webhookUrl": "https://your-app.com/webhooks/analytics"
  }
}
```

**Response:**
```json
{
  "streamId": "stream_live_456",
  "sseEndpoint": "https://api.analytics.example.com/streams/stream_live_456/events",
  "status": "active"
}
```

**SSE Stream Events:**
```
data: {"timestamp": "2025-12-20T14:30:00Z", "count": 1245, "average": 342.5, "p95": 890.2}

data: {"timestamp": "2025-12-20T14:31:00Z", "count": 1289, "average": 355.1, "p95": 905.3}
```

### Scenario 4: Data Visualization Dashboard

Create an interactive dashboard with multiple charts.

**Request:**
```json
{
  "skillName": "data-visualization",
  "input": {
    "dataset": {
      "sourceUrl": "https://storage.example.com/data/quarterly-metrics.csv"
    },
    "visualizations": [
      {
        "type": "line",
        "xAxis": "month",
        "yAxis": "revenue",
        "groupBy": "region"
      },
      {
        "type": "bar",
        "xAxis": "product_category",
        "yAxis": "units_sold"
      },
      {
        "type": "heatmap",
        "xAxis": "region",
        "yAxis": "month"
      }
    ],
    "theme": "dark"
  }
}
```

**Response:**
```json
{
  "dashboardUrl": "https://dashboards.example.com/dashboard_abc123",
  "charts": [
    {
      "chartId": "chart_001",
      "imageUrl": "https://viz.example.com/charts/revenue_by_region.png",
      "embedCode": "<iframe src='...'></iframe>"
    },
    {
      "chartId": "chart_002",
      "imageUrl": "https://viz.example.com/charts/units_by_category.png",
      "embedCode": "<iframe src='...'></iframe>"
    }
  ]
}
```

## Webhook Notifications

When streaming analytics detect anomalies or thresholds, webhooks are triggered:

**Webhook Payload:**
```json
{
  "eventType": "threshold_exceeded",
  "streamId": "stream_live_456",
  "timestamp": "2025-12-20T14:35:00Z",
  "metric": "average",
  "value": 425.8,
  "threshold": 400,
  "severity": "warning"
}
```

**Webhook Signature:**
```
X-Webhook-Signature: sha256=abc123...
```

## Deployment Instructions

1. **Generate Complex Agent Card:**
   ```bash
   ./scripts/generate-agent-card.sh --template multi-capability --output data-agent-card.json
   ```

2. **Configure OAuth 2.0:**
   - Set up authorization and token endpoints
   - Configure scopes and permissions
   - Implement token refresh logic

3. **Enable Streaming:**
   - Configure SSE endpoints
   - Set up webhook infrastructure
   - Implement retry logic

4. **Validate and Deploy:**
   ```bash
   ./scripts/validate-agent-card.sh data-agent-card.json
   ./scripts/test-agent-card.sh data-agent-card.json

   # Deploy
   cp data-agent-card.json /var/www/analytics/.well-known/agent.json
   ```

## Rate Limits and Quotas

- **Free Tier:** 10 analyses/day, 100MB datasets
- **Professional:** 100 analyses/hour, 1GB datasets
- **Enterprise:** Unlimited analyses, 10GB datasets, dedicated infrastructure

## Security Best Practices

- Use OAuth 2.0 for production applications
- Implement token refresh logic (tokens expire in 1 hour)
- Validate webhook signatures to prevent spoofing
- Store credentials in secure vaults (never in code)
- Use HTTPS for all communications
- Enable audit logging for compliance
- Rotate secrets regularly (every 90 days)
- Implement rate limiting on client side
