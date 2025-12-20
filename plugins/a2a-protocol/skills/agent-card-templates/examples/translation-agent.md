# Translation Agent Example

This example demonstrates a multi-language translation agent with support for various languages and text formats.

## Agent Card

```json
{
  "id": "urn:example:agent:translator",
  "name": "Universal Translator Agent",
  "description": "Multi-language translation service supporting 100+ languages with text, document, and real-time translation capabilities.",
  "logo": "https://translate.example.com/logo.png",
  "version": "2.3.0",
  "protocolVersion": "0.3",
  "serviceEndpoint": "https://api.translate.example.com/agent",
  "provider": {
    "name": "Global Translation Services",
    "contactEmail": "support@translate.example.com",
    "url": "https://translate.example.com"
  },
  "capabilities": {
    "streaming": true,
    "pushNotifications": false
  },
  "securitySchemes": {
    "bearer_auth": {
      "type": "http",
      "scheme": "bearer"
    },
    "oauth2": {
      "type": "oauth2",
      "flows": {
        "clientCredentials": {
          "tokenUrl": "https://auth.translate.example.com/oauth/token",
          "scopes": {
            "translate": "Translate text",
            "batch": "Batch translation operations"
          }
        }
      }
    }
  },
  "security": [
    {
      "bearer_auth": []
    },
    {
      "oauth2": ["translate"]
    }
  ],
  "skills": [
    {
      "name": "text-translation",
      "description": "Translate text between any supported language pair",
      "inputSchema": {
        "type": "object",
        "properties": {
          "text": {
            "type": "string",
            "description": "Text to translate",
            "maxLength": 10000
          },
          "sourceLanguage": {
            "type": "string",
            "description": "Source language code (ISO 639-1)",
            "pattern": "^[a-z]{2}$"
          },
          "targetLanguage": {
            "type": "string",
            "description": "Target language code (ISO 639-1)",
            "pattern": "^[a-z]{2}$"
          },
          "options": {
            "type": "object",
            "properties": {
              "formality": {
                "type": "string",
                "enum": ["formal", "informal", "default"]
              },
              "preserveFormatting": {
                "type": "boolean"
              }
            }
          }
        },
        "required": ["text", "sourceLanguage", "targetLanguage"]
      },
      "outputSchema": {
        "type": "object",
        "properties": {
          "translatedText": {
            "type": "string"
          },
          "detectedLanguage": {
            "type": "string",
            "description": "Detected source language if auto-detection was used"
          },
          "confidence": {
            "type": "number",
            "minimum": 0,
            "maximum": 1,
            "description": "Translation confidence score"
          }
        }
      },
      "inputModes": ["text/plain", "application/json"],
      "outputModes": ["application/json"],
      "tags": ["translation", "language", "text"],
      "examples": [
        {
          "input": {
            "text": "Hello, how are you?",
            "sourceLanguage": "en",
            "targetLanguage": "es"
          },
          "output": {
            "translatedText": "Hola, ¿cómo estás?",
            "confidence": 0.98
          }
        }
      ]
    },
    {
      "name": "document-translation",
      "description": "Translate entire documents while preserving formatting",
      "inputSchema": {
        "type": "object",
        "properties": {
          "documentUrl": {
            "type": "string",
            "format": "uri",
            "description": "URL of the document to translate"
          },
          "documentFormat": {
            "type": "string",
            "enum": ["pdf", "docx", "txt", "html"],
            "description": "Document format"
          },
          "sourceLanguage": {
            "type": "string",
            "pattern": "^[a-z]{2}$"
          },
          "targetLanguage": {
            "type": "string",
            "pattern": "^[a-z]{2}$"
          }
        },
        "required": ["documentUrl", "documentFormat", "targetLanguage"]
      },
      "outputSchema": {
        "type": "object",
        "properties": {
          "translatedDocumentUrl": {
            "type": "string",
            "format": "uri",
            "description": "URL to download translated document"
          },
          "status": {
            "type": "string",
            "enum": ["processing", "completed", "failed"]
          },
          "estimatedCompletionTime": {
            "type": "string",
            "format": "date-time"
          }
        }
      },
      "tags": ["translation", "document", "batch"]
    },
    {
      "name": "language-detection",
      "description": "Automatically detect the language of provided text",
      "inputSchema": {
        "type": "object",
        "properties": {
          "text": {
            "type": "string",
            "description": "Text to analyze"
          }
        },
        "required": ["text"]
      },
      "outputSchema": {
        "type": "object",
        "properties": {
          "detectedLanguage": {
            "type": "string",
            "description": "ISO 639-1 language code"
          },
          "confidence": {
            "type": "number",
            "minimum": 0,
            "maximum": 1
          },
          "alternatives": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "language": { "type": "string" },
                "confidence": { "type": "number" }
              }
            }
          }
        }
      },
      "tags": ["detection", "language"]
    }
  ],
  "metadata": {
    "supportedLanguages": 107,
    "maxDocumentSize": "50MB",
    "characterLimit": 10000,
    "rateLimit": "500 requests/hour"
  }
}
```

## Authentication Setup

The translation agent supports two authentication methods:

### Method 1: Bearer Token (Simple)

1. Obtain a bearer token from the dashboard
2. Include in Authorization header

```bash
curl -X POST https://api.translate.example.com/agent/task \
  -H "Authorization: Bearer your_bearer_token_here" \
  -H "Content-Type: application/json" \
  -d '{
    "skillName": "text-translation",
    "input": {
      "text": "Hello world",
      "sourceLanguage": "en",
      "targetLanguage": "fr"
    }
  }'
```

### Method 2: OAuth 2.0 Client Credentials (Enterprise)

1. Register your application at https://translate.example.com/apps
2. Obtain client ID and client secret
3. Exchange credentials for access token
4. Use access token in requests

```bash
# Get access token
curl -X POST https://auth.translate.example.com/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=your_client_id_here" \
  -d "client_secret=your_client_secret_here" \
  -d "scope=translate"

# Use access token
curl -X POST https://api.translate.example.com/agent/task \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '...'
```

## Usage Scenarios

### Scenario 1: Simple Text Translation

Translate a short phrase from English to Spanish.

**Request:**
```json
{
  "skillName": "text-translation",
  "input": {
    "text": "The quick brown fox jumps over the lazy dog",
    "sourceLanguage": "en",
    "targetLanguage": "es"
  }
}
```

**Response:**
```json
{
  "translatedText": "El rápido zorro marrón salta sobre el perro perezoso",
  "confidence": 0.95
}
```

### Scenario 2: Formal Translation with Options

Translate with formal tone for business communication.

**Request:**
```json
{
  "skillName": "text-translation",
  "input": {
    "text": "How can I help you today?",
    "sourceLanguage": "en",
    "targetLanguage": "de",
    "options": {
      "formality": "formal"
    }
  }
}
```

**Response:**
```json
{
  "translatedText": "Wie kann ich Ihnen heute helfen?",
  "confidence": 0.97
}
```

### Scenario 3: Language Detection

Detect the language of unknown text.

**Request:**
```json
{
  "skillName": "language-detection",
  "input": {
    "text": "Bonjour, comment allez-vous?"
  }
}
```

**Response:**
```json
{
  "detectedLanguage": "fr",
  "confidence": 0.99,
  "alternatives": [
    { "language": "fr", "confidence": 0.99 },
    { "language": "it", "confidence": 0.01 }
  ]
}
```

### Scenario 4: Document Translation

Translate a PDF document.

**Request:**
```json
{
  "skillName": "document-translation",
  "input": {
    "documentUrl": "https://storage.example.com/documents/contract.pdf",
    "documentFormat": "pdf",
    "sourceLanguage": "en",
    "targetLanguage": "ja"
  }
}
```

**Response:**
```json
{
  "translatedDocumentUrl": "https://storage.example.com/translated/contract_ja.pdf",
  "status": "processing",
  "estimatedCompletionTime": "2025-12-20T15:30:00Z"
}
```

## Deployment Instructions

1. **Create Agent Card from Template:**
   ```bash
   ./scripts/generate-agent-card.sh --template multi-capability --output translator-agent-card.json
   ```

2. **Customize for Translation Service:**
   - Update skills to match translation capabilities
   - Configure OAuth 2.0 endpoints
   - Set supported languages in metadata

3. **Validate Configuration:**
   ```bash
   ./scripts/validate-agent-card.sh translator-agent-card.json
   ./scripts/test-agent-card.sh translator-agent-card.json
   ```

4. **Deploy to Production:**
   ```bash
   # Deploy to well-known location
   cp translator-agent-card.json /var/www/translate/.well-known/agent.json

   # Verify HTTPS access
   curl https://api.translate.example.com/.well-known/agent.json
   ```

## Supported Languages

The translation agent supports 107 languages including:

- **European:** English, Spanish, French, German, Italian, Portuguese, Dutch, Polish, Swedish
- **Asian:** Chinese (Simplified/Traditional), Japanese, Korean, Hindi, Thai, Vietnamese
- **Middle Eastern:** Arabic, Hebrew, Persian, Turkish
- **And many more...**

Full language list available at: https://translate.example.com/languages

## Rate Limits and Quotas

- **Free Tier:** 100 requests/day, 1000 characters/request
- **Basic:** 500 requests/hour, 10000 characters/request
- **Pro:** 2000 requests/hour, 50000 characters/request
- **Enterprise:** Custom limits

## Error Handling

Common error codes:

- `UNSUPPORTED_LANGUAGE`: Language pair not supported
- `TEXT_TOO_LONG`: Text exceeds character limit
- `INVALID_DOCUMENT_FORMAT`: Unsupported document format
- `QUOTA_EXCEEDED`: Rate limit or quota exceeded
- `INVALID_TOKEN`: Authentication token expired or invalid

## Security Best Practices

- Store credentials in environment variables
- Use OAuth 2.0 for production applications
- Rotate tokens regularly
- Never commit credentials to version control
- Use HTTPS for all API requests
- Implement token refresh logic
